# Análisis y Plan de Adopción de Patrones CopilotKit sobre MCP

| Campo       | Valor                                                     |
| ----------- | --------------------------------------------------------- |
| **Backlog** | FF-019 — Adopción Nativa de Patrones CopilotKit sobre MCP |
| **Estado**  | Plan aprobado — Fase 1 en implementación                  |
| **Fecha**   | 2026-08-14                                                |
| **Owner**   | orchestrator                                              |

---

## Resumen Ejecutivo

**Decisión: NO integrar CopilotKit como dependencia.** Se adoptan sus patrones validados como
implementación nativa sobre el protocolo MCP del stack.

La evaluación completa de CopilotKit (32k ⭐, MIT, ~1,369 releases) concluyó que existe un desajuste
arquitectónico fundamental:

| Criterio            | CopilotKit                          | Gentle-Vanguard                   |
| ------------------- | ----------------------------------- | --------------------------------- |
| Orquestación        | LangGraph / CrewAI (Python-centric) | MCP / TypeScript nativo           |
| Runtime             | React hooks + backend Python        | WebSocket + MCP bridge + React    |
| Modelo de streaming | SDK propietario                     | JSON-RPC sobre MCP                |
| Churn               | 1,369 releases (API inestable)      | Stack estable, versionado interno |

Integrar CopilotKit implicaría arrastrar un runtime Python, un SDK React con API cambiante y una
capa de abstracción que duplica la infraestructura MCP ya existente. En cambio, los **5 patrones**
que CopilotKit validó en producción (streaming de agente, AG-UI hints, shared state,
human-in-the-loop y chat interface) se implementan como features nativas de GV sobre el protocolo
MCP existente.

**GV ya tiene ~60% de la infraestructura lista** (WebSocket, MCP bridge, React, event-bus). Este
plan cierra los gaps restantes en 4 fases graduales, sin dependencias externas.

---

## Los 5 Patrones — Estado Actual y Gaps

### Patrón 1: Bridge MCP↔Dashboard + Streaming de Agente

**Qué existe**:

- `apps/web-dashboard/server/mcp-bridge.ts` — `MCPBridge` spawnea `scripts/mcp/skill-server.ts`,
  implementa JSON-RPC request/response (`request`, `callTool`), retry con backoff exponencial (5
  reintentos, 1s→30s) y auto-restart.
- `apps/web-dashboard/server/websocket-server.ts` — `executeSkillAndStream` (línea 303) ejecuta
  `bridge.callTool('execute_skill', ...)` y hace broadcast del resultado.

**Qué falta**:

- El streaming es **simulado**: `executeSkillAndStream` hace request/response bloqueante, espera el
  resultado completo y solo entonces hace broadcast. El flag `streaming: true` es decorativo.
- No hay emisión incremental de chunks de texto hacia el frontend.

**Gap a cerrar (Fase 1)**: parsear `stream`/`chunks` de la respuesta MCP y emitir
`agent_stream_chunk` por cada chunk con delay de 50ms antes del mensaje final.

---

### Patrón 2: AG-UI Hints (ui_hints schema en respuestas MCP)

**Qué existe**:

- `apps/web-dashboard/src/types/agent.ts` — tipos `UIHint`, `UIFormField`, `UISeries`,
  `UI_HINTS_SCHEMA_VERSION = '1.0.0'`, y `AgentMessage.uiHints?: UIHint[]`.
- `apps/web-dashboard/src/components/AgentMessage.tsx` (línea 436) — renderiza `message.uiHints` con
  `UIHintBadge` y soporta `onFormAction`.

**Qué falta**:

- `executeSkillAndStream` **no parsea** `ui_hints` de la respuesta MCP → `msg.uiHints` nunca se
  puebla. El patrón AG-UI está roto en el servidor.

**Gap a cerrar (Fase 1)**: inspeccionar el resultado de `callTool('execute_skill')`, convertir
`ui_hints` (array) o `uiHint` (objeto) a `UIHint[]`, asignarlo a `msg.uiHints` y broadcast de un
mensaje `agent_ui_hints` separado para renderizado independiente.

---

### Patrón 3: Shared State event-bus↔dashboard

**Qué existe**:

- `apps/web-dashboard/server/shared-state-bridge.ts` — `SharedStateBridge` hace poll de
  `.event-bus/history.json`, emite `agent.dispatched`/`agent.completed`, y expone `emitEvent`,
  `tasks`, `on('history_update'|'task_update'|'event')`.
- `websocket-server.ts` — `initSharedState()` conecta el bridge a broadcasts `state_history`,
  `state_tasks`, `state_event`; endpoints `/api/state/events`, `/api/state/tasks`,
  `/api/state/emit`.

**Estado**: ✅ **Completo**. No requiere trabajo en Fase 1.

---

### Patrón 4: Human-in-the-Loop UI

**Qué existe**:

- `apps/web-dashboard/src/components/HitlModal.tsx` — modal de aprobación/confirmación.
- `websocket-server.ts` — `hitl_request` / `hitl_response` / `hitl_resolved` en `handleAgentCommand`
  (líneas 232-241, 272-282) y detección de intención (`approve`, `confirm`, `delegate`, `revisar`).
- `apps/web-dashboard/src/hooks/useAgentStream.ts` — maneja `hitl_request`/`hitl_resolved`.

**Estado**: ✅ **Completo** (básico). Mejoras opcionales en Fase 3 (tipos de HITL: selection, form,
review).

---

### Patrón 5: Agent Chat Interface

**Qué existe**:

- `apps/web-dashboard/src/components/AgentChat.tsx` — ruta `/agents`, chat con sesiones, tools,
  historial, agentes DEV/QA/BA/GOV/OPS/DOC.
- `websocket-server.ts` — `handleAgentCommand` (create_session, subscribe, list_sessions,
  list_history, get_session, list_tools, execute_skill, emit_event, hitl_response, send_message).
- `apps/web-dashboard/src/hooks/useAgentStream.ts` — hook de estado del chat.

**Estado**: ✅ **Completo** (básico). Mejoras en Fase 4 (cancelación, búsqueda de skills, UI de
streaming refinada).

---

## Matriz de Decisiones

| Decisión                             | Opción A                  | Opción B                              | Decisión | Justificación                                                                           |
| ------------------------------------ | ------------------------- | ------------------------------------- | -------- | --------------------------------------------------------------------------------------- |
| Integrar CopilotKit como dependencia | Sí (npm + Python runtime) | **No — patrones nativos**             | **B**    | Desajuste LangGraph/CrewAI vs MCP/TS; churn 1,369 releases; duplica infra MCP existente |
| Streaming de agente                  | SDK propietario           | **Chunks JSON-RPC sobre MCP**         | **B**    | Reutiliza `MCPBridge`; protocolo ya establecido                                         |
| UI generativa                        | AG-UI SDK                 | **Schema `ui_hints` propio (v1.0.0)** | **B**    | Tipos `UIHint` ya existen en `types/agent.ts`                                           |
| Estado compartido                    | CopilotKit state          | **event-bus + SharedStateBridge**     | **B**    | Bridge ya implementado y operativo                                                      |
| HITL                                 | CopilotKit HITL           | **hitl_request/response nativo**      | **B**    | Modal + protocolo WS ya implementados                                                   |

---

## Riesgos

| Riesgo                                              | Probabilidad | Impacto | Mitigación                                                                                          |
| --------------------------------------------------- | ------------ | ------- | --------------------------------------------------------------------------------------------------- |
| Skills MCP no devuelven `ui_hints`/`chunks` aún     | Alta         | Bajo    | Parseo defensivo: si no hay hints/chunks, comportamiento actual intacto (try/catch robusto)         |
| Chunks con delay 50ms generan orden no determinista | Media        | Bajo    | Broadcast secuencial con `setTimeout` encadenado; mensaje final siempre después de todos los chunks |
| `ui_hints` con schema inválido rompe el render      | Media        | Medio   | Conversión defensiva a `UIHint[]`; frontend ya tolera hints vacíos                                  |
| Backpressure de WebSocket con muchos chunks         | Baja         | Medio   | Chunks limitados al array `stream`/`chunks` de la respuesta; delay 50ms regula el flujo             |
| Regresión en `executeSkillAndStream`                | Baja         | Alto    | try/catch que preserva el flujo actual si no hay hints/chunks; verificación con build + typecheck   |

---

## Roadmap en 4 Fases

### Fase 1 — Streaming real + AG-UI Hints (patrones 1 y 2) ✅ EN CURSO

- [x] Crear este plan (`docs/plans/COPILOTKIT-ANALYSIS-AND-ADOPTION-PLAN.md`)
- [ ] `websocket-server.ts` `executeSkillAndStream`: parsear `ui_hints`/`uiHint` → `msg.uiHints`
- [ ] Broadcast `agent_ui_hints` separado
- [ ] Emitir `agent_stream_chunk` por cada chunk de `stream`/`chunks` (delay 50ms)
- [ ] Frontend: manejar `agent_ui_hints` y `agent_stream_chunk` en `useAgentStream.ts`
- [ ] Verificación: `cd apps/web-dashboard && npm run build`, `npm run typecheck`, `npm run lint`

### Fase 2 — Shared State avanzado (patrón 3)

- [ ] Enriquecer `SharedStateBridge` con suscripciones por tarea
- [ ] Broadcast de deltas de estado (no solo snapshots)
- [ ] Persistencia de historial de eventos en Nexus

### Fase 3 — HITL avanzado (patrón 4)

- [ ] Tipos de HITL: `selection`, `form`, `review` (además de `confirmation`)
- [ ] `HitlModal` con formularios dinámicos desde `UIFormField`
- [ ] Timeout de HITL con resolución automática

### Fase 4 — Chat Interface refinada (patrón 5)

- [ ] Acción `cancel` para interrumpir ejecución de skill
- [ ] Búsqueda de skills desde el chat (`list_skills`, `search_skills`)
- [ ] UI de streaming refinada (cursor, chunks acumulados)

---

## Referencias a Archivos

| Archivo                                              | Rol                                                                                    |
| ---------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `apps/web-dashboard/server/mcp-bridge.ts`            | Bridge MCP (spawn skill-server, JSON-RPC, retry backoff)                               |
| `apps/web-dashboard/server/shared-state-bridge.ts`   | Shared State Bridge (poll event-bus, agent.dispatched/completed)                       |
| `apps/web-dashboard/server/websocket-server.ts`      | WS server: `handleAgentCommand`, `executeSkillAndStream` (línea 303), HITL, broadcasts |
| `apps/web-dashboard/src/types/agent.ts`              | `UIHint`, `AgentStreamChunk`, `AgentCommand`, `UI_HINTS_SCHEMA_VERSION`                |
| `apps/web-dashboard/src/hooks/useAgentStream.ts`     | Hook de estado del chat (WS → React state)                                             |
| `apps/web-dashboard/src/components/AgentChat.tsx`    | Chat interface (ruta `/agents`)                                                        |
| `apps/web-dashboard/src/components/AgentMessage.tsx` | Render de mensajes + `uiHints` + tool calls                                            |
| `apps/web-dashboard/src/components/HitlModal.tsx`    | Modal Human-in-the-Loop                                                                |
| `scripts/mcp/skill-server.ts`                        | Servidor MCP (tools: `execute_skill`, `search_skills`, etc.)                           |
| `docs/backlog/items.json`                            | Backlog item FF-019                                                                    |
