[CmdletBinding()]
param(
    [ValidateSet('Auto', 'Optimize', 'Restore', 'Status')]
    [string]$Mode = 'Auto',
    [string]$TimeZone = 'Argentina Standard Time',
    [int]$PeakStart = 9,
    [int]$PeakEnd = 15,
    [switch]$Silent
)

$ErrorActionPreference = 'Continue'

function Log-Info { param([string]$m) if (-not $Silent) { Write-Host "[INFO] $m" -ForegroundColor Gray } }
function Log-Ok { param([string]$m) if (-not $Silent) { Write-Host "[OK] $m" -ForegroundColor Green } }
function Log-Warn { param([string]$m) if (-not $Silent) { Write-Host "[WARN] $m" -ForegroundColor Yellow } }

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR -and (Test-Path $env:GENTLE_VANGUARD_BASE_DIR)) { $env:GENTLE_VANGUARD_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$sessionDir = Join-Path $repoRoot 'scripts/.session'
if (-not (Test-Path $sessionDir)) { New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null }

$statePath = Join-Path $sessionDir 'adaptive-cursor-state.json'
$summaryPath = Join-Path $sessionDir 'startup-summary.json'
$metricsPath = Join-Path $repoRoot '.session/metrics/current-session.json'
$cursorRulesPath = Join-Path $repoRoot '.cursorrules'
$cursorRulesBaseline = Join-Path $sessionDir 'cursorrules.baseline'
$cursorRulesDir = Join-Path $repoRoot '.cursor\rules'
$cursorCommandsDir = Join-Path $repoRoot '.cursor\commands'
$cursorConfigPath = Join-Path $repoRoot '.cursor\config.json'
$cursorConfigBaseline = Join-Path $sessionDir 'cursor-config.baseline.json'
$notifyPath = Join-Path $repoRoot 'scripts/utilities/notify-user.ps1'

function Read-Json {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    try { return Get-Content $Path -Raw | ConvertFrom-Json } catch { return $null }
}

function Save-Json {
    param([string]$Path, [object]$Data)
    $Data | ConvertTo-Json -Depth 100 | Out-File -FilePath $Path -Encoding UTF8 -Force
}

function Is-PeakHour {
    $summary = Read-Json -Path $summaryPath
    if ($summary -and $null -ne $summary.isPeakHour) { return [bool]$summary.isPeakHour }
    try {
        $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById($TimeZone)
        $local = [System.TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz)
        return ($local.Hour -ge $PeakStart -and $local.Hour -lt $PeakEnd)
    } catch {
        $fallback = [DateTime]::UtcNow.AddHours(-3)
        return ($fallback.Hour -ge $PeakStart -and $fallback.Hour -lt $PeakEnd)
    }
}

function Has-TokenPressure {
    $m = Read-Json -Path $metricsPath
    if (-not $m -or -not $m.metrics) { return $false }
    try { return ([int]$m.metrics.totalTokens -ge 12000) } catch { return $false }
}

function Invoke-Notify {
    param([string]$Reason, [string]$Details)
    if (-not (Test-Path $notifyPath)) { return }
    try { & $notifyPath -Action 'cleanup' -Reason $Reason -Details $Details | Out-Null } catch {}
}

$state = Read-Json -Path $statePath
if (-not $state) {
    $state = [pscustomobject]@{ optimizationActive = $false; normalStreak = 0; lastAction = 'none'; lastReason = ''; lastChangedAt = '' }
}

$peak = Is-PeakHour
$pressure = Has-TokenPressure
$shouldOptimize = ($peak -or $pressure)
$reason = if ($peak -and $pressure) { 'peak-hour + token-pressure' } elseif ($peak) { 'peak-hour' } elseif ($pressure) { 'token-pressure' } else { 'normalized' }

if ($Mode -eq 'Status') {
    Write-Host "[STATUS] optimizationActive=$($state.optimizationActive) shouldOptimize=$shouldOptimize reason=$reason normalStreak=$($state.normalStreak)"
    exit 0
}
if ($Mode -eq 'Optimize') { $shouldOptimize = $true; $reason = 'manual-optimize' }
if ($Mode -eq 'Restore') { $shouldOptimize = $false; $reason = 'manual-restore' }

if ($shouldOptimize) {
    $state.normalStreak = 0
    if (-not $state.optimizationActive) {
        if (Test-Path $cursorRulesPath) { Copy-Item $cursorRulesPath $cursorRulesBaseline -Force }
        if (Test-Path $cursorConfigPath) { Copy-Item $cursorConfigPath $cursorConfigBaseline -Force }

        $optimizedRules = @"
# Cursor Rules - Gentle-Vanguard (OPTIMIZADO)
Reglas completas en .cursor/rules/

## Mandatory
- `powershell -File scripts/utilities/pre-process-input.ps1 -UserInput "INPUT" -WorkspaceRoot "."` SIEMPRE antes de responder
- Parsear: TRIGGER_MATCH_FOUND -> skill | PLAN_MODE_REQUIRED -> BA | NO_TRIGGER -> normal
- Session start: `scripts/utilities/session-autostart.cmd`
- LOCAL-FIRST | Temperature 0.3 | MaxTokens 4500
- websearch/webfetch: DENY | external_dir: ask
- Espanol, conciso, sin preamble/postamble

## Skill Emulation (sin skill tool nativo)
- Para tareas de documentacion -> leer skills/documentation-governance/SKILL.md
- Para presentaciones -> leer skills/presentaciones-visuales-skill/SKILL.md
- Para SDD lifecycle -> leer skills/sdd-lifecycle/SKILL.md
- Para review de codigo -> leer skills/code-review-orchestrator-skill/SKILL.md
- Para testing -> leer skills/playwright-skill/SKILL.md, skills/pytest-skill/SKILL.md
- Skill registry completo en .atl/skill-registry.md

## Engram Memory (emulacion)
- Datos persistentes en .engram-data/
- Contexto de sesiones previas en scripts/.session/
- Session logs en logs/ y session/
- Para restaurar contexto: leer scripts/.session/startup-summary.json
- Comandos: /pr, /review, /status, /test, /fix-issue, /update-deps en .cursor/commands/
"@
        $optimizedRules | Out-File -FilePath $cursorRulesPath -Encoding UTF8 -Force

        $state.optimizationActive = $true
        $state.lastAction = 'optimized'
        $state.lastReason = $reason
        $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
        Save-Json -Path $statePath -Data $state

        Invoke-Notify -Reason 'Adaptive Cursor optimization enabled (temporary)' -Details "Trigger: $reason"
        Log-Ok "Adaptive Cursor optimization enabled ($reason)."
    } else {
        $state.lastReason = $reason
        Save-Json -Path $statePath -Data $state
        Log-Info "Optimization already active ($reason)."
    }
    exit 0
}

$state.normalStreak = [int]$state.normalStreak + 1
if ($state.optimizationActive -and $state.normalStreak -ge 2) {
    if (Test-Path $cursorRulesBaseline) {
        Copy-Item $cursorRulesBaseline $cursorRulesPath -Force
        Remove-Item $cursorRulesBaseline -Force -ErrorAction SilentlyContinue
    }
    $state.optimizationActive = $false
    $state.normalStreak = 0
    $state.lastAction = 'restored'
    $state.lastReason = 'normalized'
    $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    Save-Json -Path $statePath -Data $state
    Invoke-Notify -Reason 'Adaptive Cursor optimization reverted to baseline' -Details 'System normalized.'
    Log-Ok 'Adaptive Cursor profile restored to baseline.'
} else {
    Save-Json -Path $statePath -Data $state
    Log-Info "No change. reason=$reason normalStreak=$($state.normalStreak)"
}
exit 0
