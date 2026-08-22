---
name: live-traceability
description: Skill: Live Traceability
triggers:
  - live traceability
---

# Skill: Live Traceability

Capture and visualize real-time agent session data — turns, tokens, mechanisms, profiles, and cost —
on the metrics dashboard.

## Key Concept

Each agent response is a "turn". Turns are grouped into "sessions". The dashboard's **Trace**
section shows all sessions with per-turn expandable detail, mechanism-change timelines, and
historical aggregation.

## Architecture

```
Agent Turn
   ↓
C:/Workspace_local/gentle-vanguard/src/tokens/token-usage-auto.ts        ← call AFTER each response with actual metrics
   ↓
.session/context-log/       ← .state.json (turn data)
   ↓
dashboard server.js         ← reads .state.json → REST API
   ↓
dashboard browser           ← polls /api/traceability/* every 5s
```

## Data Flow

1. **Log a turn** (call after each agent response):

   ```powershell
   pwsh -NoProfile -File scripts/utilities/TOKEN/C:/Workspace_local/gentle-vanguard/src/tokens/token-usage-auto.ts `
     -InputTokens <N> -OutputTokens <N> -ContextChars <N> `
     -TurnLabel "<label>" -Model "<model>"
   ```

2. **Verify the data** was written:

   ```powershell
   Get-Content .session/context-log/<session-id>/.state.json | ConvertFrom-Json
   ```

3. **Open the dashboard**: `http://localhost:8080` → click **Trace** tab

## Server Endpoints

| Endpoint | Description | | ---------------------------------------- |
-------------------------------------------- | ----- | ---- | ------------------ | |
`GET /api/metrics` | Aggregated metrics (real data from sessions) | | `GET /api/traceability/live` |
Current active session with turns | | `GET /api/traceability/sessions` | All sessions + mechanisms |
| `GET /api/traceability/session/:id` | Single session detail | |
`GET /api/traceability/history?range=day | week                                         | month | all`
| Aggregated history | | `GET /api/traceability/mechanisms` | Mechanism/profile change history |

## Alerting

Set `config/observability-config.json#alerts` for budget/rate triggers. The dashboard shows live
alerts in the Executive section.

## Traceability Files

- `reports/dashboard-v2/server.js` — 7 API endpoints, real data readers
- `reports/dashboard-v2/app.js` — `trace` section with turns table, mechanism timeline, history
  filters
- `reports/dashboard-v2/index.html` — `<section id="trace">` with all sub-components
- `reports/dashboard-v2/styles.css` — Trace styles (`.trace-*` classes)
- `.session/context-log/` — Real session data directory
- `config/model-router.json` — Agent profiles for mechanism detection
