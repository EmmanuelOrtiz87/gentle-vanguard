# Troubleshooting

## "Connecting..." or Blank Screen

- WS server may be down. Check `.runtime/dashboard-ws.log` for watchdog heartbeats.
- Restart: `npx tsx src/dashboard-stop.ts && npx tsx src/dashboard-start.ts`

## Metrics Show 0 or Stale Data

- Verify `.session/context-log/` has `.state.json` files.
- Test `GET http://localhost:8080/api/metrics` returns JSON.
- HTTP polling in `useMetrics.ts` runs every 5s regardless of WS state.

## Build Errors

- Run `cd apps/web-dashboard && npm install && npm run build`.
- Check TypeScript version matches `package.json`.

## Watchdog Keeps Restarting

- Check `websocket-server.ts` for syntax errors.
- Verify `npx tsx` is available.
- Check `.runtime/dashboard-ws.log` for error details.
- Port conflicts handled automatically (scans upward).

## Port Conflict / "address in use"

- Run `npx tsx src/dashboard-stop.ts` to kill stale processes.
- System auto-selects next free port; check `.runtime/dashboard-ports.json`.
- Engram uses port 7437 (no collision with dashboard 8080/5173).
- `Get-FreePort` scans +100 ports; falls back to `TcpListener` test if `Get-NetTCPConnection` fails.
