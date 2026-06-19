## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and
cross-file relationships.

When the user types `/graphify`, invoke the `skill` tool with `skill: "graphify"` before doing
anything else.

Rules:

- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json
  exists. For label-based searches, always use `graphify query` instead of `path`/`explain`.
- Use `graphify explain "<node_id>"` for focused explanations by exact node ID (e.g.,
  `adaptive_auto_delegate_orchestrator_start_orchestrator`). Node IDs use underscore-separated paths
  — run `graphify query` first to find the correct ID.
- `graphify path "<A>" "<B>"` and `graphify affected "X"` are limited — the graph only has
  `contains`/`calls` edges (AST-only, no `references`/`imports` edges without LLM semantic
  extraction). Cross-file paths are rare without a paid API key.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are
  not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph
  output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do
  not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
  Use `--force` when refactors delete code (node count decreases).
- Community labeling uses Gemini free tier (20 requests/day limit). If labeling fails with 429, wait
  for daily reset or set a paid API key. Re-run `graphify label .` to retry.
- For graph.html visualization: set `$env:GRAPHIFY_VIZ_NODE_LIMIT=40000` before `cluster-only` or
  `label` to handle graphs larger than the 5000-node default.

## dashboard

The LLM observability dashboard lives in `apps/web-dashboard/` (React/TypeScript/Vite).

### Architecture

- **WS server** (`server/websocket-server.ts`, port via `WS_PORT` env, default 8080) — reads real
  data from `.session/context-log/*/.state.json`, computes metrics, pushes via WebSocket every 5s,
  serves REST APIs (`/api/metrics`, `/api/traces`, `/api/alerts`, `/api/feedback`).
- **Frontend** (port via `VITE_DEV_PORT` env, default 5173, proxied via Vite to WS_PORT) — 7-section
  dashboard with real-time charts, tracing waterfall, alerts, i18n (en/es/pt-BR), and metric info
  popups.
- **No mock data** — everything derives from real traces.
- **Dynamic port allocation** — `Get-FreePort()` in `dashboard-common.ps1` scans +100 ports via
  `Get-NetTCPConnection`, picks first free. Chosen ports persisted to
  `.runtime/dashboard-ports.json`.

### Lifecycle

| Action                          | Command                                                  |
| ------------------------------- | -------------------------------------------------------- |
| Start full (WS + Vite + Chrome) | `scripts/utilities/dashboard/dashboard-start.ps1`        |
| Start WS only (pipeline)        | `scripts/utilities/dashboard/dashboard-ws-autostart.ps1` |
| Stop all                        | `scripts/utilities/dashboard/dashboard-stop.ps1`         |

### Auto-recovery

- The WS server watchdog (`dashboard-ws-autostart.ps1`) monitors the process every 5s via port check
  (`Test-NetConnection localhost:<port>`). If the process dies or the port closes, it restarts (up
  to 10 attempts). Uses `cmd /c set WS_PORT=... && npx.cmd tsx ...` for reliable Windows batch
  execution. Heartbeat logged to `.runtime/dashboard-ws.log`.
- Watchdog stores its own PID in `.runtime/dashboard-ws-watchdog.pid` — `dashboard-stop.ps1` kills
  the watchdog FIRST before the WS process to prevent restart loops.
- Frontend HTTP polling in `useMetrics.ts` always runs regardless of WebSocket state — data loads
  even if the WS server is temporarily down.

### Pipeline integration

- `config/session-autostart.config.json` includes a `lazy: true` step `dashboard-ws-start` that
  auto-launches the WS server watchdog after session start. It does NOT block the pipeline.
- Old steps `dashboard-render` and `live-feed-start` are deprecated (`enabled: false`,
  `deprecated: true`).

### Build verification

```bash
cd apps/web-dashboard
npm run build          # must exit 0 with no TS errors
```

### Key files

- `types/dashboard.ts` — core type definitions
- `server/real-data.ts` — data pipeline (reads .state.json → computes metrics)
- `server/websocket-server.ts` — WS + HTTP server (port 8080)
- `hooks/useLocale.ts` — i18n (14 metrics × 3 languages)
- `hooks/useMetrics.ts` — resilient HTTP polling + WS
- `components/TracingDashboard.tsx` — waterfall view + feedback
- `components/InfoPopup.tsx` — animated popup (fade-in + scale)
- `config/dashboard-alerts.json` — 8 alert rules
- `scripts/utilities/dashboard/dashboard-common.ps1` — shared port allocation (Get-FreePort,
  Save/Read/Clear-DashboardPorts)
- `scripts/utilities/dashboard/dashboard-ws-autostart.ps1` — watchdog start with auto-recovery (10
  restarts)
- `scripts/utilities/dashboard/dashboard-start.ps1` — full launcher (WS watchdog + Vite + Chrome)
- `scripts/utilities/dashboard/dashboard-stop.ps1` — cleanup stop (kills watchdog → PID files → port
  → process name)
- `vite.config.ts` — reads WS_PORT (proxy target) and VITE_DEV_PORT from env
- `.runtime/dashboard-ports.json` — persisted port assignments for stop/restart
- `.runtime/dashboard-ws.log` — watchdog heartbeat log
- `.runtime/dashboard-ws-watchdog.pid` — watchdog own PID (clean shutdown)

## maintenance-watchtower

Orquestador central de health checks, auto-healing y monitoreo continuo. Unifica los checks de
`health-check.ps1`, `stack-health-check.ps1` y el watchdog en un solo punto.

### Architecture

- **60 checks** en **11 componentes**: dashboard-ws, codegraph, ml-embeddings, engram, mcp, session,
  hooks, configs, tool-configs, security, governance.
- **6 modos**: health, rebuild, report, autoheal, continuous, all.
- **Pipeline integrado**: corre `-Action autoheal -Quiet` con `lazy: true` al inicio de sesión (no
  bloquea).
- **Auto-healing**: detecta procesos caídos y los restaura automáticamente.

### Modes

| Action     | Command                                  | Description                      |
| ---------- | ---------------------------------------- | -------------------------------- |
| health     | `-Action health`                         | 60 checks, 11 componentes        |
| rebuild    | `-Action rebuild`                        | health + rebuild ML/RAG indices  |
| autoheal   | `-Action autoheal`                       | health + restart procesos caídos |
| report     | `-Action report -OutputFile status.json` | JSON export                      |
| continuous | `-Action continuous -Interval 30`        | loop each N sec (Ctrl+C to exit) |
| all        | `-Action all -Force`                     | health + autoheal + rebuild      |

### Checks

- **Dashboard WS**: API 200 OK, watchdog PID alive, WS PID alive
- **CodeGraph**: index exists, nodes count, age
- **ML Embeddings**: ml-index.json, embedding files, skill-embeddings.json
- **Engram**: DB integrity, reindex log, RAG pipeline
- **MCP**: config files (3), bridge health, bridge status
- **Session**: session dir, manifest, pipeline config
- **Hooks**: git hooks (pre-commit, post-commit, post-merge)
- **Configs**: JSON schemas (5 configs), JSON validator
- **Tool Configs**: clinerules, cursorrules, continue config
- **Security**: opencode.json structure, auth config
- **Governance**: policy files, rules directory

### Estabilidad comprobada

- **60/60 PASS — 0 WARN — 0 FAIL — 0 SKIP** (todos los componentes OK)
- Dashboard WS API 200 OK, watchdog con auto-restart (10 intentos)
- CodeGraph: 133 files, 1410 nodes, 1763 edges
- Puertos dinámicos con `Get-FreePort()` en `dashboard-common.ps1`
- Pipeline session-autostart con `lazy: true` para steps no bloqueantes
- `dashboard-stop.ps1` mata watchdog primero para evitar restart loops
- Frontend HTTP polling tolera caídas temporales del WS server

## v4.0-infrastructure

Infraestructura de tracing, state persistence, auditoría, event sourcing, cloud connectors y health
API integrados en la pipeline de sesión.

### Distributed Tracing

- Script: `scripts/utilities/ops/TRACING/tracing-instrument.ps1`
- Acciones: `start`, `end`, `error`
- Almacena spans en `.telemetry/spans/` y `.telemetry/traces/` (JSONL)
- Exporta OTLP a `http://localhost:4318/v1/traces`
- Pipeline: step `tracing-init` (lazy, session start) + cleanup close
- Funciones helper: `Start-TracingSpan` / `Stop-TracingSpan` en cloud connectors

### State Persistence

| Componente | Script | Pipeline step |
|-----------|--------|---------------|
| Checkpoint | `scripts/utilities/ops/STATE-PERSISTENCE/checkpoint-manager.ps1` | `checkpoint-auto-create` (lazy) |
| Snapshot | `scripts/utilities/ops/STATE-PERSISTENCE/snapshot-manager.ps1` | — (manual) |
| Rollback | `scripts/utilities/ops/STATE-PERSISTENCE/rollback-orchestrator.ps1` | — (manual) |

- Checkpoint: create/list/diff/verify/prune — almacena en `.session/checkpoints/`
- Snapshot: snapshot/list/prune — almacena en `.session/snapshots/`
- Rollback: restaura desde checkpoint con dry-run validation

### Audit Pipeline

- Script: `scripts/security/audit-pipeline.ps1`
- Acciones: `log`, `status`, `query`, `archive`, `prune`
- Almacena en `.session/audit/logs/` (JSONL diario)
- `$root` calculado con 2x `Split-Path -Parent` desde `scripts/security/` → repo root
- Pipeline: step `audit-pipeline-init` (lazy, session start) + cleanup log

### Event Sourcing + Saga

| Componente | Script | Pipeline step |
|-----------|--------|---------------|
| Event Store | `scripts/utilities/ops/ADVANCED-PATTERNS/event-sourcing.ps1` | `event-sourcing-init` (lazy) |
| Saga | `scripts/utilities/ops/ADVANCED-PATTERNS/saga-orchestrator.ps1` | — (manual) |

- Event sourcing: append/project/snapshot/prune — almacena en `.session/event-store/`
- Saga: create/register-step/complete/compensate/list — almacena en `.session/sagas/`

### Cloud Connectors

| Componente | Script | Pipeline step |
|-----------|--------|---------------|
| Hybrid Executor | `scripts/utilities/ops/CLOUD-CONNECTORS/hybrid-executor.ps1` | `cloud-connectors-init` (lazy) |
| AWS Delegator | `scripts/utilities/ops/CLOUD-CONNECTORS/aws-delegator.ps1` | — |
| Azure Delegator | `scripts/utilities/ops/CLOUD-CONNECTORS/azure-delegator.ps1` | — |

- Routing por costo/latencia/load con fallback automático
- Circuit breaker pattern (5 failures → OPEN, 2 successes → HALF_OPEN → CLOSED)
- Métricas en `.session/cloud-metrics.json` y `.session/hybrid-metrics.json`
- SkillInput serializado como JSON para paso por CLI (hashtable splatting `@splat`)
- Pipeline: step `cloud-connectors-init` (lazy, healthcheck ping al iniciar sesión)

### Dashboard Health API

`/api/health` retorna 7 componentes: `websocket`, `mcp`, `adaptive`, `cloud`, `tracing`,
`checkpoints`, `audit`. Cada uno con status `ok`/`unknown`/`degraded` y métricas específicas.
Verificado: 7/7 responden OK en entorno local.

### Notes

- **graphify update**: The npm package `graphify@1.0.0` installed globally is a different project
  (Random Graph Generator) — NOT the opencode graphify CLI. It has no `bin` entry, so
  `graphify update .` cannot run in this environment. The `graphify-out/` directory exists
  from a prior external process. Skip `graphify update` — code changes are tracked via
  `.codegraph/` index and git hooks.
- **`$var:` syntax**: In PowerShell string interpolation, `$varname:` must be written as
  `${varname}:` to avoid parser errors. All instances are fixed.

### Autostart Pipeline (steps v4.0)

Los siguientes steps se agregaron al `config/session-autostart.config.json`:

| Step | Script | Lazy |
|------|--------|------|
| `judgment-day-correction` | `correction-rules-engine.ps1` | ✅ |
| `cloud-connectors-init` | `hybrid-executor.ps1` | ✅ |
| `cloud-connectors-metrics` | `token-budget-guard.ps1` | ✅ |
| `tracing-init` | `tracing-instrument.ps1` | ✅ |
| `checkpoint-auto-create` | `checkpoint-manager.ps1` | ✅ |
| `audit-pipeline-init` | `audit-pipeline.ps1` | ✅ |
| `event-sourcing-init` | `event-sourcing.ps1` | ✅ |
| `post-session-learning` | `post-autostart-summary.ps1` | ✅ |

### Verificación rápida

```powershell
# Probar todo el pipeline
& "scripts/utilities/ops/CLOUD-CONNECTORS/hybrid-executor.ps1" -SkillId __healthcheck__ -SkillInput @{action='ping'} -InvocationType DryRun -Quiet
& "scripts/security/audit-pipeline.ps1" -Action status -Quiet
& "scripts/utilities/ops/STATE-PERSISTENCE/checkpoint-manager.ps1" -Action list -Quiet
& "scripts/utilities/ops/TRACING/tracing-instrument.ps1" -Action start -SpanName test -Quiet
& "scripts/utilities/ops/ADVANCED-PATTERNS/event-sourcing.ps1" -Action project -AggregateId test -Quiet
& "scripts/maintenance/maintenance-watchtower.ps1" -Action health -Quiet
# Dashboard build
cd apps/web-dashboard && npm run build
```
