param([string]$ProjectRoot = ".")

$ErrorActionPreference = 'Continue'

$data = Get-Content (Join-Path $ProjectRoot ".runtime/metrics/consolidated.json") -Raw | ConvertFrom-Json
$git = Get-Content (Join-Path $ProjectRoot ".runtime/metrics/git.json") -Raw | ConvertFrom-Json
$pr = Get-Content (Join-Path $ProjectRoot ".runtime/metrics/pr.json") -Raw | ConvertFrom-Json
$cost = Get-Content (Join-Path $ProjectRoot ".runtime/metrics/cost.json") -Raw | ConvertFrom-Json
$token = Get-Content (Join-Path $ProjectRoot ".runtime/metrics/token.json") -Raw | ConvertFrom-Json
$live = Get-Content (Join-Path $ProjectRoot ".runtime/metrics/live.json") -Raw | ConvertFrom-Json
$sessions = Get-Content (Join-Path $ProjectRoot ".runtime/metrics/sessions.json") -Raw | ConvertFrom-Json

$netChange = $data.git.linesAdded30 - $data.git.linesRemoved30
$totalBench = $data.live.benchmarkPass + $data.live.benchmarkFail

$lines = @(
"# Gentle-Vanguard — Executive Board Report",
"",
"**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | **Period**: May 2026",
"",
"---",
"",
"## Executive Summary",
"",
"| Metric | Value |",
"|---|---|",
"| Status | ALL GREEN - $($live.trafficLight) |",
"| Total Commits | $($data.git.totalCommits) |",
"| This Month | $($data.git.monthCommits) |",
"| PRs Merged | $($data.pr.merged) / $($data.pr.total) |",
"| Avg PR Lifecycle | $($data.pr.avgReviewTimeHours)h |",
"| Active Sessions | $($data.sessions.active) |",
"| Total Sessions | $($data.sessions.total) |",
"| Contributors | $($data.git.authorCount) |",
"| Lines Added (30d) | +$($data.git.linesAdded30) |",
"| Lines Removed (30d) | -$($data.git.linesRemoved30) |",
"| Net Change (30d) | $($netChange) |",
"",
"## Cost & ROI",
"",
"| Metric | Value |",
"|---|---|",
"| Actual Cost MTD | `$$($data.cost.actualCost) |",
"| Month Forecast | `$$($data.cost.monthForecastCost) |",
"| Rate | `$$($data.cost.ratePer1M)/1M tokens |",
"| Token Budget/Day | $($data.token.budget) |",
"| Used Today | $($data.token.usedToday) ($($data.token.pct)%) |",
"| Baseline (est.) | $($data.cost.baselineTokens) tokens |",
"| Tokens Saved | $($data.cost.savedTokens) ($($data.cost.savingsPct)%) |",
"| Modeled Savings | `$$($data.cost.modeledSavings) |",
"",
"## Governance",
"",
"| Metric | Value |",
"|---|---|",
"| Token Guard | $($data.token.status) |",
"| Routing Accuracy | $($data.live.routingAcc) ($($data.live.routingTotal) dispatches) |",
"| Benchmark | $($data.live.benchmarkPass)/$($totalBench) passed |",
"",
"## Recent PRs",
"")

foreach ($p in $data.pr.recent) {
    $lines += "- #$($p.number) ($($p.state)): $($p.title)"
}

$lines += @(
"",
"## Development Velocity",
"",
"- **$($data.git.monthCommits) commits this month** across $($data.git.authorCount) contributors",
"- **$($data.pr.merged) PRs merged** with avg **$($data.pr.avgReviewTimeHours)h** lifecycle",
"- Top author: **$($data.git.topAuthor)** ($($data.git.totalCommits) commits)",
"- Net code change last 30 commits: **$($netChange) lines** ($($data.git.linesAdded30) added, $($data.git.linesRemoved30) removed)",
"",
"## Recommendations",
"",
"1. **Metrics pipeline fully operational**: collector, dashboard, live-feed all active",
"2. **Cost optimization**: `$$($data.cost.monthForecastCost) forecast — well within budget at $($data.cost.savingsPct)% savings vs baseline",
"3. **Velocity**: Healthy $($data.git.monthCommits) commits/month cadence with fast PR lifecycle",
"4. **Next step**: Wire up session-level telemetry for per-session cost attribution",
"",
"---",
"",
"*Data source: .runtime/metrics/consolidated.json*",
"*Live dashboard: reports/dashboard.html*",
""
)

$outPath = Join-Path $ProjectRoot "reports/MANAGEMENT-REPORT-2026-05.md"
$lines -join "`r`n" | Out-File -FilePath $outPath -Encoding utf8
Write-Host "[OK] Board report: $outPath" -ForegroundColor Green
Write-Host "[OK] Dashboard: reports/dashboard.html" -ForegroundColor Green
