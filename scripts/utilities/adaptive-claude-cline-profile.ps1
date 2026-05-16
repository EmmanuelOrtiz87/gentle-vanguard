# adaptive-claude-cline-profile.ps1
# Temporarily applies optimized Claude Code and Cline profiles and auto-restores baseline when normalized.

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

$repoRoot = if ($env:FOUNDATION_BASE_DIR -and (Test-Path $env:FOUNDATION_BASE_DIR)) { $env:FOUNDATION_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$sessionDir = Join-Path $repoRoot 'scripts/.session'
if (-not (Test-Path $sessionDir)) { New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null }

$statePath = Join-Path $sessionDir 'adaptive-claude-cline-state.json'
$summaryPath = Join-Path $sessionDir 'startup-summary.json'
$metricsPath = Join-Path $repoRoot '.session/metrics/current-session.json'

$claudeSettingsPath = Join-Path $repoRoot '.claude/settings.json'
$clineConfigPath = Join-Path $repoRoot '.cline/config.json'
$clineRulesPath = Join-Path $repoRoot '.clinerules'
$clineRulesOptimizedPath = Join-Path $repoRoot '.clinerules.optimized'

$claudeBaseline = Join-Path $sessionDir 'claude-settings.baseline.json'
$clineConfigBaseline = Join-Path $sessionDir 'cline-config.baseline.json'
$clineRulesBaseline = Join-Path $sessionDir 'clinerules.baseline'

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
    try {
        return ([int]$m.metrics.totalTokens -ge 12000)
    } catch {
        return $false
    }
}

function Apply-ClaudeOverlay {
    param([object]$Cfg)

    if ($null -eq $Cfg.claudeCodeOptimization) {
        $Cfg | Add-Member -NotePropertyName claudeCodeOptimization -NotePropertyValue ([ordered]@{}) -Force
    }

    $Cfg.claudeCodeOptimization.references = [ordered]@{
        bestPractices = 'https://code.claude.com/docs/es/best-practices'
        docsIndex = 'https://code.claude.com/docs/llms.txt'
    }
    $Cfg.claudeCodeOptimization.contextManagement = [ordered]@{
        strategy = 'selective'
        localFirst = $true
        maxContextTokens = 70000
    }
    $Cfg.claudeCodeOptimization.permissions = [ordered]@{
        defaultMode = 'on-request'
        websearch = 'deny'
        webfetch = 'deny'
        externalDirectory = 'ask'
    }
    $Cfg.claudeCodeOptimization.parallelization = [ordered]@{
        enabled = $true
        maxParallelTasks = 2
    }
    $Cfg.claudeCodeOptimization.automation = [ordered]@{
        adaptiveProfile = 'scripts/utilities/adaptive-claude-cline-profile.ps1'
        notification = 'scripts/utilities/notify-claude-cline-optimization.ps1'
    }

    if ($Cfg.clineOptimization -and $Cfg.clineOptimization.performance) {
        $Cfg.clineOptimization.performance.maxContextTokens = 70000
    }
    if ($Cfg.clineOptimization -and $Cfg.clineOptimization.contextManagement) {
        $Cfg.clineOptimization.contextManagement.maxSearchResults = 20
    }
}

function Apply-ClineConfigOverlay {
    param([object]$Cfg)

    if ($null -eq $Cfg.toolPermissions) {
        $Cfg | Add-Member -NotePropertyName toolPermissions -NotePropertyValue ([ordered]@{}) -Force
    }

    $Cfg.toolPermissions.websearch = 'deny'
    $Cfg.toolPermissions.codesearch = 'deny'
    $Cfg.toolPermissions.webfetch = 'deny'

    if ($null -eq $Cfg.aiSettings) {
        $Cfg | Add-Member -NotePropertyName aiSettings -NotePropertyValue ([ordered]@{}) -Force
    }

    $Cfg.aiSettings.localFirst = $true
    $Cfg.aiSettings.temperature = 0.3

    if ($null -eq $Cfg.preProcessing) {
        $Cfg | Add-Member -NotePropertyName preProcessing -NotePropertyValue ([ordered]@{}) -Force
    }

    $Cfg.preProcessing.enabled = $true
    $Cfg.preProcessing.mandatory = $true
}

function Notify-Change {
    param([string]$Reason, [string]$Details)
    $notify = Join-Path $repoRoot 'scripts/utilities/notify-claude-cline-optimization.ps1'
    if (Test-Path $notify) {
        & $notify -Reason $Reason -Details $Details -Silent:$Silent | Out-Null
    }
}

function Restore-BaselineNow {
    if (Test-Path $claudeBaseline) {
        Copy-Item $claudeBaseline $claudeSettingsPath -Force
        Remove-Item $claudeBaseline -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $clineConfigBaseline) {
        Copy-Item $clineConfigBaseline $clineConfigPath -Force
        Remove-Item $clineConfigBaseline -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $clineRulesBaseline) {
        Copy-Item $clineRulesBaseline $clineRulesPath -Force
        Remove-Item $clineRulesBaseline -Force -ErrorAction SilentlyContinue
    }

    $state.optimizationActive = $false
    $state.normalStreak = 0
    $state.lastAction = 'restored'
    $state.lastReason = 'normalized'
    $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    Save-Json -Path $statePath -Data $state

    Notify-Change -Reason 'Adaptive Claude Code/Cline optimization reverted to baseline' -Details 'System signals normalized. Baseline configuration restored automatically.'
    Log-Ok 'Adaptive Claude Code/Cline profile restored to baseline.'
}

$state = Read-Json -Path $statePath
if (-not $state) {
    $state = [pscustomobject]@{
        optimizationActive = $false
        normalStreak = 0
        lastAction = 'none'
        lastReason = ''
        lastChangedAt = ''
    }
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
if ($Mode -eq 'Restore') {
    if ($state.optimizationActive) {
        Restore-BaselineNow
    } else {
        Log-Info 'Manual restore requested, but optimization is not active.'
    }
    exit 0
}

if ($shouldOptimize) {
    $state.normalStreak = 0
    if (-not $state.optimizationActive) {
        if (Test-Path $claudeSettingsPath) { Copy-Item $claudeSettingsPath $claudeBaseline -Force }
        if (Test-Path $clineConfigPath) { Copy-Item $clineConfigPath $clineConfigBaseline -Force }
        if (Test-Path $clineRulesPath) { Copy-Item $clineRulesPath $clineRulesBaseline -Force }

        $claudeCfg = Read-Json -Path $claudeSettingsPath
        if ($claudeCfg) {
            Apply-ClaudeOverlay -Cfg $claudeCfg
            Save-Json -Path $claudeSettingsPath -Data $claudeCfg
        }

        $clineCfg = Read-Json -Path $clineConfigPath
        if ($clineCfg) {
            Apply-ClineConfigOverlay -Cfg $clineCfg
            Save-Json -Path $clineConfigPath -Data $clineCfg
        }

        if (Test-Path $clineRulesOptimizedPath) {
            Copy-Item $clineRulesOptimizedPath $clineRulesPath -Force
        }

        $state.optimizationActive = $true
        $state.lastAction = 'optimized'
        $state.lastReason = $reason
        $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
        Save-Json -Path $statePath -Data $state

        Notify-Change -Reason 'Adaptive Claude Code/Cline optimization enabled (temporary)' -Details "Trigger: $reason. Baseline snapshot created and auto-restore will run when normalized."
        Log-Ok "Adaptive Claude Code/Cline optimization enabled ($reason)."
    } else {
        $state.lastReason = $reason
        Save-Json -Path $statePath -Data $state
        Log-Info "Optimization already active ($reason)."
    }
    exit 0
}

$state.normalStreak = [int]$state.normalStreak + 1
if ($state.optimizationActive -and $state.normalStreak -ge 2) {
    Restore-BaselineNow
} else {
    Save-Json -Path $statePath -Data $state
    Log-Info "No change. reason=$reason normalStreak=$($state.normalStreak)"
}

exit 0
