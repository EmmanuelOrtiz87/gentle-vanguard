---
created: 2026-05-22 02:05:12
tags: [engram, architecture]
engram_id: 1001
type: architecture
---

# Live dashboard with HTTP server + background daemon

**What**: Implemented full real-time dashboard system: (1) live-feed.ps1 runs as background daemon collecting metrics every 5s, (2) metrics-server.ps1 runs as HTTP server on port 8090 serving dashboard + JSON API + SSE, (3) live-feed-manager.ps1 handles start/stop/status of both processes with PID tracking to .session/live-feed-state.json, (4) dashboard HTML enhanced with JS fetch polling every 10s from /api/live.

**Why**: Sin este sistema, el dashboard solo se actualizaba en session start/close. El usuario necesitaba datos en vivo sin refrescar manualmente.

**Where**:
- scripts/metrics/live-feed.ps1 (+ -Daemon mode)
- scripts/metrics/metrics-server.ps1 (NEW - HTTP server)
- scripts/utilities/live-feed-manager.ps1 (NEW - process lifecycle)
- scripts/metrics/dashboard-render.ps1 (+ GV_LIVE JS polling)
- config/session-autostart.config.json (+ live-feed-start step)
- scripts/utilities/session-manager.ps1 (+ live-feed-manager stop)

**Learned**:
1. System.Diagnostics.Process with CreateNoWindow=true + RedirectStandardOutput es la forma más limpia de lanzar background processes persistentes en PowerShell (más robusto que Start-Job que se muere con el parent)
2. Guardar PIDs en .session/live-feed-state.json permite matar procesos en session close aunque el parent process haya terminado
3. fetch() polling desde el browser funciona perfectamente cuando el dashboard se sirve via HTTP; desde file:// protocol no funciona por CORS, pero meta refresh cubre ese caso
4. SSE (Server-Sent Events) es mejor que polling pero más complejo de implementar en PowerShell puro

---
*Imported from Engram on 2026-09-06*
