---
name: adaptive-mode-orchestrator
description: >
  Adaptive Mode Mejorado - Orquestación inteligente con DAG dinámico, feedback loops automáticos
  y rollback inteligente. Coordina múltiples agentes con dependencias reales, permite ciclos
  de retroalimentación (QA → DEV → QA) y ejecuta rollback automático ante fallos críticos.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
  status: "ACTIVE"
  priority: "CRITICAL"
---

# ADAPTIVE MODE ORCHESTRATOR SKILL

## Descripción General

El **Adaptive Mode Orchestrator** es un sistema de orquestación inteligente que:

1. **Analiza dependencias reales** entre agentes (BA → SAD → DEV → QA → OPS)
2. **Crea fases dinámicas** basadas en un DAG (Directed Acyclic Graph)
3. **Permite feedback loops** automáticos (QA → DEV → QA, GOV → DEV)
4. **Implementa rollback automático** cuando QA o GOV fallan
5. **Ejecuta en modo automático** sin intervención manual
6. **Monitorea y adapta** el flujo en tiempo real

## Características Principales

### 🎯 DAG-Based Orchestration
- Análisis automático de dependencias entre agentes
- Ejecución topológicamente ordenada
- Paralelización inteligente donde es posible

### 🔄 Feedback Loops
- **QA → DEV**: Fallos de prueba disparan rework de desarrollo
- **QA → SAD**: Problemas de arquitectura disparan revisión de diseño
- **GOV → DEV**: Problemas de seguridad disparan fixes de código
- Máximo de iteraciones configurable por loop

### 🔙 Auto-Rollback
- Rollback automático ante fallos críticos
- Checkpoints automáticos después de cada fase
- Preservación de artefactos durante rollback
- Múltiples intentos de rollback configurables

### ⚡ Ejecución Automática
- Detección automática de fases completadas
- Transición automática entre fases
- Decisiones automáticas basadas en métricas
- Sin intervención manual requerida

### 📊 Monitoreo en Tiempo Real
- Métricas de ejecución por agente
- Tracking de feedback loops
- Logs detallados de rollbacks
- Dashboard de estado

## Flujo de Ejecución

```
PLANNING (BA)
    ↓
DESIGN (SAD)
    ↓
IMPLEMENTATION (DEV)
    ├─→ GOVERNANCE (GOV) [paralelo]
    └─→ DOCUMENTATION (DOC) [paralelo]
    ↓
QUALITY_ASSURANCE (QA)
    ├─ Si falla → FEEDBACK LOOP → IMPLEMENTATION
    ├─ Si falla seguridad → FEEDBACK LOOP → GOVERNANCE
    └─ Si pasa → DEPLOYMENT
    ↓
DEPLOYMENT (OPS)
    ├─ Si falla → AUTO-ROLLBACK
    └─ Si pasa → COMPLETE
```

## Configuración

### Archivo: `config/adaptive-dag-config.json`

```json
{
  "version": "1.0",
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
# Ejecutar orquestación adaptativa
.\skills\adaptive-mode-orchestrator\adaptive-mode-engine.ps1

# Con configuración personalizada
.\skills\adaptive-mode-orchestrator\adaptive-mode-engine.ps1 `
  -ConfigPath "config/adaptive-dag-config.json" `
  -TaskDescription "Implementar feature de autenticación"

# Modo dry-run (sin ejecutar)
.\skills\adaptive-mode-orchestrator\adaptive-mode-engine.ps1 -DryRun
```

### Desde el Orquestador Principal

```powershell
# El orquestador detectará automáticamente cuando usar Adaptive Mode
# y lo ejecutará sin intervención manual
```

## Feedback Loops en Detalle

### QA → DEV Loop

```
1. QA ejecuta pruebas
2. Si pruebas fallan:
   - Registra errores
   - Dispara feedback loop
   - DEV recibe notificación
   - DEV corrige código
   - Vuelve a QA (máx 3 iteraciones)
3. Si pruebas pasan:
   - Continúa a siguiente fase
```

### GOV → DEV Loop

```
1. GOV revisa seguridad
2. Si encuentra vulnerabilidades:
   - Registra problemas
   - Dispara feedback loop
   - DEV corrige código
   - Vuelve a GOV (máx 2 iteraciones)
3. Si pasa revisión:
   - Continúa a deployment
```

## Rollback Automático

### Triggers de Rollback

- `critical_test_failure`: Fallo crítico en pruebas
- `security_vulnerability`: Vulnerabilidad de seguridad
- `performance_degradation`: Degradación de rendimiento
- `deployment_failure`: Fallo en deployment

### Proceso de Rollback

```
1. Detectar fallo crítico
2. Obtener último checkpoint válido
3. Restaurar estado anterior
4. Preservar artefactos
5. Registrar rollback en log
6. Permitir reintentos (máx 2)
```

## Métricas y Monitoreo

### Métricas Capturadas

- Tiempo de ejecución por fase
- Tasa de éxito de pruebas
- Número de feedback loops activados
- Número de rollbacks ejecutados
- Cobertura de código
- Vulnerabilidades encontradas

### Logs

- `logs/adaptive-mode.log` - Log detallado de ejecución
- `logs/adaptive-mode-metrics.json` - Métricas en JSON

## Integración con Orquestador

El Adaptive Mode se integra automáticamente con el orquestador principal:

1. **Auto-Detection**: El orquestador detecta cuando usar Adaptive Mode
2. **Auto-Execution**: Se ejecuta sin intervención manual
3. **Auto-Reporting**: Genera reportes automáticos
4. **Auto-Escalation**: Escala a intervención manual si es necesario

## Decisiones Automáticas

### After QA

```
if qa_pass_rate >= 95 AND code_coverage >= 80:
  → Proceder a deployment
else:
  → Activar feedback loop QA → DEV
```

### After GOV

```
if security_issues == 0 AND compliance_check == true:
  → Proceder a deployment
else:
  → Activar feedback loop GOV → DEV
```

### After Deployment

```
if deployment_success == true AND health_check == true:
  → Marcar como completado
else:
  → Activar auto-rollback
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

✅ **Automatización Completa**: Sin intervención manual
✅ **Inteligencia Adaptativa**: Se adapta a resultados
✅ **Feedback Loops**: Ciclos automáticos de mejora
✅ **Rollback Seguro**: Recuperación automática ante fallos
✅ **Monitoreo Real-time**: Visibilidad completa
✅ **Escalabilidad**: Maneja múltiples agentes
✅ **Confiabilidad**: Checkpoints y recuperación

## Casos de Uso

### 1. Feature Development
```
BA → SAD → DEV → QA → OPS
Con feedback loops automáticos si QA falla
```

### 2. Bug Fixes
```
DEV → QA → OPS
Con rollback automático si deployment falla
```

### 3. Security Patches
```
DEV → GOV → QA → OPS
Con rollback automático si seguridad falla
```

## Troubleshooting

### Problema: Feedback loop infinito
**Solución**: Aumentar `max_iterations` en configuración

### Problema: Rollback no se ejecuta
**Solución**: Verificar `rollback_policy.enabled` en config

### Problema: Fases se saltan
**Solución**: Verificar dependencias en DAG

## Referencias

- Configuración: `config/adaptive-dag-config.json`
- Motor: `skills/adaptive-mode-orchestrator/adaptive-mode-engine.ps1`
- Orquestador Principal: `skills/project-orchestrator-skill/SKILL.md`
- Auto-Delegation: `skills/auto-delegation-router/SKILL.md`

---

**Estado**: ACTIVE
**Versión**: 1.0
**Última actualización**: 2026-04-23