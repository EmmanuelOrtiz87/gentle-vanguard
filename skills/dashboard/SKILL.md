---
name: dashboard
aliases: ["dashboard"]
description:
  LLM Observability Dashboard — React/TypeScript/Vite SPA with real-time WebSocket data pipeline,
  i18n (en/es/pt-BR), and 14 metric descriptions.
version: 2.1.0
  
triggers:
  - dashboard
  - metrics
  - chart
  - visualization
  - cost
  - latency
  - tracing
metadata:
  source: opencode-migrated
  migrated: true
  migratedAt: "2026-08-09T21:55:57.047Z"
  originalPath: C:\Workspace_local\gentle-vanguard\.opencode\skills\dashboard\SKILL.md
  version: "1.0.0"
---

# Dashboard Skill

Self-contained React/TypeScript/Vite observability system. No mock data — all metrics derive from
real `.session/context-log/` traces.

## Quick Start

```powershell
npx tsx src/dashboard-start.ts         # Full: WS server + Vite + Chrome
npx tsx src/dashboard-ws-autostart.ts  # WS server only (pipeline)
npx tsx src/dashboard-stop.ts          # Kill watchdog → WS → cleanup ports
```

Dynamic ports persisted to `.runtime/dashboard-ports.json`. See
[architecture](./references/architecture.md).

## Reference Files

| File                            | Content                                                     |
| ------------------------------- | ----------------------------------------------------------- |
| `references/architecture.md`    | File tree, data flow diagram, scripts, resilience           |
| `references/key-concepts.md`    | Real data pipeline, i18n/metric info, dynamic ports, alerts |
| `references/common-tasks.md`    | Adding metrics/alerts/i18n, testing checklist               |
| `references/troubleshooting.md` | WS down, stale data, build errors, port conflicts           |

## Core Rules

1. **Never mock** — all metrics from real `.state.json`
2. **Always add `infoKey`** — each metric needs translations in all 3 languages
3. **Resilient fetching** — HTTP polling works without WebSocket
4. **i18n first** — all user text via `useLocale()` hook
5. **Zero build errors** — `npm run build` must exit 0

## Usage

Use **dashboard** when a task matches its triggers (dashboard - metrics - chart - visualization - cost - latency - tracing).

Purpose: LLM Observability Dashboard — React/TypeScript/Vite SPA with real-time WebSocket data pipeline, i18n (en/es/pt-BR), and 14 metric descriptions.

## Examples

Concrete usage drawn from this skill's own documentation:

```powershell
npx tsx src/dashboard-start.ts         # Full: WS server + Vite + Chrome
npx tsx src/dashboard-ws-autostart.ts  # WS server only (pipeline)
npx tsx src/dashboard-stop.ts          # Kill watchdog → WS → cleanup ports
```
