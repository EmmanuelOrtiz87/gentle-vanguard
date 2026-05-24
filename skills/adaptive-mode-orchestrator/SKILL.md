---
name: adaptive-mode-orchestrator
description: >
  Adaptive Mode Mejorado - Orquestacin inteligente con DAG dinmico, feedback loops automticos y
  rollback inteligente. Coordina mltiples agentes con dependencias reales, permite ciclos de
  retroalimentacin (QA  DEV  QA) y ejecuta rollback automtico ante fallos crticos.
license: Apache-2.0
metadata:
  author: gentle-vanguard
  versión: '1.0'
  status: 'ACTIVE'
  priority: 'CRITICAL'
---

# ADAPTIVE MODE ORCHESTRATOR SKILL

## Descripcin General

El **Adaptive Mode Orchestrator** es un sistema de orquestacin inteligente que:

1. **Analiza dependencias reales** entre agentes (BA SAD DEV QA OPS)
2. **Crea fases dinmicas** basadas en un DAG (Directed Acyclic Graph)
3. **Permite feedback loops** automticos (QA DEV QA, GOV DEV)
4. **Implementa rollback automtico** cuando QA o GOV fallan
5. **Ejecuta en modo automtico** sin intervencin manual
6. **Monitorea y adapta** el flujo en tiempo real

## Caractersticas Principales

### DAG-Based Orchestration

- Anlisis automtico de dependencias entre agentes
- Ejecucin topolgicamente ordenada
- Paralelizacin inteligente donde es posible

### Feedback Loops

- **QA DEV**: Fallos de prueba disparan rework de desarrollo
- **QA SAD**: Problemas de arquitectura disparan revisión de diseo
- **GOV DEV**: Problemas de seguridad disparan fixes de cdigo
- Mximo de iteraciones configurable por loop

### Auto-Rollback

- Rollback automtico ante fallos crticos
- Checkpoints automticos despus de cada fase
- Preservacin de artefactos durante rollback
- Mltiples intentos de rollback configurables

### Ejecucin Automtica

- Deteccin automtica de fases completadas
- Transicin automtica entre fases
- decisiónes automticas basadas en mtricas
- Sin intervencin manual requerida

### Monitoreo en Tiempo Real

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

---

> **Referencia detallada**: [eferences/detail.md](references/detail.md)