---
created: 2026-08-15 04:07:55
tags: [engram, architecture]
engram_id: 2849
type: architecture
---

# FF-019 completado: 5 patrones CopilotKit nativos sobre MCP

**What**: FF-019 completado al 100% — los 5 patrones CopilotKit nativos sobre MCP implementados en 4 fases. Commits 4f1ce19e, f8896972, 3a5e699f.
**Why**: El usuario pidió avanzar con todo lo pendiente del plan; FF-019 era el único item backlog accionable.
**Where**:
- Fase 1 (commit 4f1ce19e): AG-UI hints + streaming por chunks (websocket-server.ts extractUiHints/extractChunks, useAgentStream.ts)
- Fase 2 (commit f8896972): shared-state-bridge.ts (subscribeByTask/getTask, state_delta/task_delta, persistencia Nexus tabla events best-effort, getPersistedEvents), endpoint GET /api/state/events/persisted, useSharedState.ts
- Fase 3 (commit f8896972): types/agent.ts (HitlKind/HitlRequest/HitlResponse con timedOut), HitlModal.tsx 4 vistas + timeout auto-resolve (9 tests), websocket-server.ts hitlTimeouts/scheduleHitlTimeout/cancelHitlTimeout
- Fase 4 (commit f8896972): cancel action (activeSkillExecutions Map + AbortController), list_skills/search_skills (handleSkillListing + ListHint clicable), streaming cursor CSS, botones Cancel/Skills en AgentChat.tsx, agent-command-utils.ts (7 tests) + AgentMessage.test.tsx (4 tests)
- docs/plans/COPILOTKIT-ANALYSIS-AND-ADOPTION-PLAN.md: 4 fases marcadas completadas + contratos documentados
- docs/backlog/items.json: FF-019 status=done
**Learned**:
1. El task tool con subagentes custom funciona perfectamente tras el fix kimi-2-5: sdd-apply implementó Fases 1-4 y sdd-verify verificó cada una (QA 5/5, 5/5, 4/4 gates).
2. QA final: build dashboard 0 errores (2082 módulos), 52/52 tests vitest, typecheck 0, lint 0, prettier OK, secret scanner 0 matches.
3. El guard TS real del dashboard es `cd apps/web-dashboard && npm run build` (tsconfig raíz NO cubre apps/web-dashboard).
4. Patrón de delegación efectivo: sdd-apply implementa + sdd-verify verifica + commit por fase + backlog actualizado.
5. El contrato de deltas: state_delta {delta, since} nuevo→viejo (consumidor usa [...delta, ...prev]); task_delta {taskId, from, to, at}.

---
*Imported from Engram on 2026-09-06*
