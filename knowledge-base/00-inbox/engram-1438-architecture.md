---
created: 2026-06-18 13:40:16
tags: [engram, architecture]
engram_id: 1438
type: architecture
---

# Dashboard integration: scripts, pipeline, skill, docs, auto-recovery

**What**: Integrated the React LLM observability dashboard fully into the Gentle-Vanguard stack. Created 3 PowerShell scripts in `scripts/utilities/dashboard/` (dashboard-ws-autostart.ps1 with watchdog, dashboard-start.ps1 for full launch, dashboard-stop.ps1 for cleanup), updated session-autostart.config.json to deprecate old dashboard-render and live-feed-start steps, added new lazy dashboard-ws-start step, rewrote SKILL.md for the React/TS/WebSocket architecture v2, updated AGENTS.md with lifecycle/auto-recovery docs, and updated dashboard-launcher.ps1 (v2) to make React dashboard the default option.

**Why**: The old HTML/JS dashboard (server.js/app.js) was superseded by the React/Vite/TypeScript LLM observability dashboard. The pipeline needed to auto-start the WS server with watchdog, and all documentation needed updating to avoid confusion.

**Where**: scripts/utilities/dashboard/dashboard-{ws-autostart,start,stop}.ps1, config/session-autostart.config.json, .opencode/skills/dashboard/SKILL.md, AGENTS.md, scripts/dashboard-launcher.ps1

**Learned**:
- `stack-dashboard.ps1` is about orchestrator health/token budget (console) and should NOT be deprecated — it's a complementary concern to the React dashboard
- The WS server starts in ~3s, build takes ~3s, no overhead concerns for pipeline
- Watchdog monitors both process existence AND port openness (Test-NetConnection localhost:8080) for reliable recovery detection
- HTTP polling fallback in useMetrics.ts works even when WS server is stopped — verified by previous stand-alone test

---
*Imported from Engram on 2026-09-06*
