---
created: 2026-09-08 22:15:48
tags: [engram, bugfix]
engram_id: 3793
type: bugfix
---

# Analytics AI panel: fixed stale server, CORS, panel-analysis wiring

**What**: Fixed gv-analytics AI config panel end-to-end. (1) Stale server on :4754 didn't have the `opencode` case in llm-config.ts — restarting fixed "Provider no soportado". (2) Added CORS/OPTIONS handling (applyCors, dev origins 5173/5174) in server/index.ts. (3) Rewrote LLMConfigPanel.tsx: relative URLs, per-provider help section (PROVIDER_HELP), pre-test validation, missing baseUrl field for custom provider, default provider now opencode. (4) Wired panel config into real analysis: llm-client.ts gained configureUserLLM() (max priority over cloud-agents.json/env/opencode fallback) + fixed Anthropic header (x-api-key + anthropic-version, was wrongly Bearer); /api/analyze accepts `llm` in body; App.tsx getSavedLLMConfig() sends saved localStorage config only when enabled=true.
**Why**: User couldn't connect any model from the AI config panel; "Detectar configuración del stack" errored; panel config was decorative (localStorage only, never consumed by analyses).
**Where**: apps/gv-analytics/server/index.ts, server/llm-client.ts, server/routes/llm-config.ts, src/components/LLMConfigPanel.tsx(+css), src/App.tsx
**Learned**: cloud-agents.local.json has provider `custom` enabled but env var `agent_custom_apikey` is NOT set → llm-client silently falls back to opencode CLI (analyses show "heurístico local" only if opencode also fails). Server must be restarted (node --import tsx server/index.ts) after editing server code — tsx does not hot-reload. Verified: /api/llm/test opencode success, CORS preflight 204, tsc exit 0, vite build exit 0.

---
*Imported from Engram on 2026-09-08*
