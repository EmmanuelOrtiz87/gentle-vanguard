---
created: 2026-08-15 02:46:56
tags: [engram, architecture]
engram_id: 2843
type: architecture
---

# FF-019 Fase 1: AG-UI hints + streaming MCP

**What**: FF-019 Fase 1 implementada: AG-UI hints + streaming real por chunks sobre MCP en el dashboard. Commits 4f1ce19e + 23793ea5.
**Why**: El usuario pidió avanzar con todo lo pendiente del plan; FF-019 era el único item backlog accionable (patrones CopilotKit nativos sobre MCP).
**Where**:
- `docs/plans/COPILOTKIT-ANALYSIS-AND-ADOPTION-PLAN.md` (nuevo, 193 líneas): 5 patrones con qué existe/qué falta, matriz de decisiones, riesgos, roadmap 4 fases
- `apps/web-dashboard/server/websocket-server.ts`: helpers extractUiHints()/extractChunks(); executeSkillAndStream parsea ui_hints → msg.uiHints + broadcast agent_ui_hints; emite agent_stream_chunk por chunk (delay 50ms escalonado) antes del mensaje final
- `apps/web-dashboard/src/hooks/useAgentStream.ts`: cases agent_ui_hints (adjunta hints) + agent_stream_chunk (acumula content, quita placeholder "Ejecutando skill")
- `docs/backlog/items.json`: FF-019 con phase_1_status=done + commit ref
**Learned**:
1. La infraestructura de FF-019 estaba ~60% lista: mcp-bridge.ts (JSON-RPC spawn), shared-state-bridge.ts (poll event-bus), AgentChat.tsx, HitlModal.tsx, tipos UIHint/AgentStreamChunk/AgentCommand ya existían. Faltaba: parseo de ui_hints en respuestas MCP + streaming incremental real + plan file.
2. El streaming anterior era request/response simulado (streaming:true pero sin chunks). Ahora emite chunks reales si el skill devuelve {stream:[...]} o {chunks:[...]}.
3. GOTCHA QA: el tsconfig raíz NO incluye apps/web-dashboard/** — el único guard TS real del dashboard es `npm run build` en apps/web-dashboard. CI debe usar dashboard:build.
4. El task tool ahora funciona con subagentes custom (sdd-apply, sdd-verify, doc-agent verificados) tras el fix kimi-2-5 → opencode/deepseek-v4-flash-free en la sesión anterior.
5. QA aprobó 5/5 sin regresiones (build 2082 módulos, typecheck 0, lint 0, prettier OK).

---
*Imported from Engram on 2026-09-06*
