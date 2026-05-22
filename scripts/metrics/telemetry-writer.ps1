param(
    [string]$Action = 'event',
    [string]$EventType = '',
    [string]$Detail = '',
    [int]$Tokens = 0,
    [int]$FilesRead = 0,
    [int]$FilesWritten = 0,
    [int]$FilesEdited = 0,
    [int]$ToolCalls = 1,
    [switch]$Flush
)

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$liveDir = Join-Path $repoRoot '.runtime' 'metrics' 'live'
if (-not (Test-Path $liveDir)) { New-Item -ItemType Directory -Path $liveDir -Force | Out-Null }
$activityFile = Join-Path $liveDir 'activity.json'
$eventsFile = Join-Path $liveDir 'events.ndjson'

# Read current activity state
$activity = if (Test-Path $activityFile) { try { Get-Content $activityFile -Raw | ConvertFrom-Json } catch {} }
if (-not $activity) {
    $activity = [PSCustomObject]@{
        sessionId = ''
        sessionStart = (Get-Date -Format 'o')
        toolCalls = 0
        estimatedTokens = 0
        filesRead = 0
        filesWritten = 0
        filesEdited = 0
        commandsRun = 0
        events = @()
        lastUpdate = (Get-Date -Format 'o')
    }
}

switch ($Action) {
    'event' {
        $activity.toolCalls += $ToolCalls
        $activity.estimatedTokens += $Tokens
        $activity.filesRead += $FilesRead
        $activity.filesWritten += $FilesWritten
        $activity.filesEdited += $FilesEdited
        if ($EventType -eq 'bash') { $activity.commandsRun += 1 }
        $activity.lastUpdate = (Get-Date -Format 'o')

        # Append to ndjson event log
        $evt = [PSCustomObject]@{
            ts = (Get-Date -Format 'o')
            type = $EventType
            detail = $Detail
            tokens = $Tokens
            filesRead = $FilesRead
            filesWritten = $FilesWritten
            filesEdited = $FilesEdited
        } | ConvertTo-Json -Compress -Depth 2
        Add-Content -Path $eventsFile -Value $evt -Encoding UTF8
    }
    'reset' {
        $activity.toolCalls = 0
        $activity.estimatedTokens = 0
        $activity.filesRead = 0
        $activity.filesWritten = 0
        $activity.filesEdited = 0
        $activity.commandsRun = 0
        $activity.events = @()
        $activity.lastUpdate = (Get-Date -Format 'o')
        if (Test-Path $eventsFile) { Remove-Item $eventsFile -Force }
    }
    'session' {
        $sid = if (Test-Path (Join-Path $repoRoot '.session' 'live-feed-state.json')) {
            try { $st = Get-Content (Join-Path $repoRoot '.session' 'live-feed-state.json') -Raw | ConvertFrom-Json; $st.liveFeedPid } catch { '' }
        } else { '' }
        $activity.sessionId = "session-$((Get-Date -Format 'yyyy-MM-dd'))-$sid"
    }
}

if ($Flush) {
    $activity | ConvertTo-Json -Depth 3 | Set-Content $activityFile
    Write-Host "[TELEMETRY] Flushed: $($activity.toolCalls) calls, $($activity.estimatedTokens) tokens" -ForegroundColor Cyan
} else {
    $activity | ConvertTo-Json -Depth 3 | Set-Content $activityFile
}

# Also update current-session.json for backward compat
$curFile = Join-Path $repoRoot '.session' 'metrics' 'current-session.json'
if (Test-Path $curFile) {
    try {
        $cur = Get-Content $curFile -Raw | ConvertFrom-Json
        $cur.metrics.toolCalls = $activity.toolCalls
        $cur.metrics.estimatedCostUsd = [math]::Round($activity.estimatedTokens / 1e6 * 10, 6)
        $cur.metrics.filesRead = $activity.filesRead
        $cur.metrics.filesCreated = $activity.filesWritten
        $cur.metrics.filesEdited = $activity.filesEdited
        $cur.metrics.totalTokens = $activity.estimatedTokens
        $cur.lastUpdate = (Get-Date -Format 'o')
        $cur | ConvertTo-Json -Depth 3 | Set-Content $curFile
    } catch {}
}
