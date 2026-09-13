---
created: 2026-07-06 11:56:38
tags: [engram, architecture]
engram_id: 1480
type: architecture
---

# v4.1 Complete: Real-time alerts, auto-compaction, predictive monitoring, incremental embeddings

**What**: Implemented all 4 components of Gentle-Vanguard v4.1 — Dashboard real-time alerts via WebSocket, Engram auto-compaction with 90-day TTL, Watchtower predictive monitoring with time-series trends, and ML skill embeddings incremental updates.

**Why**: v4.0 was reactive-only. v4.1 adds intelligence: real-time alert broadcast, automatic memory pruning, failure prediction, and efficient incremental embedding updates.

**Where**:
- `apps/web-dashboard/src/components/AlertPanel.tsx` — NEW: Dedicated alert component
- `apps/web-dashboard/src/hooks/useAlerts.ts` — Modified: WebSocket instead of HTTP polling
- `apps/web-dashboard/server/websocket-server.ts` — Modified: Alert broadcast + state tracking + transitions
- `apps/web-dashboard/src/components/Dashboard.tsx` — Modified: Uses AlertPanel component
- `scripts/utilities/memory/ENGRAM/engram-auto-compact.ps1` — NEW: 90-day TTL, safety limits, DryRun
- `scripts/utilities/monitoring/PREDICTIVE/watchtower-trends.ps1` — NEW: record/trend/predict/report
- `scripts/utilities/agents/AUTO-DELEGATION/skill-embedder-incremental.ps1` — NEW: Change detection, metadata tracking
- `config/session-autostart.config.json` — Modified: Added engram-auto-compact + ml-embeddings-incremental steps

**Learned**:
- Dashboard alerts now broadcast via WebSocket every 5s with transition detection (fired/resolved)
- Engram auto-compact skips if <100 observations or last compact <24h, never deletes >30% of total
- Watchtower trends stores history in .telemetry/watchtower-history.jsonl for time-series analysis
- ML incremental falls back to full rebuild if >50% skills changed
- Build passes: tsc + vite build, 2194 modules, 0 errors
- Watchtower: 73 PASS / 2 WARN / 0 FAIL (non-critical WARNs from tracing prometheus + engram reindex freshness)

---
*Imported from Engram on 2026-09-06*
