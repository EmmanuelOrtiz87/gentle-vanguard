---
name: dashboard
version: 2.0.0
description:
  LLM Observability Dashboard — Gentle-Vanguard React/TypeScript dashboard with real-time WebSocket
  data pipeline, i18n (en/es/pt-BR), and metric descriptions.
triggers:
  - dashboard
  - metrics
  - chart
  - visualization
  - cost
  - latency
  - tracing
---

# Dashboard Development Skill (v2)

## Architecture

React SPA + Vite + TypeScript + WebSocket. Self-contained observability system — no external tools.
Dynamic port allocation avoids conflicts.

```
apps/web-dashboard/
├── server/
│   ├── websocket-server.ts    # WebSocket + HTTP API (port via WS_PORT env, default 8080)
│   ├── real-data.ts           # Data pipeline: reads .session/context-log/*/.state.json
│   └── consolidated.ts        # Writes .runtime/metrics/consolidated.json
├── src/
│   ├── types/dashboard.ts     # Core type definitions (ModelCost, LatencyMetrics, etc.)
│   ├── components/
│   │   ├── Dashboard.tsx      # Main layout: 7 sections, language selector, info icons
│   │   ├── MetricsCard.tsx    # Card with infoKey prop → InfoPopup
│   │   ├── InfoPopup.tsx      # Animated popup (fade-in + scale), click-outside + Escape close
│   │   ├── TracingDashboard.tsx # Waterfall view, feedback buttons, search/filter by model
│   │   ├── LiveChart.tsx      # Realtime chart (tokens/sessions/cost/latency)
│   │   └── SessionTable.tsx   # Sessions table with model/cost columns, status sorting
│   └── hooks/
│       ├── useMetrics.ts      # HTTP polling (5s) + WebSocket fallback
│       ├── useAlerts.ts       # Alert polling (10s) from /api/alerts
│       ├── useSessions.ts     # Session polling (10s) from /api/agent/sessions
│       └── useLocale.ts       # i18n: 14 metric descriptions × 3 languages, useLocale() hook
├── config/
│   └── dashboard-alerts.json  # 8 alert rules (token, budget, latency, error, feedback, SLA, sessions, cost)
├── vite.config.ts             # Reads WS_PORT (proxy target) and VITE_DEV_PORT from env
└── tailwind.config.js         # fade-in animation keyframe
```

### Scripts Infrastructure

```
scripts/utilities/dashboard/
├── dashboard-common.ps1       # Shared functions: Get-FreePort, Save/Read/Clear-DashboardPorts, Get-ProcessIdByPort
├── dashboard-ws-autostart.ps1 # WS server watchdog (monitors port 5s, restarts up to 10x, tracks PID)
├── dashboard-start.ps1        # Full launcher: detects free ports → WS watchdog + Vite + Chrome
└── dashboard-stop.ps1         # Kills watchdog first → PID files → port ownership → process name cleanup
```

### Data Flow

```
.session/context-log/*/.state.json
  ↓ (real-data.ts reads on each poll)
websocket-server.ts (port 8080)
  ├── WebSocket push every 5s → React state
  ├── HTTP GET /api/metrics    → useMetrics.ts (resilient fallback)
  ├── HTTP GET /api/traces     → TracingDashboard
  ├── HTTP GET /api/alerts     → useAlerts.ts
  ├── POST /api/feedback       → persists to .runtime/metrics/feedback.json
  └── POST /api/sessions       → useSessions.ts
```

### Resilience & Port Flexibility

- HTTP polling always runs (even with WebSocket). The `wsConnected` guard was removed — data loads
  even if WS server is down.
- WS server has watchdog auto-recovery (up to 10 restarts). Watchdog PID stored in
  `.runtime/dashboard-ws-watchdog.pid` so stop script kills watchdog first before the WS process
  (preventing restart loop).
- **Dynamic port allocation**: WS server reads `WS_PORT` env var (default 8080). Vite reads
  `VITE_DEV_PORT` (default 5173) and `WS_PORT` for proxy target. `Get-FreePort()` in
  `dashboard-common.ps1` scans +100 ports upward, detecting conflicts via `Get-NetTCPConnection`.
  Chosen ports persisted to `.runtime/dashboard-ports.json`.
- `strictPort: false` in Vite config for auto-fallback if port busy.

## Key Concepts

### Real Data, No Mock Data

- Data source: `.session/context-log/*/.state.json` (real model names, token counts, costs,
  latencies)
- Pricing table `MODEL_PRICING` in `real-data.ts` — `estimatedCost` vs `actual` for cost insights
- 4 models detected, 21+ traces

### Metric Info & i18n

- `useLocale.ts` — central translation store: 14 metrics × 3 languages (en, es, pt-BR)
- Each metric has: `label`, `description`, `what` (what it measures), `how` (how it's calculated)
- `MetricsCard` accepts `infoKey` prop → shows ℹ icon → opens `InfoPopup`
- `SectionHeader` helper with info icon for section titles

### Dynamic Port Allocation

Port assignment is automatic and conflict-free:

```powershell
# Get-FreePort algorithm (in dashboard-common.ps1):
# 1. Start from preferred port (config, env, or default)
# 2. Scan upward (+100 ports max)
# 3. Check if port is in Listen/Established/Bound state
# 4. Return first free port

# Environment variables:
WS_PORT=8081       # → websocket-server.ts listens on 8081
VITE_DEV_PORT=5199 # → Vite dev server on 5199
                    # → Vite proxies /api → localhost:8081
```

Ports are persisted to `.runtime/dashboard-ports.json`:

```json
{ "wsPort": 8081, "vitePort": 5199, "updated": "2026-06-18T..." }
```

Both `dashboard-stop.ps1` and subsequent `dashboard-start.ps1` reads this file to know which ports
to kill or reuse.

### Alert System

- `config/dashboard-alerts.json` — 8 rules with `direction` ("above" or "below")
- Rules: high_token_usage, budget_limit, high_latency_p95, high_error_rate, low_feedback_score,
  low_sla, high_active_sessions, cost_spike
- Fixed `direction: "below"` bug: `actual <= threshold` evaluation when `rule.direction === 'below'`

## Best Practices

1. **Never mock data** — all metrics must derive from real `.state.json` files
2. **Always add `infoKey`** — every new metric card needs an entry in `useLocale.ts` in all 3
   languages
3. **Resilient fetching** — HTTP polling must always work without WebSocket
4. **i18n first** — any user-facing text must use `t('key')` via `useLocale()` hook
5. **No build warnings** — TypeScript must compile with 0 errors (`npm run build`)

## How to Start/Stop

```powershell
# Full start (WS server + Vite + Chrome)
.\scripts\utilities\dashboard\dashboard-start.ps1

# WS server only (for session pipeline)
.\scripts\utilities\dashboard\dashboard-ws-autostart.ps1

# Stop everything
.\scripts\utilities\dashboard\dashboard-stop.ps1
```

The session pipeline also auto-starts the WS server (lazy step `dashboard-ws-start`).

## Common Tasks

### Adding a new metric card:

1. Add metric to `types/dashboard.ts` interfaces (e.g., `DashboardData.cost.byModel`)
2. Compute in `server/real-data.ts` — read from `.state.json` files
3. Add API endpoint in `server/websocket-server.ts` (or extend existing)
4. Display in `Dashboard.tsx` using `MetricsCard` with `infoKey`
5. Add translations to `useLocale.ts` (3 languages)
6. Verify build: `cd apps/web-dashboard && npm run build`

### Adding a new alert rule:

1. Add entry to `config/dashboard-alerts.json` with threshold, direction, severity
2. Add evaluation logic in `websocket-server.ts` `/api/alerts` handler
3. Test both `direction: "above"` and `direction: "below"` scenarios

### Adding i18n language:

1. Add language entries to all 14 metric descriptions in `useLocale.ts`
2. Add flag emoji to language selector in `Dashboard.tsx`
3. Test language switch in browser

## Testing Checklist

- [ ] Dashboard loads with real data (no mock) on cold refresh
- [ ] WebSocket connected indicator shows green
- [ ] HTTP fallback works when WS server is killed (`dashboard-stop.ps1`)
- [ ] Language switch works (EN → ES → PT-BR)
- [ ] Info popup appears on ℹ click, closes on Escape and click-outside
- [ ] Alerts evaluate correctly (both "above" and "below" directions)
- [ ] Feedback thumbs up/down persists to `.runtime/metrics/feedback.json`
- [ ] `npm run build` exits with 0 errors
- [ ] Session pipeline auto-starts WS server (`dashboard-ws-start` step)

## Troubleshooting

**Dashboard shows "connecting..." or blank:**

- WS server died. Check `.runtime/dashboard-ws.log` for watchdog heartbeats
- Restart:
  `.\scripts\utilities\dashboard\dashboard-stop.ps1 && .\scripts\utilities\dashboard\dashboard-start.ps1`

**Metrics show 0 or stale data:**

- Check `.session/context-log/` has `.state.json` files
- Verify `GET http://localhost:8080/api/metrics` returns JSON
- The HTTP polling in `useMetrics.ts` runs every 5s regardless of WS state

**Build errors:**

- Run `cd apps/web-dashboard && npm install && npm run build`
- Check TypeScript version matches `package.json`

**Watchdog keeps restarting:**

- Check `websocket-server.ts` for syntax errors
- Verify `npx tsx` is available
- Check `.runtime/dashboard-ws.log` for error details
- The watchdog handles port conflicts automatically (scans upward), so port-in-use should not cause
  restarts

**Port conflict / "address in use":**

- Run `.\scripts\utilities\dashboard\dashboard-stop.ps1` to kill stale processes
- The system auto-selects the next free port; check `.runtime/dashboard-ports.json` for actual ports
  in use
- Engram uses port 7437 (no collision with dashboard 8080/5173)
- `Get-FreePort` scans +100 ports; if `Get-NetTCPConnection` fails, falls back to `TcpListener` test
  bind
