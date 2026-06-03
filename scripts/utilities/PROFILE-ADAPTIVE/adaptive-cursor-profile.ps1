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
. (Join-Path $PSScriptRoot 'adaptive-common.ps1')

$repoRoot = Get-RepoRoot
$sessionDir = Get-SessionDir -RepoRoot $repoRoot
$statePath = Join-Path $sessionDir 'adaptive-cursor-state.json'
$summaryPath = Join-Path $sessionDir 'startup-summary.json'
$metricsPath = Join-Path $repoRoot '.session/metrics/current-session.json'
$notifyPath = Join-Path $repoRoot 'scripts/utilities/notify-user.ps1'

$cursorRulesPath = Join-Path $repoRoot '.cursorrules'
$cursorRulesBaseline = Join-Path $sessionDir 'cursorrules.baseline'
$cursorConfigPath = Join-Path $repoRoot '.cursor/config.json'
$cursorConfigBaseline = Join-Path $sessionDir 'cursor-config.baseline.json'

$state = Read-JsonFile -Path $statePath
if (-not $state) { $state = Get-DefaultState }

$peak = Test-PeakHour -TimeZone $TimeZone -PeakStart $PeakStart -PeakEnd $PeakEnd
$pressure = Test-TokenPressure
$shouldOptimize = ($peak -or $pressure)
$reason = Get-AdaptiveReason -Peak $peak -Pressure $pressure

if ($Mode -eq 'Status') { Write-Host "[STATUS] optimizationActive=$($state.optimizationActive) shouldOptimize=$shouldOptimize reason=$reason normalStreak=$($state.normalStreak)"; exit 0 }
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

## Skill Emulation (sin skill tool nativo)
- Skill registry: .atl/skill-registry.md
- Para SDD lifecycle -> skills/sdd-lifecycle/SKILL.md
- Para review -> skills/code-review-orchestrator-skill/SKILL.md
- Para testing -> skills/playwright-skill/SKILL.md, skills/pytest-skill/SKILL.md

## Engram Memory (emulacion)
- Contexto persistente: .engram-data/
- Session context: scripts/.session/startup-summary.json
- Restore: pwsh -NoProfile -File scripts/utilities/engram_mem_context.ps1
- Comandos: /pr, /review, /status, /test, /fix-issue, /update-deps en .cursor/commands/
"@
        $optimizedRules | Out-File -FilePath $cursorRulesPath -Encoding UTF8 -Force
        $state.optimizationActive = $true; $state.lastAction = 'optimized'; $state.lastReason = $reason; $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
        Save-JsonFile -Path $statePath -Data $state
        Invoke-AdaptiveNotify -Reason 'Cursor optimization enabled (temporary)' -Details "Trigger: $reason"
        Write-LogOk "Adaptive Cursor optimization enabled ($reason)."
    } else { $state.lastReason = $reason; Save-JsonFile -Path $statePath -Data $state; Write-LogInfo "Optimization already active ($reason)." }
    exit 0
}

$state.normalStreak = [int]$state.normalStreak + 1
if ($state.optimizationActive -and $state.normalStreak -ge 2) {
    if (Test-Path $cursorRulesBaseline) { Copy-Item $cursorRulesBaseline $cursorRulesPath -Force; Remove-Item $cursorRulesBaseline -Force -ErrorAction SilentlyContinue }
    $state.optimizationActive = $false; $state.normalStreak = 0; $state.lastAction = 'restored'; $state.lastReason = 'normalized'; $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    Save-JsonFile -Path $statePath -Data $state
    Invoke-AdaptiveNotify -Reason 'Cursor optimization reverted to baseline' -Details 'System normalized.'
    Write-LogOk 'Adaptive Cursor profile restored to baseline.'
} else { Save-JsonFile -Path $statePath -Data $state; Write-LogInfo "No change. reason=$reason normalStreak=$($state.normalStreak)" }
exit 0
