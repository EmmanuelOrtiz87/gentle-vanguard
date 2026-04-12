param(
    [int]$Days = 7,
    [string]$MetricsPath = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')

if ([string]::IsNullOrWhiteSpace($MetricsPath)) {
    $MetricsPath = Join-Path $repoRoot 'docs/sessions/metrics/context-usage.csv'
}

if (-not (Test-Path $MetricsPath)) {
    Write-Host "[WARN] Metrics file not found: $MetricsPath" -ForegroundColor Yellow
    Write-Host 'Run ./scripts/compact-start.ps1 or ./scripts/context-pack.ps1 to start collecting metrics.' -ForegroundColor Yellow
    exit 0
}

$cutoff = (Get-Date).AddDays(-1 * $Days)
$rows = Import-Csv -Path $MetricsPath | Where-Object {
    $ts = [datetime]::Parse($_.timestamp)
    $ts -ge $cutoff
}

if (-not $rows -or $rows.Count -eq 0) {
    Write-Host "[INFO] No context usage records in the last $Days days." -ForegroundColor Cyan
    exit 0
}

$total = $rows.Count
$compactCount = @($rows | Where-Object event -eq 'compact-start').Count
$packCount = @($rows | Where-Object event -eq 'context-pack').Count
$avgObjective = [math]::Round((($rows | Measure-Object -Property objective_chars -Average).Average), 1)
$avgPrompt = [math]::Round((($rows | Measure-Object -Property prompt_chars -Average).Average), 1)

Write-Host "Context Metrics (last $Days days)" -ForegroundColor Cyan
Write-Host "  Total events: $total"
Write-Host "  context-pack: $packCount"
Write-Host "  compact-start: $compactCount"
Write-Host "  Avg objective chars: $avgObjective"
Write-Host "  Avg prompt chars: $avgPrompt"

$byDay = $rows | Group-Object { ([datetime]::Parse($_.timestamp)).ToString('yyyy-MM-dd') } | Sort-Object Name
Write-Host ''
Write-Host 'Daily usage:' -ForegroundColor Cyan
foreach ($day in $byDay) {
    $dTotal = $day.Count
    $dCompact = @($day.Group | Where-Object event -eq 'compact-start').Count
    $dPack = @($day.Group | Where-Object event -eq 'context-pack').Count
    Write-Host "  $($day.Name): total=$dTotal, context-pack=$dPack, compact-start=$dCompact"
}
