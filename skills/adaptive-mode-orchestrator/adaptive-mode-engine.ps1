<#
.SYNOPSIS
    Adaptive Mode Engine - Dynamic DAG-based orchestration with feedback loops and auto-rollback
.DESCRIPTION
    Implements intelligent workflow orchestration with:
    - Dynamic phase execution based on DAG
    - Feedback loops (QA → DEV → QA)
    - Automatic rollback on failures
    - Parallel execution where possible
    - Real-time monitoring and metrics
.AUTHOR
    Gentleman Foundation
.VERSION
    1.0
#>

param(
    [string]$ConfigPath = "config/adaptive-dag-config.json",
    [string]$TaskDescription = "",
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

# ============================================================================
# CORE STRUCTURES
# ============================================================================

class AdaptivePhase {
    [string]$Name
    [array]$Agents
    [string]$Description
    [int]$Timeout
    [bool]$Parallel
    [bool]$Required
    [array]$Dependencies
    [string]$FeedbackTarget
    [hashtable]$Status
    [datetime]$StartTime
    [datetime]$EndTime
    [array]$Results
    [int]$Iteration = 0
    
    AdaptivePhase([string]$name, [hashtable]$config) {
        $this.Name = $name
        $this.Agents = $config.agents
        $this.Description = $config.description
        $this.Timeout = $config.timeout
        $this.Parallel = $config.parallel
        $this.Required = $config.required
        $this.Dependencies = $config.dependencies
        $this.FeedbackTarget = $config.feedback_target
        $this.Status = @{
            State = "pending"
            Progress = 0
            Errors = @()
            Warnings = @()
        }
        $this.Results = @()
    }
}

class DAGExecutor {
    [hashtable]$Config
    [hashtable]$Phases
    [hashtable]$ExecutionLog
    [hashtable]$Checkpoints
    [array]$FeedbackLoops
    
    DAGExecutor([hashtable]$config) {
        $this.Config = $config
        $this.Phases = @{}
        $this.ExecutionLog = @{
            StartTime = Get-Date
            Phases = @()
            FeedbackLoops = @()
            Rollbacks = @()
        }
        $this.Checkpoints = @{}
        $this.FeedbackLoops = @()
        
        $this.InitializePhases()
    }
    
    [void]InitializePhases() {
        foreach ($phaseName in $this.Config.dag.phases.Keys) {
            $phaseConfig = $this.Config.dag.phases[$phaseName]
            $this.Phases[$phaseName] = [AdaptivePhase]::new($phaseName, $phaseConfig)
        }
    }
    
    [bool]CheckDependencies([string]$phaseName) {
        $phase = $this.Phases[$phaseName]
        
        if (-not $phase.Dependencies -or $phase.Dependencies.Count -eq 0) {
            return $true
        }
        
        foreach ($dep in $phase.Dependencies) {
            $depPhase = $this.Phases[$dep]
            if ($depPhase.Status.State -ne "completed") {
                return $false
            }
        }
        
        return $true
    }
    
    [hashtable]ExecutePhase([string]$phaseName) {
        $phase = $this.Phases[$phaseName]
        
        Write-Host "[ADAPTIVE] Iniciando fase: $phaseName" -ForegroundColor Cyan
        $phase.StartTime = Get-Date
        $phase.Status.State = "executing"
        $phase.Iteration++
        
        $result = @{
            PhaseName = $phaseName
            Status = "success"
            Agents = $phase.Agents
            StartTime = $phase.StartTime
            Duration = 0
            Errors = @()
            Warnings = @()
            Metrics = @{}
        }
        
        try {
            # Simular ejecución de agentes
            foreach ($agent in $phase.Agents) {
                Write-Host "  ├─ Ejecutando agente: $agent" -ForegroundColor Yellow
                
                $agentResult = $this.ExecuteAgent($agent, $phaseName)
                
                if ($agentResult.Status -eq "failed") {
                    $result.Status = "failed"
                    $result.Errors += $agentResult.Error
                    $phase.Status.Errors += $agentResult.Error
                } elseif ($agentResult.Status -eq "warning") {
                    $result.Warnings += $agentResult.Warning
                    $phase.Status.Warnings += $agentResult.Warning
                }
                
                $result.Metrics[$agent] = $agentResult.Metrics
            }
            
            $phase.EndTime = Get-Date
            $result.Duration = ($phase.EndTime - $phase.StartTime).TotalSeconds
            
            if ($result.Status -eq "success") {
                $phase.Status.State = "completed"
                $phase.Status.Progress = 100
                Write-Host "  ✓ Fase completada: $phaseName" -ForegroundColor Green
            } else {
                $phase.Status.State = "failed"
                Write-Host "  ✗ Fase fallida: $phaseName" -ForegroundColor Red
            }
            
        } catch {
            $result.Status = "error"
            $result.Errors += $_.Exception.Message
            $phase.Status.State = "error"
            Write-Host "  ✗ Error en fase: $_" -ForegroundColor Red
        }
        
        $phase.Results += $result
        $this.ExecutionLog.Phases += $result
        
        return $result
    }
    
    [hashtable]ExecuteAgent([string]$agent, [string]$phaseName) {
        $result = @{
            Agent = $agent
            Phase = $phaseName
            Status = "success"
            Error = ""
            Warning = ""
            Metrics = @{
                ExecutionTime = 0
                TasksCompleted = 0
                TasksFailed = 0
            }
        }
        
        # Simulación de ejecución del agente
        $startTime = Get-Date
        
        # Aquí iría la lógica real de ejecución del agente
        # Por ahora, simulamos con un pequeño delay
        Start-Sleep -Milliseconds 100
        
        $result.Metrics.ExecutionTime = ((Get-Date) - $startTime).TotalMilliseconds
        $result.Metrics.TasksCompleted = 1
        
        return $result
    }
    
    [void]CreateCheckpoint([string]$phaseName) {
        $checkpointName = "checkpoint-$phaseName-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        
        $this.Checkpoints[$checkpointName] = @{
            PhaseName = $phaseName
            Timestamp = Get-Date
            PhaseState = $this.Phases[$phaseName].Status
            ExecutionLog = $this.ExecutionLog
        }
        
        Write-Host "[CHECKPOINT] Creado: $checkpointName" -ForegroundColor Cyan
        
        return $checkpointName
    }
    
    [bool]RollbackToCheckpoint([string]$checkpointName) {
        if (-not $this.Checkpoints.ContainsKey($checkpointName)) {
            Write-Host "[ROLLBACK] Checkpoint no encontrado: $checkpointName" -ForegroundColor Red
            return $false
        }
        
        $checkpoint = $this.Checkpoints[$checkpointName]
        Write-Host "[ROLLBACK] Revirtiendo a: $checkpointName" -ForegroundColor Yellow
        
        # Restaurar estado
        $phaseName = $checkpoint.PhaseName
        $this.Phases[$phaseName].Status = $checkpoint.PhaseState
        
        $this.ExecutionLog.Rollbacks += @{
            Timestamp = Get-Date
            CheckpointName = $checkpointName
            PhaseName = $phaseName
        }
        
        Write-Host "[ROLLBACK] Completado: $checkpointName" -ForegroundColor Green
        
        return $true
    }
    
    [hashtable]CheckFeedbackLoopCondition([string]$sourcePhaseName) {
        $phase = $this.Phases[$sourcePhaseName]
        $lastResult = $phase.Results[-1]
        
        $feedbackNeeded = @{
            Triggered = $false
            TargetPhase = ""
            Reason = ""
            MaxIterations = 0
            CurrentIteration = 0
        }
        
        # Buscar feedback loops configurados
        foreach ($loopName in $this.Config.dag.feedback_loops.Keys) {
            $loop = $this.Config.dag.feedback_loops[$loopName]
            
            if ($loop.source -eq $sourcePhaseName -and $loop.enabled) {
                # Evaluar condición del feedback loop
                if ($this.EvaluateFeedbackCondition($loop, $lastResult)) {
                    $feedbackNeeded.Triggered = $true
                    $feedbackNeeded.TargetPhase = $loop.target
                    $feedbackNeeded.Reason = $loop.description
                    $feedbackNeeded.MaxIterations = $loop.max_iterations
                    $feedbackNeeded.CurrentIteration = $phase.Iteration
                    
                    break
                }
            }
        }
        
        return $feedbackNeeded
    }
    
    [bool]EvaluateFeedbackCondition([hashtable]$loop, [hashtable]$result) {
        switch ($loop.trigger) {
            "test_failure" {
                return $result.Status -eq "failed" -or $result.Errors.Count -gt 0
            }
            "architecture_issue" {
                return $result.Warnings -match "architecture|design"
            }
            "security_issue" {
                return $result.Errors -match "security|vulnerability"
            }
            default {
                return $false
            }
        }
    }
    
    [hashtable]ExecuteAdaptiveWorkflow() {
        Write-Host "`n[ADAPTIVE MODE] Iniciando orquestación adaptativa" -ForegroundColor Cyan
        Write-Host "═" * 80 -ForegroundColor Cyan
        
        $executionPlan = $this.BuildExecutionPlan()
        
        Write-Host "`n[PLAN] Fases a ejecutar:" -ForegroundColor Yellow
        foreach ($phase in $executionPlan) {
            Write-Host "  → $phase" -ForegroundColor Gray
        }
        Write-Host ""
        
        $completedPhases = @()
        $failedPhases = @()
        
        foreach ($phaseName in $executionPlan) {
            # Verificar dependencias
            if (-not $this.CheckDependencies($phaseName)) {
                Write-Host "[SKIP] Fase saltada (dependencias no cumplidas): $phaseName" -ForegroundColor Yellow
                continue
            }
            
            # Crear checkpoint antes de ejecutar
            if ($this.Config.dag.rollback_policy.checkpoint_on_phase_complete) {
                $this.CreateCheckpoint($phaseName)
            }
            
            # Ejecutar fase
            $result = $this.ExecutePhase($phaseName)
            
            if ($result.Status -eq "success") {
                $completedPhases += $phaseName
                
                # Verificar feedback loops
                $feedback = $this.CheckFeedbackLoopCondition($phaseName)
                
                if ($feedback.Triggered -and $feedback.CurrentIteration -lt $feedback.MaxIterations) {
                    Write-Host "`n[FEEDBACK LOOP] Activado: $($feedback.Reason)" -ForegroundColor Magenta
                    Write-Host "  Origen: $phaseName → Destino: $($feedback.TargetPhase)" -ForegroundColor Magenta
                    
                    # Reiniciar fase objetivo
                    $this.Phases[$feedback.TargetPhase].Status.State = "pending"
                    $this.Phases[$feedback.TargetPhase].Iteration = $feedback.CurrentIteration
                    
                    # Re-ejecutar fase objetivo
                    $retryResult = $this.ExecutePhase($feedback.TargetPhase)
                    
                    if ($retryResult.Status -eq "success") {
                        $completedPhases += $feedback.TargetPhase
                    } else {
                        $failedPhases += $feedback.TargetPhase
                    }
                }
            } else {
                $failedPhases += $phaseName
                
                # Evaluar política de rollback
                if ($this.Config.dag.rollback_policy.auto_rollback_on_qa_failure -and $phaseName -eq "quality_assurance") {
                    Write-Host "`n[AUTO-ROLLBACK] Activado por fallo en QA" -ForegroundColor Red
                    
                    # Obtener último checkpoint
                    $lastCheckpoint = $this.Checkpoints.Keys | Sort-Object -Descending | Select-Object -First 1
                    
                    if ($lastCheckpoint) {
                        $this.RollbackToCheckpoint($lastCheckpoint)
                    }
                }
            }
        }
        
        return @{
            Status = if ($failedPhases.Count -eq 0) { "success" } else { "partial" }
            CompletedPhases = $completedPhases
            FailedPhases = $failedPhases
            ExecutionLog = $this.ExecutionLog
            Checkpoints = $this.Checkpoints.Keys
            Duration = ((Get-Date) - $this.ExecutionLog.StartTime).TotalSeconds
        }
    }
    
    [array]BuildExecutionPlan() {
        $plan = @()
        $visited = @{}
        
        # Topological sort del DAG
        $this.TopologicalSort("planning", $visited, $plan)
        
        return $plan
    }
    
    [void]TopologicalSort([string]$phaseName, [hashtable]$visited, [array]$plan) {
        if ($visited.ContainsKey($phaseName)) {
            return
        }
        
        $visited[$phaseName] = $true
        
        $phase = $this.Phases[$phaseName]
        if ($phase.Dependencies) {
            foreach ($dep in $phase.Dependencies) {
                $this.TopologicalSort($dep, $visited, $plan)
            }
        }
        
        $plan += $phaseName
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function Start-AdaptiveMode {
    param(
        [string]$ConfigPath = "config/adaptive-dag-config.json",
        [string]$TaskDescription = "",
        [switch]$DryRun = $false
    )
    
    # Cargar configuración
    if (-not (Test-Path $ConfigPath)) {
        Write-Host "[ERROR] Archivo de configuración no encontrado: $ConfigPath" -ForegroundColor Red
        return $null
    }
    
    $config = Get-Content $ConfigPath | ConvertFrom-Json
    
    if (-not $config.enabled) {
        Write-Host "[INFO] Adaptive Mode está deshabilitado" -ForegroundColor Yellow
        return $null
    }
    
    # Crear ejecutor
    $executor = [DAGExecutor]::new($config)
    
    # Ejecutar workflow adaptativo
    $result = $executor.ExecuteAdaptiveWorkflow()
    
    # Mostrar resumen
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "═" * 80 -ForegroundColor Cyan
    Write-Host "[RESUMEN] Ejecución Adaptativa" -ForegroundColor Cyan
    Write-Host "═" * 80 -ForegroundColor Cyan
    Write-Host "Estado: $($result.Status)" -ForegroundColor $(if ($result.Status -eq "success") { "Green" } else { "Yellow" })
    Write-Host "Fases completadas: $($result.CompletedPhases.Count)" -ForegroundColor Green
    Write-Host "Fases fallidas: $($result.FailedPhases.Count)" -ForegroundColor $(if ($result.FailedPhases.Count -gt 0) { "Red" } else { "Green" })
    Write-Host "Duración total: $([Math]::Round($result.Duration, 2))s" -ForegroundColor Cyan
    Write-Host ""
    
    return $result
}

# Ejecutar si se llama directamente
if ($MyInvocation.InvocationName -ne ".") {
    $result = Start-AdaptiveMode -ConfigPath $ConfigPath -TaskDescription $TaskDescription -DryRun:$DryRun
    
    if ($result) {
        $result | ConvertTo-Json -Depth 10 | Out-Host
    }
}