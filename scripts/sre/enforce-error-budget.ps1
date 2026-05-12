param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "config/sre-error-budgets.json",

    [Parameter(Mandatory = $false)]
    [string]$Service = "all",

    [Parameter(Mandatory = $false)]
    [switch]$Json
)

function Get-ErrorBudgetState {
    param(
        [hashtable]$Budget,
        [hashtable]$CurrentConsumption
    )

    $ratio = 0
    if ($Budget.ContainsKey("budget_seconds") -and $Budget.budget_seconds -gt 0) {
        $ratio = $CurrentConsumption.consumed_seconds / $Budget.budget_seconds
    }
    elseif ($Budget.ContainsKey("budget_runs") -and $Budget.budget_runs -gt 0) {
        $ratio = $CurrentConsumption.consumed_runs / $Budget.budget_runs
    }

    $state = switch ($ratio) {
        { $_ -gt 0.9 } { "EXHAUSTED" }
        { $_ -gt 0.75 } { "CRITICAL" }
        { $_ -gt 0.5 } { "WARNING" }
        default { "HEALTHY" }
    }

    return @{
        Service = $CurrentConsumption.Service
        Ratio = [math]::Round($ratio, 4)
        State = $state
        Budget = $Budget.slo
        PeriodDays = $Budget.period_days
    }
}

try {
    if (-not (Test-Path $ConfigPath)) {
        Write-Error "Config not found: $ConfigPath"
        exit 1
    }

    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

    $results = @()
    $exitCode = 0

    foreach ($entry in $config.error_budgets.PSObject.Properties) {
        $serviceName = $entry.Name
        if ($Service -ne "all" -and $Service -ne $serviceName) { continue }

        $budget = $entry.Value

        $consumptionPath = ".runtime/sre/$serviceName-consumption.json"
        $consumption = @{
            Service = $serviceName
            consumed_seconds = 0
            consumed_runs = 0
        }

        if (Test-Path $consumptionPath) {
            $consumption = Get-Content $consumptionPath -Raw | ConvertFrom-Json
        }

        $state = Get-ErrorBudgetState -Budget @{budget_seconds=$budget.budget_seconds; budget_runs=$budget.budget_runs; slo=$budget.slo; period_days=$budget.period_days} -CurrentConsumption $consumption

        $results += $state

        switch ($state.State) {
            "EXHAUSTED" {
                Write-Error "[SRE] Error budget EXHAUSTED for '$serviceName' (ratio: $($state.Ratio))"
                $exitCode = 1
            }
            "CRITICAL" {
                Write-Warning "[SRE] Error budget CRITICAL for '$serviceName' (ratio: $($state.Ratio))"
            }
            "WARNING" {
                Write-Warning "[SRE] Error budget WARNING for '$serviceName' (ratio: $($state.Ratio))"
            }
            "HEALTHY" {
                Write-Host "[SRE] Error budget HEALTHY for '$serviceName' (ratio: $($state.Ratio))" -ForegroundColor Green
            }
        }
    }

    if ($Json) {
        return $results | ConvertTo-Json -Compress
    }

    exit $exitCode
}
catch {
    Write-Error "enforce-error-budget.ps1 failed: $_"
    exit 1
}
