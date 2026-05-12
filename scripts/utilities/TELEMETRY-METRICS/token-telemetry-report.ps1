param(
    [double]$CostPer1MTokens = 10,
    [int]$BaselineTokensPerTask = 14000,
    [double]$ReductionPercent = 40,
    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'
if ($env:FOUNDATION_BASE_DIR) {
    $repoRoot = $env:FOUNDATION_BASE_DIR
} else {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
        $searchDir = Split-Path -Parent $searchDir
    }
    $repoRoot = $searchDir
}
$metricsDir = Join-Path $repoRoot 'docs\sessions\metrics'
$usageFile = Join-Path $metricsDir 'token-guard-usage.csv'
$outputDir = $metricsDir

if (-not (Test-Path $usageFile)) {
    Write-Host "[WARN] token-guard-usage.csv not found" -ForegroundColor Yellow
    exit 0
}

$rows = Import-Csv -Path $usageFile -ErrorAction SilentlyContinue
if (-not $rows) {
    Write-Host "[WARN] No telemetry rows found" -ForegroundColor Yellow
    exit 0
}

$totalTokens = 0
$tasks = $rows.Count
foreach ($row in $rows) {
    $tokens = 0
        if ($row.estimated_tokens -match '^\d+$') {
            $tokens = [int]$row.estimated_tokens
        $totalTokens += $tokens
    }
}

$baselineTokens = $tasks * $BaselineTokensPerTask
$optimizedTokens = [math]::Round($baselineTokens * (1 - ($ReductionPercent / 100)), 0)
$tokenSavings = $baselineTokens - $optimizedTokens

$costPerToken = $CostPer1MTokens / 1000000
$costActual = [math]::Round($totalTokens * $costPerToken, 2)
$costBaseline = [math]::Round($baselineTokens * $costPerToken, 2)
$costOptimized = [math]::Round($optimizedTokens * $costPerToken, 2)
$costSavings = [math]::Round($costBaseline - $costOptimized, 2)

$report = [pscustomobject]@{
    generatedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')
    tasks = $tasks
    totalTokens = $totalTokens
    baselineTokens = $baselineTokens
    optimizedTokens = $optimizedTokens
    tokenSavings = $tokenSavings
    costPer1MTokens = $CostPer1MTokens
    costActual = $costActual
    costBaseline = $costBaseline
    costOptimized = $costOptimized
    costSavings = $costSavings
    reductionPercent = $ReductionPercent
}

if ($AsJson) {
    $report | ConvertTo-Json -Depth 3
    exit 0
}

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$outputPath = Join-Path $outputDir "token-telemetry-report-$stamp.md"

$content = @"
# Token Telemetry Report

- Generated: $($report.generatedAt)
- Tasks: $($report.tasks)

## Tokens
- Total tokens: $($report.totalTokens)
- Baseline tokens: $($report.baselineTokens)
- Optimized tokens: $($report.optimizedTokens)
- Estimated savings: $($report.tokenSavings)

## Cost (USD)
- Cost per 1M tokens: $($report.costPer1MTokens)
- Actual cost: $($report.costActual)
- Baseline cost: $($report.costBaseline)
- Optimized cost: $($report.costOptimized)
- Estimated savings: $($report.costSavings)

## Policy
- Reduction percent: $($report.reductionPercent)
"@

$content | Set-Content -Path $outputPath -Encoding UTF8
Write-Host "[OK] Telemetry report: $outputPath" -ForegroundColor Green
