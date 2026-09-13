---
created: 2026-08-04 02:54:18
tags: [engram, decision]
engram_id: 2491
type: decision
---

# Plan de corrección: 11 subagentes faltantes - Especificaciones

**What**: Identificados 11 subagentes declarados en opencode.json que NO tienen archivos .md en .opencode/agents/

**Agentes faltantes (11):**
1. maintenance-agent - Cleanup, optimization, health monitoring (línea 123-134)
2. gitflow-agent - Branch management, PR automation, git workflows (línea 135-146)
3. self-diag-agent - Auto-debug and break-glass recovery (línea 147-158)
4. knowledge-agent - Knowledge base operations and vault management (línea 159-170)
5. mkt-agent - Marketing content, campaigns, brand (línea 171-182)
6. sales-agent - Pipeline, outreach, deals (línea 183-194)
7. finance-agent - Financial analysis, modeling (línea 195-206)
8. hr-agent - Hiring, onboarding, people ops (línea 207-218)
9. legal-agent - Compliance, contracts (línea 219-230)
10. bus-tele-agent - Business telemetry, metrics (línea 231-242)
11. sia-agent - Self-improving agent, iterative refinement (línea 243-254)

**Agentes existentes (10):**
doc-agent, gov-agent, ops-agent, orchestrator, premortem-agent, sdd-apply, sdd-design, sdd-explore, sdd-verify, session-agent

**Formato requerido .md:**
Cada archivo debe seguir el patrón:

```
# Nombre Agente

## Role
Descripción del rol

## Capabilities
- Lista de capacidades

## Usage
Cuándo activar este agente

## Guidelines
Pautas específicas
```

**Where**: .opencode/agents/{agent-name}.md
**Priority**: HIGH para Gobierno y Queue Management
**Impact**: Los agentes funcionan sin .md (config en opencode.json), pero falta documentación para skill routing

---
*Imported from Engram on 2026-09-06*
