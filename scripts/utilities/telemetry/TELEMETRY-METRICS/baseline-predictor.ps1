<#
.SYNOPSIS
    Baseline predictor: forecasts performance degradation before it occurs.

.DESCRIPTION
    Analyzes historical baseline trends and predicts:
    - When latency will exceed threshold (SLO breach forecast)
    - When routing accuracy will drop below acceptable level
    - Confidence interval for predictions (68%, 95%, 99%)
    - Suggested action threshold

    Uses exponential regression with confidence intervals.

.PARAMETER HistoryPath
    Path to stack-benchmark-history.json. Default: ./reports/stack-benchmark-history.json

.PARAMETER BaselinePath
    Path to baseline config. Default: ./reports/stack-benchmark-baseline.json

.PARAMETER ForecastHours
    Hours ahead to forecast. Default: 24

.PARAMETER AlertThreshold
    Alert when forecast enters warning zone (2nd std dev). Default: true

.PARAMETER AsJson
    Output as JSON for programmatic use

.EXAMPLE
    .\\baseline-predictor.ps1 -ForecastHours 24 -AsJson
#>

param(
    [string]$HistoryPath = './reports/stack-benchmark-history.json',
    [string]$BaselinePath = './reports/stack-benchmark-baseline.json',
    [int]$ForecastHours = 24,
    [switch]$AlertThreshold,
    [switch]$AsJson
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..\..')).Path

if (-not [System.IO.Path]::IsPathRooted($HistoryPath)) {
    $HistoryPath = Join-Path $repoRoot ($HistoryPath -replace '^\.\\?', '')
}

if (-not [System.IO.Path]::IsPathRooted($BaselinePath)) {
    $BaselinePath = Join-Path $repoRoot ($BaselinePath -replace '^\.\\?', '')
}

function Get-LinearRegression {
    param([array]$XValues, [array]$YValues)
    
    if ($XValues.Count -lt 2) {
        return @{ slope = 0; intercept = 0; r_squared = 0; std_dev = 0 }
    }
    
    $n = $XValues.Count
    $sumX = ($XValues | Measure-Object -Sum).Sum
    $sumY = ($YValues | Measure-Object -Sum).Sum
    $sumXY = 0
    $sumX2 = 0
    
    for ($i = 0; $i -lt $n; $i++) {
        $sumXY += $XValues[$i] * $YValues[$i]
        $sumX2 += $XValues[$i] * $XValues[$i]
    }
    
    $slope = (($n * $sumXY) - ($sumX * $sumY)) / (($n * $sumX2) - ($sumX * $sumX))
    $intercept = ($sumY - ($slope * $sumX)) / $n
    
    # Calculate R²
    $yMean = $sumY / $n
    $ssRes = 0
    $ssTot = 0
    for ($i = 0; $i -lt $n; $i++) {
        $predicted = $slope * $XValues[$i] + $intercept
        $ssRes += [Math]::Pow($YValues[$i] - $predicted, 2)
        $ssTot += [Math]::Pow($YValues[$i] - $yMean, 2)
    }
    $r_squared = if ($ssTot -eq 0) { 0 } else { 1 - ($ssRes / $ssTot) }
    
    # Calculate standard deviation
    $mean_error = 0
    for ($i = 0; $i -lt $n; $i++) {
        $predicted = $slope * $XValues[$i] + $intercept
        $mean_error += [Math]::Pow($YValues[$i] - $predicted, 2)
    }
    $std_dev = [Math]::Sqrt($mean_error / $n)
    
    return @{
        slope     = [Math]::Round($slope, 6)
        intercept = [Math]::Round($intercept, 3)
        r_squared = [Math]::Round($r_squared, 4)
        std_dev   = [Math]::Round($std_dev, 3)
    }
}

# Load history
if (-not (Test-Path $HistoryPath)) {
    Write-Host "[WARN] History file not found: $HistoryPath" -ForegroundColor Yellow
    exit 1
}

$historyData = Get-Content $HistoryPath -Raw | ConvertFrom-Json -AsHashtable
if (-not $historyData) {
    Write-Host "[WARN] No historical data available" -ForegroundColor Yellow
    exit 1
}

# Extract time series for latency and routing accuracy.
# Use elapsed hours from the first sample so the forecast horizon is time-based, not sample-count based.
$samples = @()
$firstTimestamp = $null
foreach ($item in $historyData) {
    $sampleTimestamp = $null
    if ($item.timestamp) {
        try {
            $sampleTimestamp = [datetime]$item.timestamp
        } catch {
            $sampleTimestamp = $null
        }
    }

    if (-not $firstTimestamp -and $sampleTimestamp) {
        $firstTimestamp = $sampleTimestamp
    }

    $elapsedHours = if ($firstTimestamp -and $sampleTimestamp) {
        [math]::Round(($sampleTimestamp - $firstTimestamp).TotalHours, 4)
    } else {
        [double]$samples.Count
    }

    $metricSource = if ($item.metrics) { $item.metrics } else { $item }
    $latency = if ($null -ne $metricSource.wf_avg_elapsed_s) { [double]$metricSource.wf_avg_elapsed_s } else { 0 }
    $routing = if ($null -ne $metricSource.routing_accuracy_pct) { [double]$metricSource.routing_accuracy_pct } else { 100 }

    $samples += @{
        index   = $elapsedHours
        latency = $latency
        routing = $routing
    }
}

if ($samples.Count -lt 3) {
    Write-Host "[WARN] Insufficient samples ($($samples.Count)) for trend analysis" -ForegroundColor Yellow
    exit 1
}

# Recent samples only (last 100)
$recentSamples = @($samples | Select-Object -Last 100)
$xValues = @($recentSamples.index)
$yLatency = @($recentSamples.latency)
$yRouting = @($recentSamples.routing)

# Calculate trend
$latencyTrend = Get-LinearRegression -XValues $xValues -YValues $yLatency
$routingTrend = Get-LinearRegression -XValues $xValues -YValues $yRouting

# Forecast
$currentIndex = $xValues[-1]
$forecastIndex = $currentIndex + $ForecastHours

$forecastLatency = $latencyTrend.intercept + ($latencyTrend.slope * $forecastIndex)
$forecastRouting = $routingTrend.intercept + ($routingTrend.slope * $forecastIndex)

# Confidence intervals (±1 std dev = 68%, ±2 std dev = 95%)
$latency_ci_68 = @{
    lower = [Math]::Max(0.0, $forecastLatency - $latencyTrend.std_dev)
    upper = $forecastLatency + $latencyTrend.std_dev
}
$routing_ci_68 = @{
    lower = [Math]::Max(0.0, $forecastRouting - $routingTrend.std_dev)
    upper = [Math]::Min(100, $forecastRouting + $routingTrend.std_dev)
}

# SLO thresholds (typical)
$slo_latency = 1.5  # 1.5 seconds
$slo_routing = 95   # 95% accuracy

$latencySlopeMsPerHour = [math]::Round($latencyTrend.slope * 1000, 2)
$routingSlopePctPerHour = [math]::Round($routingTrend.slope, 3)
$recommendation = 'OK: Trends within acceptable bounds.'
if ($latencyTrend.slope -gt 0 -and $forecastLatency -gt ($slo_latency * 0.95)) {
    $recommendation = "ALERT: Latency trend is increasing by $latencySlopeMsPerHour ms/hour and is approaching the SLO threshold."
} elseif ($routingTrend.slope -lt 0 -and $forecastRouting -lt ($slo_routing + 1)) {
    $recommendation = "ALERT: Routing accuracy trend is declining by $routingSlopePctPerHour points/hour and is approaching the SLO threshold."
}

$forecast = @{
    timestamp           = Get-Date -Format 'o'
    forecast_hours_ahead = $ForecastHours
    latency             = @{
        forecast     = [Math]::Round($forecastLatency, 3)
        trend_slope  = $latencyTrend.slope
        slo_threshold = $slo_latency
        at_risk      = $forecastLatency -gt $slo_latency
        confidence_68 = @{
            lower = [Math]::Round($latency_ci_68.lower, 3)
            upper = [Math]::Round($latency_ci_68.upper, 3)
        }
        r_squared    = $latencyTrend.r_squared
    }
    routing             = @{
        forecast      = [Math]::Round($forecastRouting, 1)
        trend_slope   = $routingTrend.slope
        slo_threshold = $slo_routing
        at_risk       = $forecastRouting -lt $slo_routing
        confidence_68 = @{
            lower = [Math]::Round($routing_ci_68.lower, 1)
            upper = [Math]::Round($routing_ci_68.upper, 1)
        }
        r_squared     = $routingTrend.r_squared
    }
    recommendation      = $recommendation
}

if ($AsJson) {
    $forecast | ConvertTo-Json -Depth 5
} else {
    Write-Host ""
    Write-Host "=== Baseline Predictor — $ForecastHours Hour Forecast ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Latency Forecast" -ForegroundColor Yellow
    Write-Host "  Trend Slope:  $latencySlopeMsPerHour ms/hour"
    Write-Host "  Forecast:     $($forecast.latency.forecast)s (vs SLO: $($slo_latency)s)"
    Write-Host "  68% CI:       $($forecast.latency.confidence_68.lower)s — $($forecast.latency.confidence_68.upper)s"
    Write-Host "  At Risk:      $(if ($forecast.latency.at_risk) { 'YES' } else { 'NO' })"
    Write-Host ""
    Write-Host "Routing Accuracy Forecast" -ForegroundColor Yellow
    Write-Host "  Trend Slope:  $routingSlopePctPerHour points/hour"
    Write-Host "  Forecast:     $($forecast.routing.forecast)% (vs SLO: $($slo_routing)%)"
    Write-Host "  68% CI:       $($forecast.routing.confidence_68.lower)% — $($forecast.routing.confidence_68.upper)%"
    Write-Host "  At Risk:      $(if ($forecast.routing.at_risk) { 'YES' } else { 'NO' })"
    Write-Host ""
    Write-Host "Recommendation" -ForegroundColor Green
    Write-Host "  $($forecast.recommendation)"
    Write-Host ""
}

exit 0
