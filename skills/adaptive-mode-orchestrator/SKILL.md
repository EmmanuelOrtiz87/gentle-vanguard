---
name: adaptive-mode-orchestrator
description: >
  Adaptive Mode Mejorado - Orquestacin inteligente con DAG dinmico, feedback loops automticos
  y rollback inteligente. Coordina mltiples agentes con dependencias reales, permite ciclos
  de retroalimentacin (QA  DEV  QA) y ejecuta rollback automtico ante fallos crticos.
license: Apache-2.0
metadata:
  author: gentleman-programming
  versión: "1.0"
  status: "ACTIVE"
  priority: "CRITICAL"
---

# ADAPTIVE MODE ORCHESTRATOR SKILL

## Descripcin General

El **Adaptive Mode Orchestrator** es un sistema de orquestacin inteligente que:

1. **Analiza dependencias reales** entre agentes (BA  SAD  DEV  QA  OPS)
2. **Crea fases dinmicas** basadas en un DAG (Directed Acyclic Graph)
3. **Permite feedback loops** automticos (QA  DEV  QA, GOV  DEV)
4. **Implementa rollback automtico** cuando QA o GOV fallan
5. **Ejecuta en modo automtico** sin intervencin manual
6. **Monitorea y adapta** el flujo en tiempo real

## Caractersticas Principales

###  DAG-Based Orchestration
- Anlisis automtico de dependencias entre agentes
- Ejecucin topolgicamente ordenada
- Paralelizacin inteligente donde es posible

###  Feedback Loops
- **QA  DEV**: Fallos de prueba disparan rework de desarrollo
- **QA  SAD**: Problemas de arquitectura disparan revisión de diseo
- **GOV  DEV**: Problemas de seguridad disparan fixes de cdigo
- Mximo de iteraciones configurable por loop

###  Auto-Rollback
- Rollback automtico ante fallos crticos
- Checkpoints automticos despus de cada fase
- Preservacin de artefactos durante rollback
- Mltiples intentos de rollback configurables

###  Ejecucin Automtica
- Deteccin automtica de fases completadas
- Transicin automtica entre fases
- decisiónes automticas basadas en mtricas
- Sin intervencin manual requerida

###  Monitoreo en Tiempo Real
- Mtricas de ejecucin por agente
- Tracking de feedback loops
- Logs detallados de rollbacks
- Dashboard de estado

## Flujo de Ejecucin

```
PLANNING (BA)
    
DESIGN (SAD)
    
IMPLEMENTATION (DEV)
     GOVERNANCE (GOV) [paralelo]
     DOCUMENTATION (DOC) [paralelo]
    
QUALITY_ASSURANCE (QA)
     Si falla  FEEDBACK LOOP  IMPLEMENTATION
     Si falla seguridad  FEEDBACK LOOP  GOVERNANCE
     Si pasa  DEPLOYMENT
    
DEPLOYMENT (OPS)
     Si falla  AUTO-ROLLBACK
     Si pasa  COMPLETE
```

## configuración

### archivo: `config/adaptive-dag-config.json`

```json
{
  "versión": "1.0",
  "enabled": true,
  "dag": {
    "agents": {
      "BA": { "name": "Business Analyst", "dependencies": [] },
      "SAD": { "name": "Solution Architect", "dependencies": ["BA"] },
      "DEV": { "name": "Developer", "dependencies": ["SAD"] },
      "QA": { "name": "QA Engineer", "dependencies": ["DEV"] },
      "OPS": { "name": "DevOps Engineer", "dependencies": ["QA"] },
      "GOV": { "name": "Governance", "dependencies": ["DEV", "QA"] },
      "DOC": { "name": "Documentation", "dependencies": ["DEV", "QA"] }
    },
    "feedback_loops": {
      "qa_to_dev": {
        "source": "QA",
        "target": "DEV",
        "trigger": "test_failure",
        "max_iterations": 3
      },
      "gov_to_dev": {
        "source": "GOV",
        "target": "DEV",
        "trigger": "security_issue",
        "max_iterations": 2
      }
    },
    "rollback_policy": {
      "enabled": true,
      "auto_rollback_on_qa_failure": true,
      "checkpoint_on_phase_complete": true
    }
  }
}
```

## Uso

### Iniciar Adaptive Mode

```powershell
# Ejecutar orquestacin adaptativa
.\skills\adaptive-mode-orchestrator\adaptive-mode-engine.ps1

# Con configuración personalizada
.\skills\adaptive-mode-orchestrator\adaptive-mode-engine.ps1 `
  -ConfigPath "config/adaptive-dag-config.json" `
  -TaskDescription "Implementar feature de autenticacin"

# Modo dry-run (sin ejecutar)
.\skills\adaptive-mode-orchestrator\adaptive-mode-engine.ps1 -DryRun
```

### Desde el Orquestador Principal

```powershell
# El orquestador detectar automticamente cuando usar Adaptive Mode
# y lo ejecutar sin intervencin manual
```

## Feedback Loops en Detalle

### QA  DEV Loop

```
1. QA ejecuta pruebas
2. Si pruebas fallan:
   - Registra errores
   - Dispara feedback loop
   - DEV recibe notificacin
   - DEV corrige cdigo
   - Vuelve a QA (mx 3 iteraciones)
3. Si pruebas pasan:
   - Contina a siguiente fase
```

### GOV  DEV Loop

```
1. GOV revisa seguridad
2. Si encuentra vulnerabilidades:
   - Registra problemas
   - Dispara feedback loop
   - DEV corrige cdigo
   - Vuelve a GOV (mx 2 iteraciones)
3. Si pasa revisión:
   - Contina a deployment
```

## Rollback Automtico

### Triggers de Rollback

- `critical_test_failure`: Fallo crtico en pruebas
- `security_vulnerability`: Vulnerabilidad de seguridad
- `performance_degradation`: Degradacin de rendimiento
- `deployment_failure`: Fallo en deployment

### proceso de Rollback

```
1. Detectar fallo crtico
2. Obtener ltimo checkpoint vlido
3. Restaurar estado anterior
4. Preservar artefactos
5. Registrar rollback en log
6. Permitir reintentos (mx 2)
```

## Mtricas y Monitoreo

### Mtricas Capturadas

- Tiempo de ejecucin por fase
- Tasa de xito de pruebas
- Nmero de feedback loops activados
- Nmero de rollbacks ejecutados
- Cobertura de cdigo
- Vulnerabilidades encontradas

### Logs

- `logs/adaptive-mode.log` - Log detallado de ejecucin
- `logs/adaptive-mode-metrics.json` - Mtricas en JSON

## Integracin con Orquestador

El Adaptive Mode se integra automticamente con el orquestador principal:

1. **Auto-Detection**: El orquestador detecta cuando usar Adaptive Mode
2. **Auto-Execution**: Se ejecuta sin intervencin manual
3. **Auto-Reporting**: Genera reportes automticos
4. **Auto-Escalation**: Escala a intervencin manual si es necesario

## decisiónes Automticas

### After QA

```
if qa_pass_rate >= 95 AND code_coverage >= 80:
   Proceder a deployment
else:
   Activar feedback loop QA  DEV
```

### After GOV

```
if security_issues == 0 AND compliance_check == true:
   Proceder a deployment
else:
   Activar feedback loop GOV  DEV
```

### After Deployment

```
if deployment_success == true AND health_check == true:
   Marcar como completado
else:
   Activar auto-rollback
```

## Umbrales Configurables

```json
{
  "thresholds": {
    "qa_pass_rate_min": 95,
    "code_coverage_min": 80,
    "security_issues_max": 0,
    "performance_degradation_max": 5,
    "timeout_buffer_percent": 10
  }
}
```

## Ventajas

 **automatización Completa**: Sin intervencin manual
 **Inteligencia Adaptativa**: Se adapta a resultados
 **Feedback Loops**: Ciclos automticos de mejora
 **Rollback Seguro**: Recuperacin automtica ante fallos
 **Monitoreo Real-time**: Visibilidad completa
 **Escalabilidad**: Maneja mltiples agentes
 **Confiabilidad**: Checkpoints y recuperacin

## Casos de Uso

### 1. Feature Development
```
BA  SAD  DEV  QA  OPS
Con feedback loops automticos si QA falla
```

### 2. Bug Fixes
```
DEV  QA  OPS
Con rollback automtico si deployment falla
```

### 3. Security Patches
```
DEV  GOV  QA  OPS
Con rollback automtico si seguridad falla
```

## Troubleshooting

### Problema: Feedback loop infinito
**Solucin**: Aumentar `max_iterations` en configuración

### Problema: Rollback no se ejecuta
**Solucin**: Verificar `rollback_policy.enabled` en config

### Problema: Fases se saltan
**Solucin**: Verificar dependencias en DAG

## Referencias

- configuración: `config/adaptive-dag-config.json`
- Motor: `skills/adaptive-mode-orchestrator/adaptive-mode-engine.ps1`
- Orquestador Principal: `skills/project-orchestrator-skill/SKILL.md`
- Auto-Delegation: `skills/auto-delegation-router/SKILL.md`

---

**Estado**: ACTIVE
**Versin**: 1.0
**ltima actualizacin**: 2026-04-23

