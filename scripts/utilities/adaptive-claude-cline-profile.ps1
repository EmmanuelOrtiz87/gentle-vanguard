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

function Apply-ClaudeOverlay {
    param([object]$Cfg)
    if ($null -eq $Cfg.claudeCodeOptimization) { $Cfg | Add-Member -NotePropertyName claudeCodeOptimization -NotePropertyValue ([ordered]@{}) -Force }
    $Cfg.claudeCodeOptimization = [ordered]@{
        references = [ordered]@{ bestPractices = 'https://code.claude.com/docs/es/best-practices'; docsIndex = 'https://code.claude.com/docs/llms.txt' }
        contextManagement = [ordered]@{ strategy = 'selective'; localFirst = $true; maxContextTokens = 70000 }
        permissions = [ordered]@{ defaultMode = 'on-request'; websearch = 'deny'; webfetch = 'deny'; externalDirectory = 'ask' }
        parallelization = [ordered]@{ enabled = $true; maxParallelTasks = 2 }
        automation = [ordered]@{ adaptiveProfile = 'scripts/utilities/adaptive-claude-cline-profile.ps1'; notification = 'scripts/utilities/notify-claude-cline-optimization.ps1' }
    }
}

function Apply-ClineConfigOverlay {
    param([object]$Cfg)
    if ($null -eq $Cfg.toolPermissions) { $Cfg | Add-Member -NotePropertyName toolPermissions -NotePropertyValue ([ordered]@{}) -Force }
    $Cfg.toolPermissions.websearch = 'deny'; $Cfg.toolPermissions.codesearch = 'deny'; $Cfg.toolPermissions.webfetch = 'deny'
    if ($null -eq $Cfg.aiSettings) { $Cfg | Add-Member -NotePropertyName aiSettings -NotePropertyValue ([ordered]@{}) -Force }
    $Cfg.aiSettings.localFirst = $true; $Cfg.aiSettings.temperature = 0.3
    if ($null -eq $Cfg.preProcessing) { $Cfg | Add-Member -NotePropertyName preProcessing -NotePropertyValue ([ordered]@{}) -Force }
    $Cfg.preProcessing.enabled = $true; $Cfg.preProcessing.mandatory = $true
}

function Notify-Change {
    param([string]$Reason, [string]$Details)
    $n = Join-Path $repoRoot 'scripts/utilities/notify-claude-cline-optimization.ps1'
    if (Test-Path $n) { & $n -Reason $Reason -Details $Details -Silent:$Silent | Out-Null }
}

$state = Read-JsonFile -Path $statePath
if (-not $state) { $state = Get-DefaultState }

$peak = Test-PeakHour -TimeZone $TimeZone -PeakStart $PeakStart -PeakEnd $PeakEnd
$pressure = Test-TokenPressure
$shouldOptimize = ($peak -or $pressure)
$reason = Get-AdaptiveReason -Peak $peak -Pressure $pressure

if ($Mode -eq 'Status') { Write-Host "[STATUS] optimizationActive=$($state.optimizationActive) shouldOptimize=$shouldOptimize reason=$reason normalStreak=$($state.normalStreak)"; exit 0 }
if ($Mode -eq 'Optimize') { $shouldOptimize = $true; $reason = 'manual-optimize' }
if ($Mode -eq 'Restore') {
    if ($state.optimizationActive) { Restore-BaselineNow } else { Write-LogInfo 'Restore requested, but optimization not active.' }
    exit 0
}

function Restore-BaselineNow {
    if (Test-Path $claudeBaseline) { Copy-Item $claudeBaseline $claudeSettingsPath -Force; Remove-Item $claudeBaseline -Force -ErrorAction SilentlyContinue }
    if (Test-Path $clineConfigBaseline) { Copy-Item $clineConfigBaseline $clineConfigPath -Force; Remove-Item $clineConfigBaseline -Force -ErrorAction SilentlyContinue }
    if (Test-Path $clineRulesBaseline) { Copy-Item $clineRulesBaseline $clineRulesPath -Force; Remove-Item $clineRulesBaseline -Force -ErrorAction SilentlyContinue }
    $state.optimizationActive = $false; $state.normalStreak = 0; $state.lastAction = 'restored'; $state.lastReason = 'normalized'; $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    Save-JsonFile -Path $statePath -Data $state
    Notify-Change -Reason 'Claude Code/Cline optimization reverted to baseline' -Details 'System normalized.'
    Write-LogOk 'Adaptive Claude Code/Cline profile restored to baseline.'
}

if ($shouldOptimize) {
    $state.normalStreak = 0
    if (-not $state.optimizationActive) {
        if (Test-Path $claudeSettingsPath) { Copy-Item $claudeSettingsPath $claudeBaseline -Force }
        if (Test-Path $clineConfigPath) { Copy-Item $clineConfigPath $clineConfigBaseline -Force }
        if (Test-Path $clineRulesPath) { Copy-Item $clineRulesPath $clineRulesBaseline -Force }
        $claudeCfg = Read-JsonFile -Path $claudeSettingsPath
        if ($claudeCfg) { Apply-ClaudeOverlay -Cfg $claudeCfg; Save-JsonFile -Path $claudeSettingsPath -Data $claudeCfg }
        $clineCfg = Read-JsonFile -Path $clineConfigPath
        if ($clineCfg) { Apply-ClineConfigOverlay -Cfg $clineCfg; Save-JsonFile -Path $clineConfigPath -Data $clineCfg }
        if (Test-Path $clineRulesOptimizedPath) { Copy-Item $clineRulesOptimizedPath $clineRulesPath -Force }
        $state.optimizationActive = $true; $state.lastAction = 'optimized'; $state.lastReason = $reason; $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
        Save-JsonFile -Path $statePath -Data $state
        Notify-Change -Reason 'Claude Code/Cline optimization enabled (temporary)' -Details "Trigger: $reason"
        Write-LogOk "Adaptive Claude Code/Cline optimization enabled ($reason)."
    } else { $state.lastReason = $reason; Save-JsonFile -Path $statePath -Data $state; Write-LogInfo "Optimization already active ($reason)." }
    exit 0
}

$state.normalStreak = [int]$state.normalStreak + 1
if ($state.optimizationActive -and $state.normalStreak -ge 2) { Restore-BaselineNow } else { Save-JsonFile -Path $statePath -Data $state; Write-LogInfo "No change. reason=$reason normalStreak=$($state.normalStreak)" }
exit 0
