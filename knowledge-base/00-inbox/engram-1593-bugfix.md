---
created: 2026-07-12 06:44:00
tags: [engram, bugfix]
engram_id: 1593
type: bugfix
---

# Watchtower dashboard-ws resilient port fallback

**What**: Watchtower dashboard-ws resilient port fallback — eliminates false FAIL when stale dashboard-ports.json points to wrong port

**Why**: Watchtower was checking port 8083 (from stale dashboard-ports.json) but actual dashboard runs on port 8080. This caused 3 FAILs in the health check that weren't real failures.

**Where**: src/maintenance-watchtower.ts — checkDashboardWs() function

**Learned**:
- Dashboard WS uses dynamic port allocation via Get-FreePort() in dashboard-common.ps1
- Ports are persisted to .runtime/dashboard-ports.json but can become stale when processes die
- The fix tries configured port first, then fallback ports (8080, 8082) — catches the actual running server
- $PID is a read-only automatic variable in PowerShell — never use it as a variable name

**Result**: Watchtower went from 73 PASS | 2 WARN | 3 FAIL → 75 PASS | 3 WARN | 0 FAIL
- Remaining 3 WARNs are cosmetic: stale PID file, engram reindex freshness (50.6hrs, schedule-based), tracing Prometheus metrics (50.5hrs, requires external collector)

---
*Imported from Engram on 2026-09-06*
