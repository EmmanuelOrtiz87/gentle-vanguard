<#
.SYNOPSIS
Dependency Graph Management for Parallel Execution Limits

.DESCRIPTION
Provides functions for creating, validating, and visualizing dependency graphs
for parallel task execution with circular dependency detection and optimization.

.VERSION
1.0.0

.AUTHOR
Foundation Team

.LICENSE
MIT
#>

# ============================================================================
# Dependency Graph Initialization
# ============================================================================

function Initialize-DependencyGraph {
    <#
    .SYNOPSIS
    Initialize an empty dependency graph structure
    #>
    param(
        [string]$Name = "DefaultGraph",
        [hashtable]$Constraints = $null
    )
    
    if (-not $Constraints) {
        $Constraints = @{
            MaxParallelTasks = 8
            MaxCPUUsage = 100
            MaxMemoryUsage = 16384
            MaxGPUUsage = 4
        }
    }
    
    return @{
        Name = $Name
        Tasks = @()
        Constraints = $Constraints
        CreatedAt = Get-Date
        LastModified = Get-Date
    }
}

function Add-GraphTask {
    <#
    .SYNOPSIS
    Add a task to the dependency graph
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Graph,
        
        [Parameter(Mandatory=$true)]
        [string]$TaskId,
        
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        
        [string]$Type = "General",
        
        [array]$DependsOn = @(),
        
        [hashtable]$ResourceRequirements = @{
            CPU = 10
            Memory = 256
            GPU = 0
        }
    )
    
    $task = @{
        Id = $TaskId
        Name = $TaskName
        Type = $Type
        DependsOn = $DependsOn
        ResourceRequirements = $ResourceRequirements
        Status = "Pending"
        CreatedAt = Get-Date
    }
    
    $Graph.Tasks += $task
    $Graph.LastModified = Get-Date
    
    return @{
        Success = $true
        TaskId = $TaskId
        Message = "Task added successfully"
    }
}

# ============================================================================
# Graph Validation
# ============================================================================

function Test-CircularDependencies {
    <#
    .SYNOPSIS
    Detect circular dependencies in the graph using DFS
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Graph
    )
    
    $visited = @{}
    $recursionStack = @{}
    
    foreach ($task in $Graph.Tasks) {
        if (-not $visited.ContainsKey($task.Id)) {
            if (Test-CircularDependenciesDFS -Graph $Graph -TaskId $task.Id -Visited $visited -RecursionStack $recursionStack) {
                return $true
            }
        }
    }
    
    return $false
}

function Test-CircularDependenciesDFS {
    <#
    .SYNOPSIS
    Depth-first search for circular dependencies
    #>
    param(
        [hashtable]$Graph,
        [string]$TaskId,
        [hashtable]$Visited,
        [hashtable]$RecursionStack
    )
    
    $visited[$TaskId] = $true
    $recursionStack[$TaskId] = $true
    
    $task = $Graph.Tasks | Where-Object { $_.Id -eq $TaskId }
    
    foreach ($dep in $task.DependsOn) {
        if (-not $visited.ContainsKey($dep)) {
            if (Test-CircularDependenciesDFS -Graph $Graph -TaskId $dep -Visited $visited -RecursionStack $recursionStack) {
                return $true
            }
        }
        elseif ($recursionStack.ContainsKey($dep) -and $recursionStack[$dep]) {
            return $true
        }
    }
    
    $recursionStack[$TaskId] = $false
    return $false
}

function Validate-DependencyGraph {
    <#
    .SYNOPSIS
    Comprehensive validation of dependency graph
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Graph
    )
    
    $issues = @()
    $warnings = @()
    
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
    
    # Check for isolated tasks
    $connectedTasks = @()
    foreach ($task in $Graph.Tasks) {
        if ($task.DependsOn.Count -eq 0 -and -not ($Graph.Tasks | Where-Object { $task.Id -in $_.DependsOn })) {
            $warnings += "Task '$($task.Id)' is isolated (no dependencies and not depended upon)"
        }
    }
    
    # Check resource requirements
    foreach ($task in $Graph.Tasks) {
        $req = $task.ResourceRequirements
        if ($req.CPU -lt 0 -or $req.Memory -lt 0 -or $req.GPU -lt 0) {
            $issues += "Task '$($task.Id)' has negative resource requirements"
        }
    }
    
    return @{
        IsValid = $issues.Count -eq 0
        Issues = $issues
        Warnings = $warnings
        TaskCount = $Graph.Tasks.Count
        ValidationTime = Get-Date
    }
}

# ============================================================================
# Dependency Resolution
# ============================================================================

function Resolve-TaskDependencies {
    <#
    .SYNOPSIS
    Resolve task execution order respecting dependencies
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Graph
    )
    
    $executionOrder = @()
    $completed = @()
    $phases = @()
    $currentPhase = @()
    
    while ($completed.Count -lt $Graph.Tasks.Count) {
        $phaseAdded = $false
        
        foreach ($task in $Graph.Tasks) {
            if ($task.Id -notin $completed) {
                $depsMet = $true
                
                foreach ($dep in $task.DependsOn) {
                    if ($dep -notin $completed) {
                        $depsMet = $false
                        break
                    }
                }
                
                if ($depsMet) {
                    $currentPhase += $task.Id
                    $executionOrder += $task.Id
                    $completed += $task.Id
                    $phaseAdded = $true
                }
            }
        }
        
        if ($currentPhase.Count -gt 0) {
            $phases += @{
                PhaseNumber = $phases.Count + 1
                Tasks = $currentPhase
                CanParallelize = $true
            }
            $currentPhase = @()
        }
        
        if (-not $phaseAdded -and $completed.Count -lt $Graph.Tasks.Count) {
            return @{
                Success = $false
                Error = "Circular dependency or unresolvable dependencies detected"
                CompletedTasks = $completed
            }
        }
    }
    
    return @{
        Success = $true
        ExecutionOrder = $executionOrder
        Phases = $phases
        TotalPhases = $phases.Count
    }
}

function Get-TaskDependencyLevel {
    <#
    .SYNOPSIS
    Calculate dependency level (depth) for each task
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Graph
    )
    
    $levels = @{}
    
    foreach ($task in $Graph.Tasks) {
        $levels[$task.Id] = 0
    }
    
    $changed = $true
    while ($changed) {
        $changed = $false
        
        foreach ($task in $Graph.Tasks) {
            $maxDepLevel = 0
            
            foreach ($dep in $task.DependsOn) {
                if ($levels.ContainsKey($dep)) {
                    $maxDepLevel = [Math]::Max($maxDepLevel, $levels[$dep])
                }
            }
            
            $newLevel = $maxDepLevel + 1
            if ($newLevel -gt $levels[$task.Id]) {
                $levels[$task.Id] = $newLevel
                $changed = $true
            }
        }
    }
    
    return $levels
}

# ============================================================================
# Graph Visualization
# ============================================================================

function Export-DependencyGraphVisualization {
    <#
    .SYNOPSIS
    Export dependency graph as visualization structure
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Graph,
        
        [ValidateSet("JSON", "DOT", "Mermaid")]
        [string]$Format = "JSON"
    )
    
    $visualization = @{
        Nodes = @()
        Edges = @()
        Metadata = @{
            GraphName = $Graph.Name
            TaskCount = $Graph.Tasks.Count
            CreatedAt = $Graph.CreatedAt
            Format = $Format
        }
    }
    
    # Create nodes
    $levels = Get-TaskDependencyLevel -Graph $Graph
    
    foreach ($task in $Graph.Tasks) {
        $visualization.Nodes += @{
            Id = $task.Id
            Label = $task.Name
            Type = $task.Type
            Level = $levels[$task.Id]
            Resources = $task.ResourceRequirements
            Status = $task.Status
        }
    }
    
    # Create edges
    foreach ($task in $Graph.Tasks) {
        foreach ($dep in $task.DependsOn) {
            $visualization.Edges += @{
                From = $dep
                To = $task.Id
                Type = "Dependency"
            }
        }
    }
    
    if ($Format -eq "Mermaid") {
        return Convert-ToMermaidDiagram -Visualization $visualization
    }
    elseif ($Format -eq "DOT") {
        return Convert-ToDotFormat -Visualization $visualization
    }
    
    return $visualization | ConvertTo-Json -Depth 10
}

function Convert-ToMermaidDiagram {
    <#
    .SYNOPSIS
    Convert visualization to Mermaid diagram format
    #>
    param([hashtable]$Visualization)
    
    $mermaid = @"
graph TD
"@
    
    foreach ($node in $Visualization.Nodes) {
        $mermaid += "`n    $($node.Id)[$($node.Label)]"
    }
    
    foreach ($edge in $Visualization.Edges) {
        $mermaid += "`n    $($edge.From) --> $($edge.To)"
    }
    
    return $mermaid
}

function Convert-ToDotFormat {
    <#
    .SYNOPSIS
    Convert visualization to GraphViz DOT format
    #>
    param([hashtable]$Visualization)
    
    $dot = "digraph DependencyGraph {`n"
    $dot += "    rankdir=LR;`n"
    
    foreach ($node in $Visualization.Nodes) {
        $dot += "    `"$($node.Id)`" [label=`"$($node.Label)`", type=`"$($node.Type)`"];`n"
    }
    
    foreach ($edge in $Visualization.Edges) {
        $dot += "    `"$($edge.From)`" -> `"$($edge.To)`";`n"
    }
    
    $dot += "}`n"
    
    return $dot
}

# ============================================================================
# Graph Analysis
# ============================================================================

function Get-CriticalPath {
    <#
    .SYNOPSIS
    Identify critical path (longest dependency chain)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Graph
    )
    
    $levels = Get-TaskDependencyLevel -Graph $Graph
    $maxLevel = $levels.Values | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
    
    $criticalTasks = @()
    foreach ($task in $Graph.Tasks) {
        if ($levels[$task.Id] -eq $maxLevel) {
            $criticalTasks += $task.Id
        }
    }
    
    return @{
        CriticalPathLength = $maxLevel + 1
        CriticalTasks = $criticalTasks
        BottleneckTasks = $criticalTasks
    }
}

function Get-ParallelizationOpportunities {
    <#
    .SYNOPSIS
    Identify tasks that can run in parallel
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Graph
    )
    
    $resolution = Resolve-TaskDependencies -Graph $Graph
    
    if (-not $resolution.Success) {
        return @{
            Success = $false
            Error = $resolution.Error
        }
    }
    
    $opportunities = @()
    
    foreach ($phase in $resolution.Phases) {
        if ($phase.Tasks.Count -gt 1) {
            $opportunities += @{
                Phase = $phase.PhaseNumber
                ParallelTasks = $phase.Tasks
                Count = $phase.Tasks.Count
                PotentialSpeedup = $phase.Tasks.Count
            }
        }
    }
    
    return @{
        Success = $true
        TotalPhases = $resolution.TotalPhases
        ParallelPhases = $opportunities.Count
        Opportunities = $opportunities
        MaxParallelization = ($opportunities | Measure-Object -Property Count -Maximum | Select-Object -ExpandProperty Maximum)
    }
}

# ============================================================================
# Export Functions
# ============================================================================

Export-ModuleMember -Function @(
    'Initialize-DependencyGraph'
    'Add-GraphTask'
    'Test-CircularDependencies'
    'Validate-DependencyGraph'
    'Resolve-TaskDependencies'
    'Get-TaskDependencyLevel'
    'Export-DependencyGraphVisualization'
    'Get-CriticalPath'
    'Get-ParallelizationOpportunities'
)