---
name: workflow-orchestrator
description: Workflow orchestration skill for managing development workflows and automation
---

# Skill: workflow-orchestrator

**Version**: 1.0.0
**Created**: 2026-04-20
**Status**: ACTIVE
**Priority**: CRITICAL

---

## Overview

The `workflow-orchestrator` skill provides advanced workflow automation with intelligent scheduling, dependency management, and error recovery. It enables complex multi-step automation with autonomous execution and recovery.

### Key Capabilities
- 🔄 DAG-based workflow graphs
- ⏱️ Intelligent scheduling with resource awareness
- 🔗 Advanced dependency management
- 🛡️ Error handling & automatic recovery
- 📊 Real-time execution monitoring

---

## When to Use This Skill

### Activation Triggers
- User mentions "workflow" or "flujo de trabajo"
- User needs to automate complex multi-step processes
- Workflow complexity increases (>5 dependent tasks)
- Autonomous execution needed
- Error recovery required

### Use Cases
1. **Complex Automation**: "Automatizar proceso de backup, sync y reporte"
2. **Scheduled Workflows**: "Ejecutar tareas en orden específico"
3. **Error Recovery**: "Reintentar automáticamente si falla"
4. **Monitoring**: "Monitorear ejecución del workflow"

---

## Core Components

### 1. Workflow Definition

#### DAG-Based Workflow Graphs
```powershell
# Define workflow as Directed Acyclic Graph
$workflow = @{
    Name = "BackupAndSync"
    Tasks = @(
        @{
            Name = "PreCheck"
            Type = "Validation"
            DependsOn = @()
            Action = "Test-SourceIntegrity"
        }
        @{
            Name = "Backup"
            Type = "Backup"
            DependsOn = @("PreCheck")
            Action = "Invoke-BackupOperation"
        }
        @{
            Name = "Compress"
            Type = "Compression"
            DependsOn = @("Backup")
            Action = "Compress-BackupData"
        }
        @{
            Name = "Sync"
            Type = "Sync"
            DependsOn = @("Compress")
            Action = "Invoke-WorkspaceSync"
        }
        @{
            Name = "Report"
            Type = "Reporting"
            DependsOn = @("Sync")
            Action = "Generate-HTMLReport"
        }
    )
}
```

#### Conditional Execution
```powershell
# Define conditional task execution
$conditionalTask = @{
    Name = "OptionalCleanup"
    Type = "Cleanup"
    DependsOn = @("Sync")
    Condition = "if (Get-DiskUsagePercent -gt 85)"
    Action = "Remove-OldBackups"
}
```

#### Parallel Execution
```powershell
# Tasks can execute in parallel if no dependencies
$parallelTasks = @(
    @{ Name = "MetricsCollection"; DependsOn = @() }
    @{ Name = "LogAnalysis"; DependsOn = @() }
    @{ Name = "SecurityScan"; DependsOn = @() }
)
# All three execute simultaneously
```

---

### 2. Intelligent Scheduling

#### Dynamic Scheduling
```powershell
function Schedule-WorkflowDynamically {
    param(
        [hashtable]$Workflow,
        [string]$Strategy = "OptimalTime"
    )
    
    switch ($Strategy) {
        "OptimalTime" {
            # Find best time based on system load
            $bestTime = Find-OptimalExecutionTime -Workflow $Workflow
            return $bestTime
        }
        "ASAP" {
            # Execute as soon as resources available
            return Get-Date
        }
        "Scheduled" {
            # Use predefined schedule
            return $Workflow.ScheduledTime
        }
    }
}
```

#### Resource-Aware Scheduling
```powershell
function Test-ResourcesForWorkflow {
    param([hashtable]$Workflow)
    
    $requiredCPU = $Workflow.Tasks | Measure-Object -Property RequiredCPU -Sum | Select-Object -ExpandProperty Sum
    $requiredMemory = $Workflow.Tasks | Measure-Object -Property RequiredMemory -Sum | Select-Object -ExpandProperty Sum
    
    $availableCPU = 100 - (Get-CPUUsage)
    $availableMemory = Get-AvailableMemory
    
    return @{
        CanExecute = ($availableCPU -ge $requiredCPU -and $availableMemory -ge $requiredMemory)
        CPUAvailable = $availableCPU
        MemoryAvailable = $availableMemory
    }
}
```

#### Priority-Based Execution
```powershell
function Execute-WorkflowByPriority {
    param([array]$Workflows)
    
    # Sort by priority
    $sorted = $Workflows | Sort-Object -Property Priority -Descending
    
    foreach ($workflow in $sorted) {
        if (Test-ResourcesForWorkflow -Workflow $workflow) {
            Invoke-Workflow -Workflow $workflow
        }
    }
}
```

---

### 3. Dependency Management

#### Task Dependencies
```powershell
function Resolve-TaskDependencies {
    param([hashtable]$Workflow)
    
    $executionOrder = @()
    $completed = @()
    
    while ($completed.Count -lt $Workflow.Tasks.Count) {
        foreach ($task in $Workflow.Tasks) {
            if ($task.Name -notin $completed) {
                $depsMet = $task.DependsOn | ForEach-Object { $_ -in $completed }
                
                if ($depsMet -or $task.DependsOn.Count -eq 0) {
                    $executionOrder += $task.Name
                    $completed += $task.Name
                }
            }
        }
    }
    
    return $executionOrder
}
```

#### Data Flow Management
```powershell
function Manage-DataFlow {
    param(
        [hashtable]$SourceTask,
        [hashtable]$TargetTask
    )
    
    # Pass output from source to target
    $data = @{
        TaskName = $SourceTask.Name
        Output = $SourceTask.Result
        Timestamp = Get-Date
    }
    
    $TargetTask.Input = $data
    
    return $TargetTask
}
```

#### State Tracking
```powershell
function Track-WorkflowState {
    param([hashtable]$Workflow)
    
    $state = @{
        WorkflowName = $Workflow.Name
        StartTime = Get-Date
        Tasks = @()
        Status = "Running"
    }
    
    foreach ($task in $Workflow.Tasks) {
        $state.Tasks += @{
            Name = $task.Name
            Status = "Pending"
            StartTime = $null
            EndTime = $null
            Result = $null
        }
    }
    
    return $state
}
```

#### Rollback Capabilities
```powershell
function Rollback-Workflow {
    param(
        [hashtable]$Workflow,
        [hashtable]$State,
        [int]$RollbackToTask
    )
    
    # Execute rollback actions in reverse order
    for ($i = $RollbackToTask; $i -ge 0; $i--) {
        $task = $Workflow.Tasks[$i]
        
        if ($task.RollbackAction) {
            Write-Host "Rolling back: $($task.Name)"
            & $task.RollbackAction
        }
    }
    
    return @{ Success = $true; RolledBackTo = $RollbackToTask }
}
```

---

### 4. Error Handling & Recovery

#### Automatic Retry Logic
```powershell
function Invoke-TaskWithRetry {
    param(
        [scriptblock]$Task,
        [int]$MaxRetries = 3,
        [int]$RetryDelaySeconds = 5
    )
    
    $attempt = 0
    
    while ($attempt -lt $MaxRetries) {
        try {
            $result = & $Task
            return @{ Success = $true; Result = $result }
        }
        catch {
            $attempt++
            
            if ($attempt -lt $MaxRetries) {
                Write-Host "Attempt $attempt failed, retrying in $RetryDelaySeconds seconds..."
                Start-Sleep -Seconds $RetryDelaySeconds
            }
            else {
                return @{ Success = $false; Error = $_.Exception.Message }
            }
        }
    }
}
```

#### Error Recovery Strategies
```powershell
function Handle-TaskError {
    param(
        [hashtable]$Task,
        [string]$ErrorMessage,
        [string]$Strategy = "Retry"
    )
    
    switch ($Strategy) {
        "Retry" {
            return Invoke-TaskWithRetry -Task $Task.Action
        }
        "Skip" {
            Write-Host "Skipping task: $($Task.Name)"
            return @{ Success = $true; Skipped = $true }
        }
        "Rollback" {
            return Rollback-Workflow -Workflow $Workflow -State $State
        }
        "Alert" {
            Send-Alert -Message "Task failed: $ErrorMessage" -Severity "Critical"
            return @{ Success = $false; Alerted = $true }
        }
    }
}
```

---

### 5. Monitoring & Alerting

#### Real-Time Execution Tracking
```powershell
function Monitor-WorkflowExecution {
    param([hashtable]$Workflow)
    
    $monitoring = @{
        WorkflowName = $Workflow.Name
        StartTime = Get-Date
        TasksCompleted = 0
        TasksFailed = 0
        CurrentTask = $null
        Progress = 0
    }
    
    return $monitoring
}
```

#### Performance Metrics
```powershell
function Collect-WorkflowMetrics {
    param([hashtable]$State)
    
    $metrics = @{
        TotalDuration = (Get-Date) - $State.StartTime
        AverageTaskDuration = 0
        FastestTask = $null
        SlowestTask = $null
        SuccessRate = 0
    }
    
    return $metrics
}
```

#### Anomaly Detection
```powershell
function Detect-WorkflowAnomalies {
    param([hashtable]$Metrics)
    
    $anomalies = @()
    
    if ($Metrics.TotalDuration -gt [timespan]::FromHours(2)) {
        $anomalies += "Workflow taking longer than expected"
    }
    
    if ($Metrics.SuccessRate -lt 0.95) {
        $anomalies += "High failure rate detected"
    }
    
    return $anomalies
}
```

---

## Practical Examples

### Example 1: Complete Backup Workflow
```powershell
$backupWorkflow = @{
    Name = "DailyBackupWorkflow"
    Priority = "High"
    Tasks = @(
        @{ Name = "PreCheck"; DependsOn = @() }
        @{ Name = "Backup"; DependsOn = @("PreCheck") }
        @{ Name = "Compress"; DependsOn = @("Backup") }
        @{ Name = "Encrypt"; DependsOn = @("Compress") }
        @{ Name = "Sync"; DependsOn = @("Encrypt") }
        @{ Name = "Verify"; DependsOn = @("Sync") }
        @{ Name = "Report"; DependsOn = @("Verify") }
    )
}

# Execute workflow
Invoke-Workflow -Workflow $backupWorkflow
```

### Example 2: Conditional Workflow
```powershell
$conditionalWorkflow = @{
    Tasks = @(
        @{ Name = "CheckDiskSpace"; DependsOn = @() }
        @{
            Name = "Cleanup"
            DependsOn = @("CheckDiskSpace")
            Condition = "if (Get-DiskUsagePercent -gt 80)"
        }
        @{ Name = "Backup"; DependsOn = @("Cleanup") }
    )
}
```

---

## Integration with Phase 1 & 2

### Dependencies
- `session-lifecycle` - Track workflow execution
- `backup-orchestrator` - Backup operations
- `cross-workspace-sync` - Sync operations
- `monitoring-aggregator` - Metrics collection

---

## Performance Expectations

| Operation | Target Time | Max Memory |
|-----------|------------|-----------|
| Workflow Definition | <1 second | <10MB |
| Dependency Resolution | <2 seconds | <20MB |
| Task Execution | Variable | <500MB |
| State Tracking | <1 second | <50MB |
| Error Recovery | <5 seconds | <100MB |

---

## Error Handling

**Issue**: "Task dependency not met"
- **Solution**: Verify task dependencies, check for circular references

**Issue**: "Insufficient resources"
- **Solution**: Wait for resources, reschedule workflow

**Issue**: "Task execution failed"
- **Solution**: Retry, skip, or rollback based on strategy