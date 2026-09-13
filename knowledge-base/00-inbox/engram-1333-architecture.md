---
created: 2026-06-04 17:34:39
tags: [engram, architecture]
engram_id: 1333
type: architecture
---

# Fase 1 CopilotKit completada — Bridge MCP→Dashboard

**What**: Completada Fase 1 (Fundación) de adopción nativa de patrones CopilotKit sobre MCP. Implementados: schema ui_hints v1, MCP Bridge Server (spawn stdio→JSON-RPC), WebSocket extendido con canales de agente, hooks useAgentStream, componentes AgentMessage/AgentChat, ruta /agents, sección Agent Activity en Dashboard.

**Why**: Dashboard web pasa de solo monitoreo a interfaz interactiva de agentes con streaming en vivo, como fue planificado en docs/plans/COPILOTKIT-ANALYSIS-AND-ADOPTION-PLAN.md

**Where**:
- apps/web-dashboard/src/types/agent.ts (ui_hints v1 schema, tipos AgentMessage/ToolCall/Session)
- apps/web-dashboard/server/mcp-bridge.ts (bridge subproceso stdio)
- apps/web-dashboard/server/websocket-server.ts (canales agente + HTTP /api/agent/*)
- apps/web-dashboard/src/hooks/useAgentStream.ts (hook React)
- apps/web-dashboard/src/components/AgentMessage.tsx (tool calls expandibles, ui_hints rendering)
- apps/web-dashboard/src/components/AgentChat.tsx (input @mentions, panel sesiones/tools)
- apps/web-dashboard/src/components/Dashboard.tsx (sección Agent Activity)
- apps/web-dashboard/src/App.tsx (ruta /agents + nav)

**Learned**: MCP SDK v2 usa stdio transport con JSON-RPC. El bridge spawn el skill-server.ts como child process y parsea las líneas stdout para comunicación bidireccional. TSC no incluye server/ por defecto (tsconfig solo cubre src/). Build exitoso con vite, zero TS errors.

---
*Imported from Engram on 2026-09-06*
