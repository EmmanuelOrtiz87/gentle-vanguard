---
created: 2026-08-15 02:43:02
tags: [engram, architecture]
engram_id: 2841
type: architecture
---

# FF-019 Fase 1: CopilotKit patterns as native MCP features

**What**: Implementada Fase 1 de FF-019 (Adopción Nativa de Patrones CopilotKit sobre MCP). Creado docs/plans/COPILOTKIT-ANALYSIS-AND-ADOPTION-PLAN.md (documento faltante referenciado en docs/backlog/items.json) con resumen ejecutivo, 5 patrones, matriz de decisiones, riesgos y roadmap de 4 fases.

**Why**: El plan file estaba referenciado pero no existía; executeSkillAndStream hacía streaming simulado y no parseaba ui_hints de respuestas MCP (AG-UI pattern 2 roto).

**Where**:
- docs/plans/COPILOTKIT-ANALYSIS-AND-ADOPTION-PLAN.md (nuevo)
- apps/web-dashboard/server/websocket-server.ts — executeSkillAndStream (línea ~319): ahora parsea ui_hints/uiHint → msg.uiHints, broadcast agent_ui_hints, emite agent_stream_chunk por cada chunk de stream/chunks con delay 50ms antes del mensaje final. Helpers nuevos: extractUiHints(), extractChunks().
- apps/web-dashboard/src/hooks/useAgentStream.ts — casos nuevos agent_ui_hints y agent_stream_chunk (acumula chunks en content, streaming:true).

**Learned**:
- executeSkillAndStream usa broadcastToSession (no ws.send directo) — los mensajes van a suscriptores de la sesión.
- El chunk handler del frontend reemplaza el content inicial "Ejecutando skill..." con startsWith() antes de acumular.
- La decisión clave: NO integrar CopilotKit como dependencia (desajuste LangGraph/CrewAI vs MCP/TS, churn 1369 releases).
- Verificación pasó: dashboard build (tsc + vite build), typecheck root, lint root y dashboard, prettier.

---
*Imported from Engram on 2026-09-06*
