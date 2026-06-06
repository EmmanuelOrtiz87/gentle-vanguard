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
$statePath = Join-Path $sessionDir 'adaptive-continue-copilot-state.json'
$summaryPath = Join-Path $sessionDir 'startup-summary.json'
$metricsPath = Join-Path $repoRoot '.session/metrics/current-session.json'

$continueConfigPath = Join-Path $repoRoot '.continue/config.json'
$continueBaseline = Join-Path $sessionDir 'continue-config.baseline.json'
$continueChecksDir = Join-Path $repoRoot '.continue\checks'
$continueChecksBaseline = Join-Path $sessionDir 'continue-checks-baseline'

function Apply-ContinueOverlay {
    param([object]$Cfg)
    if ($null -eq $Cfg.aiSettings) { $Cfg | Add-Member -NotePropertyName aiSettings -NotePropertyValue ([ordered]@{}) -Force }
    $Cfg.aiSettings.temperature = 0.3
    $Cfg.aiSettings.maxTokens = 3500
    $Cfg.aiSettings.localFirst = $true
    if ($null -eq $Cfg.toolPermissions) { $Cfg | Add-Member -NotePropertyName toolPermissions -NotePropertyValue ([ordered]@{}) -Force }
    $Cfg.toolPermissions.websearch = 'deny'
    $Cfg.toolPermissions.codesearch = 'deny'
    $Cfg.toolPermissions.webfetch = 'deny'
    if ($null -eq $Cfg.responseFormat) { $Cfg | Add-Member -NotePropertyName responseFormat -NotePropertyValue ([ordered]@{}) -Force }
    $Cfg.responseFormat.conciseMode = $true
    $Cfg.responseFormat.maxResponseTokens = 2500
}

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
        if (Test-Path $continueConfigPath) { Copy-Item $continueConfigPath $continueBaseline -Force }
        if (Test-Path $continueChecksDir) {
            if (Test-Path $continueChecksBaseline) { Remove-Item $continueChecksBaseline -Recurse -Force -ErrorAction SilentlyContinue }
            Copy-Item $continueChecksDir $continueChecksBaseline -Recurse -Force
        }
        $continueCfg = Read-JsonFile -Path $continueConfigPath
        if ($continueCfg) { Apply-ContinueOverlay -Cfg $continueCfg; Save-JsonFile -Path $continueConfigPath -Data $continueCfg }
        $state.optimizationActive = $true; $state.lastAction = 'optimized'; $state.lastReason = $reason; $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
        Save-JsonFile -Path $statePath -Data $state
        Invoke-AdaptiveNotify -Reason 'Continue/Copilot optimization enabled (temporary)' -Details "Trigger: $reason"
        Write-LogOk "Adaptive Continue/Copilot optimization enabled ($reason)."
    } else { $state.lastReason = $reason; Save-JsonFile -Path $statePath -Data $state; Write-LogInfo "Optimization already active ($reason)." }
    exit 0
}

$state.normalStreak = [int]$state.normalStreak + 1
if ($state.optimizationActive -and $state.normalStreak -ge 2) {
    if (Test-Path $continueBaseline) { Copy-Item $continueBaseline $continueConfigPath -Force; Remove-Item $continueBaseline -Force -ErrorAction SilentlyContinue }
    if (Test-Path $continueChecksBaseline) {
        if (Test-Path $continueChecksDir) { Remove-Item $continueChecksDir -Recurse -Force -ErrorAction SilentlyContinue }
        Copy-Item $continueChecksBaseline $continueChecksDir -Recurse -Force; Remove-Item $continueChecksBaseline -Recurse -Force -ErrorAction SilentlyContinue
    }
    $state.optimizationActive = $false; $state.normalStreak = 0; $state.lastAction = 'restored'; $state.lastReason = 'normalized'; $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    Save-JsonFile -Path $statePath -Data $state
    Invoke-AdaptiveNotify -Reason 'Continue/Copilot optimization reverted to baseline' -Details 'System normalized.'
    Write-LogOk 'Adaptive Continue/Copilot profile restored to baseline.'
} else { Save-JsonFile -Path $statePath -Data $state; Write-LogInfo "No change. reason=$reason normalStreak=$($state.normalStreak)" }
exit 0