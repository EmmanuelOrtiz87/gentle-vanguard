<#
.SYNOPSIS
  Predictive Incident Response — anomaly detection and preemptive auto-healing.

.DESCRIPTION
  Reads time-series metrics from .telemetry/metrics/ and dashboard WS, detects
  anomalies using a simple statistical model (moving average + 3σ threshold),
  and triggers preemptive auto-healing when confidence > 70%.

.PARAMETER Action
  analyze  — run anomaly detection on latest metrics (default)
  status   — show predictor health and recent predictions
  learn    — adjust thresholds based on false positive history

.PARAMETER MetricSource
  Path to metric data file or directory (default: .telemetry/metrics/).

.PARAMETER ConfidenceThreshold
  Minimum confidence to trigger preemptive heal (default: 0.7).

.EXAMPLE
  .\predictive-incident-response.ps1 -Action analyze
  .\predictive-incident-response.ps1 -Action status
#>

param(
  [ValidateSet("analyze", "status", "learn")]
  [string]$Action = "analyze",
  [string]$MetricSource = "",
  [double]$ConfidenceThreshold = 0.7
)

$ErrorActionPreference = "Stop"

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
  $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
  if (-not $root) { $root = (Get-Location).Path }
  $root
}

$predictorDir = Join-Path $repoRoot ".session\predictive"
$null = New-Item -ItemType Directory -Path $predictorDir -Force

$confidenceFile = Join-Path $predictorDir "confidence.json"
$historyFile = Join-Path $predictorDir "predictions.json"

# Default thresholds (adjusted by -Action learn)
$thresholds = if (Test-Path $confidenceFile) {
  Get-Content $confidenceFile -Raw | ConvertFrom-Json
} else {
  @{
    zScoreThreshold = 3.0        # Number of standard deviations for anomaly
    windowSize = 60              # Window in minutes
    minDataPoints = 10           # Minimum data points before prediction
    falsePositivePenalty = 0.05  # Threshold adjustment per false positive
    truePositiveReward = 0.01    # Threshold adjustment per true positive
  }
}

function Get-TimeSeriesMetrics {
  # Read metrics from .telemetry/metrics/ directory
  $metricsDir = if ($MetricSource) { $MetricSource } else { Join-Path $repoRoot ".telemetry\metrics" }
  if (-not (Test-Path $metricsDir)) {
    # Fall back to dashboard health check
    try {
      $healthResp = Invoke-WebRequest -Uri "http://localhost:$($env:WS_PORT)/api/health" -TimeoutSec 5 -ErrorAction SilentlyContinue
      if ($healthResp.StatusCode -eq 200) {
        $data = $healthResp.Content | ConvertFrom-Json
        return @{ source = "dashboard-ws"; data = $data; timestamp = Get-Date -Format "o" }
      }
    } catch {}
    return $null
  }

  $files = Get-ChildItem -Path $metricsDir -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 10
  if ($files.Count -eq 0) { return $null }

  $allMetrics = @()
  foreach ($f in $files) {
    try {
      $allMetrics += Get-Content $f.FullName -Raw | ConvertFrom-Json
    } catch {}
  }
  return @{ source = "telemetry"; data = $allMetrics; files = $files.Count; timestamp = Get-Date -Format "o" }
}

function Detect-Anomalies {
  param($MetricData)
  $anomalies = @()

  if (-not $MetricData -or -not $MetricData.data) { return $anomalies }

  # Extract numeric metric values for analysis
  $values = @()
  $metricData = $MetricData.data

  if ($metricData -is [array]) {
    $values = $metricData | ForEach-Object { $_.value } | Where-Object { $_ -ne $null }
  } elseif ($metricData.PSObject.Properties) {
    $values = $metricData.PSObject.Properties | ForEach-Object { $_.Value } | Where-Object { $_ -is [int] -or $_ -is [double] }
  }

  if ($values.Count -lt $thresholds.minDataPoints) {
    Write-Host "[PREDICT] Insufficient data points ($($values.Count) < $($thresholds.minDataPoints))" -ForegroundColor Gray
    return $anomalies
  }

  $mean = ($values | Measure-Object -Average).Average
  $stdDev = [math]::Sqrt(($values | ForEach-Object { [math]::Pow($_ - $mean, 2) } | Measure-Object -Sum).Sum / $values.Count)
  if ($stdDev -eq 0) { return $anomalies }

  $latestValue = $values[-1]
  $zScore = [math]::Abs(($latestValue - $mean) / $stdDev)

  if ($zScore -gt $thresholds.zScoreThreshold) {
    $confidence = [math]::Min([math]::Abs($zScore / $thresholds.zScoreThreshold), 1.0)
    if ($confidence -ge $ConfidenceThreshold) {
      $anomalies += @{
        metric = "composite"
        value = $latestValue
        mean = [math]::Round($mean, 2)
        stdDev = [math]::Round($stdDev, 2)
        zScore = [math]::Round($zScore, 2)
        confidence = [math]::Round($confidence, 2)
        direction = if ($latestValue -gt $mean) { "spike" } else { "drop" }
        timestamp = Get-Date -Format "o"
      }
    }
  }

  return $anomalies
}

function Invoke-PredictiveHeal {
  param($Anomaly)
  Write-Host "[PREDICT] Preemptive heal triggered — confidence: $($Anomaly.confidence)" -ForegroundColor Yellow

  $healResult = @{
    timestamp = Get-Date -Format "o"
    anomaly = $Anomaly
    action = "watchtower-autoheal"
    status = "triggered"
  }

  # Try to invoke watchtower autoheal
  $watchtowerPath = Join-Path $repoRoot "scripts\maintenance\maintenance-watchtower.ps1"
  if (Test-Path $watchtowerPath) {
    try {
      & $watchtowerPath -Action autoheal -Quiet 2>&1 | Out-Null
      $healResult.status = "healed"
      Write-Host "[PREDICT] Watchtower autoheal completed" -ForegroundColor Green
    } catch {
      $healResult.status = "failed"
      $healResult.error = $_.Exception.Message
      Write-Host "[PREDICT] Watchtower autoheal failed: $($_.Exception.Message)" -ForegroundColor Red
    }
  }

  return $healResult
}

# ---- Main ----

$predictions = if (Test-Path $historyFile) {
  Get-Content $historyFile -Raw | ConvertFrom-Json
} else {
  @{ predictions = @(); falsePositives = 0; truePositives = 0; totalPredictions = 0 }
}

switch ($Action) {
  "analyze" {
    Write-Host "[PREDICT] Analyzing metrics for anomalies..." -ForegroundColor Cyan

    $metricData = Get-TimeSeriesMetrics
    if (-not $metricData) {
      Write-Host "[PREDICT] No metrics available" -ForegroundColor Yellow
      return @{ status = "no-data" }
    }

    $anomalies = Detect-Anomalies -MetricData $metricData

    if ($anomalies.Count -eq 0) {
      Write-Host "[PREDICT] No anomalies detected" -ForegroundColor Green
      return @{ status = "normal"; metricSource = $metricData.source }
    }

    foreach ($anomaly in $anomalies) {
      Write-Host "[PREDICT] ANOMALY DETECTED:" -ForegroundColor Red
      Write-Host "  Value: $($anomaly.value) (mean: $($anomaly.mean), σ: $($anomaly.stdDev))" -ForegroundColor Yellow
      Write-Host "  Z-score: $($anomaly.zScore) | Confidence: $($anomaly.confidence)" -ForegroundColor Yellow
      Write-Host "  Direction: $($anomaly.direction)" -ForegroundColor Yellow

      if ($anomaly.confidence -ge $ConfidenceThreshold) {
        $healResult = Invoke-PredictiveHeal -Anomaly $anomaly
        $anomaly.healResult = $healResult

        $predictions.totalPredictions++
        if ($healResult.status -eq "healed") {
          $predictions.truePositives++
          # Adjust threshold (make it slightly more sensitive)
          $thresholds.zScoreThreshold = [math]::Max(2.0, $thresholds.zScoreThreshold - $thresholds.truePositiveReward)
        } else {
          $predictions.falsePositives++
          $thresholds.zScoreThreshold += $thresholds.falsePositivePenalty
        }

        # Save updated thresholds
        $thresholds | ConvertTo-Json | Set-Content $confidenceFile -Encoding utf8
      }
    }

    # Save prediction history
    $predictions.predictions += $anomalies
    $predictions | ConvertTo-Json -Depth 10 | Set-Content $historyFile -Encoding utf8

    return @{ status = "anomaly"; anomalies = $anomalies; predictions = $predictions }
  }

  "status" {
    Write-Host "[PREDICT] Status:" -ForegroundColor Cyan
    Write-Host "  Total predictions: $($predictions.totalPredictions)" -ForegroundColor Gray
    Write-Host "  True positives: $($predictions.truePositives)" -ForegroundColor Green
    Write-Host "  False positives: $($predictions.falsePositives)" -ForegroundColor Yellow
    $accuracy = if ($predictions.totalPredictions -gt 0) { [math]::Round($predictions.truePositives / $predictions.totalPredictions * 100, 1) } else { "N/A" }
    Write-Host "  Accuracy: $accuracy%" -ForegroundColor $(if ($accuracy -ne "N/A" -and $accuracy -ge 80) { "Green" } elseif ($accuracy -ne "N/A") { "Yellow" } else { "Gray" })
    Write-Host "  Z-score threshold: $($thresholds.zScoreThreshold)" -ForegroundColor Gray
    Write-Host "  Confidence threshold: $ConfidenceThreshold" -ForegroundColor Gray
    return @{
      totalPredictions = $predictions.totalPredictions
      truePositives = $predictions.truePositives
      falsePositives = $predictions.falsePositives
      zScoreThreshold = $thresholds.zScoreThreshold
    }
  }

  "learn" {
    Write-Host "[PREDICT] Learning from history..." -ForegroundColor Cyan
    $rate = if ($predictions.totalPredictions -gt 0) { $predictions.falsePositives / $predictions.totalPredictions } else { 0 }
    if ($rate -gt 0.3) {
      $thresholds.zScoreThreshold += 0.5
      Write-Host "[PREDICT] High false positive rate ($rate) — increased threshold to $($thresholds.zScoreThreshold)" -ForegroundColor Yellow
    } elseif ($rate -lt 0.1 -and $predictions.totalPredictions -gt 5) {
      $thresholds.zScoreThreshold = [math]::Max(2.0, $thresholds.zScoreThreshold - 0.3)
      Write-Host "[PREDICT] Low false positive rate ($rate) — decreased threshold to $($thresholds.zScoreThreshold)" -ForegroundColor Green
    } else {
      Write-Host "[PREDICT] No adjustment needed (rate: $rate)" -ForegroundColor Gray
    }
    $thresholds | ConvertTo-Json | Set-Content $confidenceFile -Encoding utf8
    return $thresholds
  }
}
