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
$statePath = Join-Path $sessionDir 'adaptive-opencode-state.json'
$summaryPath = Join-Path $sessionDir 'startup-summary.json'
$metricsPath = Join-Path $repoRoot '.session/metrics/current-session.json'
$notifyPath = Join-Path $repoRoot 'scripts/utilities/notify-user.ps1'

$opencodePath = Join-Path $repoRoot 'opencode.json'
$baselinePath = Join-Path $sessionDir 'opencode-baseline.json'

if (-not (Test-Path $opencodePath)) { Write-LogWarn "opencode.json not found. Skipped."; exit 0 }

function Apply-OptimizedOverlay {
    param([object]$Config)
    $Config | Add-Member -NotePropertyName default_agent -NotePropertyValue 'orchestrator' -Force
    $Config | Add-Member -NotePropertyName share -NotePropertyValue 'manual' -Force
    $Config | Add-Member -NotePropertyName compaction -NotePropertyValue ([pscustomobject]@{ auto = $true; prune = $true }) -Force
    $Config | Add-Member -NotePropertyName watcher -NotePropertyValue ([pscustomobject]@{ ignore = @('node_modules/**','dist/**','build/**','.git/**','.engram-data/**','tmp-session-debug/**','logs/**','session/**') }) -Force
    $Config | Add-Member -NotePropertyName permission -NotePropertyValue ([ordered]@{
        read = 'allow'; glob = 'allow'; grep = 'allow'; skill = 'allow'
        question = 'allow'; todowrite = 'allow'; lsp = 'ask'
        webfetch = 'deny'; websearch = 'deny'; external_directory = 'ask'
        doom_loop = 'deny'; edit = 'allow'
        bash = [ordered]@{ '*' = 'ask'; 'git status*' = 'allow'; 'git log*' = 'allow'; 'git diff*' = 'allow'; 'git show*' = 'allow'; 'rg *' = 'allow'; 'Get-ChildItem *' = 'allow'; 'Test-Path *' = 'allow' }
        task = [ordered]@{ '*' = 'allow' }
    }) -Force
    if ($null -ne $Config.agent) {
        foreach ($agentName in $Config.agent.PSObject.Properties.Name) {
            $agent = $Config.agent.$agentName
            if ($null -ne $agent.permission -and $agent.permission.PSObject.Properties.Name -contains 'codesearch') { $agent.permission.PSObject.Properties.Remove('codesearch') }
            if ($agentName -eq 'orchestrator') {
                if ($null -eq $agent.permission) { $agent | Add-Member -NotePropertyName permission -NotePropertyValue ([ordered]@{}) }
                $agent.permission.websearch = 'deny'; $agent.permission.webfetch = 'deny'
                $agent.permission.task = [ordered]@{ '*' = 'allow' }
                $agent | Add-Member -NotePropertyName steps -NotePropertyValue 12 -Force
            } else { $agent | Add-Member -NotePropertyName steps -NotePropertyValue 6 -Force }
        }
    }
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
        $currentConfig = Read-JsonFile -Path $opencodePath
        if (-not $currentConfig) { Write-LogWarn "opencode.json invalid"; exit 0 }
        Copy-Item $opencodePath $baselinePath -Force
        Apply-OptimizedOverlay -Config $currentConfig
        Save-JsonFile -Path $opencodePath -Data $currentConfig
        $state.optimizationActive = $true; $state.lastAction = 'optimized'; $state.lastReason = $reason; $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
        Save-JsonFile -Path $statePath -Data $state
        Invoke-AdaptiveNotify -Reason 'OpenCode optimization enabled (temporary)' -Details "Trigger: $reason"
        Write-LogOk "Adaptive OpenCode optimization enabled ($reason)."
    } else { $state.lastReason = $reason; Save-JsonFile -Path $statePath -Data $state; Write-LogInfo "Optimization already active ($reason)." }
    exit 0
}

$state.normalStreak = [int]$state.normalStreak + 1
if ($state.optimizationActive -and $state.normalStreak -ge 2) {
    if (Test-Path $baselinePath) {
        Copy-Item $baselinePath $opencodePath -Force; Remove-Item $baselinePath -Force -ErrorAction SilentlyContinue
        $state.optimizationActive = $false; $state.lastReason = 'normalized'; $state.lastAction = 'restored'; $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'); $state.normalStreak = 0
        Save-JsonFile -Path $statePath -Data $state
        Invoke-AdaptiveNotify -Reason 'OpenCode optimization reverted to baseline' -Details 'System normalized.'
        Write-LogOk 'Adaptive profile restored to baseline.'
    } else { Write-LogWarn 'Baseline missing. No restore performed.' }
} else { Save-JsonFile -Path $statePath -Data $state; Write-LogInfo "No change. reason=$reason normalStreak=$($state.normalStreak)" }
exit 0
