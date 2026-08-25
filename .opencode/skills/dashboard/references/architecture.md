# Architecture

## File Tree

```
apps/web-dashboard/
├── server/
│   ├── websocket-server.ts    # WebSocket + HTTP API (WS_PORT env, default 8080)
│   ├── real-data.ts           # Reads runtime sources → metrics
│   └── consolidated.ts        # Writes derived dashboard metrics
├── src/
│   ├── types/dashboard.ts     # ModelCost, LatencyMetrics, etc.
│   ├── components/
│   │   ├── Dashboard.tsx      # 7-section layout, language selector, info icons
│   │   ├── MetricsCard.tsx    # Card with infoKey prop → InfoPopup
│   │   ├── InfoPopup.tsx      # Animated popup (fade-in + scale), click-outside + Escape
│   │   ├── TracingDashboard.tsx # Waterfall, feedback, search/filter by model
│   │   ├── LiveChart.tsx      # Realtime chart (tokens/sessions/cost/latency)
│   │   └── SessionTable.tsx   # Sessions table with model/cost, status sorting
│   └── hooks/
│       ├── useMetrics.ts      # HTTP polling (5s) + WebSocket fallback
│       ├── useAlerts.ts       # Alert polling (10s) from /api/alerts
│       ├── useSessions.ts     # Session polling (10s) from /api/agent/sessions
│       └── useLocale.ts       # i18n: 14 metric descriptions × 3 languages
├── config/dashboard-alerts.json  # 8 alert rules
├── vite.config.ts             # Reads WS_PORT (proxy) and VITE_DEV_PORT
└── tailwind.config.js         # fade-in animation keyframe
```

```
src/
├── dashboard-common.ts       # Get-FreePort, Save/Read/Clear-DashboardPorts, Get-ProcessIdByPort
├── dashboard-ws-autostart.ts # Watchdog (monitors port 5s, restarts up to 10x)
├── dashboard-start.ts        # Full launcher: free ports → WS watchdog + Vite + Chrome
└── dashboard-stop.ts         # Kill watchdog → PID files → port → process name
```

## Data Flow

```
Nexus SQLite (.runtime/gentle-vanguard.db)
  ↓ (real-data.ts reads on each poll)
websocket-server.ts
  ├── WebSocket push every 5s → React state
  ├── GET /api/metrics  → useMetrics.ts
  ├── GET /api/traces   → TracingDashboard
  ├── GET /api/alerts   → useAlerts.ts
  ├── POST /api/feedback → Nexus feedback table (TraceRepo)
  └── POST /api/sessions → useSessions.ts
```

> **Authority note:** `.runtime/metrics/feedback.json` and `.session/feedback/*.json` are
> historical/compatibility paths only. They are not active dashboard write targets and must not be
> documented as the feedback store.

## Resilience & Port Flexibility

- HTTP polling always runs (even without WebSocket).
- WS watchdog auto-recovery (up to 10 restarts). Watchdog PID in
  `.runtime/dashboard-ws-watchdog.pid`.
- Dynamic ports: `WS_PORT` env (default 8080), `VITE_DEV_PORT` (default 5173). `Get-FreePort()`
  scans +100 ports via `Get-NetTCPConnection`. Ports persisted to `.runtime/dashboard-ports.json`.
- `strictPort: false` in Vite config for auto-fallback.
