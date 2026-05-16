<#
.SYNOPSIS
Custom Parallelism Rules for Parallel Execution Limits

.DESCRIPTION
Provides functions for defining, applying, and managing custom parallelism rules
that control how tasks are executed in parallel based on task type, priority, and resources.

.VERSION
1.0.0

.AUTHOR
Gentle-Vanguard Team

.LICENSE
MIT
#>

# ============================================================================
# Rule Definition and Management
# ============================================================================

function Initialize-ParallelismRules {
    <#
    .SYNOPSIS
    Initialize default parallelism rules
    #>
    param(
        [string]$Strategy = "Balanced"
    )
    
    $defaultRules = @{
        Strategy = $Strategy
        Rules = @()
        DefaultRule = $null
        CreatedAt = Get-Date
    }
    
    switch ($Strategy) {
        "Conservative" {
            $defaultRules.Rules = @(
                @{
                    Name = "AITasksRule"
                    Condition = { $task.Type -eq "AI" }
                    MaxParallel = 1
                    Priority = 10
                    ResourceMultiplier = 2.0
                    Description = "AI tasks run sequentially for stability"
                }
                @{
                    Name = "GPUTasksRule"
                    Condition = { $task.ResourceRequirements.GPU -gt 0 }
                    MaxParallel = 1
                    Priority = 9
                    ResourceMultiplier = 1.8
                    Description = "GPU tasks run one at a time"
                }
                @{
                    Name = "ValidationTasksRule"
                    Condition = { $task.Type -eq "Validation" }
                    MaxParallel = 2
                    Priority = 5
                    ResourceMultiplier = 1.0
                    Description = "Validation tasks can run in pairs"
                }
            )
            $defaultRules.DefaultRule = @{
                MaxParallel = 1
                Priority = 1
                ResourceMultiplier = 1.0
            }
        }
        "Balanced" {
            $defaultRules.Rules = @(
                @{
                    Name = "AITasksRule"
                    Condition = { $task.Type -eq "AI" }
                    MaxParallel = 2
                    Priority = 10
                    ResourceMultiplier = 1.5
                    Description = "AI tasks run in pairs"
                }
                @{
                    Name = "GPUTasksRule"
                    Condition = { $task.ResourceRequirements.GPU -gt 0 }
                    MaxParallel = 2
                    Priority = 9
                    ResourceMultiplier = 1.3
                    Description = "GPU tasks run in pairs"
                }
                @{
                    Name = "ValidationTasksRule"
                    Condition = { $task.Type -eq "Validation" }
                    MaxParallel = 4
                    Priority = 5
                    ResourceMultiplier = 1.0
                    Description = "Validation tasks can run in groups of 4"
                }
                @{
                    Name = "ProcessingTasksRule"
                    Condition = { $task.Type -eq "Processing" }
                    MaxParallel = 3
                    Priority = 8
                    ResourceMultiplier = 1.2
                    Description = "Processing tasks run in groups of 3"
                }
            )
            $defaultRules.DefaultRule = @{
                MaxParallel = 2
                Priority = 1
                ResourceMultiplier = 1.0
            }
        }
        "Aggressive" {
            $defaultRules.Rules = @(
                @{
                    Name = "AITasksRule"
                    Condition = { $task.Type -eq "AI" }
                    MaxParallel = 4
                    Priority = 10
                    ResourceMultiplier = 1.2
                    Description = "AI tasks run in groups of 4"
                }
                @{
                    Name = "GPUTasksRule"
                    Condition = { $task.ResourceRequirements.GPU -gt 0 }
                    MaxParallel = 4
                    Priority = 9
                    ResourceMultiplier = 1.1
                    Description = "GPU tasks run in groups of 4"
                }
                @{
                    Name = "ValidationTasksRule"
                    Condition = { $task.Type -eq "Validation" }
                    MaxParallel = 8
                    Priority = 5
                    ResourceMultiplier = 0.9
                    Description = "Validation tasks run in groups of 8"
                }
                @{
                    Name = "ProcessingTasksRule"
                    Condition = { $task.Type -eq "Processing" }
                    MaxParallel = 6
                    Priority = 8
                    ResourceMultiplier = 1.0
                    Description = "Processing tasks run in groups of 6"
                }
            )
            $defaultRules.DefaultRule = @{
                MaxParallel = 4
                Priority = 1
                ResourceMultiplier = 0.8
            }
        }
    }
    
    return $defaultRules
}

function Add-ParallelismRule {
    <#
    .SYNOPSIS
    Add a custom parallelism rule
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Rules,
        
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [scriptblock]$Condition,
        
        [Parameter(Mandatory=$true)]
        [int]$MaxParallel,
        
        [int]$Priority = 1,
        
        [double]$ResourceMultiplier = 1.0,
        
        [string]$Description = ""
    )
    
    $rule = @{
        Name = $Name
        Condition = $Condition
        MaxParallel = $MaxParallel
        Priority = $Priority
        ResourceMultiplier = $ResourceMultiplier
        Description = $Description
        CreatedAt = Get-Date
    }
    
    $Rules.Rules += $rule
    
    return @{
        Success = $true
        RuleName = $Name
        Message = "Rule added successfully"
    }
}

function Remove-ParallelismRule {
    <#
    .SYNOPSIS
    Remove a parallelism rule by name
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Rules,
        
        [Parameter(Mandatory=$true)]
        [string]$RuleName
    )
    
    $initialCount = $Rules.Rules.Count
    $Rules.Rules = $Rules.Rules | Where-Object { $_.Name -ne $RuleName }
    
    if ($Rules.Rules.Count -lt $initialCount) {
        return @{
            Success = $true
            Message = "Rule removed successfully"
        }
    }
    else {
        return @{
            Success = $false
            Message = "Rule not found"
        }
    }
}

# ============================================================================
# Rule Application
# ============================================================================

function Apply-ParallelismRules {
    <#
    .SYNOPSIS
    Apply parallelism rules to generate execution plan
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Graph,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Rules
    )
    
    $executionPlan = @{
        Strategy = $Rules.Strategy
        Phases = @()
        TaskAssignments = @{}
        RuleApplications = @()
        CreatedAt = Get-Date
    }
    
    # Apply rules to each task
    foreach ($task in $Graph.Tasks) {
        $applicableRule = $null
        
        # Find the highest priority matching rule
        $matchingRules = @($Rules.Rules | Where-Object { & $_.Condition $task })
        
        if ($matchingRules.Count -gt 0) {
            $applicableRule = $matchingRules | Sort-Object -Property Priority -Descending | Select-Object -First 1
        }
        else {
            $applicableRule = $Rules.DefaultRule
        }
        
        $assignment = @{
            TaskId = $task.Id
            TaskName = $task.Name
            TaskType = $task.Type
            Rule = $applicableRule.Name
            MaxParallel = $applicableRule.MaxParallel
            Priority = $applicableRule.Priority
            ResourceMultiplier = $applicableRule.ResourceMultiplier
            AdjustedResources = @{
                CPU = [int]($task.ResourceRequirements.CPU * $applicableRule.ResourceMultiplier)
                Memory = [int]($task.ResourceRequirements.Memory * $applicableRule.ResourceMultiplier)
                GPU = [int]($task.ResourceRequirements.GPU * $applicableRule.ResourceMultiplier)
            }
        }
        
        $executionPlan.TaskAssignments[$task.Id] = $assignment
        
        $executionPlan.RuleApplications += @{
            TaskId = $task.Id
            RuleName = $applicableRule.Name
            Timestamp = Get-Date
        }
    }
    
    return $executionPlan
}

# ============================================================================
# Execution Plan Generation
# ============================================================================

function Generate-ExecutionPlan {
    <#
    .SYNOPSIS
    Generate execution plan with phases respecting rules and dependencies
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Graph,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$ExecutionPlan
    )
    
    $phases = @()
    $completed = @()
    $currentPhase = @()
    $phaseNumber = 0
    
    while ($completed.Count -lt $Graph.Tasks.Count) {
        $phaseNumber++
        $currentPhase = @()
        $parallelCount = 0
        
        foreach ($task in $Graph.Tasks) {
            if ($task.Id -notin $completed) {
                # Check dependencies
                $depsMet = $true
                foreach ($dep in $task.DependsOn) {
                    if ($dep -notin $completed) {
                        $depsMet = $false
                        break
                    }
                }
                
                if ($depsMet) {
                    $assignment = $ExecutionPlan.TaskAssignments[$task.Id]
                    
                    # Check if we can add this task to current phase
                    if ($parallelCount -lt $assignment.MaxParallel) {
                        $currentPhase += @{
                            TaskId = $task.Id
                            TaskName = $task.Name
                            Rule = $assignment.Rule
                            Priority = $assignment.Priority
                        }
                        $parallelCount++
                        $completed += $task.Id
                    }
                }
            }
        }
        
        if ($currentPhase.Count -gt 0) {
            $phases += @{
                PhaseNumber = $phaseNumber
                Tasks = $currentPhase
                TaskCount = $currentPhase.Count
                CanParallelize = $currentPhase.Count -gt 1
            }
        }
        
        if ($completed.Count -lt $Graph.Tasks.Count -and $currentPhase.Count -eq 0) {
            return @{
                Success = $false
                Error = "Unable to schedule remaining tasks"
                CompletedTasks = $completed.Count
                TotalTasks = $Graph.Tasks.Count
            }
        }
    }
    
    return @{
        Success = $true
        Phases = $phases
        TotalPhases = $phases.Count
        TotalTasks = $Graph.Tasks.Count
        EstimatedSpeedup = Get-EstimatedSpeedup -Phases $phases
    }
}

function Get-EstimatedSpeedup {
    <#
    .SYNOPSIS
    Calculate estimated speedup from parallelization
    #>
    param([array]$Phases)
    
    $maxParallel = 0
    foreach ($phase in $Phases) {
        if ($phase.TaskCount -gt $maxParallel) {
            $maxParallel = $phase.TaskCount
        }
    }
    
    $totalTasks = 0
    foreach ($phase in $Phases) {
        $totalTasks += $phase.TaskCount
    }
    
    if ($maxParallel -eq 0) {
        return 1.0
    }
    
    $sequentialTime = $totalTasks
    $parallelTime = $Phases.Count
    
    return [math]::Round($sequentialTime / $parallelTime, 2)
}

# ============================================================================
# Rule Validation and Analysis
# ============================================================================

function Validate-ParallelismRules {
    <#
    .SYNOPSIS
    Validate parallelism rules for consistency
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Rules
    )
    
    $issues = @()
    $warnings = @()
    
    # Check for duplicate rule names
    $ruleNames = $Rules.Rules | Select-Object -ExpandProperty Name
    $duplicates = $ruleNames | Group-Object | Where-Object { $_.Count -gt 1 }
    
    if ($duplicates) {
        $issues += "Duplicate rule names found: $($duplicates.Name -join ', ')"
    }
    
    # Check for invalid MaxParallel values
    foreach ($rule in $Rules.Rules) {
        if ($rule.MaxParallel -lt 1) {
            $issues += "Rule '$($rule.Name)' has invalid MaxParallel value: $($rule.MaxParallel)"
        }
        
        if ($rule.ResourceMultiplier -le 0) {
            $issues += "Rule '$($rule.Name)' has invalid ResourceMultiplier: $($rule.ResourceMultiplier)"
        }
        
        if ($rule.Priority -lt 0) {
            $warnings += "Rule '$($rule.Name)' has negative priority"
        }
    }
    
    # Check default rule
    if ($Rules.DefaultRule) {
        if ($Rules.DefaultRule.MaxParallel -lt 1) {
            $issues += "Default rule has invalid MaxParallel value"
        }
    }
    
    return @{
        IsValid = $issues.Count -eq 0
        Issues = $issues
        Warnings = $warnings
        RuleCount = $Rules.Rules.Count
    }
}

function Get-RuleStatistics {
    <#
    .SYNOPSIS
    Get statistics about parallelism rules
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Rules
    )
    
    $stats = @{
        TotalRules = $Rules.Rules.Count
        Strategy = $Rules.Strategy
        AverageMaxParallel = 0
        MaxParallelRange = @{ Min = 999; Max = 0 }
        PriorityRange = @{ Min = 999; Max = 0 }
        ResourceMultiplierRange = @{ Min = 999; Max = 0 }
    }
    
    if ($Rules.Rules.Count -gt 0) {
        $stats.AverageMaxParallel = [math]::Round(($Rules.Rules | Measure-Object -Property MaxParallel -Average | Select-Object -ExpandProperty Average), 2)
        
        $stats.MaxParallelRange.Min = $Rules.Rules | Measure-Object -Property MaxParallel -Minimum | Select-Object -ExpandProperty Minimum
        $stats.MaxParallelRange.Max = $Rules.Rules | Measure-Object -Property MaxParallel -Maximum | Select-Object -ExpandProperty Maximum
        
        $stats.PriorityRange.Min = $Rules.Rules | Measure-Object -Property Priority -Minimum | Select-Object -ExpandProperty Minimum
        $stats.PriorityRange.Max = $Rules.Rules | Measure-Object -Property Priority -Maximum | Select-Object -ExpandProperty Maximum
        
        $stats.ResourceMultiplierRange.Min = $Rules.Rules | Measure-Object -Property ResourceMultiplier -Minimum | Select-Object -ExpandProperty Minimum
        $stats.ResourceMultiplierRange.Max = $Rules.Rules | Measure-Object -Property ResourceMultiplier -Maximum | Select-Object -ExpandProperty Maximum
    }
    
    return $stats
}

# ============================================================================
# Rule Export and Import
# ============================================================================

function Export-ParallelismRules {
    <#
    .SYNOPSIS
    Export parallelism rules to JSON
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Rules,
        
        [string]$Path = $null
    )
    
    $exportData = @{
        Strategy = $Rules.Strategy
        Rules = @()
        DefaultRule = $Rules.DefaultRule
        ExportedAt = Get-Date
    }
    
    foreach ($rule in $Rules.Rules) {
        $exportData.Rules += @{
            Name = $rule.Name
            MaxParallel = $rule.MaxParallel
            Priority = $rule.Priority
            ResourceMultiplier = $rule.ResourceMultiplier
            Description = $rule.Description
        }
    }
    
    $json = $exportData | ConvertTo-Json -Depth 10
    
    if ($Path) {
        $json | Out-File -FilePath $Path -Encoding UTF8
        return @{
            Success = $true
            Path = $Path
            Message = "Rules exported successfully"
        }
    }
    
    return $json
}

# ============================================================================
# Export Functions
# ============================================================================

Export-ModuleMember -Function @(
    'Initialize-ParallelismRules'
    'Add-ParallelismRule'
    'Remove-ParallelismRule'
    'Apply-ParallelismRules'
    'Generate-ExecutionPlan'
    'Get-EstimatedSpeedup'
    'Validate-ParallelismRules'
    'Get-RuleStatistics'
    'Export-ParallelismRules'
)
