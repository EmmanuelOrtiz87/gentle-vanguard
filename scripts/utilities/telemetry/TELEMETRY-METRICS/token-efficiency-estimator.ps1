param(
    [int]$TasksPerMonth = 20,
    [int]$BaselineTokensPerTask = 14000,
    [double]$ReductionPercent = 40,
    [double]$AvgTaskMinutesBaseline = 90,
    [double]$TimeReductionPercent = 18,
    [double]$CostPer1MTokens = 10
)

if ($TasksPerMonth -le 0 -or $BaselineTokensPerTask -le 0) {
    throw "TasksPerMonth and BaselineTokensPerTask must be greater than zero."
}

if ($ReductionPercent -lt 0 -or $ReductionPercent -gt 100) {
    throw "ReductionPercent must be between 0 and 100."
}

if ($TimeReductionPercent -lt 0 -or $TimeReductionPercent -gt 100) {
    throw "TimeReductionPercent must be between 0 and 100."
}

$baselineMonthlyTokens = $TasksPerMonth * $BaselineTokensPerTask
$optimizedTokensPerTask = [math]::Round($BaselineTokensPerTask * (1 - ($ReductionPercent / 100)), 0)
$optimizedMonthlyTokens = $TasksPerMonth * $optimizedTokensPerTask
$tokenSavingsMonthly = $baselineMonthlyTokens - $optimizedMonthlyTokens
$tokenSavingsYearly = $tokenSavingsMonthly * 12

$baselineMonthlyMinutes = $TasksPerMonth * $AvgTaskMinutesBaseline
$optimizedTaskMinutes = [math]::Round($AvgTaskMinutesBaseline * (1 - ($TimeReductionPercent / 100)), 2)
$optimizedMonthlyMinutes = [math]::Round($TasksPerMonth * $optimizedTaskMinutes, 2)
$timeSavingsMonthlyMinutes = [math]::Round($baselineMonthlyMinutes - $optimizedMonthlyMinutes, 2)
$timeSavingsMonthlyHours = [math]::Round($timeSavingsMonthlyMinutes / 60, 2)
$timeSavingsYearlyHours = [math]::Round($timeSavingsMonthlyHours * 12, 2)

$costPerToken = $CostPer1MTokens / 1000000
$monthlyCostBaseline = [math]::Round($baselineMonthlyTokens * $costPerToken, 2)
$monthlyCostOptimized = [math]::Round($optimizedMonthlyTokens * $costPerToken, 2)
$monthlyCostSavings = [math]::Round($monthlyCostBaseline - $monthlyCostOptimized, 2)
$yearlyCostSavings = [math]::Round($monthlyCostSavings * 12, 2)

$result = [pscustomobject]@{
    tasksPerMonth = $TasksPerMonth
    baselineTokensPerTask = $BaselineTokensPerTask
    optimizedTokensPerTask = $optimizedTokensPerTask
    reductionPercent = $ReductionPercent
    baselineMonthlyTokens = $baselineMonthlyTokens
    optimizedMonthlyTokens = $optimizedMonthlyTokens
    monthlyTokenSavings = $tokenSavingsMonthly
    yearlyTokenSavings = $tokenSavingsYearly
    baselineTaskMinutes = $AvgTaskMinutesBaseline
    optimizedTaskMinutes = $optimizedTaskMinutes
    monthlyTimeSavingsMinutes = $timeSavingsMonthlyMinutes
    monthlyTimeSavingsHours = $timeSavingsMonthlyHours
    yearlyTimeSavingsHours = $timeSavingsYearlyHours
    monthlyCostBaseline = $monthlyCostBaseline
    monthlyCostOptimized = $monthlyCostOptimized
    monthlyCostSavings = $monthlyCostSavings
    yearlyCostSavings = $yearlyCostSavings
}

$result | ConvertTo-Json -Depth 3
