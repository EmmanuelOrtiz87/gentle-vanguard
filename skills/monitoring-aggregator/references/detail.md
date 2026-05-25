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
