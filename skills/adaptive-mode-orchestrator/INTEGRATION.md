# Adaptive Mode - Integration Guide

## Integracin con Project Orchestrator

### 1. Deteccin Automtica

El orquestador principal detecta automticamente cundo usar Adaptive Mode:

```powershell
# En project-orchestrator-skill
if ($taskComplexity -eq "high" -and $agentCount -gt 2) {
    # Activar Adaptive Mode
    & .\skills\adaptive-mode-orchestrator\adaptive-mode-engine.ps1
}
```

### 2. Configuracin de Activacin

Agregar a `config/orchestrator.json`:

```json
{
  "adaptive_mode": {
    "enabled": true,
    "auto_detect": true,
    "complexity_threshold": "high",
    "min_agents": 2,
    "config_path": "config/adaptive-dag-config.json"
  }
}
```

### 3. Puntos de Integracin

#### A. Session Start
```powershell
# En session-autostart.cmd
call .\skills\adaptive-mode-orchestrator\adaptive-mode-engine.ps1 -DryRun
```

#### B. Task Execution
```powershell
# En project-orchestrator-skill
$adaptiveResult = & .\skills\adaptive-mode-orchestrator\adaptive-mode-engine.ps1 `
  -TaskDescription $taskDescription `
  -ConfigPath $configPath
```

#### C. Pre-Push Validation
```powershell
# Antes de push, verificar estado de Adaptive Mode
$status = Get-AdaptiveMode-Status
if ($status.FailedPhases -gt 0) {
    Write-Host "Fases fallidas detectadas - revisar antes de push"
}
```

### 4. Flujo de Ejecucin Integrado

```
SESSION START
    
DETECT TASK COMPLEXITY
     Simple  Usar auto-delegation normal
     Complex  Activar Adaptive Mode
    
ADAPTIVE MODE ENGINE
     Build DAG
     Execute Phases
     Monitor Feedback Loops
     Auto-Rollback if needed
     Generate Report
    
RETURN TO ORCHESTRATOR
     Update session state
     Log metrics
     Continue workflow
```

### 5. Comunicacin entre Componentes

#### Orchestrator  Adaptive Mode

```json
{
  "command": "execute_workflow",
  "task_description": "Implementar feature de autenticacin",
  "config_path": "config/adaptive-dag-config.json",
  "options": {
    "dry_run": false,
    "verbose": true,
    "max_iterations": 3
  }
}
```

#### Adaptive Mode  Orchestrator

```json
{
  "status": "success",
  "completed_phases": ["planning", "design", "implementation", "quality_assurance"],
  "failed_phases": [],
  "feedback_loops_triggered": 1,
  "rollbacks_executed": 0,
  "duration_seconds": 1234,
  "metrics": {
    "qa_pass_rate": 98,
    "code_coverage": 85,
    "security_issues": 0
  }
}
```

### 6. Configuracin de Auto-Delegation

Actualizar `config/auto-delegation.json`:

```json
{
  "adaptive_mode": {
    "enabled": true,
    "integration": "orchestrator",
    "feedback_loop_support": true,
    "rollback_support": true
  }
}
```

### 7. Skill Loading Order

```powershell
# Orden de carga de skills
1. project-orchestrator-skill (siempre)
2. auto-delegation-router (siempre)
3. adaptive-mode-orchestrator (si complejidad alta)
4. Otros skills especficos del dominio
```

### 8. Monitoreo y Observabilidad

#### Mtricas a Capturar

```powershell
$metrics = @{
    "adaptive_mode_enabled" = $true
    "phases_executed" = 7
    "phases_completed" = 6
    "phases_failed" = 1
    "feedback_loops_triggered" = 1
    "rollbacks_executed" = 0
    "total_duration_seconds" = 1234
    "average_phase_duration" = 176
}
```

#### Logs a Generar

```
logs/adaptive-mode.log
logs/adaptive-mode-metrics.json
logs/adaptive-mode-checkpoints.json
```

### 9. Error Handling

```powershell
try {
    $result = & .\skills\adaptive-mode-orchestrator\adaptive-mode-engine.ps1
} catch {
    # Fallback a auto-delegation normal
    Write-Host "Adaptive Mode fall, usando auto-delegation"
    & .\skills\auto-delegation-router\auto-delegation-router.ps1
}
```

### 10. Session State Management

Actualizar `docs/sessions/YYYY-MM-DD-session-start.md`:

```markdown
## Adaptive Mode Status

- **Enabled**: true
- **Phases Executed**: 7
- **Feedback Loops**: 1 (QA  DEV)
- **Rollbacks**: 0
- **Status**: RUNNING

### Phase Progress
-  Planning (BA)
-  Design (SAD)
-  Implementation (DEV)
-  Quality Assurance (QA)
-  Governance (GOV)
-  Documentation (DOC)
-  Deployment (OPS)
```

## Comandos de Integracin

```powershell
# Habilitar Adaptive Mode
.\scripts\utilities\wf.ps1 adaptive-mode enable

# Deshabilitar Adaptive Mode
.\scripts\utilities\wf.ps1 adaptive-mode disable

# Ver estado
.\scripts\utilities\wf.ps1 adaptive-mode status

# Ver mtricas
.\scripts\utilities\wf.ps1 adaptive-mode metrics

# Ejecutar manualmente
.\scripts\utilities\wf.ps1 adaptive-mode run --task "descripcin"

# Ver logs
.\scripts\utilities\wf.ps1 adaptive-mode logs

# Ver checkpoints
.\scripts\utilities\wf.ps1 adaptive-mode checkpoints

# Rollback manual
.\scripts\utilities\wf.ps1 adaptive-mode rollback --checkpoint "nombre"
```

## Configuracin Recomendada

### Para Desarrollo

```json
{
  "adaptive_mode": {
    "enabled": true,
    "auto_detect": true,
    "complexity_threshold": "medium",
    "max_feedback_loops": 3,
    "auto_rollback": true,
    "verbose_logging": true
  }
}
```

### Para Produccin

```json
{
  "adaptive_mode": {
    "enabled": true,
    "auto_detect": true,
    "complexity_threshold": "high",
    "max_feedback_loops": 2,
    "auto_rollback": true,
    "verbose_logging": false,
    "strict_mode": true
  }
}
```

## Troubleshooting de Integracin

### Problema: Adaptive Mode no se activa
**Solucin**: Verificar `enabled: true` en config

### Problema: Feedback loops no funcionan
**Solucin**: Verificar `feedback_loops` en DAG config

### Problema: Rollback no se ejecuta
**Solucin**: Verificar `rollback_policy.enabled` en config

### Problema: Mtricas no se capturan
**Solucin**: Verificar `logging.enabled` en config

## Testing de Integracin

```powershell
# Test 1: Verificar carga del skill
Test-Path "skills/adaptive-mode-orchestrator/adaptive-mode-engine.ps1"

# Test 2: Verificar configuracin
$config = Get-Content "config/adaptive-dag-config.json" | ConvertFrom-Json
$config.enabled

# Test 3: Ejecutar en dry-run
.\skills\adaptive-mode-orchestrator\adaptive-mode-engine.ps1 -DryRun

# Test 4: Verificar logs
Get-Content "logs/adaptive-mode.log" -Tail 20
```

## Prximos Pasos

1.  Crear configuracin DAG
2.  Implementar motor de ejecucin
3.  Crear documentacin
4.  Integrar con orchestrator.json
5.  Crear comandos de CLI
6.  Implementar dashboard de monitoreo
7.  Realizar testing completo
8.  Documentar casos de uso reales

---

**Versin**: 1.0
**Fecha**: 2026-04-23
**Estado**: READY FOR INTEGRATION