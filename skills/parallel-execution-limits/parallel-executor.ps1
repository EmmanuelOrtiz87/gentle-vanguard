<#
.SYNOPSIS
Parallel Executor - Main Orchestrator for Parallel Execution Limits

.DESCRIPTION
Main orchestrator that coordinates parallel execution with dependency graphs,
custom parallelism rules, resource pooling, and token budget circuit breaker.

.VERSION
1.0.0

.AUTHOR
Gentle-Vanguard Team

.LICENSE
MIT
#>

# Import supporting modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath\dependency-graph.ps1"
. "$scriptPath\parallelism-rules.ps1"
. "$scriptPath\resource-pooling.ps1"
. "$scriptPath\circuit-breaker.ps1"

# ============================================================================
# Parallel Executor Initialization
# ============================================================================

function Initialize-ParallelExecutor {
    <#
    .SYNOPSIS
    Initialize parallel executor with all components
    #>
    param(
        [hashtable]$Config = $null
    )
    
    if (-not $Config) {
        $Config = @{
            Strategy = "Balanced"
            TokenBudget = 100000
            MaxParallelTasks = 8
            CPUCores = $null
            MemoryMB = $null
            GPUCount = $null
        }
    }
    
    $executor = @{
        DependencyGraph = Initialize-DependencyGraph -Name "ParallelExecutionGraph"
        ParallelismRules = Initialize-ParallelismRules -Strategy $Config.Strategy
        ResourcePool = Initialize-ResourcePool -CPUCores $Config.CPUCores -MemoryMB $Config.MemoryMB -GPUCount $Config.GPUCount
        CircuitBreaker = Initialize-CircuitBreaker -TokenBudgetTotal $Config.TokenBudget
        ExecutionPlan = $null
        ExecutionState = @{
            Status = "Initialized"
            StartTime = $null
            EndTime = $null
            TasksCompleted = 0
            TasksFailed = 0
            TasksQueued = @()
            TasksRunning = @()
            TasksCompleted_List = @()
        }
        Config = $Config
        CreatedAt = Get-Date
    }
    
    return $executor
}

# ============================================================================
# Execution Planning
# ============================================================================

function Plan-ParallelExecution {
    <#
    .SYNOPSIS
    Create execution plan from dependency graph and rules
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Executor
    )
    
    # Validate dependency graph
    $validation = Validate-DependencyGraph -Graph $Executor.DependencyGraph
    if (-not $validation.IsValid) {
        return @{
            Success = $false
            Error = "Dependency graph validation failed"
            Issues = $validation.Issues
        }
    }
    
    # Apply parallelism rules
    $rulePlan = Apply-ParallelismRules -Graph $Executor.DependencyGraph -Rules $Executor.ParallelismRules
    
    # Generate execution plan
    $executionPlan = Generate-ExecutionPlan -Graph $Executor.DependencyGraph -ExecutionPlan $rulePlan
    
    if (-not $executionPlan.Success) {
        return @{
            Success = $false
            Error = $executionPlan.Error
        }
    }
    
    $Executor.ExecutionPlan = $executionPlan
    
    return @{
        Success = $true
        TotalPhases = $executionPlan.TotalPhases
        TotalTasks = $executionPlan.TotalTasks
        EstimatedSpeedup = $executionPlan.EstimatedSpeedup
        Phases = $executionPlan.Phases
    }
}

# ============================================================================
# Execution
# ============================================================================

function Invoke-ParallelExecution {
    <#
    .SYNOPSIS
    Execute tasks in parallel respecting all constraints
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Executor,
        
        [scriptblock]$TaskExecutor = $null
    )
    
    # Create execution plan if not exists
    if (-not $Executor.ExecutionPlan) {
        $planResult = Plan-ParallelExecution -Executor $Executor
        if (-not $planResult.Success) {
            return $planResult
        }
    }
    
    $Executor.ExecutionState.Status = "Running"
    $Executor.ExecutionState.StartTime = Get-Date
    
    $results = @{
        Success = $true
        ExecutionResults = @()
        Failures = @()
        Statistics = @{}
    }
    
    # Execute phases
    foreach ($phase in $Executor.ExecutionPlan.Phases) {
        Write-Host "Executing Phase $($phase.PhaseNumber)/$($Executor.ExecutionPlan.TotalPhases): $($phase.TaskCount) tasks"
        
        $phaseResults = @()
        
        # Execute tasks in phase (can be parallel)
        foreach ($taskId in $phase.Tasks) {
            $task = $Executor.DependencyGraph.Tasks | Where-Object { $_.Id -eq $taskId }
            
            # Check circuit breaker
            $cbTest = Test-CircuitBreaker -CircuitBreaker $Executor.CircuitBreaker -TokensRequired 1000
            if (-not $cbTest.CanExecute) {
                $Executor.ExecutionState.TasksFailed++
                $results.Failures += @{
                    TaskId = $taskId
                    Reason = $cbTest.Reason
                    Timestamp = Get-Date
                }
                continue
            }
            
            # Check resource availability
            $resourceCheck = Test-ResourceAvailability -ResourcePool $Executor.ResourcePool -Requirements $task.ResourceRequirements
            if (-not $resourceCheck.CanAllocate) {
                $Executor.ExecutionState.TasksQueued += $taskId
                continue
            }
            
            # Allocate resources
            $allocation = Allocate-Resources -ResourcePool $Executor.ResourcePool -TaskId $taskId -Requirements $task.ResourceRequirements
            if (-not $allocation.Success) {
                $Executor.ExecutionState.TasksFailed++
                $results.Failures += @{
                    TaskId = $taskId
                    Reason = $allocation.Reason
                    Timestamp = Get-Date
                }
                continue
            }
            
            # Execute task
            $taskResult = @{
                TaskId = $taskId
                TaskName = $task.Name
                Status = "Success"
                StartTime = Get-Date
                TokensUsed = 1000
            }
            
            if ($TaskExecutor) {
                try {
                    $customResult = & $TaskExecutor -TaskId $taskId -Task $task
                    $taskResult.CustomResult = $customResult
                    $taskResult.TokensUsed = $customResult.TokensUsed -or 1000
                }
                catch {
                    $taskResult.Status = "Failed"
                    $taskResult.Error = $_.Exception.Message
                    $Executor.ExecutionState.TasksFailed++
                }
            }
            
            $taskResult.EndTime = Get-Date
            
            # Track token usage
            Track-TokenUsage -CircuitBreaker $Executor.CircuitBreaker -TaskId $taskId -TokensUsed $taskResult.TokensUsed -TaskName $task.Name
            
            # Release resources
            Release-Resources -ResourcePool $Executor.ResourcePool -TaskId $taskId
            
            if ($taskResult.Status -eq "Success") {
                $Executor.ExecutionState.TasksCompleted++
                Record-CircuitBreakerSuccess -CircuitBreaker $Executor.CircuitBreaker
            }
            else {
                Record-CircuitBreakerFailure -CircuitBreaker $Executor.CircuitBreaker -FailureReason $taskResult.Error
            }
            
            $phaseResults += $taskResult
            $results.ExecutionResults += $taskResult
        }
        
        Write-Host "Phase $($phase.PhaseNumber) completed: $($phaseResults.Count) tasks executed"
    }
    
    $Executor.ExecutionState.Status = "Completed"
    $Executor.ExecutionState.EndTime = Get-Date
    
    # Collect statistics
    $results.Statistics = @{
        TotalTasks = $Executor.DependencyGraph.Tasks.Count
        CompletedTasks = $Executor.ExecutionState.TasksCompleted
        FailedTasks = $Executor.ExecutionState.TasksFailed
        QueuedTasks = $Executor.ExecutionState.TasksQueued.Count
        ExecutionTime = $Executor.ExecutionState.EndTime - $Executor.ExecutionState.StartTime
        ResourceUtilization = Get-ResourceUtilization -ResourcePool $Executor.ResourcePool
        TokenBudgetStatus = Get-TokenBudgetStatus -CircuitBreaker $Executor.CircuitBreaker
    }
    
    return $results
}

# ============================================================================
# Status and Monitoring
# ============================================================================

function Get-ExecutionStatus {
    <#
    .SYNOPSIS
    Get current execution status
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Executor
    )
    
    return @{
        Status = $Executor.ExecutionState.Status
        TasksCompleted = $Executor.ExecutionState.TasksCompleted
        TasksFailed = $Executor.ExecutionState.TasksFailed
        TasksQueued = $Executor.ExecutionState.TasksQueued.Count
        ResourceUtilization = Get-ResourceUtilization -ResourcePool $Executor.ResourcePool
        TokenBudgetStatus = Get-TokenBudgetStatus -CircuitBreaker $Executor.CircuitBreaker
        CircuitBreakerState = $Executor.CircuitBreaker.State
        Timestamp = Get-Date
    }
}

function Get-ExecutionMetrics {
    <#
    .SYNOPSIS
    Get detailed execution metrics
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Executor
    )
    
    $metrics = @{
        ExecutionTime = $null
        ThroughputTasksPerSecond = 0
        AverageTaskDuration = 0
        ResourceEfficiency = 0
        TokenEfficiency = 0
        CircuitBreakerStats = Get-CircuitBreakerStatistics -CircuitBreaker $Executor.CircuitBreaker
    }
    
    if ($Executor.ExecutionState.StartTime -and $Executor.ExecutionState.EndTime) {
        $metrics.ExecutionTime = $Executor.ExecutionState.EndTime - $Executor.ExecutionState.StartTime
        $metrics.ThroughputTasksPerSecond = [math]::Round($Executor.ExecutionState.TasksCompleted / $metrics.ExecutionTime.TotalSeconds, 2)
    }
    
    return $metrics
}

# ============================================================================
# Reporting
# ============================================================================

function Export-ExecutionReport {
    <#
    .SYNOPSIS
    Export comprehensive execution report
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Executor,
        
        [string]$Path = $null
    )
    
    $report = @{
        GeneratedAt = Get-Date
        ExecutionStatus = Get-ExecutionStatus -Executor $Executor
        ExecutionMetrics = Get-ExecutionMetrics -Executor $Executor
        DependencyGraph = @{
            TaskCount = $Executor.DependencyGraph.Tasks.Count
            Visualization = Export-DependencyGraphVisualization -Graph $Executor.DependencyGraph -Format "JSON"
        }
        ParallelismRules = @{
            Strategy = $Executor.ParallelismRules.Strategy
            RuleCount = $Executor.ParallelismRules.Rules.Count
            Statistics = Get-RuleStatistics -Rules $Executor.ParallelismRules
        }
        ResourcePool = @{
            Utilization = Get-ResourceUtilization -ResourcePool $Executor.ResourcePool
            Optimization = Optimize-ResourceAllocation -ResourcePool $Executor.ResourcePool
        }
        CircuitBreaker = @{
            Status = Get-TokenBudgetStatus -CircuitBreaker $Executor.CircuitBreaker
            Statistics = Get-CircuitBreakerStatistics -CircuitBreaker $Executor.CircuitBreaker
            DegradationStrategy = Get-DegradationStrategy -CircuitBreaker $Executor.CircuitBreaker
        }
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
    'Initialize-ParallelExecutor'
    'Plan-ParallelExecution'
    'Invoke-ParallelExecution'
    'Get-ExecutionStatus'
    'Get-ExecutionMetrics'
    'Export-ExecutionReport'
)
