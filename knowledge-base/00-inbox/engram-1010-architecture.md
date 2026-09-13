---
created: 2026-05-22 12:50:59
tags: [engram, architecture]
engram_id: 1010
type: architecture
---

# Dashboard enhancements: agent monitor, session detail, monthly history

**What**: Implemented 3 new dashboard sections, auto-restart mechanism, session ID format change, and collector enhancements

**Why**: User requested clearer session ID format, auto-restart after dashboard changes, and real-time monitoring screens for agent activity, accumulated session data, and monthly historical comparison

**Where**:
- `scripts/utilities/session-manager.ps1:247` — session ID format changed from `session-YYYY-MM-DD-NN` (cryptic counter) to `session-YYYY-MM-DD_HHMM` (time-based, self-explanatory)
- `scripts/metrics/dashboard-render.ps1` — added 3 sections: `#agent` (Live Agent Monitor with per-response feed), `#session-detail` (accumulated usage with event timeline), `#monthly` (monthly history with hover tooltip charts); added auto-restart logic that kills/relaunches metrics-server after generation
- `scripts/metrics/collector.ps1` — added `Collect-MonthlyHistory()` (aggregates snapshot data by day/month), `Collect-Aggregates()` (builds per-response data from events.ndjson with input/output tokens, cost, savings)
- `scripts/metrics/metrics-server.ps1` — added endpoints `/api/metrics/monthly` and `/api/metrics/per-response`

**Learned**:
- Snapshot aggregation requires max-value dedup per day (multiple snapshots per day)
- Per-response data from events.ndjson needs type inference (response/tool/llm events mapped to input/output tokens)
- Chart hover tooltip requires manual canvas hit-testing since there's no chart library

---
*Imported from Engram on 2026-09-06*
