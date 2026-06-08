param([switch]$Quiet, [switch]$Open)

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$reportsDir = Join-Path $repoRoot 'reports'
$outFile = Join-Path $reportsDir 'dashboard.html'
$metricsDir = Join-Path $repoRoot '.runtime' 'metrics'
$sessionDir = Join-Path $repoRoot 'session'
if (-not (Test-Path $reportsDir)) { New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null }

function Log { param([string]$M) if (-not $Quiet) { Write-Host "[DASHBOARD] $M" -ForegroundColor Green } }

function Read-Metric($Name) {
    $path = Join-Path $metricsDir "$Name.json"
    if (-not (Test-Path $path)) { return $null }
    try { return Get-Content $path -Raw | ConvertFrom-Json }
    catch { Log "Error reading $Name`: $($_.Exception.Message)"; return $null }
}

function Read-Sessions {
    $result = @()
    $dir = $sessionDir
    if (-not (Test-Path $dir)) { return $result }
    try {
        $files = Get-ChildItem -Path $dir -Filter 'session-*.json' -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 50
        foreach ($f in $files) {
            try {
                $s = Get-Content $f.FullName -Raw -ErrorAction Stop | ConvertFrom-Json
                $start = if ($s.startTime) { [DateTime]$s.startTime } else { $f.LastWriteTime }
                $durSec = [int](($f.LastWriteTime - $start).TotalSeconds)
                if ($durSec -lt 0) { $durSec = 0 }
                $result += [PSCustomObject]@{
                    sessionId = $s.sessionId; startTime = $s.startTime
                    status = $s.status; mode = $s.mode; project = $s.project
                    durationSec = $durSec; sourceFile = $f.Name
                }
            } catch { Log "Error parsing $($f.Name): $($_.Exception.Message)" }
        }
    } catch { Log "Error reading sessions: $($_.Exception.Message)" }
    return $result
}

function FmtDur($sec) {
    if (-not $sec -or $sec -eq 0) { return '-' }
    $ts = [TimeSpan]::FromSeconds($sec)
    if ($ts.TotalHours -ge 1) { return "$([math]::Floor($ts.TotalHours))h $($ts.Minutes)m" }
    if ($ts.TotalMinutes -ge 1) { return "$($ts.Minutes)m $($ts.Seconds)s" }
    return "$($sec)s"
}

function FmtNum($n) {
    if (-not $n) { return '0' }
    if ($n -ge 1e6) { return "$([math]::Round($n/1e6,1))M" }
    if ($n -ge 1e3) { return "$([math]::Round($n/1e3,1))K" }
    return "$n"
}

Log "Reading metrics from $metricsDir"

$git = Read-Metric 'git'
$sessions = Read-Metric 'sessions'
$token = Read-Metric 'token'
$cost = Read-Metric 'cost'
$rawSessions = Read-Sessions

if (-not $git) { Log "git.json not found or empty"; $git = $null }
if (-not $sessions) { Log "sessions.json not found or empty"; $sessions = $null }
if (-not $token) { Log "token.json not found or empty"; $token = $null }
if (-not $cost) { Log "cost.json not found or empty"; $cost = $null }

$totalCommits = if ($git) { $git.totalCommits } else { 'No data' }
$monthCommits = if ($git) { $git.monthCommits } else { '-' }
$todayCommits = if ($git) { $git.todayCommits } else { '-' }
$linesAdded = if ($git) { $git.linesAdded30 } else { '-' }
$linesRemoved = if ($git) { $git.linesRemoved30 } else { '-' }
$authorCount = if ($git) { $git.authorCount } else { '-' }
$topAuthor = if ($git -and $git.topAuthor) { $git.topAuthor } else { '-' }

$sessionTotal = if ($sessions) { $sessions.total } else { 'No data' }
$sessionActive = if ($sessions) { $sessions.active } else { '-' }
$sessionToday = if ($sessions) { $sessions.today } else { '-' }
$avgDurSec = if ($sessions -and $sessions.avgDurationSec -gt 0) { $sessions.avgDurationSec } else { 0 }
$totalDurMin = if ($sessions) { $sessions.totalDurationMin } else { 0 }

$tokenUsed = if ($token) { $token.usedToday } else { 'No data' }
$tokenBudget = if ($token) { $token.budget } else { '-' }
$tokenPct = if ($token) { $token.pct } else { '-' }
$tokenStatus = if ($token) { $token.status } else { 'unknown' }
$estCost = if ($token) { $token.estCost } else { 0 }
$forecastCost = if ($token) { $token.monthForecastCost } else { 0 }

$costActual = if ($cost) { $cost.actualCost } else { 0 }
$costForecast = if ($cost) { $cost.monthForecastCost } else { 0 }
$savings = if ($cost) { $cost.modeledSavings } else { 0 }
$savingsPct = if ($cost) { $cost.savingsPct } else { 0 }

$activeSessions = @($rawSessions | Where-Object { $_.status -eq 'active' })
$todaySessions = @($rawSessions | Where-Object {
    try { ([DateTime]$_.startTime).Date -eq (Get-Date).Date } catch { $false }
})

$cards = @"
<div class="card">
    <div class="card-title">Git Metrics</div>
    <div class="card-body">
        <div class="stat-row"><span class="stat-label">Total Commits</span><span class="stat-value">$(FmtNum $totalCommits)</span></div>
        <div class="stat-row"><span class="stat-label">This Month</span><span class="stat-value">$(FmtNum $monthCommits)</span></div>
        <div class="stat-row"><span class="stat-label">Today</span><span class="stat-value">$todayCommits</span></div>
        <div class="stat-row"><span class="stat-label">Lines +/-</span><span class="stat-value">+$linesAdded / -$linesRemoved</span></div>
        <div class="stat-row"><span class="stat-label">Authors</span><span class="stat-value">$authorCount</span></div>
        <div class="stat-row"><span class="stat-label">Top Author</span><span class="stat-value">$topAuthor</span></div>
    </div>
</div>
"@

$cards += @"
<div class="card">
    <div class="card-title">Sessions</div>
    <div class="card-body">
        <div class="stat-row"><span class="stat-label">Total Sessions</span><span class="stat-value">$(FmtNum $sessionTotal)</span></div>
        <div class="stat-row"><span class="stat-label">Active Now</span><span class="stat-value">$sessionActive</span></div>
        <div class="stat-row"><span class="stat-label">Today</span><span class="stat-value">$sessionToday</span></div>
        <div class="stat-row"><span class="stat-label">Avg Duration</span><span class="stat-value">$(FmtDur $avgDurSec)</span></div>
        <div class="stat-row"><span class="stat-label">Total Duration</span><span class="stat-value">$totalDurMin min</span></div>
    </div>
</div>
"@

$tokenLabel = if ($tokenUsed -is [int]) { "$(FmtNum $tokenUsed) / $(FmtNum $tokenBudget)" } else { "$tokenUsed / $tokenBudget" }
$cards += @"
<div class="card">
    <div class="card-title">Token Usage</div>
    <div class="card-body">
        <div class="stat-row"><span class="stat-label">Used / Budget</span><span class="stat-value">$tokenLabel</span></div>
        <div class="stat-row"><span class="stat-label">Usage</span><span class="stat-value">$(if($tokenPct -is [int]){"$tokenPct%"}else{$tokenPct})</span></div>
        <div class="stat-row"><span class="stat-label">Status</span><span class="stat-value">$tokenStatus</span></div>
    </div>
</div>
"@

$cards += @"
<div class="card">
    <div class="card-title">Cost &amp; Savings</div>
    <div class="card-body">
        <div class="stat-row"><span class="stat-label">Est. Cost Today</span><span class="stat-value">`$$([math]::Round($costActual, 4))</span></div>
        <div class="stat-row"><span class="stat-label">Month Forecast</span><span class="stat-value">`$$([math]::Round($costForecast, 2))</span></div>
        <div class="stat-row"><span class="stat-label">Modeled Savings</span><span class="stat-value">`$$([math]::Round($savings, 4))</span></div>
        <div class="stat-row"><span class="stat-label">Savings %</span><span class="stat-value">$savingsPct%</span></div>
    </div>
</div>
"@

$recentRows = ''
$recentData = $rawSessions | Select-Object -First 20
if ($recentData.Count -eq 0) {
    $recentRows = '<tr><td colspan="5" class="no-data">No session data available</td></tr>'
} else {
    foreach ($s in $recentData) {
        $id = if ($s.sessionId) { $s.sessionId.Substring(0, [Math]::Min(12, $s.sessionId.Length)) } else { '-' }
        $start = if ($s.startTime) { $s.startTime } else { '-' }
        $dur = FmtDur $s.durationSec
        $proj = if ($s.project) { $s.project } else { '-' }
        $recentRows += "<tr><td>$id</td><td>$start</td><td>$dur</td><td>$($s.status)</td><td>$proj</td></tr>"
    }
}

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Gentle-Vanguard Dashboard</title>
<style>
:root {
    --bg: #0d1117; --card-bg: #161b22; --border: #30363d;
    --text: #c9d1d9; --text-muted: #8b949e; --accent: #58a6ff;
    --green: #3fb950; --yellow: #d29922; --red: #f85149;
}
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: var(--bg); color: var(--text); padding: 20px; }
h1 { font-size: 1.5rem; margin-bottom: 8px; color: var(--accent); }
.subtitle { color: var(--text-muted); margin-bottom: 20px; font-size: 0.85rem; }
.dashboard { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 16px; margin-bottom: 24px; }
.card { background: var(--card-bg); border: 1px solid var(--border); border-radius: 8px; padding: 16px; }
.card-title { font-size: 0.8rem; text-transform: uppercase; letter-spacing: 0.05em; color: var(--text-muted); margin-bottom: 12px; }
.card-body { display: flex; flex-direction: column; gap: 6px; }
.stat-row { display: flex; justify-content: space-between; align-items: center; font-size: 0.9rem; }
.stat-label { color: var(--text-muted); }
.stat-value { font-weight: 600; font-variant-numeric: tabular-nums; }
.section-title { font-size: 1.1rem; margin-bottom: 12px; color: var(--accent); }
table { width: 100%; border-collapse: collapse; background: var(--card-bg); border: 1px solid var(--border); border-radius: 8px; overflow: hidden; }
th { text-align: left; padding: 10px 12px; font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em; color: var(--text-muted); border-bottom: 1px solid var(--border); }
td { padding: 10px 12px; font-size: 0.85rem; border-bottom: 1px solid var(--border); }
tr:last-child td { border-bottom: none; }
.no-data { text-align: center; color: var(--text-muted); padding: 24px; }
</style>
</head>
<body>
<h1>Gentle-Vanguard Metrics Dashboard</h1>
<div class="subtitle">Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</div>
<div class="dashboard">$cards</div>
<h2 class="section-title">Recent Sessions</h2>
<table>
<thead><tr><th>Session</th><th>Start Time</th><th>Duration</th><th>Status</th><th>Project</th></tr></thead>
<tbody>$recentRows</tbody>
</table>
</body>
</html>
"@

$html | Set-Content -Path $outFile -Encoding UTF8
Log "Dashboard written to $outFile"

if ($Open -and (Get-Command 'Start-Process' -ErrorAction SilentlyContinue)) {
    Start-Process $outFile
}
