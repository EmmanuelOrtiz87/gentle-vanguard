param(
    [int]$RefreshSeconds = 15,
    [int]$Iterations = 0,
    [switch]$Open,
    [switch]$Daemon
)

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$collector = Join-Path $repoRoot 'scripts' 'metrics' 'collector.ps1'
$renderer = Join-Path $repoRoot 'scripts' 'metrics' 'dashboard-render.ps1'
$liveDir = Join-Path $repoRoot '.runtime' 'metrics' 'live'
$feedFile = Join-Path $liveDir 'feed.json'
$healthFile = Join-Path $liveDir 'daemon-health.json'
$dashboardFile = Join-Path $repoRoot 'reports' 'dashboard.html'
$stateFile = Join-Path $repoRoot '.session' 'live-feed-state.json'

if (-not (Test-Path $liveDir)) { New-Item -ItemType Directory -Path $liveDir -Force | Out-Null }

# Initialize telemetry on startup if activity.json doesn't exist
$initFile = Join-Path $liveDir 'activity.json'
if (-not (Test-Path $initFile)) {
    $initScript = Join-Path $repoRoot 'scripts' 'metrics' 'telemetry-writer.ps1'
    if (Test-Path $initScript) {
        & $initScript -Action session -Flush
        & $initScript -Action event -EventType 'session' -Detail 'live-feed daemon started' -Flush
    } else {
        # Minimal init without telemetry-writer
        $init = @{ sessionId = "session-$((Get-Date -Format 'yyyy-MM-dd'))-livefeed"; sessionStart = (Get-Date -Format 'o'); toolCalls = 0; estimatedTokens = 0; filesRead = 0; filesWritten = 0; filesEdited = 0; commandsRun = 0; events = @(); lastUpdate = (Get-Date -Format 'o') }
        $init | ConvertTo-Json -Depth 3 | Set-Content $initFile
    }
}

function Write-Feed {
    $feed = [PSCustomObject]@{
        timestamp    = (Get-Date -Format 'o')
        epochMs      = [long]([DateTimeOffset]::Now.ToUnixTimeMilliseconds())
        sessionId    = ''
        sessionStart = ''
        sessionMode  = ''
        tokensUsed   = 0
        tokenBudget  = 0
        tokenPct     = 0
        trafficLight = 'GREEN'
        routingAcc   = '0%'
        isPeakHour   = $false
        sessionCount = 0
        telemetry    = $null
    }
    $consolidated = Join-Path $repoRoot '.runtime' 'metrics' 'consolidated.json'
    if (Test-Path $consolidated) {
        try {
            $c = Get-Content $consolidated -Raw | ConvertFrom-Json
            if ($c.sessions) {
                $feed.sessionId = $c.sessions.latest
                $feed.sessionCount = $c.sessions.total
            }
            if ($c.token) {
                $feed.tokensUsed = $c.token.usedToday
                $feed.tokenBudget = $c.token.budget
                $feed.tokenPct = $c.token.pct
            }
            if ($c.live) {
                $feed.trafficLight = $c.live.trafficLight
                $feed.routingAcc = $c.live.routingAcc
            }
            if ($c.telemetry -and $c.telemetry.hasData) {
                $feed.telemetry = $c.telemetry
            }
        } catch {}
    }
    $h = (Get-Date).Hour
    $feed.isPeakHour = ($h -ge 9 -and $h -lt 15)
    $feed | ConvertTo-Json -Depth 4 | Set-Content $feedFile
}

function Write-Health {
    $serverPid = 0; $serverPort = 8090
    if (Test-Path $stateFile) {
        try {
            $st = Get-Content $stateFile -Raw | ConvertFrom-Json
            $serverPid = if ($st.serverPid) { $st.serverPid } else { 0 }
            $serverPort = if ($st.serverPort) { $st.serverPort } else { 8090 }
        } catch {}
    }
    $myPid = [System.Diagnostics.Process]::GetCurrentProcess().Id
    $health = [PSCustomObject]@{
        timestamp     = (Get-Date -Format 'o')
        liveFeedPid   = $myPid
        serverPid     = $serverPid
        serverPort    = $serverPort
        liveFeedAlive = $true
        serverAlive   = (Get-Process -Id $serverPid -ErrorAction SilentlyContinue) -and -not (Get-Process -Id $serverPid -ErrorAction SilentlyContinue).HasExited
    } | ConvertTo-Json -Depth 3
    $health | Set-Content $healthFile
}

function Update-Dashboard {
    if (Test-Path $renderer) {
        & $renderer -Quiet
    }
}

if (-not $Daemon) {
    Write-Host "[LIVE-FEED] Starting live feed (every ${RefreshSeconds}s)" -ForegroundColor Cyan
    Write-Host "[LIVE-FEED] Feed: $feedFile" -ForegroundColor Gray
    Write-Host "[LIVE-FEED] Dashboard: $dashboardFile" -ForegroundColor Gray
    Write-Host "[LIVE-FEED] Ctrl+C to stop`n" -ForegroundColor Yellow
}

$cycle = 0
$opened = $false

while ($true) {
    $cycle++
    if (-not $Daemon) {
        Write-Host "`r[LIVE-FEED] Cycle $cycle @ $(Get-Date -Format 'HH:mm:ss')" -NoNewline -ForegroundColor Green
    }
    & $collector -Scope full -Quiet
    Write-Feed
    Write-Health
    if ($cycle % 4 -eq 0) {
        Update-Dashboard
    }
    if ($Open -and -not $opened) {
        if (Test-Path $dashboardFile) {
            Start-Process $dashboardFile
        }
        $opened = $true
    }
    if ($Iterations -gt 0 -and $cycle -ge $Iterations) {
        if (-not $Daemon) { Write-Host "`n[LIVE-FEED] Completed $Iterations cycles" -ForegroundColor Cyan }
        break
    }
    Start-Sleep -Seconds $RefreshSeconds
}
