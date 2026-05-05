<#
.SYNOPSIS
    Generates a static HTML dashboard from telemetry JSON data.

.DESCRIPTION
    Reads from:
    - config/metrics-config.json        (runtime_state, agent metrics)
    - .event-bus/history.json           (event history)
    - .event-bus/rate-limit-state.json  (rate-limit window)
    - docs/sessions/metrics/token-guard-usage.csv (daily token usage)
    - config/orchestrator.json          (token budget config)
    Output: reports/dashboard.html (self-contained, no CDN required)

.PARAMETER OutputPath
    Path for the generated HTML file. Default: reports/dashboard.html

.PARAMETER Open
    Open the generated file in the default browser.

.EXAMPLE
    .\generate-dashboard.ps1
    .\generate-dashboard.ps1 -Open
    .\generate-dashboard.ps1 -OutputPath C:\tmp\report.html
#>
param(
    [string]$OutputPath = '',
    [switch]$Open
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = (Resolve-Path (Join-Path $scriptDir '..\..\..')).Path

if (-not $OutputPath) {
    $reportsDir = Join-Path $repoRoot 'reports'
    if (-not (Test-Path $reportsDir)) { New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null }
    $OutputPath = Join-Path $reportsDir 'dashboard.html'
}

function Read-JsonFile {
    param([string]$Path)
    if (Test-Path $Path) {
        try { return Get-Content -Path $Path -Raw -Encoding UTF8 | ConvertFrom-Json } catch { return $null }
    }
    return $null
}

# ── Load data sources ─────────────────────────────────────────────────────────
$metrics    = Read-JsonFile (Join-Path $repoRoot 'config\metrics-config.json')
$orch       = Read-JsonFile (Join-Path $repoRoot 'config\orchestrator.json')
$eventHist  = Read-JsonFile (Join-Path $repoRoot '.event-bus\history.json')
$rlState    = Read-JsonFile (Join-Path $repoRoot '.event-bus\rate-limit-state.json')
$tokenCsv   = Join-Path $repoRoot 'docs\sessions\metrics\token-guard-usage.csv'

# ── Extract metrics ────────────────────────────────────────────────────────────
$generated = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$orchVersion = if ($orch) { $orch.version } else { 'N/A' }
$dailyBudget = if ($orch) { $orch.subagent_orchestration.token_budget_guard.daily_budget_tokens } else { 30000 }

# Agent dispatch counts from metrics runtime_state
$runtimeState = if ($metrics -and $metrics.runtime_state) { $metrics.runtime_state } else { $null }
$sessionsTotal   = if ($runtimeState -and $runtimeState.total_sessions) { $runtimeState.total_sessions } else { 0 }
$dispatchTotal   = if ($runtimeState -and $runtimeState.total_dispatches) { $runtimeState.total_dispatches } else { 0 }
$tokensAllTime   = if ($runtimeState -and $runtimeState.total_tokens_used) { $runtimeState.total_tokens_used } else { 0 }

# Event history stats
$eventCount = 0
$eventEmitted = 0
$eventBlocked = 0
$eventByType  = @{}
if ($eventHist -and $eventHist.events) {
    $eventCount = $eventHist.events.Count
    foreach ($e in $eventHist.events) {
        if ($e.status -eq 'emitted') { $eventEmitted++ } else { $eventBlocked++ }
        $key = if ($e.event) { $e.event } else { 'unknown' }
        if (-not $eventByType.ContainsKey($key)) { $eventByType[$key] = 0 }
        $eventByType[$key]++
    }
}

# Rate limit state summary
$rlSummary = ''
if ($rlState -and $rlState.updated) { $rlSummary = "Last updated: $($rlState.updated)" }

# Token CSV — last 7 days
$tokenRows = @()
if (Test-Path $tokenCsv) {
    try {
        $csvLines = Get-Content $tokenCsv -Encoding UTF8 | Select-Object -Skip 1 | Select-Object -Last 14
        foreach ($line in $csvLines) {
            $parts = $line -split ','
            if ($parts.Count -ge 3) {
                $tokenRows += @{ date = $parts[0].Trim(); tokens = $parts[1].Trim(); budget = $parts[2].Trim() }
            }
        }
    } catch { }
}

# ── Build chart data ──────────────────────────────────────────────────────────
$eventTypeLabels = ($eventByType.Keys | ForEach-Object { "'$_'" }) -join ','
$eventTypeValues = ($eventByType.Values | ForEach-Object { $_ }) -join ','

$tokenLabels = ($tokenRows | ForEach-Object { "'$($_.date)'" }) -join ','
$tokenValues = ($tokenRows | ForEach-Object { $_.tokens }) -join ','

# Recent events table (last 20)
$recentEventsHtml = ''
if ($eventHist -and $eventHist.events) {
    $recent = $eventHist.events | Select-Object -Last 20
    foreach ($e in $recent) {
        $statusClass = if ($e.status -eq 'emitted') { 'ok' } else { 'blocked' }
        $ts = if ($e.timestamp) { $e.timestamp } else { '' }
        $ev = if ($e.event) { $e.event } else { '' }
        $st = if ($e.status) { $e.status } else { '' }
        $recentEventsHtml += "<tr class='$statusClass'><td>$ts</td><td>$ev</td><td>$st</td></tr>`n"
    }
}

# ── HTML template ─────────────────────────────────────────────────────────────
$html = @"
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Gentleman Foundation - Dashboard</title>
<style>
  :root {
    --bg: #0d1117; --surface: #161b22; --border: #30363d;
    --text: #c9d1d9; --accent: #58a6ff; --ok: #3fb950;
    --warn: #d29922; --err: #f85149; --muted: #8b949e;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: var(--bg); color: var(--text); font-family: 'Segoe UI', system-ui, sans-serif; font-size: 14px; padding: 24px; }
  h1 { color: var(--accent); font-size: 1.6rem; margin-bottom: 4px; }
  .subtitle { color: var(--muted); margin-bottom: 24px; font-size: 12px; }
  .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin-bottom: 24px; }
  .card { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 18px; }
  .card h3 { color: var(--muted); font-size: 11px; text-transform: uppercase; letter-spacing: .5px; margin-bottom: 8px; }
  .card .value { font-size: 2rem; font-weight: 700; color: var(--accent); }
  .card .label { color: var(--muted); font-size: 12px; margin-top: 4px; }
  .section { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 18px; margin-bottom: 16px; }
  .section h2 { color: var(--text); font-size: 1rem; margin-bottom: 14px; border-bottom: 1px solid var(--border); padding-bottom: 8px; }
  table { width: 100%; border-collapse: collapse; font-size: 13px; }
  th { color: var(--muted); text-align: left; padding: 6px 8px; border-bottom: 1px solid var(--border); font-weight: 600; }
  td { padding: 5px 8px; border-bottom: 1px solid #21262d; }
  tr.ok td:last-child { color: var(--ok); }
  tr.blocked td:last-child { color: var(--err); }
  canvas { max-height: 220px; }
  .two-col { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
  @media (max-width: 700px) { .two-col { grid-template-columns: 1fr; } }
  .pill { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 600; }
  .pill.ok { background: #1a3a2a; color: var(--ok); }
  .pill.warn { background: #3a2e1a; color: var(--warn); }
  .pill.err { background: #3a1a1a; color: var(--err); }
  footer { color: var(--muted); font-size: 11px; text-align: center; margin-top: 24px; }
</style>
</head>
<body>

<h1>Gentleman Foundation</h1>
<p class="subtitle">Dashboard - Generated: $generated | Orchestrator: $orchVersion | Budget: $dailyBudget tokens/day</p>

<div class="grid">
  <div class="card">
    <h3>Sessions</h3>
    <div class="value">$sessionsTotal</div>
    <div class="label">total tracked</div>
  </div>
  <div class="card">
    <h3>Dispatches</h3>
    <div class="value">$dispatchTotal</div>
    <div class="label">total agent dispatches</div>
  </div>
  <div class="card">
    <h3>Tokens Used</h3>
    <div class="value">$tokensAllTime</div>
    <div class="label">all-time accumulated</div>
  </div>
  <div class="card">
    <h3>Events Emitted</h3>
    <div class="value">$eventEmitted</div>
    <div class="label">of $eventCount total ($eventBlocked blocked)</div>
  </div>
</div>

<div class="two-col">
  <div class="section">
    <h2>Event Distribution</h2>
    <canvas id="eventChart"></canvas>
  </div>
  <div class="section">
    <h2>Token Usage (last 14 entries)</h2>
    <canvas id="tokenChart"></canvas>
  </div>
</div>

<div class="section">
  <h2>Recent Events (last 20)</h2>
  <table>
    <thead><tr><th>Timestamp</th><th>Event</th><th>Status</th></tr></thead>
    <tbody>$recentEventsHtml</tbody>
  </table>
</div>

<footer>Gentleman Foundation &mdash; Local-First AI Orchestration Platform &mdash; $generated</footer>

<script>
// Minimal bar chart renderer (no CDN dependency)
function drawBarChart(canvasId, labels, values, color) {
  const canvas = document.getElementById(canvasId);
  if (!canvas || !labels.length) return;
  const ctx = canvas.getContext('2d');
  const W = canvas.width = canvas.parentElement.clientWidth - 36;
  const H = canvas.height = 200;
  const pad = { top: 10, right: 10, bottom: 40, left: 50 };
  const chartW = W - pad.left - pad.right;
  const chartH = H - pad.top - pad.bottom;
  const max = Math.max(...values, 1);
  const barW = Math.max(8, (chartW / labels.length) - 4);
  ctx.clearRect(0, 0, W, H);
  ctx.fillStyle = '#161b22';
  ctx.fillRect(0, 0, W, H);
  // Grid lines
  for (let i = 0; i <= 4; i++) {
    const y = pad.top + (chartH * (1 - i/4));
    ctx.strokeStyle = '#30363d'; ctx.lineWidth = 1;
    ctx.beginPath(); ctx.moveTo(pad.left, y); ctx.lineTo(W - pad.right, y); ctx.stroke();
    ctx.fillStyle = '#8b949e'; ctx.font = '10px system-ui'; ctx.textAlign = 'right';
    ctx.fillText(Math.round(max * i / 4), pad.left - 4, y + 3);
  }
  // Bars
  labels.forEach((lbl, i) => {
    const x = pad.left + i * (chartW / labels.length) + 2;
    const barH = (values[i] / max) * chartH;
    const y = pad.top + chartH - barH;
    ctx.fillStyle = color;
    ctx.fillRect(x, y, barW, barH);
    // Label
    ctx.fillStyle = '#8b949e'; ctx.font = '9px system-ui'; ctx.textAlign = 'center';
    const shortLbl = lbl.length > 12 ? lbl.slice(lbl.lastIndexOf('.') + 1) : lbl;
    ctx.fillText(shortLbl, x + barW/2, H - pad.bottom + 12);
  });
}

const eventLabels = [$eventTypeLabels];
const eventValues = [$eventTypeValues];
const tokenLabels = [$tokenLabels];
const tokenValues = [$tokenValues];

window.addEventListener('load', () => {
  drawBarChart('eventChart', eventLabels, eventValues, '#58a6ff');
  drawBarChart('tokenChart', tokenLabels, tokenValues.map(Number), '#3fb950');
});
</script>
</body>
</html>
"@

Set-Content -Path $OutputPath -Value $html -Encoding UTF8 -Force
Write-Host "[OK] Dashboard generated: $OutputPath" -ForegroundColor Green
if ($Open) {
    if ($IsWindows -or $env:OS -eq 'Windows_NT') { Start-Process $OutputPath }
    elseif ($IsMacOS) { & open $OutputPath }
    else { & xdg-open $OutputPath 2>$null }
}
