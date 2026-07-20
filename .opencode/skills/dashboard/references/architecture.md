# Architecture

## File Tree

```
apps/web-dashboard/
├── server/
│   ├── websocket-server.ts    # WebSocket + HTTP API (WS_PORT env, default 8080)
│   ├── real-data.ts           # Reads .session/context-log/*/.state.json → metrics
│   └── consolidated.ts        # Writes .runtime/metrics/consolidated.json
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
scripts/utilities/dashboard/
├── dashboard-common.ps1       # Get-FreePort, Save/Read/Clear-DashboardPorts, Get-ProcessIdByPort
├── dashboard-ws-autostart.ps1 # Watchdog (monitors port 5s, restarts up to 10x)
├── dashboard-start.ps1        # Full launcher: free ports → WS watchdog + Vite + Chrome
└── dashboard-stop.ps1         # Kill watchdog → PID files → port → process name
```

## Data Flow

```
.session/context-log/*/.state.json
  ↓ (real-data.ts reads on each poll)
websocket-server.ts
  ├── WebSocket push every 5s → React state
  ├── GET /api/metrics  → useMetrics.ts
  ├── GET /api/traces   → TracingDashboard
  ├── GET /api/alerts   → useAlerts.ts
  ├── POST /api/feedback → .runtime/metrics/feedback.json
  └── POST /api/sessions → useSessions.ts
```

## Resilience & Port Flexibility

- HTTP polling always runs (even without WebSocket).
- WS watchdog auto-recovery (up to 10 restarts). Watchdog PID in `.runtime/dashboard-ws-watchdog.pid`.
- Dynamic ports: `WS_PORT` env (default 8080), `VITE_DEV_PORT` (default 5173). `Get-FreePort()` scans +100 ports via `Get-NetTCPConnection`. Ports persisted to `.runtime/dashboard-ports.json`.
- `strictPort: false` in Vite config for auto-fallback.
