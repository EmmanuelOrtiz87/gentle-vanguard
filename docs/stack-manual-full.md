## Operating model: LOCAL-FIRST / SERVER-OPTIONAL

Gentle-Vanguard's primary supported scope is local operation: CLI/orchestration, local SQLite/Nexus,
`.session/`, Engram, CodeGraph, local MCP, and the loopback dashboard. Server, SaaS, cloud, and
Kubernetes paths remain opt-in evolution paths. Registry digests, Cosign identity,
CNI/NetworkPolicy, OS/runtime sandbox evidence, and OIDC/LDAP identity are external-promotion
inputs—not prerequisites for the local profile. See
`docs/adr/ADR-0017-local-first-operating-model.md`.

## SESSION START (MANDATORY — run before ANY other action)

At the very beginning of every session, **before responding to the user**, run:

```bash
npx tsx src/session/session-autostart.ts
```

This initializes the full autonomous stack: session ID, engram integrity, security orchestrator,
codegraph sync, token budget, session scoring, Karpathy guidelines, adaptive profiles, watchtower
auto-heal, dashboard WS, and all lazy background tasks. The pipeline is idempotent and handles
errors gracefully (`onStepFailure: continue`).

Do NOT skip, defer, or ask the user whether to run it. It is mandatory and non-blocking.

**Non-blocking alternative** (fire-and-forget, returns in ~1.3s; pipeline runs fully in background
with a per-run log at `.runtime/autostart-detached-<timestamp>.log`):

```bash
npm run session:autostart:detached
```

Use the detached launcher when the caller is a CI step, git hook, or agent shell that must not hang
on the pipeline's lazy background daemons. The lock is robust (validates the owning process is a
real `node` running session-autostart), so orphaned `conhost.exe` processes can never wedge the
pipeline. Logs are pruned automatically after 7 days.

---

## graphify

Native knowledge graph at graphify-out/ (AST-built: file/function/class/method nodes,
`contains`/`calls` edges, label-propagation communities). Built by `src/cli/graphify-build.ts` —
deterministic, no LLM, no network.

When the user types `/graphify`, invoke the `skill` tool with `skill: "graphify"` before doing
anything else.

Rules:

- If graphify-out/graph.json is missing, run `npm run graphify -- build` first (seconds, native).
- For codebase questions, first run `npm run graphify -- query "<question>"` when
  graphify-out/graph.json exists. For label-based searches, always use `npm run graphify -- query`
  instead of `path`/`explain`.
- Use `npm run graphify -- explain "<node_id>"` for focused explanations by exact node ID (e.g.,
  `adaptive_auto_delegate_orchestrator_start_orchestrator`). Node IDs use underscore-separated paths
  — run `npm run graphify -- query` first to find the correct ID.
- `npm run graphify -- path "<A>" "<B>"` and `npm run graphify -- affected "X"` are limited — the
  graph only has `contains`/`calls` edges (AST-only, no `references`/`imports` edges without LLM
  semantic extraction). Cross-file paths are rare without a paid API key.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are
  not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph
  output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do
  not surface enough context.
- After modifying code, run `npm run graphify -- update .` to validate the graph snapshot and keep
  the Graphify workflow active. Use CodeGraph sync for freshness in this environment.
- Community labeling uses Gemini free tier (20 requests/day limit). If labeling fails with 429, wait
  for daily reset or set a paid API key. Re-run the labeling workflow only when the real labeler is
  available.
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
- **Dynamic port allocation** — `Get-FreePort()` in `src/dashboard-common.ts` scans +100 ports via
  `Get-NetTCPConnection`, picks first free. Chosen ports persisted to
  `.runtime/dashboard-ports.json`.

### Lifecycle

| Action                          | Command                                 |
| ------------------------------- | --------------------------------------- |
| Start full (WS + Vite + Chrome) | `npx tsx src/dashboard-start.ts`        |
| Start WS only (pipeline)        | `npx tsx src/dashboard-ws-autostart.ts` |
| Stop all                        | `npx tsx src/dashboard-stop.ts`         |

### Auto-recovery

- The WS server watchdog (`src/dashboard-ws-autostart.ts`) monitors the process every 5s via port
  check (`Test-NetConnection localhost:<port>`). If the process dies or the port closes, it restarts
  (up to 10 attempts). Uses `cmd /c set WS_PORT=... && npx.cmd tsx ...` for reliable Windows batch
  execution. Heartbeat logged to `.runtime/dashboard-ws.log`.
- Watchdog stores its own PID in `.runtime/dashboard-ws-watchdog.pid` — `src/dashboard-stop.ts`
  kills the watchdog FIRST before the WS process to prevent restart loops.
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
- `src/dashboard-common.ts` — shared port allocation (Get-FreePort, Save/Read/Clear-DashboardPorts)
- `src/dashboard-ws-autostart.ts` — watchdog start with auto-recovery (10 restarts)
- `src/dashboard-start.ts` — full launcher (WS watchdog + Vite + Chrome)
- `src/dashboard-stop.ts` — cleanup stop (kills watchdog → PID files → port → process name)
- `vite.config.ts` — reads WS_PORT (proxy target) and VITE_DEV_PORT from env
- `.runtime/dashboard-ports.json` — persisted port assignments for stop/restart
- `.runtime/dashboard-ws.log` — watchdog heartbeat log
- `.runtime/dashboard-ws-watchdog.pid` — watchdog own PID (clean shutdown)

## maintenance-watchtower

Orquestador central de health checks, auto-healing y monitoreo continuo. Unifica los checks de
`health-check.ps1`, `stack-health-check.ps1` y el watchdog en un solo punto.

### Architecture

- **108 checks** en **25 componentes** (incluye process-hygiene + loop-guard + web-crawler):
  dashboard-ws, codegraph, ml-embeddings, engram, mcp, session, hooks, configs, tool-configs,
  security, governance, secret-scanner, cli-guard, hidden-spawns, cloud-connectors, tracing,
  state-persistence, audit, gentle-vanguard-db, model-provider-health, web-crawler, loop-guard,
  process-hygiene. _Live: `config/stack-metrics.json` (`gv metrics`)._
- **6 modos**: health, rebuild, report, autoheal, continuous, all.
- **Pipeline integrado**: corre `-Action autoheal -Quiet` con `lazy: true` al inicio de sesión (no
  bloquea).
- **Auto-healing**: detecta procesos caídos y los restaura automáticamente.

### Modes

| Action     | Command                                  | Description                      |
| ---------- | ---------------------------------------- | -------------------------------- |
| health     | `-Action health`                         | 108 checks, 25 componentes       |
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

- **106/108 PASS — 2 WARN — 0 FAIL — 0 SKIP** (loop-guard + web-crawler añadidos; 25 comps. Live:
  `config/stack-metrics.json`)
- Dashboard WS API 200 OK, watchdog con auto-restart (10 intentos)
- CodeGraph: 133 files, 1410 nodes, 1763 edges
- Puertos dinámicos con `Get-FreePort()` en `src/dashboard-common.ts`
- Pipeline session-autostart con `lazy: true` para steps no bloqueantes
- `src/dashboard-stop.ts` mata watchdog primero para evitar restart loops
- Frontend HTTP polling tolera caídas temporales del WS server
- **CLI Guard**: check anti-regresión que detecta el patrón roto
  `import.meta.url === \`file://${process.argv[1]}\``(no normaliza rutas Windows → main() nunca se ejecuta). Ver`src/auto-url-fix.ts`
  para el fix automático de 33 archivos.

---

## guardrail-orchestrator — Framework de Resiliencia Unificado

Punto central donde el orquestador (o cualquier agente) consulta **"¿qué hacer ante este fallo?"** y
obtiene una decisión coherente + aprendizaje. Es el complemento del anti-loop guard: mientras el
anti-loop detecta _bucles de razonamiento_ (misma estrategia fallando repetidamente), el orquestador
maneja _cualquier tipo de fallo_ con una decisión de acción y un bucle de aprendizaje.

### Filosofía

El stack debe ser **autónomo y resiliente**: capaz de detectar fallos, tomar acciones correctivas y
continuar sin intervención humana, aprendiendo de cada incidente. Los guardrails no sustituyen al
criterio — lo **escalan**: un humano revisa cuando quiere; el stack decide y actúa siempre, sin días
malos.

### Clasificación de fallos (10 categorías)

| Categoría   | Firmas típicas                                   | Acción     | ¿Superficie al usuario? |
| ----------- | ------------------------------------------------ | ---------- | ----------------------- |
| `config`    | config not found/invalid, JSON malformado        | `correct`  | No                      |
| `network`   | ECONNREFUSED, ETIMEDOUT, fetch failed            | `retry`    | No                      |
| `model`     | model not found, 429, rate limit, provider error | `retry`    | No                      |
| `db`        | SQLITE, database locked/corrupt, no such table   | `correct`  | No                      |
| `git`       | merge conflict, push rejected, non-fast-forward  | `retry`    | Sí                      |
| `security`  | prompt injection, blocked pattern, secret leaked | `block`    | Sí                      |
| `resource`  | token budget, out of memory, workload limit      | `isolate`  | No                      |
| `reasoning` | anti-loop, same strategy, max steps reached      | `escalate` | Sí                      |
| `quality`   | quality score, hallucination, lint/typecheck     | `correct`  | No                      |
| `unknown`   | no clasificado                                   | `continue` | Sí                      |

### Decisiones de acción

- **`retry`** — reintentar con backoff (red, modelo, git).
- **`correct`** — aplicar corrección automática (config, db, calidad).
- **`escalate`** — detener y escalar al usuario (razonamiento).
- **`isolate`** — aislar y limitar recursos (recurso).
- **`continue`** — continuar con advertencia (desconocido).
- **`block`** — detener la operación (seguridad).

### Aprendizaje (bucle)

Cada incidente se registra en `.session/guardrails/incidents.jsonl` con categoría, acción, fuente,
error y estado de resolución. `getCategoryStats()` expone la tasa de resolución por categoría, y
`resolveIncident(id, resolution)` cierra el bucle tras la recuperación. Esto permite que el stack
"aprenda" qué acción funciona para cada tipo de fallo y resuelva más rápido en el futuro.

### API principal

```ts
import { evaluateFailure, resolveIncident, getCategoryStats } from './guardrail-orchestrator.js';

// Clasifica, decide, registra incidente y devuelve si proceder
const guard = evaluateFailure({ error, source: 'delegate:sdd-apply' });
if (!guard.proceed) {
  // No reintentar a ciegas — usar guard.decision.guidance
}

// Cerrar el bucle de aprendizaje tras la recuperación
resolveIncident(guard.incident.id, 'retried successfully');
```

### Integración en el orquestador

`src/agent-delegator.ts` expone `delegateWithGuardrail()` que envuelve `delegateWithAntiLoop()`:

- Si la delegación falla, clasifica el fallo y registra un incidente.
- Si el guardrail dice NO proceder (`block`/`isolate`/`escalate`), devuelve un resultado sintético
  con la guía correctiva en vez de dejar que el caller reintente a ciegas.
- Si es procedible (`retry`/`correct`/`continue`), adjunta el `incident.id` para que el caller lo
  resuelva tras la recuperación.

### CLI

```bash
npx tsx src/guardrail-orchestrator.ts classify "<error>"   # categoría
npx tsx src/guardrail-orchestrator.ts decide "<error>"     # decisión JSON
npx tsx src/guardrail-orchestrator.ts evaluate "<error>" [src]  # resultado + incidente
npx tsx src/guardrail-orchestrator.ts stats                # aprendizaje por categoría
npx tsx src/guardrail-orchestrator.ts resolve <id> [res]   # marcar incidente resuelto
```

### Guardrails existentes que el orquestador reutiliza (no duplica)

| Guardrail                                | Rol                                                                |
| ---------------------------------------- | ------------------------------------------------------------------ |
| `anti-loop-guard.ts`                     | Detecta bucles de razonamiento (3 → change_strategy, 5 → escalate) |
| `correction-rules-engine.ts`             | Corrige config por scores de calidad                               |
| `resilience-handler.ts`                  | Timeout/retry/circuit-breaker/fallback por operación               |
| `auto-escalation.ts`                     | Escala por conteo de fallos (3/5/10)                               |
| `safety-guardrails.ts`                   | Evalúa mutaciones contra reglas constitucionales                   |
| `self-mutation-guard.ts`                 | Protege contra auto-modificación no deseada                        |
| `prompt-injection-guard.ts`              | Protege contra inyección de prompts                                |
| `workload-guard.ts` / `token-*-guard.ts` | Límites de recursos                                                |
| `circuit-breaker-v2.ts`                  | Circuit breakers por componente                                    |
| `self-healing-db.ts`                     | Auto-reparación de la base de datos                                |
| `session-close-guardian.ts`              | Guardián de cierre de sesión                                       |

### Tests

`tests/unit/guardrail-orchestrator.test.ts` — 17 tests (clasificación, decisión por categoría,
learning loop end-to-end, integración con `delegateWithGuardrail`).

---

## absorbed-knowledge

Conocimiento externo absorbido como nativo al stack (ADR-010, 2026-08-13). Ver
`docs/adr/ADR-010-knowledge-absorption-external-repos.md`.

### Secret Scanner nativo (`src/secret-scanner.ts`)

Detector de secrets/API keys en TS puro, reimplementado (sin copiar código GPL-3.0 de cariddi):

```bash
npm run scan:secrets -- --scan <path|url>      # archivo, directorio o URL
npm run scan:secrets -- --dir <dir>            # escaneo recursivo
npm run scan:secrets -- --scan . --json        # output JSON
```

- **80 patrones**: AWS, GCP, Azure, GitHub, GitLab, OpenAI, Anthropic, Slack, Stripe, JWT, private
  keys, y más (categorías: aws/gcp/azure/github/gitlab/llm/slack/payment/cloud/generic/private-key)
- Entropy Shannon opcional (`--entropy`, ≥3.5 bits/char) para filtrar falsos positivos
- Redacción automática por defecto (`--redact` / `--no-redact`)
- Exit codes: 0 = sin secrets, 1 = secrets encontrados, 2 = error
- Config en `config/secret-scanner.json`; tests en `tests/unit/secret-scanner.test.ts`

#### Integraciones del scanner en el stack

- **Pre-commit**: `.lefthook.yml` comando `secret-scanner` sobre los staged files (todos los tipos
  relevantes: ts/js/json/yml/yaml/md/env/toml/xml/py/ps1/sh/sql). Complementa a trufflehog y
  secretlint. Verificar con `npx lefthook validate`.
- **Watchtower**: componente `secret-scanner` en `src/core/maintenance-watchtower.ts`
  (`checkSecretScanner` — valida módulo, CLI, config y tests). Se ejecuta con `-Action health` (108
  checks, 25 componentes). Verificado 106/108 PASS (2 WARN: dashboard-ws transient).
- **Routing de subagentes**: `config/subagent-mapping.json` registra las skills absorbidas por rol:
  - **DEV**: DevSecOps (devsecops-scanning, secret-scanning gitleaks, secrets CI/CD, SBOM,
    dependency-confusion, supply-chain CI/CD)
  - **GOV**: compliance (NIST 800-30, NIST CSF, ISO 27001, GDPR, CMMC), MCP tool-poisoning,
    ai-provenance
  - **QA**: API security (OWASP API Top 10, WebSocket, inventory), prompt leakage, RAG injection
- **`src/recommend-agent.ts`**: keywords de cibersec añadidos a `matchDomain` (sbom, prompt
  injection, garak, promptfoo, guardrails, nist, iso 27001, cmmc, gitleaks, api security, owasp, mcp
  server, tool poisoning, etc.) → rutean a dominio `security` → `gov-agent`.

### Skills de ciberseguridad absorbidas (25, Apache-2.0)

En `.opencode/skills/` nivel 1, con frontmatter rico (mapeos MITRE ATT&CK/ATLAS, NIST CSF/AI RMF)

- triggers. Dominios:

- **AI/LLM Security**: `red-teaming-llms-with-garak`, `continuous-llm-red-teaming-with-promptfoo`,
  `defending-llms-with-guardrails`, `detecting-ai-model-prompt-injection-attacks`,
  `detecting-indirect-prompt-injection`, `testing-prompt-injection-in-rag-pipelines`,
  `testing-for-system-prompt-leakage`, `securing-agentic-ai-tool-invocation`,
  `auditing-mcp-servers-for-tool-poisoning`
- **DevSecOps / Supply Chain**: `implementing-devsecops-security-scanning`,
  `implementing-secret-scanning-with-gitleaks`, `implementing-secrets-scanning-in-ci-cd`,
  `generating-and-analyzing-sboms`, `analyzing-sbom-for-supply-chain-vulnerabilities`,
  `detecting-supply-chain-attacks-in-ci-cd`, `detecting-dependency-confusion`
- **API Security**: `conducting-api-security-testing`, `testing-api-security-with-owasp-top-10`,
  `testing-websocket-api-security`, `performing-api-inventory-and-discovery`
- **Compliance**: `conducting-cyber-risk-assessment-with-nist-800-30`,
  `performing-nist-csf-maturity-assessment`,
  `implementing-iso-27001-information-security-management`,
  `implementing-gdpr-data-protection-controls`, `achieving-cmmc-level-2-compliance`

⚠️ Técnicas ofensivas (red-team): uso restringido a entornos autorizados (notice legal en cada
skill).

### diagram-design (MIT, v2.3)

`.opencode/skills/diagram-design/` — 27 tipos de diagramas editoriales HTML/SVG self-contained
(arquitectura, flowchart, sequence, ER, timeline, swimlane, quadrant, radar, loop, Gantt,
data-flow…). Redibuja fuentes .drawio/Mermaid. Sin build step; abre directo en navegador. Usar para
ADRs, reportes y documentación de arquitectura en lugar de "Mermaid-slop".

### ai-provenance — política dual (MIT)

`.opencode/skills/ai-provenance/` — gestión de marcas de proveniencia AI (C2PA, Unicode, SynthID,
EXIF/XMP) en texto y archivos.

| Modo                     | Comportamiento                     | Activación                                                                   |
| ------------------------ | ---------------------------------- | ---------------------------------------------------------------------------- |
| **INSPECCIÓN** (default) | Detectar/reportar/verificar marcas | Automática, comportamiento normal                                            |
| **REMOCIÓN** (on-demand) | Limpiar C2PA/Unicode/metadatos     | **SOLO** solicitud explícita e inequívoca del usuario sobre contenido propio |

**Regla de oro**: el stack NUNCA remueve marcas de proveniencia en comportamiento normal. La
remoción es una capacidad de emergencia/privacidad que requiere petición explícita del usuario. Ante
dudas, inspeccionar y reportar; no limpiar.

## v4.0-infrastructure

Infraestructura de tracing, state persistence, auditoría, event sourcing, cloud connectors y health
API integrados en la pipeline de sesión.

### Distributed Tracing

- Script: `src/tracing-instrument.ts`
- Acciones: `start`, `end`, `error`
- Almacena spans en `.telemetry/spans/` y `.telemetry/traces/` (JSONL)
- Exporta OTLP a `http://localhost:4318/v1/traces`
- Pipeline: step `tracing-init` (lazy, session start) + cleanup close
- Funciones helper de tracing en `src/tracing-instrument.ts`

### State Persistence

| Componente | Script                         | Pipeline step                   |
| ---------- | ------------------------------ | ------------------------------- |
| Checkpoint | `src/checkpoint-manager.ts`    | `checkpoint-auto-create` (lazy) |
| Snapshot   | `src/snapshot-manager.ts`      | — (manual)                      |
| Rollback   | `src/rollback-orchestrator.ts` | — (manual)                      |

- Checkpoint: create/list/diff/verify/prune — almacena en `.session/checkpoints/`
- Snapshot: snapshot/list/prune — almacena en `.session/snapshots/`
- Rollback: restaura desde checkpoint con dry-run validation

### Audit Pipeline

- Script: `src/infrastructure/audit-pipeline.ts`
- Acciones: `log`, `status`, `query`, `archive`, `prune`
- Almacena en `.session/audit/logs/` (JSONL diario)
- Pipeline: step `audit-pipeline-init` (lazy, session start) + cleanup log

### Event Sourcing + Saga

| Componente  | Script                     | Pipeline step                |
| ----------- | -------------------------- | ---------------------------- |
| Event Store | `src/event-sourcing.ts`    | `event-sourcing-init` (lazy) |
| Saga        | `src/saga-orchestrator.ts` | — (manual)                   |

- Event sourcing: append/project/snapshot/prune — almacena en `.session/event-store/`
- Saga: create/register-step/complete/compensate/list — almacena en `.session/sagas/`

### Cloud Connectors (opt-in external promotion)

| Componente      | Script                      | Pipeline step                  |
| --------------- | --------------------------- | ------------------------------ |
| Hybrid Executor | `src/hybrid-executor.ts`    | `cloud-connectors-init` (lazy) |
| Agent Delegator | `src/agent-delegator.ts`    | —                              |
| Route+Delegate  | `src/route-and-delegate.ts` | —                              |

- Routing por costo/latencia/load con fallback automático
- Circuit breaker pattern (5 failures → OPEN, 2 successes → HALF_OPEN → CLOSED)
- Métricas en `.session/cloud-metrics.json` y `.session/hybrid-metrics.json`
- SkillInput serializado como JSON para paso por CLI (hashtable splatting `@splat`)
- Pipeline: step `cloud-connectors-init` (lazy, healthcheck ping al iniciar sesión); optional for
  local-first operation and not a local prerequisite.

### Dashboard Health API

`/api/health` retorna 7 componentes: `websocket`, `mcp`, `adaptive`, `cloud`, `tracing`,
`checkpoints`, `audit`. Cada uno con status `ok`/`unknown`/`degraded` y métricas específicas.
Verificado: 7/7 responden OK en entorno local.

### Notes

- **graphify CLI**: Use the stack-local Graphify command through `npm run graphify -- <command>`. It
  reads `graphify-out/graph.json` and supports `query`, `explain`, `path`, `affected`, `status`, and
  `update .`. Do not install the unrelated npm package `graphify@1.0.0`; it is a random graph
  generator, not this stack's knowledge graph CLI. Code freshness is still handled by `.codegraph/`
  and git hooks.
- **`$var:` syntax**: In PowerShell string interpolation, `$varname:` must be written as
  `${varname}:` to avoid parser errors. All instances are fixed.

### Autostart Pipeline (steps v4.0)

Los siguientes steps se agregaron al `config/session-autostart.config.json`:

| Step                       | Script                                 | Lazy |
| -------------------------- | -------------------------------------- | ---- |
| `judgment-day-correction`  | `src/correction-rules-engine.ts`       | ✅   |
| `cloud-connectors-init`    | `src/hybrid-executor.ts`               | ✅   |
| `cloud-connectors-metrics` | `src/tokens/token-budget-guard.ts`     | ✅   |
| `tracing-init`             | `src/tracing-instrument.ts`            | ✅   |
| `checkpoint-auto-create`   | `src/checkpoint-manager.ts`            | ✅   |
| `audit-pipeline-init`      | `src/infrastructure/audit-pipeline.ts` | ✅   |
| `event-sourcing-init`      | `src/event-sourcing.ts`                | ✅   |
| `post-session-learning`    | `src/post-autostart-summary.ts`        | ✅   |

## TypeScript Migrations

Los scripts PS1 core han sido migrados a TypeScript en `src/`:

| PS1 Original                                      | TS Replacement                                                                  | Comando                                            |
| ------------------------------------------------- | ------------------------------------------------------------------------------- | -------------------------------------------------- |
| `scripts/health-check/health-check.ps1`           | `src/core/health-check.ts`                                                      | `npm run health:check`                             |
| `scripts/utilities/session/session-autostart.ps1` | `src/session/session-autostart.ts` (wrapper de `src/core/session-autostart.ts`) | `npx tsx src/session/session-autostart.ts`         |
| `scripts/maintenance/maintenance-watchtower.ps1`  | `src/core/maintenance-watchtower.ts`                                            | `npm run watchtower` / `npm run watchtower:health` |

Los PS1 originales fueron eliminados tras verificar que las versiones TS cubren toda la
funcionalidad. Los comandos `npm run` apuntan exclusivamente a las versiones TS.

## Research Scripts

Los ~21 scripts Python duplicados en `research/rlhf-dataset-search/` fueron consolidados en un solo
script:

```bash
python research/rlhf-dataset-search/search_datasets.py --source huggingface --query "RLHF" --max-results 20
python research/rlhf-dataset-search/search_datasets.py --source arxiv --query "preference optimization" --csv
python research/rlhf-dataset-search/search_datasets.py --source all --query "reward model" --categorize
```

## Configuration Consolidation

- `config/model-router.json` ahora contiene los datos de routing policy, cost tracking y model
  levels (antes en `config/model-routing.json`, eliminado)
- 15 referencias a `model-routing.json` fueron actualizadas a `model-router.json` en toda la
  codebase

## Integraciones Nativas (Headroom / gentle-ai / awesome-llm)

Estrategias absorbidas de repos externos como TypeScript nativo (sin sidecars Python/Rust/Go):

### Structural Compression (`src/compression/structural-compression.ts`)

Absorbe 5 estrategias de compresión de Headroom en TS puro, complementando la compresión extractiva
(`prompt-compression.ts` / `output-compression.ts`):

| Estrategia         | Qué hace                                                          |
| ------------------ | ----------------------------------------------------------------- |
| SmartCrusher       | Comprime arrays JSON con decisión estadística (preserva outliers) |
| Tabular compaction | JSON tabular → CSV con esquema (lossless)                         |
| LogCompressor      | Colapsa logs/stack-traces de build/test                           |
| TextCrusher + BM25 | Prosa con relevancia a la query + dedup de shingles               |
| CrossCompression   | Dedup de bytes entre turnos                                       |

**Seguridad por modo** (crítico): `compressStructural(input, { mode })`.

- `mode: 'input'` (prompt/delegación) → **lossless-only** por defecto (`input.allowLossy: false`).
  Protege el razonamiento del modelo: no descarta filas/prosa que el modelo necesita.
- `mode: 'output'` (respuesta) → lossy OK (`output.allowLossy: true`). El modelo ya razonó.

`compressPrompt` usa `mode:'input'`; `compressOutput` usa `mode:'output'`. Config en
`config/structural-compression.json`. Tests: `tests/unit/structural-compression.test.ts`.

### Multi-perfiles por fase SDD (`src/ml/model-profile-switcher.ts`)

Convención de gentle-ai absorbida nativamente. `config/model-router.json` sección `profiles` define
perfiles `cheap`/`balanced`/`premium`, cada uno con temperature + hallucinationGuard por fase SDD
(BA/SAD/DEV/QA):

```bash
npm run profile:list    # listar perfiles
npm run profile:status  # perfil activo
npm run profile:set -- premium   # dry-run
npm run profile:apply -- premium # aplicar y persistir
```

### Hash-Chained Audit (`src/event-sourcing.ts`)

Patrón de awesome-llm (trust-gated audit trail). Cada evento guarda `prevHash` + `hash` (SHA-256),
formando una cadena a prueba de manipulación:

```bash
npx tsx src/event-sourcing.ts -Action append -AggregateId <id> -EventType <type> -EventData '{}'
npx tsx src/event-sourcing.ts -Action verify -AggregateId <id>   # valida integridad de la cadena
```

`verify` detecta manipulación (`tamper-mismatch` / `broken`). Tests:
`tests/unit/event-sourcing-hashchain.test.ts`.

### Retrieval Grader CRAG (`src/retrieval/retrieval-grader.ts`)

Patrón Corrective RAG de `awesome-llm-apps`. Gradúa la relevancia de chunks recuperados con BM25
lexical (sin ML) y dispara `keyword-fallback` si el retrieval es pobre (evita alucinación):

```bash
npx tsx src/retrieval/retrieval-grader.ts --query "..." --chunks '["...","..."]'
```

Tests: `tests/unit/retrieval-grader.test.ts`.

## Integraciones Nativas (Capability Stack)

Herramientas de capacidad absorbidas como TypeScript nativo — operativas desde la CLI, sin
dependencias de servicios externos para su funcionamiento core.

### Web Crawler dual-provider (`src/web/web-crawler.ts`)

Motor de adquisición de contenido web con **proveedores en cadena**:

| Operación | Primario                        | Fallback (sin API key, cero-config)                                                                                                |
| --------- | ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Scrape    | Firecrawl (`FIRECRAWL_API_KEY`) | **Jina Reader** `r.jina.ai/<url>` → markdown                                                                                       |
| Search    | Firecrawl (`FIRECRAWL_API_KEY`) | **DuckDuckGo HTML** `html.duckduckgo.com/html/` → parse `result__a`/`result__snippet`; segundo fallback **Bing RSS** `&format=rss` |
| Crawl/Map | Firecrawl (requiere key)        | Error descriptivo                                                                                                                  |

- `fallbackEnabled: true` por defecto en `config/web-crawler.json`; el health reporta
  `provider: firecrawl | jina-reader+ddg+bing` y `fallbackActive`.
- Cache SHA256 por provider (`cacheKey` con tag `fb`/`fc`) — evita envenenar resultados entre
  proveedores. Compresión estructural + logging a Nexus (`web-crawler.usage`).
- **GOTCHA**: Jina Reader bloquea User-Agents de navegador (Chrome → 403); usa `curl/8.0.1`. Los
  href de DuckDuckGo son redirects `//duckduckgo.com/l/?uddg=<encoded>` — decodificar el param
  `uddg` con `decodeURIComponent` para obtener la URL real. Bing search HTML sirve bot-detection a
  fetch de Node — usar el endpoint RSS.

```bash
npx tsx src/web/web-crawler-cli.ts search --query "typescript" --limit 5
npx tsx src/web/web-crawler-cli.ts scrape --url https://example.com
npx tsx src/web/web-crawler-cli.ts health
```

Tests: `tests/unit/web-crawler.test.ts` (14).

### Web Research Select (`src/web/web-research-select.ts`)

Pipeline de **búsqueda → selección por relevancia** para research: busca con el web-crawler (cadena
de proveedores), gradea los resultados con BM25 (retrieval-grader, patrón CRAG) y persiste el mejor
subconjunto en `.session/web-research/<slug>.json`.

```bash
npm run web:select -- --query "customer retention strategies" --limit 5
npm run web:select -- --query "GDPR breach notification" --deep        # scrape + grade full markdown (cap 20K chars)
npm run web:select -- --query "..." --deep-limit 3                      # top-N candidatos a scrapear
```

- Modo snippet: gradea títulos + snippets del buscador (rápido, cero scraping).
- Modo `--deep`: scrapea los top-N candidatos y reemplaza el score del snippet con `deepScore` sobre
  el markdown completo — más preciso para research profundo.
- `averageScore` en el output; resultados ordenados desc. Verdict `relevant` si avg ≥ umbral.
- Tests: `tests/unit/web-crawler.test.ts` (14, incluye DDG redirect decode).

### witr trace (`src/web/witr-wrapper.ts` + `src/web/witr-cli.ts`)

Wrapper TS del binario [witr](https://github.com/pranshuparmar/witr) — "Why Is This Running?". Traza
procesos/puertos/archivos/contenedores hasta su cadena causal, con auto-install y serialización
segura. Los campos sensibles (entorno, headers, argumentos, query strings, tokens, passwords y keys)
se omiten estructuralmente; los secretos embebidos en comandos se reemplazan antes de imprimir.

```bash
npx tsx src/web/witr-cli.ts process <pid>
npx tsx src/web/witr-cli.ts port <port>
```

Integrado en la watchtower para trazar la cadena causal de componentes con FAIL/WARN. Tests:
`tests/unit/witr-wrapper.test.ts`.

### Research Trends (`src/research/research-trends.ts` + `src/research/research-trends-cli.ts`)

Agregador de tendencias Last30Days desde GitHub, Hacker News, Stack Overflow, Dev.to y Reddit en un
`TrendReport` normalizado (themes, hottest, emerging). Alimenta el skill `web-research` y puede
cruzar páginas trending vía web-crawler (Firecrawl/scrape).

```bash
npx tsx src/research/research-trends-cli.ts fetch --timeframe 7d --sources github,hackernews
npx tsx src/research/research-trends-cli.ts themes --query "typescript OR rust"
npx tsx src/research/research-trends-cli.ts report
```

Funciones puras exportadas: `buildReport`, `queryThemes` (soporta `OR`), `renderMarkdown`,
`deserializeReport`. Tests: `tests/unit/research-trends.test.ts`.

### Humanizer (`src/humanize/humanizer.ts` + `src/humanize/humanizer-cli.ts`)

Transforma texto técnico/IA en prosa humana con análisis de legibilidad y scoring.

```bash
npm run humanize:analyze -- <texto>
npm run humanize:transform -- <texto>
npm run humanize:score -- <texto>
```

Tests: `tests/unit/humanizer.test.ts`.

### Design Tokens (`src/design/design-tokens.ts` + `src/design/design-system-cli.ts`)

Sistema de tokens de diseño (colores, tipografía, spacing) con generación de CSS/JSON y validación
de escala.

```bash
npm run design:generate   # regenera tokens desde config/design-tokens.json
npm run design:check      # valida consistencia
npm run design:scale      # comprueba escala
```

Tests: `tests/unit/design-tokens.test.ts`.

### Design System Oficial de Marca (v2 Premium — desde 2026-09-02)

Normativa completa: `rules/NORMATIVA-DESIGN-SYSTEM.md`. Resumen operativo:

- **Canon**: `docs/brand/BRAND-DECISION-2026-09-01.md` → `BRAND-KIT.md` → `TOKENS-v2.json`.
  Diseño = v2 Premium (bg `#0F1115`, purple `#a78bfa`, cyan `#22d3ee`, Space Grotesk);
  logo = monograma v1 con gradiente v2 (`assets/logo.svg` + mono/icon en `assets/`).
- **Paquete** `packages/gv-design-system/` v2.0.0 (src+dist versionados en ESTE repo, excepción
  al ignore): tokens consumibles, 7 componentes React, MCP server. Regenerar:
  `npx tsx packages/gv-design-system/src/cli/build-tokens.ts`.
- **CLI/visual**: `config/brand.json` (siempre regenerado desde el canon) → `npm run gv:tokens`.
- **Herramienta visual**: Design Hub (`apps/design-hub`, :8095) — token editor, componentes,
  assets, docs; experimentos en `src/labs/`. Apps desacopladas: cada app copia sus assets
  (snapshot) y tiene `apps/<app>/start.sh|stop.sh` nativos.
- `assets/gv-design-system.css` (clases `.gv-*`) CONGELADO en clases; solo `--gv-*` actualizables.
- Ciclo de cambio de marca: editar `TOKENS-v2.json` → regenerar (build-tokens + gv:tokens) →
  espejo del hub (`apps/design-hub/public/tokens/`) → commits (root + apps repo).

### Planning Templates (`src/planning/planning-templates.ts` + `src/planning/planning-templates.ts`)

Plantillas de planificación pre-write (planes de sesión, desglose de tareas, ADRs) con validación de
estructura. Tests: `tests/unit/planning-templates.test.ts`.

### Animations (`src/animations/`)

Motor de animaciones para la dashboard (fade-in, scale, transitions) con CLI de creación/análisis.

```bash
npm run animation:create -- <name>
npm run animation:analyze -- <name>
```

## CI/CD Pipeline

- `.github/workflows/ci.yml` — 6 jobs: lint-typecheck, test, dashboard-tests, dashboard-build,
  security-scan, workflow-lint
- `.github/workflows/security.yml` — 3 jobs: gitleaks, secretlint, trivy

## Testing

| Suite             | Comando                  | Tests |
| ----------------- | ------------------------ | ----- |
| Config validation | `npm run test:config`    | 6     |
| CI/CD workflows   | `npm run test:workflows` | 2     |
| Research scripts  | `npm run test:research`  | 5     |

## nexus — Base de Datos Operacional

**Nexus** es la base de datos operacional del stack Gentle-Vanguard (`.runtime/gentle-vanguard.db`).
Es el sistema nervioso central donde converge toda la información operacional: métricas, sesiones,
trazas, eventos, alertas, feedback, caché de respuestas, resultados de contratos, uso de skills, uso
de tokens, reglas de ruteo y session scoring.

### Identity Manifest

```json
{
  "name": "Nexus",
  "type": "SQLite (WAL mode, FK ON)",
  "path": ".runtime/gentle-vanguard.db",
  "manager": "DatabaseManager (singleton)",
  "tables": 23,
  "migrations": 7,
  "purpose": "Operational database — all stack operational data",
  "autoInit": true,
  "autoPrune": true,
  "autoBackup": true,
  "monitoredBy": "watchtower (gentle-vanguard-db component)",
  "pipelineSteps": ["db-init", "db-health-check", "db-prune"]
}
```

### Architecture

**Arquitectura**: Singleton `DatabaseManager` en `src/database/nexus/manager.ts` con migraciones
automáticas (WAL mode, foreign keys ON). Importable desde cualquier script del stack.

#### Migration 001 - Initial Schema (Core operacional)

- `metric_snapshots` — Time-series: tokens, sesiones, latencia, health cada 30s
- `sessions` — Historial de sesiones (upsert por session_id)
- `traces` — Distributed tracing spans (árbol trace_id → span_id)
- `events` — Event sourcing — append-only (type + JSON payload)
- `alerts` — Evaluaciones de alertas (5s broadcast cycle)
- `feedback` — User feedback thumbs up/down por span

#### Migration 002 - Stack Tables (Capa operacional extendida)

- `response_cache` — SHA256 key → response (TTL-aware, hit_count tracking)
- `contract_results` — SDD contract validation results
- `skill_usage` — Per-session skill usage tracking
- `token_usage` — Token accounting with generated `total_tokens` column
- `routing_rules` — Adaptive router persistence with hit_count

#### Migration 003 - Session Scoring (Wave 37 E)

- `session_scoring` — Quality scoring por sesión (delegations, corrections, proactive hits, etc.)

### Lifecycle

| Comando                   | Descripción                                                                 |
| ------------------------- | --------------------------------------------------------------------------- |
| `npm run db:init`         | Initialize DB + run all migrations (idempotent)                             |
| `npm run db:health`       | Health check: integrity, WAL, tables, rows                                  |
| `npm run db:backup`       | Safe online backup to `.runtime/backups/`                                   |
| `npm run db:restore`      | Restore latest backup                                                       |
| `npm run db:list`         | List available backups                                                      |
| `npm run db:optimize`     | WAL checkpoint + REINDEX + VACUUM                                           |
| `npm run db:prune`        | Prune old data from stack tables (events >30d, cache >7d, token_usage >90d) |
| `npm run db:prune:backup` | Keep only 10 most recent backups                                            |

### Pipeline Integration

3 lazy steps en `config/session-autostart.config.json` (non-blocking):

| Step              | Script                                | Propósito                     |
| ----------------- | ------------------------------------- | ----------------------------- |
| `db-init`         | `src/database/db-init.ts`             | Init + migrations cada sesión |
| `db-health-check` | `scripts/recovery/db-health-check.ts` | Validate SQLite integrity     |
| `db-prune`        | `scripts/database/db-prune.ts`        | Prune old data cada sesión    |

### Watchtower Monitoring

El componente `gentle-vanguard-db` en la watchtower verifica en cada ciclo:

1. **database file** — existencia y tamaño
2. **WAL file** — tamaño (> 5MB = WARN → checkpoint)
3. **integrity check** — `PASS` (ok), `WARN` (transient: DB locked, CLI unavailable), `FAIL`
   (corruption)
4. **size** — conteo de tablas y rows

### Normativa y Skill

- **Normativa**: `rules/NEXUS-NORMATIVA.md` — identidad, ciclo de vida, guardrails, retention policy
- **Skill**: `skills/nexus-database/SKILL.md` — cómo gestionar Nexus autónomamente
- **Comando**: load the skill via `"nexus"`, `"db"`, `"database"`, or `"gentle-vanguard.db"`
  triggers

### Relaciones con el Stack

| Componente          | Relación con Nexus                                |
| ------------------- | ------------------------------------------------- |
| **Dashboard**       | Lee métricas, sesiones, trazas, alertas, feedback |
| **Session Scoring** | Escribe/lee quality scores por sesión             |
| **Adaptive Router** | Persiste routing_rules con hit_count              |
| **Response Cache**  | Cachea respuestas SHA256 con TTL                  |
| **Watchtower**      | Monitorea integridad, tamaño, WAL en cada ciclo   |
| **Token Budget**    | Almacena token_usage por sesión                   |
| **SDD Contracts**   | Almacena contract_results para validación         |

### Verificación rápida

```powershell
# Verificar estado de Nexus
npm run db:health
npm run db:init
# Verificar integridad via watchtower
npm run watchtower:health
```

---

## Adaptive Steps System

**Versión implementada: 1.0** | **Fecha: Agosto 2026**

El stack implementa un sistema de steps adaptativos que auto-escala el presupuesto de pasos para
orquestador y subagentes basándose en la complejidad de la tarea.

### Problema Resuelto

Los subagentes estaban configurados con solo 6 steps (`steps: 6`), lo que causaba que se agotaran
rápidamente sin completar tareas complejas. El sistema adaptativo ahora asigna steps basándose en:

1. **Tipo de agente** (capacidad base)
2. **Complejidad de la tarea** (señales de texto)
3. **Cantidad de archivos** (heurística de tamaño)
4. **Historial de ejecuciones** (learning data en `.session/routing/routing-table.json`)

### Comandos del Sistema Adaptativo

```bash
# Estimar steps para una tarea
npx tsx src/adaptive-steps.ts --estimate "fix broken ps1 refs in 20 files"

# Aplicar steps a un agente específico
npx tsx src/adaptive-steps.ts --apply sdd-apply --steps 40

# Auto-estimar y aplicar
npx tsx src/adaptive-steps.ts --auto "complex refactoring task" --agent sdd-apply

# Reactivar agente con más steps (cuando agota)
npx tsx src/adaptive-steps.ts --resume sdd-apply --task_id ses_xxx

# Ver estado actual de todos los agentes
npx tsx src/adaptive-steps.ts --status

# Consultar agente recomendado para una tarea
npx tsx src/recommend-agent.ts --task "fix broken ps1 references" --topn 3
```

### Configuration por Agente (opencode.json)

| Agente              | Steps  | Tipo     | Complejidad            |
| ------------------- | ------ | -------- | ---------------------- |
| orchestrator        | 24     | Primary  | Media                  |
| sdd-explore         | 38     | Subagent | Alta (investigación)   |
| sdd-design          | 30     | Subagent | Alta (diseño)          |
| **sdd-apply**       | **52** | Subagent | **Muy alta (código)**  |
| sdd-verify          | 36     | Subagent | Alta (testing)         |
| doc-agent           | 34     | Subagent | Media-alta             |
| ops-agent           | 30     | Subagent | Media                  |
| gov-agent           | 38     | Subagent | Alta (seguridad)       |
| session-agent       | 25     | Subagent | Media                  |
| premortem-agent     | 30     | Subagent | Media-alta             |
| maintenance-agent   | 30     | Subagent | Media                  |
| **self-diag-agent** | **38** | Subagent | **Alta (diagnóstico)** |
| sia-agent           | 35     | Subagent | Alta (refinamiento)    |

### Señales de Complejidad Detectadas

- **+12 steps**: `files`, `refactor`, `migrate`, `implement`, `feature`, `module`
- **+8 steps**: `explore`, `investigate`, `research`, `audit`, `analyze`, `parallel`
- **+6 steps**: `test`, `verify`, `validate`, `typecheck`, `lint`
- **+4 steps**: `config`, `doc`, `readme`, `guide`, `schema`
- **+10 steps**: `complex`, `large`, `big`, `deep`, `nested`, `integrate`

### Routing Table Learnable

Para auto-asignación inteligente, el sistema usa `.session/routing/routing-table.json` con:

- 17 dominios pre-configurados (requirements, architecture, implementation, etc.)
- 10 overrides de alta prioridad (security audit, code review, bug fix, etc.)
- Success rate tracking por agente
- Auto-update con cada ejecución

### Auto-Reassignment

Cuando un agente reporta "maximum steps reached", el orquestador:

1. **Detecta** el evento en la respuesta del agente
2. **Re-asigna** automáticamente con `adaptive-steps.ts --resume`
3. **Incrementa** steps en +20 (máx 80)
4. **Preserva** el contexto y continúa desde donde quedó

### Archivos Clave del Sistema

- `src/adaptive-steps.ts` — Motor de estimación y escalado
- `src/recommend-agent.ts` — Bridge de auto-asignación con routing table
- `src/route-and-delegate.ts` — Delegador multi-dominio cross-platform (recomienda agente + delega
  con tiering)
- `.session/routing/routing-table.json` — Tabla de aprendizaje (creada automáticamente)
- `opencode.json` — Configuración de steps por agente
- `src/auto-ps1-fixer.ts` — Herramienta para migración PS1→TS

### Delegación Multi-Dominio (`src/route-and-delegate.ts`)

Recomienda el agente nativo adecuado para una petición y delega con el tiering de
`config/model-router.json` aplicado (`AGENT_TEMPERATURE`):

```bash
# Recomendar agente + delegar con contexto (cross-platform: npx.cmd en Windows, shellQuote en Unix)
npm run delegate:run -- --task "build a revenue forecast"
npm run delegate:run -- --task "audit gdpr compliance" --context "..." --topn 3
```

- Internamente usa `recommend-agent.ts` (STATIC_MAP 8 dominios de negocio + keywords
  negocio-primero + routing table aprendida)
- Inyecta `AGENT_TEMPERATURE` desde el tier del dominio (M6 tiering aplicado)
- Reporte de validación: `reports/delegation-validation-report.md`

### Integración en el Orquestador

El orquestador aplica automáticamente steps optimizados para cada delegación basándose en:

```typescript
// Prioridad de asignación:
// 1. routing-table.json (si existe historial)
// 2. adaptive-steps.ts --auto (estimación por tarea)
// 3. opencode.json defaults (fallback)
```

### Verificación de Funcionamiento

```bash
# 1. Verificar steps aplicados
npx tsx src/adaptive-steps.ts --status

# 2. Verificar routing table
npx tsx src/recommend-agent.ts --task "code review" --topn 3

# 3. Verificar health completo
npm run watchtower:health
```

---

## Auto-Fixer para Migraciones

Durante la migración PS1→TS se creó `src/auto-ps1-fixer.ts` para automatizar correcciones de
referencias rotas.

### Uso

```bash
# Modo dry-run (ver qué se arreglaría)
npx tsx src/auto-ps1-fixer.ts --dry-run

# Aplicar correcciones
npx tsx src/auto-ps1-fixer.ts

# Para archivos de configuración específicos
npx tsx src/auto-ps1-fixer-configs.ts
```

### Resultados de la Migración

| Métrica                | Valor                            |
| ---------------------- | -------------------------------- |
| Scripts PS1 migrados   | 390+                             |
| Scripts PS1 restantes  | ~60 (entrad, helpers, templates) |
| Referencias corregidas | 77+ en esta sesión               |
| TS Files totales       | 231+                             |
| Migration Waves        | 1-24 completadas                 |

---

## Token Tracking y Trazabilidad (Real y Agnóstico)

El stack mide el consumo REAL de tokens de forma **agnóstica a la herramienta** (no depende de
plugins de opencode/claude/cursor). Un daemon lee los datos de sesión que CADA herramienta persiste
en disco y los consolida en Nexus.

### Arquitectura

- **`src/tokens/token-ingest.ts`** — daemon de ingesta agnóstica:
  - Lee la DB de opencode (`~/.local/share/opencode/opencode.db`, tablas `session` y `message`).
  - Extensible a otras herramientas (registry `detectSources()`: opencode/codex/claude/cursor).
  - Escribe en Nexus: `token_usage` (por sesión), `token_transactions` (por mensaje, con agente
    orquestador/subagente), `token_savings` (cache + compresión).
  - Actualiza `reports/stack-live-observability-latest.json` y otros snapshots derivados.
- **Fuentes de tokens** — los rollouts JSONL de cada herramienta son la autoridad de uso bruto
  cuando la herramienta los produce (por ejemplo, ZCode y Codex). No se deben tratar como una base
  agregada.
- **Nexus** (`.runtime/gentle-vanguard.db`) — autoridad operativa para los agregados y transacciones
  ingeridos (`token_usage`, `token_transactions`, `token_savings`).
- **`src/tokens/token-usage-reader.ts`** — lector único: Nexus primero, luego el reporte live y
  fallbacks explícitos.
- **`src/tokens/token-metrics-store.ts`** — el close report lee tokens REALES desde Nexus y sus
  reportes derivados.

> **Compatibilidad:** `.session/token-usage.json` y `.session/session-current.json` pueden existir
> como snapshots/estado de sesión para consumidores heredados; no reemplazan la autoridad de Nexus
> ni la autoridad de los rollouts JSONL de las herramientas.

### Comandos

| Comando                | Descripción                                            |
| ---------------------- | ------------------------------------------------------ |
| `npm run token:ingest` | Ingesta una pasada (--once)                            |
| `npm run token:trace`  | Report de trazabilidad (transacciones/agentes/ahorros) |
| `npm run token:status` | Budget real: usado / presupuesto / %                   |

### Ciclo de vida

El lazy step `token-ingest-init` (`--watch 30`) en `config/session-autostart.config.json` arranca
con la sesión y captura en vivo hasta el cierre.

### Presupuestos (fuente única)

`config/token-budget-guard.json` — daily **5M**, perSession **3M** (valores realistas vs ~1.5M/día
real). `model-router.json` alineado.

### Trazabilidad disponible

- **Por transacción**: `token_transactions` (input/output/reasoning/cache/cost/model por mensaje).
- **Por sesión**: `token_usage` (241 sesiones, 658M tokens históricos).
- **Por agente**: orquestador (parent ROOT) vs subagentes (parent_id != ROOT), agrupados e
  individuales.
- **Ahorros**: `token_savings` — cache reads (1.061M tokens) + compresión del stack
  (prompt/output/structural).
