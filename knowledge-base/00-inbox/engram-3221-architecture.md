---
created: 2026-08-28 19:15:43
tags: [engram, architecture]
engram_id: 3221
type: architecture
---

# F2.2 survey: 261 archivos clasificados en 13 dominios (plan listo)

**What**: Relevamiento F2.2 completado y persistido en docs/plans/F2.2-SURVEY.md (commit 5a48c490). Clasificacion de los 261 archivos sueltos de src/ en 13 dominios: orchestration(32), ops(24), review(18), ml(22), security(16), sdd(4), infrastructure(14), monitor(16), tools(38), knowledge(18), integrations(12), resilience(14), misc(33). Incluye colisiones (auto-code-review vs autonomous-review, dashboard-*vs dashboard/, engram-* vs mcp/, skill-*vs skills/, codegraph-* vs mcp/, model-*vs core/, session-* vs core/) y orden de ejecucion por riesgo.
**Why**: Pendiente F2.2 de sesiones previas — reorganizar src/ por dominios con el playbook probado (CONTINUATION-STATE.md §3.1).
**Where**: docs/plans/F2.2-SURVEY.md
**Learned**: El relevamiento se hizo con el orchestrator directamente (big-pickle) porque el task tool de la plataforma tenia config stale en memoria (gpt-5.6-luna). La ejecucion de los movimientos debe esperar el restart de la sesion para que sdd-apply use big-pickle, o usar el agent-delegator (lee config/agents.json fresco).

---
*Imported from Engram on 2026-09-06*
