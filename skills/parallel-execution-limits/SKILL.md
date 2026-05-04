---
name: parallel-execution-limits
description: Advanced parallel execution management with dependency graphs, resource pooling, and token budget circuit breaker
---

# Skill: parallel-execution-limits

**versión**: 1.0.0
**Created**: 2026-04-23
**Status**: ACTIVE
**Priority**: CRITICAL

---

## Overview

The `parallel-execution-limits` skill provides enterprise-grade parallel execution management with explicit dependency graphs, custom parallelism rules, resource pooling with GPU/CPU awareness, and token budget circuit breaker protection.

### Key Capabilities
-  **Explicit Dependency Graphs**: DAG visualization and validation
-  **Custom Parallelism Rules**: Define execution patterns per task type
-  **Resource Pooling**: GPU/CPU awareness with dynamic allocation
-  **Circuit Breaker**: Token budget protection and graceful degradation
-  **Real-time Monitoring**: Execution metrics and resource utilization
-  **Adaptive Scheduling**: Dynamic task prioritization based on resources

---

## When to Use This Skill

### Activation Triggers
- User mentions "parallel execution", "ejecucin paralela", or "execution limits"
- Complex workflows with >10 tasks requiring optimization
- GPU/CPU resource constraints need management
- Token budget protection required
- Custom parallelism strategies needed

### Use Cases
1. **Multi-Agent Orchestration**: "Ejecutar 5 agentes en paralelo con lmites de recursos"
2. **Token Budget Protection**: "Proteger presupuesto de tokens con circuit breaker"
3. **Resource-Aware Scheduling**: "Asignar tareas segn disponibilidad de GPU/CPU"
4. **Dependency Optimization**: "Optimizar ejecucin paralela respetando dependencias"

---

## Core Components

### 1. Explicit Dependency Graph

#### Graph Definition
```powershell
# Define tasks with explicit dependencies
$dependencyGraph = @{
    Tasks = @(
        @{
            Id = "task-1"
            Name = "DataValidation"
            Type = "Validation"
            DependsOn = @()
            ResourceRequirements = @{
                CPU = 20
                Memory = 512
                GPU = 0
            }
        }
        @{
            Id = "task-2"
            Name = "DataProcessing"
            Type = "Processing"
            DependsOn = @("task-1")
            ResourceRequirements = @{
                CPU = 50
                Memory = 2048
                GPU = 1
            }
        }
        @{
            Id = "task-3"
            Name = "ModelInference"
            Type = "AI"
            DependsOn = @("task-2")
            ResourceRequirements = @{
                CPU = 30
                Memory = 4096
                GPU = 2
            }
        }
        @{
            Id = "task-4"
            Name = "ResultsAggregation"
            Type = "Aggregation"
            DependsOn = @("task-2", "task-3")
            ResourceRequirements = @{
                CPU = 20
                Memory = 1024
                GPU = 0
            }
        }
    )
    Constraints = @{
        MaxParallelTasks = 4
        MaxCPUUsage = 80
        MaxMemoryUsage = 8192
        MaxGPUUsage = 4
    }
}
```

#### Graph Validation
```powershell
function Validate-DependencyGraph {
    param([hashtable]$Graph)
    
    $issues = @()
    
    # Check for circular dependencies
    if (Test-CircularDependencies -Graph $Graph) {
        $issues += "Circular dependency detected"
    }
    
    # Check for missing dependencies
    $taskIds = $Graph.Tasks | Select-Object -ExpandProperty Id
    foreach ($task in $Graph.Tasks) {
        foreach ($dep in $task.DependsOn) {
            if ($dep -notin $taskIds) {
                $issues += "Task '$($task.Id)' depends on non-existent task '$dep'"
            }
        }
    }
    
    return @{
        IsValid = $issues.Count -eq 0
        Issues = $issues
    }
}
```

#### Graph Visualization
```powershell
function Export-DependencyGraphVisualization {
    param([hashtable]$Graph)
    
    $visualization = @{
        Nodes = @()
        Edges = @()
    }
    
    # Create nodes
    foreach ($task in $Graph.Tasks) {
        $visualization.Nodes += @{
            Id = $task.Id
            Label = $task.Name
            Type = $task.Type
            Resources = $task.ResourceRequirements
        }
    }
    
    # Create edges
    foreach ($task in $Graph.Tasks) {
        foreach ($dep in $task.DependsOn) {
            $visualization.Edges += @{
                From = $dep
                To = $task.Id
            }
        }
    }
    
    return $visualization
}
```

---

### 2. Custom Parallelism Rules

#### Rule Definition
```powershell
# Define custom parallelism rules
$parallelismRules = @{
    Rules = @(
        @{
            Name = "AITasksRule"
            Condition = { $task.Type -eq "AI" }
            MaxParallel = 2
            Priority = 10
            ResourceMultiplier = 1.5
        }
        @{
            Name = "ValidationTasksRule"
            Condition = { $task.Type -eq "Validation" }
            MaxParallel = 4
            Priority = 5
            ResourceMultiplier = 1.0
        }
        @{
            Name = "ProcessingTasksRule"
            Condition = { $task.Type -eq "Processing" }
            MaxParallel = 3
            Priority = 8
            ResourceMultiplier = 1.2
        }
    )
    DefaultRule = @{
        MaxParallel = 2
        Priority = 1
        ResourceMultiplier = 1.0
    }
}
```

#### Rule Application
```powershell
function Apply-ParallelismRules {
    param(
        [hashtable]$Graph,
        [hashtable]$Rules
    )
    
    $executionPlan = @{
        Phases = @()
        TaskAssignments = @{}
    }
    
    foreach ($task in $Graph.Tasks) {
        $applicableRule = $Rules.Rules | Where-Object { & $_.Condition $task } | Select-Object -First 1
        
        if (-not $applicableRule) {
            $applicableRule = $Rules.DefaultRule
        }
        
        $executionPlan.TaskAssignments[$task.Id] = @{
            Rule = $applicableRule.Name
            MaxParallel = $applicableRule.MaxParallel
            Priority = $applicableRule.Priority
            ResourceMultiplier = $applicableRule.ResourceMultiplier
        }
    }
    
    return $executionPlan
}
```

---

### 3. Resource Pooling (GPU/CPU Awareness)

#### Resource Pool Management
```powershell
# Initialize resource pool
$resourcePool = @{
    CPU = @{
        Total = 100
        Available = 100
        Allocated = @{}
        Threshold = 80
    }
    Memory = @{
        Total = 16384  # MB
        Available = 16384
        Allocated = @{}
        Threshold = 85
    }
    GPU = @{
        Total = 4
        Available = 4
        Allocated = @{}
        Threshold = 90
        Devices = @(
            @{ Id = 0; VRAM = 24576; Available = 24576 }
            @{ Id = 1; VRAM = 24576; Available = 24576 }
            @{ Id = 2; VRAM = 24576; Available = 24576 }
            @{ Id = 3; VRAM = 24576; Available = 24576 }
        )
    }
}
```

#### Resource Allocation
```powershell
function Allocate-Resources {
    param(
        [hashtable]$ResourcePool,
        [hashtable]$Task,
        [string]$TaskId
    )
    
    $requirements = $Task.ResourceRequirements
    
    # Check CPU availability
    if ($ResourcePool.CPU.Available -lt $requirements.CPU) {
        return @{
            Success = $false
            Reason = "Insufficient CPU resources"
            Required = $requirements.CPU
            Available = $ResourcePool.CPU.Available
        }
    }
    
    # Check Memory availability
    if ($ResourcePool.Memory.Available -lt $requirements.Memory) {
        return @{
            Success = $false
            Reason = "Insufficient Memory resources"
            Required = $requirements.Memory
            Available = $ResourcePool.Memory.Available
        }
    }
    
    # Check GPU availability
    if ($requirements.GPU -gt 0) {
        $availableGPUs = @($ResourcePool.GPU.Devices | Where-Object { $_.Available -ge ($requirements.GPU * 1024) })
        
        if ($availableGPUs.Count -lt 1) {
            return @{
                Success = $false
                Reason = "Insufficient GPU resources"
                Required = $requirements.GPU
                Available = $ResourcePool.GPU.Available
            }
        }
    }
    
    # Allocate resources
    $ResourcePool.CPU.Available -= $requirements.CPU
    $ResourcePool.Memory.Available -= $requirements.Memory
    $ResourcePool.GPU.Available -= $requirements.GPU
    
    $ResourcePool.CPU.Allocated[$TaskId] = $requirements.CPU
    $ResourcePool.Memory.Allocated[$TaskId] = $requirements.Memory
    $ResourcePool.GPU.Allocated[$TaskId] = $requirements.GPU
    
    return @{
        Success = $true
        Allocation = @{
            CPU = $requirements.CPU
            Memory = $requirements.Memory
            GPU = $requirements.GPU
        }
    }
}
```

#### Resource Release
```powershell
function Release-Resources {
    param(
        [hashtable]$ResourcePool,
        [string]$TaskId
    )
    
    if ($ResourcePool.CPU.Allocated.ContainsKey($TaskId)) {
        $ResourcePool.CPU.Available += $ResourcePool.CPU.Allocated[$TaskId]
        $ResourcePool.CPU.Allocated.Remove($TaskId)
    }
    
    if ($ResourcePool.Memory.Allocated.ContainsKey($TaskId)) {
        $ResourcePool.Memory.Available += $ResourcePool.Memory.Allocated[$TaskId]
        $ResourcePool.Memory.Allocated.Remove($TaskId)
    }
    
    if ($ResourcePool.GPU.Allocated.ContainsKey($TaskId)) {
        $ResourcePool.GPU.Available += $ResourcePool.GPU.Allocated[$TaskId]
        $ResourcePool.GPU.Allocated.Remove($TaskId)
    }
    
    return @{ Success = $true }
}
```

---

### 4. Circuit Breaker for Token Budget

#### Circuit Breaker Configuration
```powershell
$circuitBreakerConfig = @{
    TokenBudget = @{
        Total = 100000
        Used = 0
        Threshold = 0.85  # 85% threshold
        HardLimit = 0.95  # 95% hard limit
    }
    State = "CLOSED"  # CLOSED, OPEN, HALF_OPEN
    FailureThreshold = 3
    SuccessThreshold = 2
    Timeout = 60  # seconds
    LastStateChange = Get-Date
}
```

#### Circuit Breaker Logic
```powershell
function Test-CircuitBreaker {
    param(
        [hashtable]$CircuitBreaker,
        [int]$TokensRequired
    )
    
    $tokenUsagePercent = $CircuitBreaker.TokenBudget.Used / $CircuitBreaker.TokenBudget.Total
    
    # Check hard limit
    if ($tokenUsagePercent -ge $CircuitBreaker.TokenBudget.HardLimit) {
        return @{
            CanExecute = $false
            State = "OPEN"
            Reason = "Hard token limit reached"
            UsagePercent = $tokenUsagePercent
        }
    }
    
    # Check soft threshold
    if ($tokenUsagePercent -ge $CircuitBreaker.TokenBudget.Threshold) {
        if ($CircuitBreaker.State -eq "CLOSED") {
            $CircuitBreaker.State = "HALF_OPEN"
            $CircuitBreaker.LastStateChange = Get-Date
        }
    }
    
    # Check if execution would exceed budget
    if (($CircuitBreaker.TokenBudget.Used + $TokensRequired) -gt $CircuitBreaker.TokenBudget.Total) {
        return @{
            CanExecute = $false
            State = "OPEN"
            Reason = "Execution would exceed token budget"
            Required = $TokensRequired
            Available = $CircuitBreaker.TokenBudget.Total - $CircuitBreaker.TokenBudget.Used
        }
    }
    
    return @{
        CanExecute = $true
        State = $CircuitBreaker.State
        UsagePercent = $tokenUsagePercent
    }
}
```

#### Token Tracking
```powershell
function Track-TokenUsage {
    param(
        [hashtable]$CircuitBreaker,
        [string]$TaskId,
        [int]$TokensUsed,
        [string]$Status = "Success"
    )
    
    $CircuitBreaker.TokenBudget.Used += $TokensUsed
    
    $usagePercent = $CircuitBreaker.TokenBudget.Used / $CircuitBreaker.TokenBudget.Total
    
    return @{
        TaskId = $TaskId
        TokensUsed = $TokensUsed
        TotalUsed = $CircuitBreaker.TokenBudget.Used
        UsagePercent = $usagePercent
        RemainingBudget = $CircuitBreaker.TokenBudget.Total - $CircuitBreaker.TokenBudget.Used
        Status = $Status
        Timestamp = Get-Date
    }
}
```

---

## Practical Examples

### Example 1: Complete Parallel Execution with All Features
```powershell
# Initialize all components
$graph = Initialize-DependencyGraph
$rules = Initialize-ParallelismRules
$resourcePool = Initialize-ResourcePool
$circuitBreaker = Initialize-CircuitBreaker

# Validate and execute
$validation = Validate-DependencyGraph -Graph $graph
if ($validation.IsValid) {
    $executionPlan = Apply-ParallelismRules -Graph $graph -Rules $rules
    $results = Invoke-ParallelExecution -Graph $graph -Plan $executionPlan -ResourcePool $resourcePool -CircuitBreaker $circuitBreaker
}
```

### Example 2: Resource-Constrained Execution
```powershell
# Execute with strict resource limits
$execution = @{
    Graph = $dependencyGraph
    ResourceLimits = @{
        MaxCPU = 60
        MaxMemory = 4096
        MaxGPU = 2
    }
    TokenBudget = 50000
    Strategy = "Conservative"  # Conservative, Balanced, Aggressive
}

Invoke-ConstrainedExecution -Execution $execution
```

---

## Integration with Foundation Stack

### Dependencies
- `workflow-orchestrator` - Base workflow execution
- `project-orchestrator-skill` - Task coordination
- `monitoring-aggregator` - Metrics collection
- `session-lifecycle` - Session tracking

### Integration Points
1. **Workflow Orchestrator**: Extends with advanced parallelism
2. **Project Orchestrator**: Provides task context and priorities
3. **Monitoring**: Real-time resource and token tracking
4. **Session Lifecycle**: Persists execution state

---

## Performance Expectations

| Operation | Target Time | Max Memory |
|-----------|------------|-----------|
| Graph Validation | <500ms | <50MB |
| Dependency Resolution | <1s | <100MB |
| Resource Allocation | <200ms | <30MB |
| Circuit Breaker Check | <50ms | <10MB |
| Parallel Execution | Variable | <2GB |
| Metrics Collection | <100ms | <50MB |

---

## Error Handling

**Issue**: "Circular dependency detected"
- **Solution**: Review task dependencies, use graph visualization to identify cycle

**Issue**: "Insufficient resources"
- **Solution**: Reduce parallelism, increase resource limits, or queue tasks

**Issue**: "Token budget exceeded"
- **Solution**: Circuit breaker activates, gracefully degrade execution or wait for budget reset

**Issue**: "Resource allocation failed"
- **Solution**: Release resources from lower-priority tasks, reschedule execution

---

## Configuration

### Environment Variables
```powershell
$env:PARALLEL_MAX_TASKS = "8"
$env:PARALLEL_CPU_THRESHOLD = "80"
$env:PARALLEL_MEMORY_THRESHOLD = "85"
$env:PARALLEL_GPU_THRESHOLD = "90"
$env:TOKEN_BUDGET_TOTAL = "100000"
$env:TOKEN_BUDGET_THRESHOLD = "0.85"
```

### Configuration File
```json
{
  "parallelExecution": {
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
    },
    "circuitBreaker": {
      "enabled": true,
      "failureThreshold": 3,
      "successThreshold": 2,
      "timeout": 60
    }
  }
}
```

---

## References

- [Workflow Orchestrator](../workflow-orchestrator/SKILL.md)
- [Project Orchestrator](../project-orchestrator-skill/SKILL.md)
- [Monitoring Aggregator](../monitoring-aggregator/SKILL.md)

