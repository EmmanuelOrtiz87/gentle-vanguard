param(
    [int]$RefreshSeconds = 15,
    [int]$Iterations = 0,
    [switch]$Open
)

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$collector = Join-Path $repoRoot 'scripts' 'metrics' 'collector.ps1'
$renderer = Join-Path $repoRoot 'scripts' 'metrics' 'dashboard-render.ps1'
$liveDir = Join-Path $repoRoot '.runtime' 'metrics' 'live'
$feedFile = Join-Path $liveDir 'feed.json'
$dashboardFile = Join-Path $repoRoot 'reports' 'dashboard.html'

if (-not (Test-Path $liveDir)) { New-Item -ItemType Directory -Path $liveDir -Force | Out-Null }

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
        } catch {}
    }
    $h = (Get-Date).Hour
    $feed.isPeakHour = ($h -ge 9 -and $h -lt 15)
    $feed | ConvertTo-Json -Depth 3 | Set-Content $feedFile
}

function Update-Dashboard {
    if (Test-Path $renderer) {
        & $renderer -Quiet
    }
}

$cycle = 0
$opened = $false

Write-Host "[LIVE-FEED] Starting live feed (every ${RefreshSeconds}s)" -ForegroundColor Cyan
Write-Host "[LIVE-FEED] Feed: $feedFile" -ForegroundColor Gray
Write-Host "[LIVE-FEED] Dashboard: $dashboardFile" -ForegroundColor Gray
Write-Host "[LIVE-FEED] Ctrl+C to stop`n" -ForegroundColor Yellow

while ($true) {
    $cycle++
    Write-Host "`r[LIVE-FEED] Cycle $cycle @ $(Get-Date -Format 'HH:mm:ss')" -NoNewline -ForegroundColor Green
    & $collector -Scope full -Quiet
    Write-Feed
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
        Write-Host "`n[LIVE-FEED] Completed $Iterations cycles" -ForegroundColor Cyan
        break
    }
    Start-Sleep -Seconds $RefreshSeconds
}
