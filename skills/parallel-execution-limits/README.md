# Parallel Execution Limits Skill

Advanced parallel execution management with explicit dependency graphs, custom parallelism rules,
resource pooling with GPU/CPU awareness, and token budget circuit breaker protection.

## Quick Start

```powershell
# Import the skill
. .\skills\parallel-execution-limits\parallel-executor.ps1

# Initialize executor
$executor = Initialize-ParallelExecutor -Config @{
    Strategy = "Balanced"
    TokenBudget = 100000
}

# Add tasks with dependencies
Add-GraphTask -Graph $executor.DependencyGraph `
    -TaskId "task-1" -TaskName "Validation" -Type "Validation" `
    -ResourceRequirements @{ CPU = 20; Memory = 512; GPU = 0 }

Add-GraphTask -Graph $executor.DependencyGraph `
    -TaskId "task-2" -TaskName "Processing" -Type "Processing" `
    -DependsOn @("task-1") `
    -ResourceRequirements @{ CPU = 50; Memory = 2048; GPU = 1 }

# Plan and execute
$plan = Plan-ParallelExecution -Executor $executor
$results = Invoke-ParallelExecution -Executor $executor

# Monitor
$status = Get-ExecutionStatus -Executor $executor
Export-ExecutionReport -Executor $executor -Path "report.json"
```

## Features

### 1. Explicit Dependency Graphs

- DAG-based workflow graphs with circular dependency detection
- Dependency level calculation and critical path analysis
- Parallelization opportunity detection

### 2. Custom Parallelism Rules

- Three strategies: Conservative, Balanced, Aggressive
- Custom rule definition with conditions and priorities
- Dynamic resource multiplier adjustment

### 3. Resource Pooling (GPU/CPU Awareness)

- Automatic system resource detection
- GPU device management with VRAM tracking
- Three allocation strategies: FirstFit, BestFit, BalancedLoad
- Real-time utilization monitoring

### 4. Circuit Breaker for Token Budget

- Token budget tracking with soft/hard limits
- Three states: CLOSED, OPEN, HALF_OPEN
- Graceful degradation based on token usage
- Comprehensive analytics and reporting

## Core Functions

### Dependency Graph

- `Initialize-DependencyGraph` - Create graph
- `Add-GraphTask` - Add task with dependencies
- `Validate-DependencyGraph` - Validate structure
- `Resolve-TaskDependencies` - Resolve execution order
- `Get-CriticalPath` - Identify bottlenecks

### Parallelism Rules

- `Initialize-ParallelismRules` - Create rules
- `Add-ParallelismRule` - Add custom rule
- `Apply-ParallelismRules` - Apply to graph
- `Generate-ExecutionPlan` - Create execution plan

### Resource Pooling

- `Initialize-ResourcePool` - Create pool
- `Allocate-Resources` - Allocate for task
- `Release-Resources` - Free resources
- `Get-ResourceUtilization` - Monitor usage
- `Optimize-ResourceAllocation` - Get recommendations

### Circuit Breaker

- `Initialize-CircuitBreaker` - Create breaker
- `Test-CircuitBreaker` - Check if execution allowed
- `Track-TokenUsage` - Record token usage
- `Get-TokenBudgetStatus` - Get budget status
- `Get-DegradationStrategy` - Get execution strategy

### Executor

- `Initialize-ParallelExecutor` - Initialize all components
- `Plan-ParallelExecution` - Create execution plan
- `Invoke-ParallelExecution` - Execute tasks
- `Get-ExecutionStatus` - Get current status
- `Export-ExecutionReport` - Generate report

## Configuration

```json
{
  "parallelExecution": {
    "strategy": "Balanced",
    "maxParallelTasks": 8,
    "resourceThresholds": {
      "cpu": 80,
      "memory": 85,
      "gpu": 90
    },
    "tokenBudget": {
      "total": 100000,
      "softThreshold": 0.85,
      "hardLimit": 0.95
    }
  }
}
```

## Files

- `SKILL.md` - Detailed documentation
- `dependency-graph.ps1` - Graph management
- `parallelism-rules.ps1` - Parallelism rules
- `resource-pooling.ps1` - Resource management
- `circuit-breaker.ps1` - Token budget protection
- `parallel-executor.ps1` - Main orchestrator

## License

MIT
