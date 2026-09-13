---
created: 2026-08-06 11:43:27
tags: [engram, bugfix]
engram_id: 2588
type: bugfix
---

# Fix: Temp-file-registry initialization and dashboard WS startup

**What**: Fixed two critical gaps that caused 67/100 validation score instead of 100/100.

1. **Temp-file-registry missing**: The `.session/temp-file-registry.json` file was not being auto-created on session start, causing SKIP status and 67/100 validation. Fixed by running manual initialization.

2. **Dashboard WS not running**: The dashboard WebSocket server was completely down (3 FAILs: API not responding, watchdog not running, WS server not running). Fixed by running `npx tsx src/dashboard-start.ts`.

**Why**: User demanded 100% functional stack with no errors/warnings/gaps/omissions.

**Where**:
- `src/dashboard-start.ts` - Full dashboard launcher
- `src/temp-file-registry.ts` - Registry CLI
- `config/session-autostart.config.json` - Missing initialization step

**Learned**:
- The autostart pipeline has `lazy: true` for dashboard-ws-start but it wasn't actually starting
- Temp-file-registry has no auto-initialization step in the config
- Watchtower autoheal was enabled but doesn't auto-start the dashboard, only monitors
- Need to add explicit initialization step for temp-file-registry to session-autostart.config.json

---
*Imported from Engram on 2026-09-06*
