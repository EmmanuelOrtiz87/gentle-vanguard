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

$statePath = Join-Path $sessionDir 'adaptive-continue-copilot-state.json'
$summaryPath = Join-Path $sessionDir 'startup-summary.json'
$metricsPath = Join-Path $repoRoot '.session/metrics/current-session.json'
$notifyPath = Join-Path $repoRoot 'scripts/utilities/notify-user.ps1'

$continueConfigPath = Join-Path $repoRoot '.continue/config.json'
$continueBaseline = Join-Path $sessionDir 'continue-config.baseline.json'
$continueChecksDir = Join-Path $repoRoot '.continue\checks'
$continueChecksBaseline = Join-Path $sessionDir 'continue-checks-baseline'

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
        if (Test-Path $continueConfigPath) { Copy-Item $continueConfigPath $continueBaseline -Force }
        if (Test-Path $continueChecksDir) {
            if (Test-Path $continueChecksBaseline) { Remove-Item $continueChecksBaseline -Recurse -Force -ErrorAction SilentlyContinue }
            Copy-Item $continueChecksDir $continueChecksBaseline -Recurse -Force
        }
        $continueCfg = Read-Json -Path $continueConfigPath
        if ($continueCfg) {
            Apply-ContinueOverlay -Cfg $continueCfg
            Save-Json -Path $continueConfigPath -Data $continueCfg
        }
        $state.optimizationActive = $true
        $state.lastAction = 'optimized'
        $state.lastReason = $reason
        $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
        Save-Json -Path $statePath -Data $state
        Invoke-Notify -Reason 'Adaptive Continue/Copilot optimization enabled (temporary)' -Details "Trigger: $reason"
        Log-Ok "Adaptive Continue/Copilot optimization enabled ($reason)."
    } else {
        $state.lastReason = $reason
        Save-Json -Path $statePath -Data $state
        Log-Info "Optimization already active ($reason)."
    }
    exit 0
}

$state.normalStreak = [int]$state.normalStreak + 1
if ($state.optimizationActive -and $state.normalStreak -ge 2) {
    if (Test-Path $continueBaseline) {
        Copy-Item $continueBaseline $continueConfigPath -Force
        Remove-Item $continueBaseline -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $continueChecksBaseline) {
        if (Test-Path $continueChecksDir) { Remove-Item $continueChecksDir -Recurse -Force -ErrorAction SilentlyContinue }
        Copy-Item $continueChecksBaseline $continueChecksDir -Recurse -Force
        Remove-Item $continueChecksBaseline -Recurse -Force -ErrorAction SilentlyContinue
    }
    $state.optimizationActive = $false
    $state.normalStreak = 0
    $state.lastAction = 'restored'
    $state.lastReason = 'normalized'
    $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    Save-Json -Path $statePath -Data $state
    Invoke-Notify -Reason 'Adaptive Continue/Copilot optimization reverted to baseline' -Details 'System normalized.'
    Log-Ok 'Adaptive Continue/Copilot profile restored to baseline.'
} else {
    Save-Json -Path $statePath -Data $state
    Log-Info "No change. reason=$reason normalStreak=$($state.normalStreak)"
}
exit 0
