# adaptive-opencode-profile.ps1
# Intelligently toggles OpenCode optimization profile temporarily and restores baseline when normalized.

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

function Write-Info { param([string]$Message) if (-not $Silent) { Write-Host "[INFO] $Message" -ForegroundColor Gray } }
function Write-Ok { param([string]$Message) if (-not $Silent) { Write-Host "[OK] $Message" -ForegroundColor Green } }
function Write-Warn { param([string]$Message) if (-not $Silent) { Write-Host "[WARN] $Message" -ForegroundColor Yellow } }

$repoRoot = if ($env:GV_BASE_DIR -and (Test-Path $env:GV_BASE_DIR)) { $env:GV_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$opencodePath = Join-Path $repoRoot 'opencode.json'
$sessionDir = Join-Path $repoRoot 'scripts\.session'
$statePath = Join-Path $sessionDir 'adaptive-opencode-state.json'
$baselinePath = Join-Path $sessionDir 'opencode-baseline.json'
$summaryPath = Join-Path $sessionDir 'startup-summary.json'
$metricsPath = Join-Path $repoRoot '.session\metrics\current-session.json'
$notifyPath = Join-Path $repoRoot 'scripts\utilities\notify-user.ps1'

if (-not (Test-Path $sessionDir)) {
    New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null
}

if (-not (Test-Path $opencodePath)) {
    Write-Warn "opencode.json not found. Adaptive profile skipped."
    exit 0
}

function Get-Json {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    try { return Get-Content $Path -Raw | ConvertFrom-Json } catch { return $null }
}

function Save-Json {
    param(
        [string]$Path,
        [object]$Data
    )
    $Data | ConvertTo-Json -Depth 100 | Out-File -FilePath $Path -Encoding UTF8 -Force
}

function Ensure-Hashtable {
    param([object]$InputObject)
    if ($null -eq $InputObject) { return [ordered]@{} }
    if ($InputObject -is [System.Collections.IDictionary]) { return $InputObject }
    $hash = [ordered]@{}
    foreach ($p in $InputObject.PSObject.Properties) {
        $hash[$p.Name] = $p.Value
    }
    return $hash
}

function Apply-OptimizedOverlay {
    param([object]$Config)

    $Config | Add-Member -NotePropertyName default_agent -NotePropertyValue 'orchestrator' -Force
    $Config | Add-Member -NotePropertyName share -NotePropertyValue 'manual' -Force
    $Config | Add-Member -NotePropertyName compaction -NotePropertyValue ([pscustomobject]@{ auto = $true; prune = $true }) -Force
    $Config | Add-Member -NotePropertyName watcher -NotePropertyValue ([pscustomobject]@{
        ignore = @(
            'node_modules/**',
            'dist/**',
            'build/**',
            '.git/**',
            '.engram-data/**',
            'tmp-session-debug/**',
            'logs/**',
            'session/**'
        )
    }) -Force

    $Config | Add-Member -NotePropertyName permission -NotePropertyValue ([ordered]@{
        read = 'allow'
        glob = 'allow'
        grep = 'allow'
        skill = 'allow'
        question = 'allow'
        todowrite = 'allow'
        lsp = 'ask'
        webfetch = 'deny'
        websearch = 'deny'
        external_directory = 'ask'
        doom_loop = 'deny'
        edit = 'allow'
        bash = [ordered]@{
            '*' = 'ask'
            'git status*' = 'allow'
            'git log*' = 'allow'
            'git diff*' = 'allow'
            'git show*' = 'allow'
            'rg *' = 'allow'
            'Get-ChildItem *' = 'allow'
            'Test-Path *' = 'allow'
        }
        task = [ordered]@{ '*' = 'allow' }
    }) -Force

    if ($null -ne $Config.agent) {
        foreach ($agentName in $Config.agent.PSObject.Properties.Name) {
            $agent = $Config.agent.$agentName
            if ($null -ne $agent.permission -and $agent.permission.PSObject.Properties.Name -contains 'codesearch') {
                $agent.permission.PSObject.Properties.Remove('codesearch')
            }
            if ($agentName -eq 'orchestrator') {
                if ($null -eq $agent.permission) {
                    $agent | Add-Member -NotePropertyName permission -NotePropertyValue ([ordered]@{})
                }
                $agent.permission.websearch = 'deny'
                $agent.permission.webfetch = 'deny'
                $agent.permission.task = [ordered]@{ '*' = 'allow' }
                $agent | Add-Member -NotePropertyName steps -NotePropertyValue 12 -Force
            }
            else {
                $agent | Add-Member -NotePropertyName steps -NotePropertyValue 6 -Force
            }
        }
    }
}

function Invoke-Notify {
    param(
        [string]$Reason,
        [string]$Details,
        [string]$RecoveryCommand
    )

    if (-not (Test-Path $notifyPath)) { return }
    try {
        & $notifyPath -Action 'cleanup' -Reason $Reason -Details $Details -RecoveryCommand $RecoveryCommand | Out-Null
    } catch {
        Write-Warn "Could not send adaptive notification: $($_.Exception.Message)"
    }
}

function Get-PeakHour {
    $summary = Get-Json -Path $summaryPath
    if ($summary -and $null -ne $summary.isPeakHour) {
        return [bool]$summary.isPeakHour
    }

    try {
        $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById($TimeZone)
        $localTime = [System.TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz)
        return ($localTime.Hour -ge $PeakStart -and $localTime.Hour -lt $PeakEnd)
    }
    catch {
        $fallback = [DateTime]::UtcNow.AddHours(-3)
        return ($fallback.Hour -ge $PeakStart -and $fallback.Hour -lt $PeakEnd)
    }
}

function Get-TokenPressure {
    $metrics = Get-Json -Path $metricsPath
    if (-not $metrics -or -not $metrics.metrics) { return $false }
    try {
        $totalTokens = [int]$metrics.metrics.totalTokens
        return ($totalTokens -ge 12000)
    } catch {
        return $false
    }
}

function New-State {
    return [pscustomobject]@{
        optimizationActive = $false
        baselinePath = $baselinePath
        normalStreak = 0
        lastReason = ''
        lastAction = 'none'
        lastChangedAt = ''
    }
}

$state = Get-Json -Path $statePath
if (-not $state) { $state = New-State }

$currentConfig = Get-Json -Path $opencodePath
if (-not $currentConfig) {
    Write-Warn 'opencode.json is not valid JSON. Adaptive profile skipped.'
    exit 0
}

$isPeakHour = Get-PeakHour
$hasTokenPressure = Get-TokenPressure
$shouldOptimize = ($isPeakHour -or $hasTokenPressure)
$reason = if ($isPeakHour -and $hasTokenPressure) {
    'peak-hour + token-pressure'
} elseif ($isPeakHour) {
    'peak-hour'
} elseif ($hasTokenPressure) {
    'token-pressure'
} else {
    'normalized'
}

if ($Mode -eq 'Status') {
    Write-Host "[STATUS] optimizationActive=$($state.optimizationActive) shouldOptimize=$shouldOptimize reason=$reason normalStreak=$($state.normalStreak)"
    exit 0
}

if ($Mode -eq 'Optimize') { $shouldOptimize = $true; $reason = 'manual-optimize' }
if ($Mode -eq 'Restore') { $shouldOptimize = $false; $reason = 'manual-restore' }

if ($shouldOptimize) {
    $state.normalStreak = 0

    if (-not $state.optimizationActive) {
        Copy-Item -Path $opencodePath -Destination $baselinePath -Force

        $workingConfig = Get-Json -Path $opencodePath
        Apply-OptimizedOverlay -Config $workingConfig
        Save-Json -Path $opencodePath -Data $workingConfig

        $state.optimizationActive = $true
        $state.lastReason = $reason
        $state.lastAction = 'optimized'
        $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
        Save-Json -Path $statePath -Data $state

        Invoke-Notify -Reason 'Adaptive OpenCode optimization enabled (temporary)' -Details "Trigger: $reason. The baseline config was snapshotted and will be restored automatically when normalized." -RecoveryCommand 'pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/adaptive-opencode-profile.ps1 -Mode Status'
        Write-Ok "Adaptive OpenCode optimization enabled ($reason)."
    }
    else {
        $state.lastReason = $reason
        Save-Json -Path $statePath -Data $state
        Write-Info "Optimization already active ($reason)."
    }

    exit 0
}

# Normalized path: restore only after 2 consecutive normal checks to avoid thrashing.
$state.normalStreak = [int]$state.normalStreak + 1

if ($state.optimizationActive -and $state.normalStreak -ge 2) {
    if (Test-Path $baselinePath) {
        Copy-Item -Path $baselinePath -Destination $opencodePath -Force
        Remove-Item -Path $baselinePath -Force -ErrorAction SilentlyContinue

        $state.optimizationActive = $false
        $state.lastReason = 'normalized'
        $state.lastAction = 'restored'
        $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
        $state.normalStreak = 0
        Save-Json -Path $statePath -Data $state

        Invoke-Notify -Reason 'Adaptive OpenCode optimization reverted to baseline' -Details 'System signals normalized. Previous baseline restored automatically.' -RecoveryCommand 'pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/adaptive-opencode-profile.ps1 -Mode Status'
        Write-Ok 'Adaptive profile restored to baseline.'
    }
    else {
        Write-Warn 'Adaptive state expected baseline snapshot, but baseline file is missing. No restore performed.'
    }
}
else {
    Save-Json -Path $statePath -Data $state
    Write-Info "No change required. reason=$reason normalStreak=$($state.normalStreak)"
}

exit 0
