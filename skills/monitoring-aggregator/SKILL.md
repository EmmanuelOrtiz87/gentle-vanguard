---
name: monitoring-aggregator
description: Monitoring aggregation skill for collecting and analyzing workspace metrics
---

# Skill: monitoring-aggregator

**versión**: 1.0.0 **Created**: 2026-04-20 **Status**: ACTIVE **Priority**: MEDIUM

---

## Overview

The `monitoring-aggregator` skill provides comprehensive metrics aggregation, analysis, and insights
from multiple data sources. It enables trend analysis, forecasting, and actionable recommendations
for system optimization.

### Key Capabilities

- Metrics aggregation from multiple sources
- Trend analysis and pattern recognition
- Forecasting and capacity planning
- Intelligent recommendations
- Visualization and reporting

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

## References

See `references/patterns.md` for detailed patterns and code examples.
