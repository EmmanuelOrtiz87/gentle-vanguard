---
created: 2026-08-17 06:31:14
tags: [engram, bugfix]
engram_id: 2871
type: bugfix
---

# Restauración daemons dashboard-ws y codegraph (95/95 health)

**What**: Restaurados los componentes caídos del health check (dashboard-ws y codegraph) → 95/95 PASS.
**Why**: El health check reportaba 4 FAIL: dashboard-ws (API 8080, watchdog, WS server) y codegraph (server MCP down).
**Where**: src/dashboard-ws-autostart.ts, src/codegraph-mcp-server-start.ts, .runtime/dashboard-ws-watchdog.pid, .runtime/codegraph-mcp-server.pid
**Learned**:
1. dashboard-ws: lanzar `npx tsx src/dashboard-ws-autostart.ts` arranca el watchdog (PID file) + WS en background; el comando se queda en foreground pero el watchdog ya quedó corriendo (port 8080 PID 41144, watchdog PID 10316). Verificar con API health 200 + pid files.
2. codegraph MCP server: ES CRÍTICO lanzar el wrapper detached (`Start-Process npx.cmd tsx src/codegraph-mcp-server-start.ts -WindowStyle Hidden`), NO con el bash tool directo. El wrapper mantiene stdin abierto del child `codegraph.js serve --mcp`; si el shell mata el wrapper (timeout), stdin se cierra → el server muere con exit 0. El server arranca en ~3-8s; el WARN "process not detected" del log es normal durante la ventana de boot.
3. El health check usa PID file + process-table scan (codegraph.js serve --mcp) como señales autoritativas; el port 3000 es solo secundario (el MCP es stdio, no TCP).

---
*Imported from Engram on 2026-09-06*
