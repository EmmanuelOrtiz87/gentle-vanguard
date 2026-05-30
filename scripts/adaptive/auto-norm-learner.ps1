<#
.SYNOPSIS
    Autonomous Norm Learner — queries Engram memory and session artifacts for patterns,
    extracts learnings, and updates LEARNED-NORMS.md with new/updated norms.

.DESCRIPTION
    Runs at session start/close or on orchestrator demand.
    - Queries Engram via `mem_search` for patterns
    - Scans session summaries in .session/ and .local/session-artifacts/
    - Identifies recurring patterns → creates/updates norms
    - Promotes high-confidence (≥3 occurrences) norms
    - Prunes stale norms (no validation in 30+ days)

.PARAMETER Trigger
    What triggered this run: session-start, session-close, orchestrator, manual

.PARAMETER DryRun
    Simulate without writing changes

.PARAMETER VerboseOutput
    Show detailed output

.EXAMPLE
    .\auto-norm-learner.ps1 -Trigger session-close -VerboseOutput

.NOTES
    Author: gentle-vanguard
    Version: 2.0.0
#>

param(
    [ValidateSet("session-start", "session-close", "orchestrator", "manual")]
    [string]$Trigger = "manual",
    [switch]$DryRun,
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir '..\..') | Select-Object -ExpandProperty Path

$adaptiveRulesPath = Join-Path $repoRoot "rules\adaptive"
$learnedNormsPath = Join-Path $adaptiveRulesPath "LEARNED-NORMS.md"
$sessionDir = Join-Path $repoRoot ".session"
$artifactsDir = Join-Path $repoRoot ".local\session-artifacts"

$NewNorms = [System.Collections.ArrayList]::new()
$UpdatedNorms = [System.Collections.ArrayList]::new()
$PromotedNorms = [System.Collections.ArrayList]::new()
$StaleNorms = [System.Collections.ArrayList]::new()

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

# Load current learned norms from LEARNED-NORMS.md
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

# Generate next norm ID for a prefix
function Get-NextNormID {
    param([string]$Prefix)
    $existing = Get-CurrentNorms | Where-Object { $_.ID -match "^$Prefix-\d+" } | ForEach-Object { [int]($_.ID -split '-')[1] }
    if ($existing.Count -eq 0) { return "$Prefix-001" }
    $max = ($existing | Measure-Object -Maximum).Maximum
    return "$Prefix-$($max + 1).ToString('000')"
}

# Query Engram for session observations
function Get-EngramPatterns {
    Write-Learn "Querying Engram for session observations..."
    $patterns = [System.Collections.ArrayList]::new()

    $engramExe = Join-Path $repoRoot "tools\engram.exe"
    if (-not (Test-Path $engramExe)) {
        Write-Learn "engram.exe not found at $engramExe — using file-based discovery"
        return Get-FileBasedPatterns
    }

    try {
        $result = & $engramExe search --project gentle-vanguard --limit 20 --type session_summary 2>$null
        if ($LASTEXITCODE -eq 0 -and $result) {
            $lines = $result | Where-Object { $_ -match '(?i)(learned|pattern|norm|recurring|always|never|fixed|bug|issue)' }
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

    Write-Learn "Found $($patterns.Count) patterns from Engram"
    return $patterns
}

# Fallback: scan session summaries and artifact directories
function Get-FileBasedPatterns {
    Write-Learn "Scanning session artifacts for patterns..."
    $patterns = [System.Collections.ArrayList]::new()
    $seen = @{}

    $searchPaths = @()
    if (Test-Path $sessionDir) { $searchPaths += $sessionDir }
    if (Test-Path $artifactsDir) { $searchPaths += $artifactsDir }

    foreach ($dir in $searchPaths) {
        $files = Get-ChildItem -Path $dir -Filter "*.md" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 20
        foreach ($f in $files) {
            $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
            if (-not $content) { continue }

            # Extract "## Discoveries" / "## Key Learnings" / "## Accomplished" sections
            $sections = $content | Select-String -Pattern '(?<=## (Discoveries|Key Learnings|Accomplished|Learned))\s*[\s\S]*?(?=## |\z)' -AllMatches
            foreach ($s in $sections.Matches) {
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
        }
    }

    Write-Learn "Found $($patterns.Count) patterns from file scan"
    return $patterns
}

# Match patterns against existing norms, create new ones
function Invoke-Learning {
    Write-Host "`n[NORM-LEARNER] Trigger: $Trigger" -ForegroundColor Magenta

    $patterns = Get-EngramPatterns
    $currentNorms = Get-CurrentNorms

    # Merge duplicate patterns
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
        $firstWords = ($p.Pattern -split ' ')[0..2] -join ' '
        $existing = $currentNorms | Where-Object { $_.Norm -like "*$firstWords*" } | Select-Object -First 1

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
                Confidence = 'low'
                Source = $p.Source
                Date = Get-Date -Format 'yyyy-MM-dd'
            }
            Write-LearnNew "  $newID : $($p.Pattern.Substring(0, [Math]::Min(60, $p.Pattern.Length)))"
            [void]$NewNorms.Add($newNorm)
        }
    }

    # Prune stale norms (no validation in 30d)
    $thirtyDaysAgo = (Get-Date).AddDays(-30).ToString('yyyy-MM-dd')
    foreach ($n in $currentNorms) {
        if ($n.Date -lt $thirtyDaysAgo -and $n.Confidence -ne 'critical') {
            Write-LearnStale "  $($n.ID) stale since $($n.Date)"
            [void]$StaleNorms.Add($n)
        }
    }
}

# Write updated LEARNED-NORMS.md
function Update-LearnedNorms {
    if ($DryRun) {
        Write-Host "`n[DRY-RUN] Would update LEARNED-NORMS.md" -ForegroundColor Yellow
        return
    }

    Write-Learn "Writing LEARNED-NORMS.md..."
    $allNorms = Get-CurrentNorms
    foreach ($n in $NewNorms) { [void]$allNorms.Add($n) }
    $activeNorms = $allNorms | Where-Object { $_.ID -notin $StaleNorms.ID }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('# Learned Norms (Autonomous)')
    $lines.Add('')
    $lines.Add('Auto-maintained by auto-norm-learner.ps1 — last run: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm'))
    $lines.Add('')

    # Group by prefix
    $groups = $activeNorms | Group-Object { ($_.ID -split '-')[0] }
    foreach ($g in $groups) {
        $lines.Add("## $($g.Name) Norms")
        $lines.Add('')
        $lines.Add('| ID | Norm | Confidence | Source | Date |')
        $lines.Add('|----|------|------------|--------|------|')
        foreach ($n in $g.Group | Sort-Object ID) {
            $lines.Add("| $($n.ID) | $($n.Norm) | $($n.Confidence) | $($n.Source) | $($n.Date) |")
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
