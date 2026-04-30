---
name: monitoring-aggregator
description: Monitoring aggregation skill for collecting and analyzing workspace metrics
---

# Skill: monitoring-aggregator

**Version**: 1.0.0
**Created**: 2026-04-20
**Status**: ACTIVE
**Priority**: MEDIUM

---

## Overview

The `monitoring-aggregator` skill provides comprehensive metrics aggregation, analysis, and insights from multiple data sources. It enables trend analysis, forecasting, and actionable recommendations for system optimization.

### Key Capabilities
-  Metrics aggregation from multiple sources
-  Trend analysis and pattern recognition
-  Forecasting and capacity planning
-  Intelligent recommendations
-  Visualization and reporting

---

## When to Use This Skill

### Activation Triggers
- User mentions "analyze metrics" or "analizar mtricas"
- User asks to "show trends" or "mostrar tendencias"
- User requests "predict resource usage" or "predecir uso de recursos"
- Regular monitoring reports needed
- Performance analysis required

---

## Core Components

### 1. Metrics Aggregation

#### CPU Usage Tracking
```powershell
function Get-CPUMetrics {
    param([int]$SampleCount = 10)
    
    $samples = @()
    for ($i = 0; $i -lt $SampleCount; $i++) {
        $cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
        $samples += $cpu
        Start-Sleep -Seconds 1
    }
    
    return @{
        Average = ($samples | Measure-Object -Average).Average
        Peak = ($samples | Measure-Object -Maximum).Maximum
        Min = ($samples | Measure-Object -Minimum).Minimum
    }
}
```

#### Memory Consumption
```powershell
function Get-MemoryMetrics {
    $os = Get-CimInstance Win32_OperatingSystem
    $totalMemory = $os.TotalVisibleMemorySize * 1KB
    $freeMemory = $os.FreePhysicalMemory * 1KB
    $usedMemory = $totalMemory - $freeMemory
    $usagePercent = ($usedMemory / $totalMemory) * 100
    
    return @{
        TotalMemory = $totalMemory
        UsedMemory = $usedMemory
        FreeMemory = $freeMemory
        UsagePercent = [math]::Round($usagePercent, 2)
    }
}
```

#### Disk I/O Patterns
```powershell
function Get-DiskIOMetrics {
    param([string]$Drive = "C:")
    
    $diskMetrics = Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk | 
        Where-Object { $_.Name -match $Drive }
    
    return @{
        Drive = $Drive
        ReadBytesPerSec = $diskMetrics.DiskReadBytesPerSec
        WriteBytesPerSec = $diskMetrics.DiskWriteBytesPerSec
        PercentDiskTime = $diskMetrics.PercentDiskTime
    }
}
```

---

### 2. Trend Analysis

#### Pattern Recognition
```powershell
function Detect-Patterns {
    param([array]$DataPoints)
    
    $patterns = @{
        Increasing = $false
        Decreasing = $false
        Stable = $false
        Volatile = $false
    }
    
    if ($DataPoints.Count -lt 3) {
        return $patterns
    }
    
    $diffs = @()
    for ($i = 1; $i -lt $DataPoints.Count; $i++) {
        $diffs += $DataPoints[$i] - $DataPoints[$i-1]
    }
    
    $avgDiff = ($diffs | Measure-Object -Average).Average
    $stdDev = [math]::Sqrt(($diffs | ForEach-Object { [math]::Pow($_ - $avgDiff, 2) } | Measure-Object -Average).Average)
    
    if ($stdDev -lt 5) { $patterns.Stable = $true }
    elseif ($avgDiff -gt 2) { $patterns.Increasing = $true }
    elseif ($avgDiff -lt -2) { $patterns.Decreasing = $true }
    else { $patterns.Volatile = $true }
    
    return $patterns
}
```

#### Seasonality Detection
```powershell
function Detect-Seasonality {
    param([array]$DataPoints, [int]$Period = 7)
    
    if ($DataPoints.Count -lt $Period * 2) {
        return @{ Detected = $false; Reason = "Insufficient data" }
    }
    
    $correlation = 0
    $count = 0
    
    for ($i = 0; $i -lt $DataPoints.Count - $Period; $i++) {
        $val1 = $DataPoints[$i]
        $val2 = $DataPoints[$i + $Period]
        $correlation += $val1 * $val2
        $count++
    }
    
    $correlation = $correlation / $count
    
    return @{
        Detected = ($correlation -gt 0.7)
        Correlation = [math]::Round($correlation, 2)
        Period = $Period
    }
}
```

#### Anomaly Scoring
```powershell
function Calculate-AnomalyScore {
    param([array]$DataPoints, [float]$CurrentValue)
    
    $mean = ($DataPoints | Measure-Object -Average).Average
    $stdDev = [math]::Sqrt(($DataPoints | ForEach-Object { [math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)
    
    $zScore = ($CurrentValue - $mean) / $stdDev
    $anomalyScore = [math]::Min([math]::Abs($zScore) / 3, 1.0)
    
    return @{
        ZScore = [math]::Round($zScore, 2)
        AnomalyScore = [math]::Round($anomalyScore, 2)
        IsAnomaly = ($anomalyScore -gt 0.7)
    }
}
```

---

### 3. Forecasting

#### Resource Usage Predictions
```powershell
function Predict-ResourceUsage {
    param(
        [array]$HistoricalData,
        [int]$ForecastDays = 7
    )
    
    if ($HistoricalData.Count -lt 3) {
        return @{ Error = "Insufficient historical data" }
    }
    
    $n = $HistoricalData.Count
    $sumX = 0
    $sumY = 0
    $sumXY = 0
    $sumX2 = 0
    
    for ($i = 0; $i -lt $n; $i++) {
        $x = $i
        $y = $HistoricalData[$i]
        $sumX += $x
        $sumY += $y
        $sumXY += $x * $y
        $sumX2 += $x * $x
    }
    
    $slope = ($n * $sumXY - $sumX * $sumY) / ($n * $sumX2 - $sumX * $sumX)
    $intercept = ($sumY - $slope * $sumX) / $n
    
    $forecast = @()
    for ($i = 0; $i -lt $ForecastDays; $i++) {
        $predicted = $intercept + $slope * ($n + $i)
        $forecast += [math]::Max(0, $predicted)
    }
    
    return @{
        Forecast = $forecast
        Slope = [math]::Round($slope, 2)
        Trend = if ($slope -gt 0) { "Increasing" } else { "Decreasing" }
    }
}
```

#### Capacity Planning
```powershell
function Plan-Capacity {
    param(
        [array]$HistoricalData,
        [float]$Threshold = 0.8
    )
    
    $prediction = Predict-ResourceUsage -HistoricalData $HistoricalData -ForecastDays 30
    
    $maxCapacity = 100
    $daysUntilThreshold = -1
    
    for ($i = 0; $i -lt $prediction.Forecast.Count; $i++) {
        if ($prediction.Forecast[$i] -ge ($maxCapacity * $Threshold)) {
            $daysUntilThreshold = $i
            break
        }
    }
    
    return @{
        DaysUntilThreshold = $daysUntilThreshold
        RecommendedAction = if ($daysUntilThreshold -lt 7) { "Urgent" } elseif ($daysUntilThreshold -lt 14) { "Soon" } else { "Plan" }
        CurrentTrend = $prediction.Trend
    }
}
```

---

### 4. Recommendations Engine

#### Optimization Suggestions
```powershell
function Get-OptimizationSuggestions {
    param([hashtable]$Metrics)
    
    $suggestions = @()
    
    if ($Metrics.CPUUsage -gt 80) {
        $suggestions += @{
            Priority = "High"
            Category = "CPU"
            Suggestion = "CPU usage is high. Consider optimizing processes or increasing resources."
        }
    }
    
    if ($Metrics.MemoryUsage -gt 85) {
        $suggestions += @{
            Priority = "High"
            Category = "Memory"
            Suggestion = "Memory usage is critical. Review running processes and consider cleanup."
        }
    }
    
    if ($Metrics.DiskUsage -gt 90) {
        $suggestions += @{
            Priority = "Critical"
            Category = "Disk"
            Suggestion = "Disk space is critically low. Archive or delete old files immediately."
        }
    }
    
    return $suggestions
}
```

#### Resource Allocation Advice
```powershell
function Get-ResourceAllocationAdvice {
    param([hashtable]$CurrentAllocation, [hashtable]$Usage)
    
    $advice = @()
    
    if ($Usage.CPUUsage -gt 75 -and $Usage.CPUUsage -lt 95) {
        $advice += "Consider allocating 20-30% more CPU resources"
    }
    
    if ($Usage.MemoryUsage -gt 80) {
        $advice += "Increase memory allocation by 25-50%"
    }
    
    if ($Usage.DiskUsage -gt 75) {
        $advice += "Expand storage or implement archival strategy"
    }
    
    return $advice
}
```

---

### 5. Visualization & Reporting

#### Terminal-Based Charts
```powershell
function Show-SimpleChart {
    param(
        [array]$Data,
        [string]$Title,
        [int]$Height = 10
    )
    
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    
    $max = $Data | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
    
    for ($row = $Height; $row -gt 0; $row--) {
        $threshold = ($max / $Height) * $row
        Write-Host -NoNewline " "
        
        foreach ($value in $Data) {
            if ($value -ge $threshold) {
                Write-Host -NoNewline " "
            } else {
                Write-Host -NoNewline "  "
            }
        }
        Write-Host ""
    }
    
    Write-Host ""
}
```

#### HTML Report Generation
```powershell
function Generate-HTMLReport {
    param(
        [hashtable]$Metrics,
        [string]$OutputPath = "report.html"
    )
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Monitoring Report</title>
    <style>
        body { font-family: Arial; margin: 20px; }
        .metric { border: 1px solid #ddd; padding: 10px; margin: 10px 0; }
        .high { color: red; }
        .normal { color: green; }
    </style>
</head>
<body>
    <h1>System Monitoring Report</h1>
    <div class="metric">
        <h3>CPU Usage: <span class="$(if ($Metrics.CPU -gt 80) { 'high' } else { 'normal' })">$($Metrics.CPU)%</span></h3>
    </div>
    <div class="metric">
        <h3>Memory Usage: <span class="$(if ($Metrics.Memory -gt 85) { 'high' } else { 'normal' })">$($Metrics.Memory)%</span></h3>
    </div>
    <div class="metric">
        <h3>Disk Usage: <span class="$(if ($Metrics.Disk -gt 90) { 'high' } else { 'normal' })">$($Metrics.Disk)%</span></h3>
    </div>
</body>
</html>
"@
    
    $html | Set-Content -Path $OutputPath
    return @{ Generated = $true; Path = $OutputPath }
}
```

#### JSON Export
```powershell
function Export-MetricsJSON {
    param(
        [hashtable]$Metrics,
        [string]$OutputPath = "metrics.json"
    )
    
    $Metrics | ConvertTo-Json | Set-Content -Path $OutputPath
    
    return @{
        Exported = $true
        Path = $OutputPath
        Timestamp = Get-Date
    }
}
```

---

## Practical Examples

### Example 1: Weekly Performance Report
```powershell
$cpu = Get-CPUMetrics -SampleCount 100
$memory = Get-MemoryMetrics
$disk = Get-DiskIOMetrics

$metrics = @{
    CPU = $cpu.Average
    Memory = $memory.UsagePercent
    Disk = $disk.PercentDiskTime
}

$suggestions = Get-OptimizationSuggestions -Metrics $metrics
Generate-HTMLReport -Metrics $metrics -OutputPath "weekly_report.html"
```

### Example 2: Capacity Planning
```powershell
$historicalCPU = @(45, 48, 52, 55, 58, 62, 65)
$plan = Plan-Capacity -HistoricalData $historicalCPU -Threshold 0.8

Write-Host "Days until 80% capacity: $($plan.DaysUntilThreshold)"
Write-Host "Recommended action: $($plan.RecommendedAction)"
```

### Example 3: Anomaly Detection
```powershell
$normalData = @(50, 52, 51, 53, 50, 52, 51)
$currentValue = 95

$anomaly = Calculate-AnomalyScore -DataPoints $normalData -CurrentValue $currentValue

if ($anomaly.IsAnomaly) {
    Write-Host " Anomaly detected! Z-Score: $($anomaly.ZScore)"
}
```

---

## Integration with Phase 1

### Dependencies
- `session-lifecycle` - Track metrics across sessions
- `backup-orchestrator` - Backup metrics data

---

## Performance Expectations

| Operation | Target Time | Max Memory |
|-----------|------------|-----------|
| Metrics Collection | <2 seconds | <50MB |
| Trend Analysis | <3 seconds | <75MB |
| Forecasting | <5 seconds | <100MB |
| Report Generation | <10 seconds | <150MB |

---

## Error Handling

**Issue**: "Insufficient historical data"
- **Solution**: Collect more data points before analysis

**Issue**: "Anomaly detected"
- **Solution**: Investigate cause, check system health

**Issue**: "Forecast unreliable"
- **Solution**: Increase data collection period