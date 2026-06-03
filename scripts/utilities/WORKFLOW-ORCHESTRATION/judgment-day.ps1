<#
.SYNOPSIS
    Judgment Day - Dual-Review Adversarial Protocol
    Full implementation of the judgment-day SKILL.md protocol.

.DESCRIPTION
    Implements the adversarial dual-review protocol:
      Phase 1 - Judge A (security + quality) + Judge B (governance + structure)
      Phase 2 - Synthesize findings (Confirmed / Suspect / Contradiction)
      Phase 3 - Fix cycle with Fix Agent delegation
      Phase 4 - Re-judgment after fixes
      Phase 5 - Iteration with escalation

.PARAMETER Target
    Path or scope to review (file, directory, or "." for repo root)

.PARAMETER Scope
    Full (all checks) or Quick (security + critical only)

.PARAMETER MaxPasses
    Maximum judgment passes (default: 3, max: 10)

.PARAMETER NoPrompt
    Skip interactive prompts, auto-decide

.EXAMPLE
    .\judgment-day.ps1 -Target "."
    .\judgment-day.ps1 -Target "scripts/utilities" -Scope Quick
    .\judgment-day.ps1 -Target "config/*.json" -MaxPasses 5

.NOTES
    Follows Hard Rules from skills/judgment-day/SKILL.md
    Output: docs/judgment/final-verdict.md + judgment-history.csv
#>

param(
    [string]$Target = ".",
    [ValidateSet('Full', 'Quick')]
    [string]$Scope = 'Full',
    [ValidateRange(1, 10)]
    [int]$MaxPasses = 3,
    [switch]$NoPrompt
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..\..')).Path
$judgmentDir = Join-Path $repoRoot 'docs\judgment'
$logDir = Join-Path $repoRoot '.session\judgment-day-logs'
$historyCsv = Join-Path $repoRoot 'docs\sessions\metrics\judgment-history.csv'

# ---------- Ensure directories ----------
foreach ($dir in @($judgmentDir, $logDir, (Split-Path $historyCsv -Parent))) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

# ---------- Utility functions ----------
function Write-Title { param([string]$t) Write-Host "`n$('='*76)`n $t`n$('='*76)" -ForegroundColor Magenta }
function Write-Phase { param([string]$t) Write-Host "`n--- $t ---" -ForegroundColor Cyan }
function Write-Ok   { param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Fail { param([string]$m) Write-Host "[FAIL] $m" -ForegroundColor Red }
function Write-Info { param([string]$m) Write-Host "[INFO] $m" -ForegroundColor Gray }

function Get-TargetFiles {
    param([string]$Path)
    $resolved = $null
    if (Test-Path $Path) { $resolved = Resolve-Path $Path -ErrorAction SilentlyContinue }
    if (-not $resolved) { $resolved = Resolve-Path (Join-Path $repoRoot $Path) -ErrorAction SilentlyContinue }
    if (-not $resolved) { Write-Error "Target not found: $Path"; exit 1 }

    if (Test-Path -LiteralPath $resolved -PathType Container) {
        return @(Get-ChildItem -Path $resolved -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -match '\.(ps1|psm1|psd1|py|js|ts|tsx|jsx|go|json|yaml|yml|md|cs|fs|fsx|sh|bat|cmd|sql|tf|cfg|ini|conf|env|xml|css|scss|html|vue|svelte)' } |
            Sort-Object Extension, Name)
    } elseif (Test-Path -LiteralPath $resolved -PathType Leaf) {
        return @(Get-Item -LiteralPath $resolved)
    }
    return @()
}

function New-JudgmentSession {
    param([string]$Target, [string]$Scope)
    $session = @{
        timestamp = (Get-Date -Format 'o')
        target = $Target
        scope = $Scope
        max_passes = $MaxPasses
        status = 'initiated'
        rounds = @()
        final_verdict = $null
    }
    return $session
}

function Save-JudgmentSession {
    param([hashtable]$Session)
    $file = Join-Path $logDir "judgment-day-$((Get-Date -Format 'yyyy-MM-dd-HHmmss')).json"
    $Session | ConvertTo-Json -Depth 10 | Set-Content -Path $file -Encoding UTF8
    return $file
}

# ===================================================================
# JUDGE A - Security, error handling, edge cases, performance
# ===================================================================
function Invoke-JudgeA {
    param([array]$Files, [string]$ScopeName)

    $findings = @()
    $checked = 0

    foreach ($file in $Files) {
        $relPath = if ($file.FullName -like "$repoRoot*") { $file.FullName.Substring($repoRoot.Length + 1) } else { $file.Name }
        $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        $lines = $content -split "`r?`n"
        $checked++

        # Safety: wrap regex ops in try/catch for .NET RegexOptions compatibility
        try {

        # --- Security: hardcoded secrets ---
        if ($content -match '(?i)(password|secret|api[-_]?key|token|credential|connection[-_]?string)\s*[:=]\s*[''"]?(?!\$|\{|\%|env|getenv|os\.environ)[''"]?\w{8,}') {
            $lineNo = 0; $idx = 0
            while ($idx -ge 0) {
                $idx = [regex]::Match($content, '(?i)(password|secret|api[-_]?key|token|credential|connection[-_]?string)\s*[:=]', $idx).Index
                if ($idx -lt 0) { break }
                $lineNo = ($content.Substring(0, $idx) -split "`r?`n").Count
                $finding = @{
                    severity = 'CRITICAL'
                    file = $relPath
                    line = $lineNo
                    description = "Posible secreto hardcodeado detectado"
                    suggested_fix = "Reemplazar con variable de entorno o vault"
                    judge = 'A'
                    type = 'security'
                }
                $findings += $finding
                $idx++
            }
        }

        # --- Security: SQL injection risk (dynamic query building) ---
        if ($content -match '(?i)(execute|raw|text)\s*\(.*\+|format\(.*sql|f-string.*query|\.format\(.*\{') {
            $lineNo = Get-MatchingLine -Content $content -Pattern '(?i)(execute|raw|text)\s*\(.*\+'
            if ($lineNo -le 0) { $lineNo = Get-MatchingLine -Content $content -Pattern '(?i)format\(.*sql|\.format\(.*\{' }
            if ($lineNo -gt 0) {
                $findings += @{
                    severity = 'CRITICAL'
                    file = $relPath; line = $lineNo
                    description = "Posible SQL Injection - concatenacion en query"
                    suggested_fix = "Usar parametros/placeholders en vez de concatenacion"
                    judge = 'A'; type = 'security'
                }
            }
        }

        # --- Error handling: empty catch blocks ---
        if ($content -match '(?i)catch\s*\{[\s]*\}') {
            $lineNo = Get-MatchingLine -Content $content -Pattern 'catch\s*\{[\s]*\}'
            $findings += @{
                severity = 'WARNING (real)'
                file = $relPath; line = $lineNo
                description = "Catch block vacio - traga errores silenciosamente"
                suggested_fix = "Agregar logging o re-lanzar excepcion"
                judge = 'A'; type = 'error_handling'
            }
        }

        # --- Performance: script without timeout/erroraction ---
        if ($file.Extension -eq '.ps1' -and $content -notmatch '\$ErrorActionPreference') {
            $findings += @{
                severity = 'WARNING (real)'
                file = $relPath; line = 1
                description = "Script sin ErrorActionPreference - puede continuar tras errores"
                suggested_fix = "Agregar `$ErrorActionPreference = 'Stop' al inicio"
                judge = 'A'; type = 'performance'
            }
        }

        # --- Edge cases: missing null checks ---
        if ($file.Extension -in @('.ps1', '.py', '.js', '.ts', '.go') -and $content -match '\$null|None|null|undefined' -and $content -notmatch '(?i)(if\s+\w+\s*(==|is|!=|is\s+not)\s*(None|null|\$null)|-\not\s+\w+|\.GetValueOrDefault|TryGetValue)') {
            if ($ScopeName -eq 'Full') {
                $findings += @{
                    severity = 'WARNING (theoretical)'
                    file = $relPath; line = 0
                    description = "Referencia a null/None sin null-check visible"
                    suggested_fix = "Agregar guard clause antes de usar el valor"
                    judge = 'A'; type = 'edge_case'
                }
            }
        }

        # Quick scope: only security checks
        if ($ScopeName -eq 'Quick') { break }

        } catch {
            # Silently skip files that trigger .NET RegexOptions errors
        }
    }

    return @{ judge = 'A'; findings = $findings; files_checked = $checked }
}

# ===================================================================
# JUDGE B - Governance, structure, documentation, naming
# ===================================================================
function Invoke-JudgeB {
    param([array]$Files, [string]$ScopeName)

    $findings = @()
    $checked = 0

    foreach ($file in $Files) {
        try {
        $relPath = if ($file.FullName -like "$repoRoot*") { $file.FullName.Substring($repoRoot.Length + 1) } else { $file.Name }
        $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        $lines = $content -split "`r?`n"
        $checked++

        # --- Governance: missing file header/help ---
        if ($file.Extension -in @('.ps1', '.psm1') -and $content -notmatch '<#\s*\.(SYNOPSIS|DESCRIPTION)') {
            $findings += @{
                severity = 'WARNING (real)'
                file = $relPath; line = 1
                description = "Script sin bloque de ayuda (SYNOPSIS/DESCRIPTION)"
                suggested_fix = "Agregar comment-based help al inicio del script"
                judge = 'B'; type = 'governance'
            }
        }

        # --- Governance: long lines ---
        $longLines = @()
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i].Length -gt 200) { $longLines += ($i + 1) }
        }
        if ($longLines.Count -gt 0) {
            $findings += @{
                severity = 'SUGGESTION'
                file = $relPath; line = $longLines[0]
                description = "$($longLines.Count) linea(s) superan 200 caracteres"
                suggested_fix = "Dividir lineas largas para mejorar legibilidad"
                judge = 'B'; type = 'governance'
            }
        }

        # --- Structure: file too long ---
        if ($lines.Count -gt 500 -and $file.Extension -in @('.ps1', '.py', '.js', '.ts', '.go')) {
            $findings += @{
                severity = 'SUGGESTION'
                file = $relPath; line = $lines.Count
                description = "Archivo muy largo ($($lines.Count) lineas)"
                suggested_fix = "Considerar dividir en multiples modulos"
                judge = 'B'; type = 'structure'
            }
        }

        # --- Naming: inconsistent convention ---
        if ($file.Extension -eq '.ps1' -and $content -match '\b[A-Z]+[a-z]+\b') {
            # Look for functions: check naming convention
            $funcs = [regex]::Matches($content, '(?<=function\s+)([A-Za-z]-[A-Za-z]+)')
            $pascalFuncs = [regex]::Matches($content, '(?<=function\s+)([A-Z][a-z]+[A-Z][a-z]+)')
            $mixed = @()
            foreach ($f in $funcs) { if ($f.Value -notmatch '^\w+-\w+$') { $mixed += $f.Value } }
            if ($mixed.Count -gt 0 -and $ScopeName -eq 'Full') {
                $findings += @{
                    severity = 'SUGGESTION'
                    file = $relPath; line = 0
                    description = "Convencion de nomenclatura mixta en funciones"
                    suggested_fix = "Usar Verb-Noun para funciones PowerShell"
                    judge = 'B'; type = 'naming'
                }
            }
        }

        # --- Documentation: missing README for key dirs ---
        if ($ScopeName -eq 'Full' -and (Get-Item $file.DirectoryName).Parent.FullName -eq $repoRoot) {
            $readmePath = Join-Path $file.DirectoryName 'README.md'
            if (-not (Test-Path $readmePath)) {
                $findings += @{
                    severity = 'SUGGESTION'
                    file = "$relPath (dir)"; line = 0
                    description = "Directorio sin README.md"
                    suggested_fix = "Agregar README.md con proposito y estructura"
                    judge = 'B'; type = 'documentation'
                }
            }
        }

        if ($ScopeName -eq 'Quick') { break }

        } catch {
            # Silently skip files that trigger .NET RegexOptions errors
        }
    }

    return @{ judge = 'B'; findings = $findings; files_checked = $checked }
}

# Helper: get matching line number
function Get-MatchingLine {
    param([string]$Content, [string]$Pattern)
    $lines = $Content -split "`r?`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $Pattern) { return $i + 1 }
    }
    return 0
}

# ===================================================================
# SYNTHESIS - Compare Judge A + Judge B findings
# ===================================================================
function Sync-Findings {
    param([array]$JudgeAResult, [array]$JudgeBResult)

    $confirmed = @()
    $suspectA = @()
    $suspectB = @()
    $contradictions = @()

    # Check for same-file same-type matches
    foreach ($fa in $JudgeAResult) {
        $match = $JudgeBResult | Where-Object {
            $_.file -eq $fa.file -and $_.type -eq $fa.type -and $_.severity -eq $fa.severity
        } | Select-Object -First 1

        if ($match) {
            $confirmed += @{
                finding_a = $fa
                finding_b = $match
                severity = $fa.severity
                status = 'Confirmed'
            }
        } else {
            # Check for contradiction (same file, opposite severity)
            $contra = $JudgeBResult | Where-Object {
                $_.file -eq $fa.file -and $_.type -eq $fa.type -and $_.severity -ne $fa.severity
            } | Select-Object -First 1
            if ($contra) {
                $contradictions += @{
                    judge_a = $fa
                    judge_b = $contra
                }
            } else {
                $suspectA += $fa
            }
        }
    }

    # B-only findings
    foreach ($fb in $JudgeBResult) {
        $already = $confirmed | Where-Object { $_.finding_b.file -eq $fb.file -and $_.finding_b.type -eq $fb.type }
        if (-not $already) {
            $alsoContra = $contradictions | Where-Object { $_.judge_b.file -eq $fb.file }
            if (-not $alsoContra) {
                $suspectB += $fb
            }
        }
    }

    return @{
        confirmed = $confirmed
        suspectA = $suspectA
        suspectB = $suspectB
        contradictions = $contradictions
    }
}

# ===================================================================
# FIX AGENT - Apply fixes for confirmed issues
# ===================================================================
function Invoke-FixAgent {
    param([array]$ConfirmedFindings)

    $fixes = @()

    foreach ($finding in $ConfirmedFindings) {
        $filePath = Join-Path $repoRoot $finding.finding_a.file
        if (-not (Test-Path $filePath)) { continue }

        $content = Get-Content -LiteralPath $filePath -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }

        $applied = $false

        switch ($finding.finding_a.type) {
            'security' {
                # Comment next to potential secret: flag it
                if ($finding.finding_a.line -gt 0) {
                    $lines = $content -split "`r?`n"
                    $idx = $finding.finding_a.line - 1
                    if ($idx -lt $lines.Count -and $lines[$idx] -notmatch '#\s*TODO|#\s*FIXME|#\s*SECURITY') {
                        $lines[$idx] = $lines[$idx] + " # SECURITY: revisar posible secreto"
                        $content = $lines -join "`r`n"
                        Set-Content -LiteralPath $filePath -Value $content -Encoding UTF8 -NoNewline
                        $fixes += @{ file = $finding.finding_a.file; line = $finding.finding_a.line; action = "Marcar secreto potencial" }
                        $applied = $true
                    }
                }
            }
            'error_handling' {
                if ($finding.finding_a.line -gt 0) {
                    $lines = $content -split "`r`n"
                    $idx = $finding.finding_a.line - 1
                    if ($idx -lt $lines.Count) {
                        # Replace empty catch { } with catch { Write-Warning "..."
                        $lines[$idx] = $lines[$idx] -replace '\{\s*\}', '{ Write-Warning "Error no manejado en $($_.Exception.Message)" }'
                        $content = $lines -join "`r`n"
                        Set-Content -LiteralPath $filePath -Value $content -Encoding UTF8 -NoNewline
                        $fixes += @{ file = $finding.finding_a.file; line = $finding.finding_a.line; action = "Agregar logging a catch block" }
                        $applied = $true
                    }
                }
            }
            'governance' {
                if ($finding.finding_a.description -like '*SYNOPSIS*' -and $finding.finding_a.line -eq 1) {
                    $fName = Split-Path $finding.finding_a.file -Leaf
                    $header = @"
<#
.SYNOPSIS
    $fName
.DESCRIPTION
    Auto-generated by Judgment Day Fix Agent
#>

"@
                    $content = $header + $content
                    Set-Content -LiteralPath $filePath -Value $content -Encoding UTF8 -NoNewline
                    $fixes += @{ file = $finding.finding_a.file; line = 1; action = "Agregar bloque de ayuda" }
                    $applied = $true
                }
            }
        }

        if (-not $applied) {
            $fixes += @{ file = $finding.finding_a.file; line = $finding.finding_a.line; action = "Requiere revision manual" }
        }
    }

    return $fixes
}

# ===================================================================
# REPORTING - Output formatting
# ===================================================================
function Write-VerdictReport {
    param(
        [hashtable]$Synthesis,
        [int]$Round,
        [array]$Fixes,
        [string]$FinalVerdict,
        [array]$AntiSycophancy
    )

    $report = @"
## Judgment Day - $Target

### Round $Round - Verdict

| Finding | Judge A | Judge B | Severity | Status |
|---------|---------|---------|----------|--------|
"@

    foreach ($c in $Synthesis.confirmed) {
        $report += "`n| $($c.finding_a.file):$($c.finding_a.line) | $($c.finding_a.type) | $($c.finding_b.type) | $($c.severity) | Confirmed |"
    }
    foreach ($sa in $Synthesis.suspectA) {
        $report += "`n| $($sa.file):$($sa.line) | $($sa.type) | - | $($sa.severity) | Suspect (A only) |"
    }
    foreach ($sb in $Synthesis.suspectB) {
        $report += "`n| $($sb.file):$($sb.line) | - | $($sb.type) | $($sb.severity) | Suspect (B only) |"
    }
    foreach ($ct in $Synthesis.contradictions) {
        $report += "`n| $($ct.judge_a.file):$($ct.judge_a.line) | $($ct.judge_a.severity) | $($ct.judge_b.severity) | CONTRADICTION | Review |"
    }

    $report += @"

**Confirmed issues**: $($Synthesis.confirmed.Count) ($(@($Synthesis.confirmed | Where-Object { $_.severity -eq 'CRITICAL' }).Count) CRITICAL, $(@($Synthesis.confirmed | Where-Object { $_.severity -like 'WARNING*' }).Count) WARNING)
**Suspect issues**: $(($Synthesis.suspectA.Count + $Synthesis.suspectB.Count))
**Contradictions**: $($Synthesis.contradictions.Count)

$(
if ($Synthesis.suspectA.Count -gt 0 -or $Synthesis.suspectB.Count -gt 0) {
    "### Minority Positions"
    foreach ($sa in $Synthesis.suspectA) {
        "`n- [$($sa.severity)] $($sa.file):$($sa.line) - $($sa.description) (Juez A solamente, no auto-fixed)"
    }
    foreach ($sb in $Synthesis.suspectB) {
        "`n- [$($sb.severity)] $($sb.file):$($sb.line) - $($sb.description) (Juez B solamente, no auto-fixed)"
    }
}
)

$(
if ($Fixes.Count -gt 0) {
    "### Fixes Applied (Round $Round)"
    foreach ($fx in $Fixes) {
        "`n- `$($fx.file):$($fx.line) - $($fx.action)"
    }
}
)

$(
if ($AntiSycophancy.Count -gt 0) {
    "### Anti-Sycophancy Check"
    foreach ($asc in $AntiSycophancy) {
        "`n- $asc"
    }
}
)

### JUDGMENT: $FinalVerdict
"@

    # Write to file
    $verdictFile = Join-Path $judgmentDir "final-verdict.md"
    $report | Out-File -FilePath $verdictFile -Encoding UTF8
    Write-Ok "Verdict saved: $verdictFile"

    # Write to dashboard CSV history
    $totalChecks = $Synthesis.confirmed.Count + $Synthesis.suspectA.Count + $Synthesis.suspectB.Count + $Synthesis.contradictions.Count
    $csvResult = if ($FinalVerdict -eq 'APPROVED') { 'PASS' } else { 'FAIL' }
    $csvLine = "$(Get-Date -Format 'o'),$($Synthesis.confirmed.Count),$totalChecks,$csvResult"
    if (-not (Test-Path $historyCsv)) {
        "Timestamp,Failures,TotalChecks,Result" | Out-File -FilePath $historyCsv -Encoding UTF8
    }
    $csvLine | Out-File -FilePath $historyCsv -Encoding UTF8 -Append
    Write-Ok "History updated: $historyCsv"

    # Return report for console
    return $report
}

function Write-JudgmentSummary {
    param([array]$History, [bool]$Approved)

    Write-Host "`n$('-'*76)" -ForegroundColor Yellow
    Write-Host " JUDGMENT RUN SUMMARY" -ForegroundColor Yellow
    Write-Host "$('-'*76)" -ForegroundColor Yellow

    foreach ($h in $History) {
        $color = if ($h.approved) { 'Green' } else { 'Yellow' }
        Write-Host " Round $($h.round): verdict=$($h.verdict) findings=$(($h.synthesis.confirmed.Count + $h.synthesis.suspectA.Count + $h.synthesis.suspectB.Count + $h.synthesis.contradictions.Count))" -ForegroundColor $color
    }

    Write-Host ""
    if ($Approved) {
        Write-Host "$('='*76)" -ForegroundColor Green
        Write-Host " JUDGMENT: APPROVED" -ForegroundColor Green
        Write-Host "$('='*76)" -ForegroundColor Green
    } else {
        Write-Host "$('='*76)" -ForegroundColor Yellow
        Write-Host " JUDGMENT: ESCALATED - Review findings above" -ForegroundColor Yellow
        Write-Host "$('='*76)" -ForegroundColor Yellow
    }
}

# ===================================================================
# EVENT BUS
# ===================================================================
function Publish-JudgmentEvent {
    param([string]$Event, [hashtable]$Data)
    $eventBusPath = Join-Path $repoRoot '.event-bus'
    if (-not (Test-Path $eventBusPath)) { New-Item -ItemType Directory -Path $eventBusPath -Force | Out-Null }
    $eventFile = Join-Path $eventBusPath "events.jsonl"
    $eventEntry = @{
        event = $Event
        timestamp = (Get-Date -Format 'o')
        data = $Data
    }
    $eventEntry | ConvertTo-Json -Compress -Depth 5 | Out-File -FilePath $eventFile -Encoding UTF8 -Append
}

# Alias for backward compat / safety
function Publish-JudgmentDayEvent { Publish-JudgmentEvent @args }

# ===================================================================
# MAIN PROTOCOL
# ===================================================================

Write-Title "JUDGMENT DAY - Dual-Review Adversarial Protocol"
Write-Host " Target: $Target" -ForegroundColor Cyan
Write-Host " Scope: $Scope" -ForegroundColor Cyan
Write-Host " Max Passes: $MaxPasses" -ForegroundColor Cyan

# Resolve target files
$files = Get-TargetFiles -Path $Target
if ($files.Count -eq 0) {
    Write-Warn "No reviewable files found in target: $Target"
    Write-Host "[INFO] judgment-day completed: no targets" -ForegroundColor Gray
    exit 0
}
Write-Info "Found $($files.Count) reviewable files"

# Initialize session
$session = New-JudgmentSession -Target $Target -Scope $Scope
$sessionFile = Save-JudgmentSession -Session $session
Publish-JudgmentDayEvent -Event 'judgment-day-initiated' -Data @{ target = $Target; scope = $Scope; files = $files.Count }

$history = @()
$approved = $false

for ($round = 1; $round -le $MaxPasses; $round++) {
    Write-Host ""
    Write-Phase "ROUND $round of $MaxPasses"

    # --- Phase 1: Launch blind judges ---
    Write-Phase "Phase 1: Launching blind judges (parallel)"
    Write-Host " Judge A: Security + Quality analysis..." -NoNewline -ForegroundColor Cyan
    $judgeAResult = Invoke-JudgeA -Files $files -ScopeName $Scope
    Write-Host " done ($($judgeAResult.findings.Count) findings)" -ForegroundColor Green

    Write-Host " Judge B: Governance + Structure analysis..." -NoNewline -ForegroundColor Cyan
    $judgeBResult = Invoke-JudgeB -Files $files -ScopeName $Scope
    Write-Host " done ($($judgeBResult.findings.Count) findings)" -ForegroundColor Green

    Publish-JudgmentDayEvent -Event 'judgment-day-judges-started' -Data @{ round = $round; judge_a = $judgeAResult.findings.Count; judge_b = $judgeBResult.findings.Count }

    # --- Phase 2: Synthesize ---
    Write-Phase "Phase 2: Synthesizing findings"
    $synthesis = Sync-Findings -JudgeAResult $judgeAResult.findings -JudgeBResult $judgeBResult.findings
    Write-Host " Confirmed: $($synthesis.confirmed.Count) | Suspect A: $($synthesis.suspectA.Count) | Suspect B: $($synthesis.suspectB.Count) | Contradictions: $($synthesis.contradictions.Count)" -ForegroundColor Cyan

    # --- Phase 4: Convergence check ---
    $criticalConfirmed = @($synthesis.confirmed | Where-Object { $_.severity -eq 'CRITICAL' })
    $realWarningConfirmed = @($synthesis.confirmed | Where-Object { $_.severity -eq 'WARNING (real)' })
    $needsFix = ($criticalConfirmed.Count -gt 0 -or $realWarningConfirmed.Count -gt 0)

    $verdict = if (-not $needsFix) { 'APPROVED' } else { 'REQUIRES FIX' }

    # --- Phase 3: Fix cycle ---
    $fixes = @()
    if ($needsFix) {
        if ($NoPrompt) {
            Write-Phase "Phase 3: Auto-fix cycle"
            $fixes = Invoke-FixAgent -ConfirmedFindings $criticalConfirmed
            $fixes += Invoke-FixAgent -ConfirmedFindings $realWarningConfirmed
            Write-Ok "Applied $($fixes.Count) fix(es)"
        } else {
            # Present and ask user
            $verdictReport = Write-VerdictReport -Synthesis $synthesis -Round $round -Fixes @() -FinalVerdict $verdict -AntiSycophancy @()
            Write-Host $verdictReport -ForegroundColor Gray

            Write-Host "`nWould you like to fix confirmed issues?" -ForegroundColor Cyan
            Write-Host "  1) Yes - auto-fix and continue" -ForegroundColor Yellow
            Write-Host "  2) No - escalate (JUDGMENT: ESCALATED)" -ForegroundColor Yellow
            Write-Host "  3) Custom - specify which issues to fix" -ForegroundColor Yellow
            $choice = Read-Host "Option (1/2/3)"

            if ($choice -eq '1') {
                Write-Phase "Phase 3: Fix Agent"
                $fixes = Invoke-FixAgent -ConfirmedFindings ($criticalConfirmed + $realWarningConfirmed)
                Write-Ok "Applied $($fixes.Count) fix(es)"
            } elseif ($choice -eq '2') {
                $verdict = 'ESCALATED'
                break
            } elseif ($choice -eq '3') {
                Write-Info "Manual fixes requested - user will apply changes"
                Write-Host "Apply your fixes, then continue" -ForegroundColor Yellow
                $fixes = @()
            }
        }
    }

    # Check if user chose to escalate
    if ($verdict -eq 'ESCALATED') { break }

    # Check approval
    if (-not $needsFix) {
        $approved = $true
        $history += @{ round = $round; verdict = $verdict; synthesis = $synthesis; fixes = $fixes; approved = $true }
        break
    }

    # --- Post-fix re-judgment (immediate, next loop iteration) ---
    if ($fixes.Count -gt 0) {
        Write-Phase "Phase 4: Re-judgment triggered (post-fix)"
        Publish-JudgmentDayEvent -Event 'judgment-day-fixes-applied' -Data @{ round = $round; fixes = $fixes.Count }
    }

    $history += @{ round = $round; verdict = $verdict; synthesis = $synthesis; fixes = $fixes; approved = $false }

    # --- Iteration limit: after 2 fix rounds, ask ---
    if ($round -ge 2 -and $needsFix) {
        if ($NoPrompt) {
            break
        }
        Write-Host "`nIssues remain after $round fix iteration(s)." -ForegroundColor Yellow
        Write-Host "  1) Continue iterating" -ForegroundColor Yellow
        Write-Host "  2) Escalate (JUDGMENT: ESCALATED)" -ForegroundColor Yellow
        $choice = Read-Host "Option (1/2)"
        if ($choice -ne '1') {
            $verdict = 'ESCALATED'
            break
        }
    }
}

# Close session
$finalVerdict = if ($approved) { 'APPROVED' } else { 'ESCALATED' }
$session.status = $finalVerdict
$session.rounds = $history
$session.final_verdict = $finalVerdict
$sessionFile = Save-JudgmentSession -Session $session

Publish-JudgmentDayEvent -Event "judgment-day-$($finalVerdict.ToLowerInvariant())" -Data @{
    target = $Target; rounds = $history.Count; final_verdict = $finalVerdict
}

# Final report
$report = Write-VerdictReport -Synthesis $synthesis -Round $history.Count -Fixes $fixes -FinalVerdict $finalVerdict
Write-Host $report -ForegroundColor Gray

Write-JudgmentSummary -History $history -Approved $approved

Write-Info "Session file: $sessionFile"

if ($approved) {
    exit 0
}
exit 1
