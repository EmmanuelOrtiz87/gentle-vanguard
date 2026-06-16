param(
    [ValidateSet("session-start", "session-close", "orchestrator", "manual")]
    [string]$Trigger = "manual",
    [switch]$DryRun,
    [switch]$VerboseOutput,
    [switch]$ForceBaseline
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir '..\..') | Select-Object -ExpandProperty Path

$adaptiveRulesPath = Join-Path $repoRoot "rules\adaptive"
$learnedNormsPath = Join-Path $adaptiveRulesPath "LEARNED-NORMS.md"
$sessionDir = Join-Path $repoRoot ".session"
$rulesDir = Join-Path $repoRoot "rules"

$NewNorms = [System.Collections.ArrayList]::new()
$UpdatedNorms = [System.Collections.ArrayList]::new()
$PromotedNorms = [System.Collections.ArrayList]::new()
$StaleNorms = [System.Collections.ArrayList]::new()
$UsedIDs = @{}  # track session-level IDs to avoid collisions

function Write-Learn {
    param([string]$Message)
    if ($VerboseOutput) { Write-Host "[LEARNER] $Message" -ForegroundColor Magenta }
}

function Write-LearnNew {
    param([string]$Message)
    Write-Host "[NEW-NORM] $Message" -ForegroundColor Green
}

function Write-LearnUpdate {
    param([string]$Message)
    Write-Host "[UPDATE-NORM] $Message" -ForegroundColor Yellow
}

function Write-LearnPromote {
    param([string]$Message)
    Write-Host "[PROMOTE] $Message" -ForegroundColor Cyan
}

function Write-LearnStale {
    param([string]$Message)
    Write-Host "[STALE] $Message" -ForegroundColor DarkGray
}

function Get-CurrentNorms {
    $norms = [System.Collections.ArrayList]::new()
    if (-not (Test-Path $learnedNormsPath)) { return $norms }
    $content = Get-Content $learnedNormsPath -Raw
    $regex = [regex]::new('\| (\w+-\d+) \| (.+?) \| (\w+) \| (.+?) \| (\d{4}-\d{2}-\d{2}) \|')
    $matches = $regex.Matches($content)
    foreach ($m in $matches) {
        [void]$norms.Add([PSCustomObject]@{
            ID = $m.Groups[1].Value
            Norm = $m.Groups[2].Value.Trim()
            Confidence = $m.Groups[3].Value.Trim()
            Source = $m.Groups[4].Value.Trim()
            Date = $m.Groups[5].Value.Trim()
            ValidationCount = 0
        })
    }
    return $norms
}

function Get-NextNormID {
    param([string]$Prefix)
    $existing = Get-CurrentNorms | Where-Object { $_.ID -match "^$Prefix-\d+" } | ForEach-Object { [int]($_.ID -split '-')[1] }
    $allIds = @($existing) + @($UsedIDs.Keys | Where-Object { $_ -match "^$Prefix-\d+" } | ForEach-Object { [int]($_ -split '-')[1] })
    if ($allIds.Count -eq 0) { $next = 1 } else { $next = (($allIds | Measure-Object -Maximum).Maximum) + 1 }
    $newId = "$Prefix-$($next.ToString('000'))"
    $UsedIDs[$newId] = $true
    return $newId
}

function Get-EngramPatterns {
    Write-Learn "Querying Engram for session observations..."
    $patterns = [System.Collections.ArrayList]::new()

    $engramExe = Join-Path $repoRoot "tools\engram.exe"
    if (-not (Test-Path $engramExe)) {
        Write-Learn "engram.exe not found — using file-based discovery"
        return Get-FileBasedPatterns
    }

    try {
        $result = & $engramExe search --project gentle-vanguard --limit 20 --type session_summary 2>&1
        if ($LASTEXITCODE -eq 0 -and $result) {
            $lines = $result | Where-Object { $_ -is [string] -and $_ -match '(?i)(learned|pattern|norm|recurring|always|never|fixed|bug|issue)' }
            foreach ($line in $lines) {
                [void]$patterns.Add([PSCustomObject]@{
                    Type = 'engram'
                    Pattern = $line
                    Source = 'engram-memory'
                    Frequency = 1
                })
            }
        }
    } catch {
        Write-Learn "Engram query failed: $_ — falling back to file scan"
    }

    if ($patterns.Count -eq 0) {
        Write-Learn "No engram patterns found — falling back to file scan"
        return Get-FileBasedPatterns
    }

    Write-Learn "Found $($patterns.Count) patterns from Engram"
    return $patterns
}

function Get-FileBasedPatterns {
    Write-Learn "Scanning session artifacts for patterns..."
    $patterns = [System.Collections.ArrayList]::new()
    $seen = @{}

    $searchPaths = @()
    if (Test-Path $sessionDir) { $searchPaths += $sessionDir }

    foreach ($dir in $searchPaths) {
        $files = Get-ChildItem -Path $dir -Include "*.md", "*.json" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 30
        foreach ($f in $files) {
            $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
            if (-not $content) { continue }

            if ($f.Extension -eq '.md') {
                $sections = [regex]::Matches($content, '(?<=## (Discoveries|Key Learnings|Accomplished|Learned))\s*\n(.*?)(?=\n## |\z)', [System.Text.RegularExpressions.RegexOptions]::Singleline)
                foreach ($s in $sections) {
                    $lines = ($s.Value -split "`n") | Where-Object { $_ -match '^-\s+' }
                    foreach ($line in $lines) {
                        $clean = $line -replace '^-\s+', '' -replace '\[(x| )\]\s*', '' -replace '`', ''
                        if ($clean.Length -gt 15 -and -not $seen.ContainsKey($clean.Substring(0, 30))) {
                            $seen[$clean.Substring(0, 30)] = $true
                            [void]$patterns.Add([PSCustomObject]@{
                                Type = if ($clean -match '(?i)(doc|docs|readme|md)') { 'documentation' } elseif ($clean -match '(?i)(bug|fix|error|crash)') { 'correction' } else { 'learning' }
                                Pattern = $clean
                                Source = $f.Name
                                Frequency = 1
                            })
                        }
                    }
                }
            } elseif ($f.Extension -eq '.json') {
                try {
                    $json = $content | ConvertFrom-Json -ErrorAction SilentlyContinue
                    $jsonText = $content
                    $patternLines = [regex]::Matches($jsonText, '(?i)(learned|pattern|norm|recurring|always|never|fixed|bug|issue).{0,200}') | ForEach-Object { $_.Value }
                    foreach ($pl in $patternLines) {
                        $clean = $pl -replace '"', '' -replace '\{|\}', '' -replace '\[|\]', '' -replace '\\u\d+', ''
                        if ($clean.Length -gt 20 -and -not $seen.ContainsKey($clean.Substring(0, 30))) {
                            $seen[$clean.Substring(0, 30)] = $true
                            [void]$patterns.Add([PSCustomObject]@{
                                Type = 'learning'
                                Pattern = $clean.Trim()
                                Source = $f.Name
                                Frequency = 1
                            })
                        }
                    }
                } catch { Write-Learn "Could not parse $($f.Name) as JSON" }
            }
        }
    }

    if ($patterns.Count -eq 0 -and $ForceBaseline) {
        Write-Learn "No patterns found — generating baseline from existing rules..."
        return Get-BaselinePatterns
    }

    Write-Learn "Found $($patterns.Count) patterns from file scan"
    return $patterns
}

function Get-BaselinePatterns {
    $patterns = [System.Collections.ArrayList]::new()
    $seen = @{}

    $ruleFiles = Get-ChildItem -Path $rulesDir -Filter "*.md" -File -ErrorAction SilentlyContinue | Select-Object -First 20
    foreach ($rf in $ruleFiles) {
        $content = Get-Content $rf.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        $fileName = $rf.Name

        # Extract section headings (## or ###) followed by content as readable norms
        $sections = [regex]::Matches($content, '(?m)^(#{2,3})\s+(.+?)$(?:\s*\n(.*?))?(?=\n#{2,3}\s|\z)')
        foreach ($s in $sections) {
            $heading = $s.Groups[2].Value.Trim()
            $bodyText = if ($s.Groups[3].Success) { $s.Groups[3].Value.Trim() } else { '' }
            $firstLine = ($bodyText -split "`n" | Where-Object { $_ -match '\S' } | Select-Object -First 1) -replace '^[-*\d.\[\]]+\s*', ''
            $normText = if ($firstLine) { "${heading}: $firstLine" } else { $heading }
            $dedupKey = $normText.Substring(0, [Math]::Min(60, $normText.Length))
            $normText = $normText -replace "`n|`r", ' ' -replace '\s+', ' '

            if ($normText.Length -gt 15 -and -not $seen.ContainsKey($dedupKey)) {
                $seen[$dedupKey] = $true
                [void]$patterns.Add([PSCustomObject]@{
                    Type = if ($normText -match '(?i)(doc|docs|readme|documentación)') { 'documentation' } elseif ($normText -match '(?i)(bug|fix|error|crash|corregir)') { 'correction' } else { 'learning' }
                    Pattern = $normText
                    Source = $fileName
                    Frequency = 1
                })
            }
        }

        # Also extract lines with "Rule:" or "NORM-XXX" patterns as actionable norms
        $ruleLines = [regex]::Matches($content, '(?im)^\s*(?:[-*]\s*)?(?:Rule:|Norm[^\n]+?:\s*).*$')
        foreach ($rl in $ruleLines) {
            $normText = $rl.Value.Trim() -replace "^[-*\s]+", ''
            $dedupKey = $normText.Substring(0, [Math]::Min(60, $normText.Length))
            if ($normText.Length -gt 20 -and -not $seen.ContainsKey($dedupKey)) {
                $seen[$dedupKey] = $true
                [void]$patterns.Add([PSCustomObject]@{
                    Type = 'learning'
                    Pattern = $normText
                    Source = $fileName
                    Frequency = 1
                })
            }
        }

        # Extract "Always ..." and "Never ..." sentences as actionable norms
        $actionLines = [regex]::Matches($content, '(?i)((?:Always|Never|MUST|SHOULD|Prohibido|Obligatorio|Required)\s+[^.]*\.)')
        foreach ($al in $actionLines) {
            $normText = $al.Value.Trim()
            $dedupKey = $normText.Substring(0, [Math]::Min(60, $normText.Length))
            if ($normText.Length -gt 15 -and -not $seen.ContainsKey($dedupKey)) {
                $seen[$dedupKey] = $true
                [void]$patterns.Add([PSCustomObject]@{
                    Type = 'learning'
                    Pattern = $normText
                    Source = $fileName
                    Frequency = 1
                })
            }
        }
    }

    Write-Learn "Generated $($patterns.Count) baseline patterns from $($ruleFiles.Count) rule files"
    return $patterns
}

function Invoke-Learning {
    Write-Host "`n[NORM-LEARNER] Trigger: $Trigger" -ForegroundColor Magenta

    $patterns = if ($ForceBaseline) { Get-BaselinePatterns } else { Get-EngramPatterns }
    $currentNorms = Get-CurrentNorms

    # Deduplicate IDs: keep last occurrence of each ID to fix corrupted files with duplicate IDs
    if ($currentNorms.Count -gt 0) {
        $seenIds = @{}
        $deduped = [System.Collections.ArrayList]::new()
        foreach ($n in $currentNorms) {
            if (-not $seenIds.ContainsKey($n.ID)) {
                $seenIds[$n.ID] = $true
                [void]$deduped.Add($n)
            } else {
                Write-Learn "Dropping duplicate ID $($n.ID) from $($n.Source)"
            }
        }
        $currentNorms = $deduped
    }

    # On ForceBaseline, write a fresh file (backup old first)
    if ($ForceBaseline -and (Test-Path $learnedNormsPath)) {
        $backup = $learnedNormsPath -replace '\.md$', ".bak.$(Get-Date -Format 'yyyyMMddHHmmss').md"
        Copy-Item -Path $learnedNormsPath -Destination $backup -Force -ErrorAction SilentlyContinue
        Write-Learn "Backed up existing norms to $backup"
        Remove-Item -Path $learnedNormsPath -Force -ErrorAction SilentlyContinue
        $currentNorms = [System.Collections.ArrayList]::new()
        Write-Learn "ForceBaseline: starting clean (backup saved)"
    }

    $merged = @{}
    foreach ($p in $patterns) {
        $key = $p.Pattern.Substring(0, [Math]::Min(40, $p.Pattern.Length))
        if ($merged.ContainsKey($key)) {
            $merged[$key].Frequency++
        } else {
            $merged[$key] = $p
        }
    }

    foreach ($key in $merged.Keys) {
        $p = $merged[$key]
        Write-Learn "  Processing: $($p.Pattern.Substring(0, [Math]::Min(60, $p.Pattern.Length)))..."
        $matchWords = ($p.Pattern -split '\s+')[0..3] -join ' '
        $matchEscaped = [regex]::Escape($matchWords)
        $existing = $currentNorms | Where-Object { $_.Norm -match $matchEscaped } | Select-Object -First 1

        if ($existing) {
            $existing.ValidationCount++
            Write-LearnUpdate "  Norm $($existing.ID) validated (x$($existing.ValidationCount))"
            [void]$UpdatedNorms.Add($existing.ID)

            if ($existing.ValidationCount -ge 3) {
                Write-LearnPromote "  $($existing.ID) ready for promotion"
                [void]$PromotedNorms.Add($existing)
            }
        } else {
            $prefix = switch -Regex ($p.Type) {
                'documentation' { 'DOC' }
                'correction' { 'CORR' }
                'learning' { 'LEARN' }
                default { 'GEN' }
            }
            $newID = Get-NextNormID -Prefix $prefix
            $newNorm = [PSCustomObject]@{
                ID = $newID
                Norm = $p.Pattern
                Confidence = if ($ForceBaseline) { 'medium' } else { 'low' }
                Source = $p.Source
                Date = Get-Date -Format 'yyyy-MM-dd'
            }
            Write-LearnNew "  $newID : $($p.Pattern.Substring(0, [Math]::Min(60, $p.Pattern.Length)))"
            [void]$NewNorms.Add($newNorm)
        }
    }

    $thirtyDaysAgo = (Get-Date).AddDays(-30).ToString('yyyy-MM-dd')
    foreach ($n in $currentNorms) {
        if ($n.Date -lt $thirtyDaysAgo -and $n.Confidence -ne 'critical') {
            Write-LearnStale "  $($n.ID) stale since $($n.Date)"
            [void]$StaleNorms.Add($n)
        }
    }
}

function Update-LearnedNorms {
    if ($DryRun) {
        Write-Host "`n[DRY-RUN] Would update LEARNED-NORMS.md" -ForegroundColor Yellow
        return
    }

    Write-Learn "Writing LEARNED-NORMS.md..."
    $current = Get-CurrentNorms
    if ($null -eq $current) { $current = [System.Collections.ArrayList]::new() }
    $allNorms = [System.Collections.ArrayList]::new()
    foreach ($n in $current) { [void]$allNorms.Add($n) }
    foreach ($n in $NewNorms) { [void]$allNorms.Add($n) }
    $activeNorms = $allNorms | Where-Object { $_.ID -notin $StaleNorms.ID }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('# Learned Norms (Autonomous)')
    $lines.Add('')
    $lines.Add('Auto-maintained by auto-norm-learner.ps1 — last run: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm'))
    $lines.Add('')

    $groups = $activeNorms | Group-Object { ($_.ID -split '-')[0] }
    foreach ($g in $groups) {
        $lines.Add("## $($g.Name) Norms")
        $lines.Add('')
        $lines.Add('| ID | Norm | Confidence | Source | Date |')
        $lines.Add('|----|------|------------|--------|------|')
        foreach ($n in $g.Group | Sort-Object ID) {
            $normText = $n.Norm -replace '\|', '/' -replace "`n", ' '
            if ($normText.Length -gt 2000) { $normText = $normText.Substring(0, 1997) + '...' }
            $lines.Add("| $($n.ID) | $normText | $($n.Confidence) | $($n.Source) | $($n.Date) |")
        }
        $lines.Add('')
    }

    $lines.Add('## Statistics')
    $lines.Add('')
    $lines.Add("- Total norms: $($activeNorms.Count)")
    $lines.Add("- New norms: $($NewNorms.Count)")
    $lines.Add("- Updated norms: $($UpdatedNorms.Count)")
    $lines.Add("- Promoted norms: $($PromotedNorms.Count)")
    $lines.Add("- Pruned stale norms: $($StaleNorms.Count)")
    $lines.Add("- Last trigger: $Trigger")

    Set-Content -Path $learnedNormsPath -Value ($lines -join "`n") -Encoding UTF8
    Write-Learn "LEARNED-NORMS.md updated"
}

Invoke-Learning
Update-LearnedNorms

Write-Host "`n[NORM-LEARNER] Summary: $($NewNorms.Count) new, $($UpdatedNorms.Count) updated, $($PromotedNorms.Count) promoted, $($StaleNorms.Count) pruned" -ForegroundColor Cyan
