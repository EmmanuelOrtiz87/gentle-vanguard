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
$statePath = Join-Path $sessionDir 'adaptive-antigravity-state.json'
$summaryPath = Join-Path $sessionDir 'startup-summary.json'
$metricsPath = Join-Path $repoRoot '.session/metrics/current-session.json'
$notifyPath = Join-Path $repoRoot 'scripts/utilities/notify-user.ps1'

$antigravityConfigPath = Join-Path $repoRoot '.antigravity/config.json'
$antigravityBaseline = Join-Path $sessionDir 'antigravity-config.baseline.json'

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
        if (Test-Path $antigravityConfigPath) { Copy-Item $antigravityConfigPath $antigravityBaseline -Force }
        $optimizedConfig = @"
{
  "name": "Antigravity - Gentle-Vanguard (OPTIMIZADO)",
  "version": "2.0.0",
  "description": "Perfil optimizado temporal — horario pico / token pressure",
  "aiSettings": { "temperature": 0.3, "maxTokens": 2500, "localFirst": true },
  "toolPermissions": { "websearch": "deny", "webfetch": "deny", "codesearch": "deny" },
  "preProcessing": { "enabled": true, "mandatory": true, "script": "scripts/utilities/pre-process-input.ps1", "scriptArgs": { "UserInput": "USER_INPUT_HERE", "WorkspaceRoot": "." } },
  "missionParameters": { "project": "gentle-vanguard", "governanceLayers": ["GOV", "DEV", "QA"] },
  "language": { "default": "es", "technicalTerms": "en" }
}
"@
        $optimizedConfig | Out-File -FilePath $antigravityConfigPath -Encoding UTF8 -Force
        $state.optimizationActive = $true; $state.lastAction = 'optimized'; $state.lastReason = $reason; $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
        Save-JsonFile -Path $statePath -Data $state
        Invoke-AdaptiveNotify -Reason 'Antigravity optimization enabled (temporary)' -Details "Trigger: $reason"
        Write-LogOk "Adaptive Antigravity optimization enabled ($reason)."
    } else { $state.lastReason = $reason; Save-JsonFile -Path $statePath -Data $state; Write-LogInfo "Optimization already active ($reason)." }
    exit 0
}

$state.normalStreak = [int]$state.normalStreak + 1
if ($state.optimizationActive -and $state.normalStreak -ge 2) {
    if (Test-Path $antigravityBaseline) { Copy-Item $antigravityBaseline $antigravityConfigPath -Force; Remove-Item $antigravityBaseline -Force -ErrorAction SilentlyContinue }
    $state.optimizationActive = $false; $state.normalStreak = 0; $state.lastAction = 'restored'; $state.lastReason = 'normalized'; $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    Save-JsonFile -Path $statePath -Data $state
    Invoke-AdaptiveNotify -Reason 'Antigravity optimization reverted to baseline' -Details 'System normalized.'
    Write-LogOk 'Adaptive Antigravity profile restored to baseline.'
} else { Save-JsonFile -Path $statePath -Data $state; Write-LogInfo "No change. reason=$reason normalStreak=$($state.normalStreak)" }
exit 0
