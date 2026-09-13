---
created: 2026-07-25 00:59:58
tags: [engram, decision]
engram_id: 1958
type: decision
---

# Token budget consolidation — single source of truth

**What**: Consolidated all token budget configurations into a single source of truth: config/token-budget-guard.json v2.0.0

**Why**: Previously there were 3+ inconsistent configs (orchestrator.json: 30K, token-budget-guard.json: 30K, token-budget-limits.json: 500K, timeout-config.json: 30K). This caused false HARD_LIMIT alerts (141%) due to stale CSV counters and conflicting values.

**Where**: config/token-budget-guard.json (v2.0.0), config/token-budget-limits.json (DEPRECATED), config/orchestrator.json, config/timeout-config.json, src/token-budget-guard.ts, apps/web-dashboard/server/websocket-server.ts

**Learned**:
- token-budget-guard.ts now reads from token-budget-guard.json first (Priority 1), falls back to orchestrator.json (Priority 2)
- Dashboard health API now has 9th component "budget" exposing dailyLimit, perSessionLimit, perAgentLimit, usedToday, usedPercent, softThreshold, hardThreshold
- CSV counter was reset (was 42K from dev runs, now 3200 = 3%)
- Agent limits synced with opencode.json#agent config

---
*Imported from Engram on 2026-09-06*
