<#
.SYNOPSIS
Circuit Breaker for Token Budget Management

.DESCRIPTION
Provides circuit breaker pattern implementation for token budget protection,
graceful degradation, and execution flow control based on token consumption.

.VERSION
1.0.0

.AUTHOR
Foundation Team

.LICENSE
MIT
#>

# ============================================================================
# Circuit Breaker Initialization
# ============================================================================

function Initialize-CircuitBreaker {
    <#
    .SYNOPSIS
    Initialize circuit breaker with token budget configuration
    #>
    param(
        [int]$TokenBudgetTotal = 100000,
        [double]$SoftThreshold = 0.85,
        [double]$HardLimit = 0.95,
        [int]$FailureThreshold = 3,
        [int]$SuccessThreshold = 2,
        [int]$TimeoutSeconds = 60
    )
    
    return @{
        TokenBudget = @{
            Total = $TokenBudgetTotal
            Used = 0
            Remaining = $TokenBudgetTotal
            SoftThreshold = $SoftThreshold
            HardLimit = $HardLimit
        }
        State = "CLOSED"  # CLOSED, OPEN, HALF_OPEN
        FailureCount = 0
        SuccessCount = 0
        FailureThreshold = $FailureThreshold
        SuccessThreshold = $SuccessThreshold
        Timeout = $TimeoutSeconds
        LastStateChange = Get-Date
        StateHistory = @()
        TokenHistory = @()
        CreatedAt = Get-Date
    }
}

# ============================================================================
# Circuit Breaker State Management
# ============================================================================

function Test-CircuitBreaker {
    <#
    .SYNOPSIS
    Test if circuit breaker allows execution
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$CircuitBreaker,
        
        [int]$TokensRequired = 0
    )
    
    $tokenUsagePercent = $CircuitBreaker.TokenBudget.Used / $CircuitBreaker.TokenBudget.Total
    
    # Check hard limit
    if ($tokenUsagePercent -ge $CircuitBreaker.TokenBudget.HardLimit) {
        Update-CircuitBreakerState -CircuitBreaker $CircuitBreaker -NewState "OPEN"
        
        return @{
            CanExecute = $false
            State = "OPEN"
            Reason = "Hard token limit reached"
            UsagePercent = $tokenUsagePercent
            RemainingBudget = $CircuitBreaker.TokenBudget.Remaining
        }
    }
    
    # Check soft threshold
    if ($tokenUsagePercent -ge $CircuitBreaker.TokenBudget.SoftThreshold) {
        if ($CircuitBreaker.State -eq "CLOSED") {
            Update-CircuitBreakerState -CircuitBreaker $CircuitBreaker -NewState "HALF_OPEN"
        }
    }
    
    # Check if execution would exceed budget
    if (($CircuitBreaker.TokenBudget.Used + $TokensRequired) -gt $CircuitBreaker.TokenBudget.Total) {
        Update-CircuitBreakerState -CircuitBreaker $CircuitBreaker -NewState "OPEN"
        
        return @{
            CanExecute = $false
            State = "OPEN"
            Reason = "Execution would exceed token budget"
            Required = $TokensRequired
            Available = $CircuitBreaker.TokenBudget.Remaining
        }
    }
    
    # Check if state is OPEN
    if ($CircuitBreaker.State -eq "OPEN") {
        $timeSinceChange = (Get-Date) - $CircuitBreaker.LastStateChange
        
        if ($timeSinceChange.TotalSeconds -ge $CircuitBreaker.Timeout) {
            Update-CircuitBreakerState -CircuitBreaker $CircuitBreaker -NewState "HALF_OPEN"
        }
        else {
            return @{
                CanExecute = $false
                State = "OPEN"
                Reason = "Circuit breaker is open"
                TimeUntilReset = $CircuitBreaker.Timeout - [int]$timeSinceChange.TotalSeconds
            }
        }
    }
    
    return @{
        CanExecute = $true
        State = $CircuitBreaker.State
        UsagePercent = $tokenUsagePercent
        RemainingBudget = $CircuitBreaker.TokenBudget.Remaining
    }
}

function Update-CircuitBreakerState {
    <#
    .SYNOPSIS
    Update circuit breaker state with history tracking
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$CircuitBreaker,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("CLOSED", "OPEN", "HALF_OPEN")]
        [string]$NewState
    )
    
    if ($CircuitBreaker.State -ne $NewState) {
        $stateChange = @{
            FromState = $CircuitBreaker.State
            ToState = $NewState
            Timestamp = Get-Date
            TokenUsage = $CircuitBreaker.TokenBudget.Used
            UsagePercent = [math]::Round(($CircuitBreaker.TokenBudget.Used / $CircuitBreaker.TokenBudget.Total * 100), 2)
        }
        
        $CircuitBreaker.StateHistory += $stateChange
        $CircuitBreaker.State = $NewState
        $CircuitBreaker.LastStateChange = Get-Date
        
        # Reset counters on state change
        if ($NewState -eq "CLOSED") {
            $CircuitBreaker.FailureCount = 0
            $CircuitBreaker.SuccessCount = 0
        }
    }
}

function Record-CircuitBreakerFailure {
    <#
    .SYNOPSIS
    Record a failure and potentially open the circuit
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$CircuitBreaker,
        
        [string]$FailureReason = "Unknown"
    )
    
    $CircuitBreaker.FailureCount++
    
    if ($CircuitBreaker.FailureCount -ge $CircuitBreaker.FailureThreshold) {
        Update-CircuitBreakerState -CircuitBreaker $CircuitBreaker -NewState "OPEN"
        
        return @{
            Success = $true
            Action = "Circuit breaker opened"
            FailureCount = $CircuitBreaker.FailureCount
            Reason = $FailureReason
        }
    }
    
    return @{
        Success = $true
        Action = "Failure recorded"
        FailureCount = $CircuitBreaker.FailureCount
        Reason = $FailureReason
    }
}

function Record-CircuitBreakerSuccess {
    <#
    .SYNOPSIS
    Record a success and potentially close the circuit
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$CircuitBreaker
    )
    
    $CircuitBreaker.SuccessCount++
    
    if ($CircuitBreaker.State -eq "HALF_OPEN" -and $CircuitBreaker.SuccessCount -ge $CircuitBreaker.SuccessThreshold) {
        Update-CircuitBreakerState -CircuitBreaker $CircuitBreaker -NewState "CLOSED"
        
        return @{
            Success = $true
            Action = "Circuit breaker closed"
            SuccessCount = $CircuitBreaker.SuccessCount
        }
    }
    
    return @{
        Success = $true
        Action = "Success recorded"
        SuccessCount = $CircuitBreaker.SuccessCount
    }
}

# ============================================================================
# Token Tracking
# ============================================================================

function Track-TokenUsage {
    <#
    .SYNOPSIS
    Track token usage for a task
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$CircuitBreaker,
        
        [Parameter(Mandatory=$true)]
        [string]$TaskId,
        
        [Parameter(Mandatory=$true)]
        [int]$TokensUsed,
        
        [string]$Status = "Success",
        
        [string]$TaskName = ""
    )
    
    $CircuitBreaker.TokenBudget.Used += $TokensUsed
    $CircuitBreaker.TokenBudget.Remaining = $CircuitBreaker.TokenBudget.Total - $CircuitBreaker.TokenBudget.Used
    
    $usagePercent = [math]::Round(($CircuitBreaker.TokenBudget.Used / $CircuitBreaker.TokenBudget.Total * 100), 2)
    
    $tokenRecord = @{
        TaskId = $TaskId
        TaskName = $TaskName
        TokensUsed = $TokensUsed
        TotalUsed = $CircuitBreaker.TokenBudget.Used
        UsagePercent = $usagePercent
        RemainingBudget = $CircuitBreaker.TokenBudget.Remaining
        Status = $Status
        Timestamp = Get-Date
    }
    
    $CircuitBreaker.TokenHistory += $tokenRecord
    
    # Check if we've crossed thresholds
    if ($usagePercent -ge $CircuitBreaker.TokenBudget.HardLimit) {
        Update-CircuitBreakerState -CircuitBreaker $CircuitBreaker -NewState "OPEN"
    }
    elseif ($usagePercent -ge $CircuitBreaker.TokenBudget.SoftThreshold -and $CircuitBreaker.State -eq "CLOSED") {
        Update-CircuitBreakerState -CircuitBreaker $CircuitBreaker -NewState "HALF_OPEN"
    }
    
    return $tokenRecord
}

function Get-TokenBudgetStatus {
    <#
    .SYNOPSIS
    Get current token budget status
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$CircuitBreaker
    )
    
    $usagePercent = [math]::Round(($CircuitBreaker.TokenBudget.Used / $CircuitBreaker.TokenBudget.Total * 100), 2)
    
    # Calculate burn rate
    $burnRate = 0
    if ($CircuitBreaker.TokenHistory.Count -gt 1) {
        $recentTokens = $CircuitBreaker.TokenHistory[-10..-1] | Measure-Object -Property TokensUsed -Sum | Select-Object -ExpandProperty Sum
        $burnRate = [math]::Round($recentTokens / 10, 2)
    }
    
    # Estimate time to exhaustion
    $timeToExhaustion = "N/A"
    if ($burnRate -gt 0) {
        $remainingTokens = $CircuitBreaker.TokenBudget.Total - $CircuitBreaker.TokenBudget.Used
        $estimatedMinutes = [math]::Round($remainingTokens / $burnRate, 2)
        $timeToExhaustion = "$estimatedMinutes minutes"
    }
    
    return @{
        Total = $CircuitBreaker.TokenBudget.Total
        Used = $CircuitBreaker.TokenBudget.Used
        Remaining = $CircuitBreaker.TokenBudget.Remaining
        UsagePercent = $usagePercent
        State = $CircuitBreaker.State
        BurnRate = $burnRate
        TimeToExhaustion = $timeToExhaustion
        SoftThreshold = [math]::Round($CircuitBreaker.TokenBudget.Total * $CircuitBreaker.TokenBudget.SoftThreshold, 0)
        HardLimit = [math]::Round($CircuitBreaker.TokenBudget.Total * $CircuitBreaker.TokenBudget.HardLimit, 0)
        Timestamp = Get-Date
    }
}

# ============================================================================
# Graceful Degradation
# ============================================================================

function Get-DegradationStrategy {
    <#
    .SYNOPSIS
    Determine degradation strategy based on token usage
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$CircuitBreaker
    )
    
    $usagePercent = $CircuitBreaker.TokenBudget.Used / $CircuitBreaker.TokenBudget.Total
    
    $strategy = @{
        Level = "Normal"
        Actions = @()
        Recommendations = @()
    }
    
    if ($usagePercent -lt 0.5) {
        $strategy.Level = "Normal"
        $strategy.Actions = @("Execute all tasks normally")
    }
    elseif ($usagePercent -lt 0.75) {
        $strategy.Level = "Caution"
        $strategy.Actions = @(
            "Monitor token usage closely",
            "Reduce non-critical tasks",
            "Increase task batching"
        )
        $strategy.Recommendations = @(
            "Consider reducing parallelism",
            "Prioritize critical tasks"
        )
    }
    elseif ($usagePercent -lt 0.85) {
        $strategy.Level = "Warning"
        $strategy.Actions = @(
            "Execute only high-priority tasks",
            "Reduce parallelism significantly",
            "Batch similar tasks together"
        )
        $strategy.Recommendations = @(
            "Defer non-critical work",
            "Optimize task efficiency"
        )
    }
    elseif ($usagePercent -lt 0.95) {
        $strategy.Level = "Critical"
        $strategy.Actions = @(
            "Execute only critical tasks",
            "Minimize parallelism",
            "Use minimal token operations"
        )
        $strategy.Recommendations = @(
            "Stop non-essential operations",
            "Wait for budget reset"
        )
    }
    else {
        $strategy.Level = "Exhausted"
        $strategy.Actions = @(
            "Stop all non-critical execution",
            "Queue remaining tasks",
            "Wait for budget reset"
        )
        $strategy.Recommendations = @(
            "All execution halted",
            "Waiting for budget reset"
        )
    }
    
    return $strategy
}

# ============================================================================
# Budget Reset and Management
# ============================================================================

function Reset-TokenBudget {
    <#
    .SYNOPSIS
    Reset token budget (typically for new session/day)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$CircuitBreaker,
        
        [int]$NewBudget = $null
    )
    
    $oldBudget = $CircuitBreaker.TokenBudget.Total
    $oldUsage = $CircuitBreaker.TokenBudget.Used
    
    if ($NewBudget) {
        $CircuitBreaker.TokenBudget.Total = $NewBudget
    }
    
    $CircuitBreaker.TokenBudget.Used = 0
    $CircuitBreaker.TokenBudget.Remaining = $CircuitBreaker.TokenBudget.Total
    
    Update-CircuitBreakerState -CircuitBreaker $CircuitBreaker -NewState "CLOSED"
    
    return @{
        Success = $true
        PreviousBudget = $oldBudget
        PreviousUsage = $oldUsage
        NewBudget = $CircuitBreaker.TokenBudget.Total
        ResetTime = Get-Date
    }
}

function Adjust-TokenBudget {
    <#
    .SYNOPSIS
    Adjust token budget (increase or decrease)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$CircuitBreaker,
        
        [Parameter(Mandatory=$true)]
        [int]$AdjustmentAmount,
        
        [string]$Reason = "Manual adjustment"
    )
    
    $oldBudget = $CircuitBreaker.TokenBudget.Total
    $CircuitBreaker.TokenBudget.Total += $AdjustmentAmount
    $CircuitBreaker.TokenBudget.Remaining = $CircuitBreaker.TokenBudget.Total - $CircuitBreaker.TokenBudget.Used
    
    # If we were in OPEN state and now have budget, transition to HALF_OPEN
    if ($CircuitBreaker.State -eq "OPEN" -and $CircuitBreaker.TokenBudget.Remaining -gt 0) {
        Update-CircuitBreakerState -CircuitBreaker $CircuitBreaker -NewState "HALF_OPEN"
    }
    
    return @{
        Success = $true
        PreviousBudget = $oldBudget
        NewBudget = $CircuitBreaker.TokenBudget.Total
        Adjustment = $AdjustmentAmount
        Reason = $Reason
        Timestamp = Get-Date
    }
}

# ============================================================================
# Analytics and Reporting
# ============================================================================

function Get-CircuitBreakerStatistics {
    <#
    .SYNOPSIS
    Get statistics about circuit breaker usage
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$CircuitBreaker
    )
    
    $stats = @{
        TotalTokensUsed = $CircuitBreaker.TokenBudget.Used
        TotalTokensBudget = $CircuitBreaker.TokenBudget.Total
        UsagePercent = [math]::Round(($CircuitBreaker.TokenBudget.Used / $CircuitBreaker.TokenBudget.Total * 100), 2)
        CurrentState = $CircuitBreaker.State
        StateChanges = $CircuitBreaker.StateHistory.Count
        TasksTracked = $CircuitBreaker.TokenHistory.Count
        AverageTokensPerTask = 0
        MaxTokensPerTask = 0
        MinTokensPerTask = 0
    }
    
    if ($CircuitBreaker.TokenHistory.Count -gt 0) {
        $stats.AverageTokensPerTask = [math]::Round(($CircuitBreaker.TokenHistory | Measure-Object -Property TokensUsed -Average | Select-Object -ExpandProperty Average), 2)
        $stats.MaxTokensPerTask = $CircuitBreaker.TokenHistory | Measure-Object -Property TokensUsed -Maximum | Select-Object -ExpandProperty Maximum
        $stats.MinTokensPerTask = $CircuitBreaker.TokenHistory | Measure-Object -Property TokensUsed -Minimum | Select-Object -ExpandProperty Minimum
    }
    
    return $stats
}

function Export-CircuitBreakerReport {
    <#
    .SYNOPSIS
    Export circuit breaker report to JSON
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$CircuitBreaker,
        
        [string]$Path = $null
    )
    
    $report = @{
        GeneratedAt = Get-Date
        Status = Get-TokenBudgetStatus -CircuitBreaker $CircuitBreaker
        Statistics = Get-CircuitBreakerStatistics -CircuitBreaker $CircuitBreaker
        DegradationStrategy = Get-DegradationStrategy -CircuitBreaker $CircuitBreaker
        StateHistory = $CircuitBreaker.StateHistory
        RecentTokenHistory = $CircuitBreaker.TokenHistory[-50..-1]  # Last 50 records
    }
    
    $json = $report | ConvertTo-Json -Depth 10
    
    if ($Path) {
        $json | Out-File -FilePath $Path -Encoding UTF8
        return @{
            Success = $true
            Path = $Path
            Message = "Report exported successfully"
        }
    }
    
    return $json
}

# ============================================================================
# Export Functions
# ============================================================================

Export-ModuleMember -Function @(
    'Initialize-CircuitBreaker'
    'Test-CircuitBreaker'
    'Update-CircuitBreakerState'
    'Record-CircuitBreakerFailure'
    'Record-CircuitBreakerSuccess'
    'Track-TokenUsage'
    'Get-TokenBudgetStatus'
    'Get-DegradationStrategy'
    'Reset-TokenBudget'
    'Adjust-TokenBudget'
    'Get-CircuitBreakerStatistics'
    'Export-CircuitBreakerReport'
)