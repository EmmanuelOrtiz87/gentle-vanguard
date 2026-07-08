# Changelog

## [7.1.0] - 2026-07-08

### Changed

- **Dashboard UI (v7.1)**: UX refinements and live updates for Knowledge Panel and Multi-repo View.
  - `apps/web-dashboard/src/components/KnowledgePanel.tsx` — Added "engram" source with red badge and Braces icon, auto-search on source toggle, relevance color bar (green/yellow/gray), Ctrl+Enter shortcut, error state with retry, Refresh button with spinner, loading skeleton.
  - `apps/web-dashboard/src/components/MultiRepoView.tsx` — Auto-refresh every 30s with silent polling, "last checked" timestamp with Clock icon, error state with retry, connection status indicator.

## [7.0.0] - 2026-07-08

### Added

- **Multi-repo Orchestration (v7.0)**: Mesh API REST endpoints for cross-workspace MCP orchestration.
  - `apps/web-dashboard/server/mesh-api.ts` — REST handlers: `GET /api/mesh`, `POST /api/mesh/discover`, `POST /api/mesh/sync`. Reads federation-config.json + MCP registries + PID lock files across all mesh workspaces.
  - `apps/web-dashboard/server/websocket-server.ts` — 3 new routes for mesh data.
  - `apps/web-dashboard/src/components/MultiRepoView.tsx` — Full rewrite: consumes `/api/mesh` with real workspace data, Discover/Sync/Refresh controls, per-server start/stop, global status counters.
- **Engram Integration (v7.2)**: knowledge-query.ps1 now queries `mem_search` CLI directly before falling back to file scan and context-log summaries.

### Changed

- **VERSION**: Updated from 6.7.0 to 7.0.0.
- **ROADMAP**: v7.0 marked as completed, v7.2 moved from Future to Next.

## [6.7.0] - 2026-07-07

### Added

- **Knowledge Persistence Layer (v6.7)**: Unified query engine for workspace memory.
  - `scripts/utilities/knowledge/knowledge-query.ps1` — query CLI que cruza events, traces,
    feedback y checkpoints con scoring de relevancia y filtro temporal (`-TimeRange`).
  - `apps/web-dashboard/server/knowledge-api.ts` — REST endpoint `GET /api/knowledge?q=&sources=`.
  - `apps/web-dashboard/src/components/KnowledgePanel.tsx` — React UI con search bar, source
    checkboxes, resultados con badges color-coded y detalle expandible.
  - `apps/web-dashboard/src/App.tsx` — nueva ruta `/knowledge`.
- **SDD**: `docs/sdd/v6.7-knowledge-layer-sdd.md`.

### Changed

- **VERSION**: Updated from 6.6.0 to 6.7.0.
- **ROADMAP**: v6.7 marked as completed.

## [6.6.0] - 2026-07-07

### Added

- **MCP SDK / Scaffolder (v6.6)**: Multi-language MCP server generator.
  - `mcp-manager.ps1` `-Action create` extendido con 5 lenguajes: `-Lang ts|js|py|go|rs`.
  - Cada lenguaje genera boilerplate funcional con MCP hello world tool, package manager config
    (package.json, pyproject.toml, go.mod, Cargo.toml) y entry point.
  - Nuevos flags: `-Build` (npm install/pip install/go build/cargo build), `-Register` (auto-registro
    en mcp-registry.json), `-Start` (inicia el server post-registro).
  - TypeScript: tsconfig.json + src/index.ts con MCP SDK.
  - JavaScript: index.js con MCP SDK (sin compilación).
  - Python: pyproject.toml + server.py con MCP SDK Python.
  - Go: go.mod + main.go con mcp-go.
  - Rust: Cargo.toml + src/main.rs con rmcp.
- **Multi-repo Orchestration (v7.0)**: MCP server mesh across workspaces.
  - `scripts/utilities/MCP/mcp-mesh-scan.ps1` — 3 acciones: `discover` (escanea workspaces mesh
    por MCP registries), `status` (health check multi-repo), `sync` (copia templates entre repos).
- **SDDs**: `docs/sdd/v6.6-mcp-sdk-sdd.md`, `docs/sdd/v7.0-multi-repo-orchestration-sdd.md`.

### Changed

- **VERSION**: Updated from 6.5.0 to 6.6.0.
- **ROADMAP**: v6.6 marked as completed, v7.0 in Next section.

## [6.5.0] - 2026-07-07

### Added

- **MCP Quickstart (v6.5)**: Pre-built MCP server templates — enable any server with 1 command.
  - `config/mcp-templates.json` — 5 templates: sqlite, filesystem, memory, browser, git.
  - `mcp-manager.ps1` — 3 nuevas acciones: `quickstart` (registra + inicia desde template),
    `list-templates` (lista templates disponibles), `create` (scaffold boilerplate de servidor MCP
    con TypeScript SDK, tsconfig, package.json, src/index.ts hello world).
  - `maintenance-watchtower.ps1` — nuevo check de integridad de templates.
- **SDDs**: `docs/sdd/v6.4-mcp-native-sdd.md`, `docs/sdd/v6.5-mcp-quickstart-sdd.md`.

### Changed

- **VERSION**: Updated from 6.4.0 to 6.5.0.
- **ROADMAP**: Refactorizado — reemplazado marketplace/vscode con v6.6 MCP SDK, v6.7 Knowledge
  Layer, v7.0 Multi-repo Orchestration.
- **docs/QUICK-COMMANDS.md**: Comandos MCP agregados.

## [6.4.0] - 2026-07-07

### Added

- **MCP Native (v6.4)**: MCP (Model Context Protocol) como ciudadano de primera clase.
  - `config/mcp-registry.json` — registro central de servidores MCP con built-in `skill-server`
    y `engram-mcp`.
  - `scripts/utilities/MCP/mcp-manager.ps1` — CLI completa: register, unregister, list, start,
    stop, restart, health, reload.
  - `scripts/utilities/MCP/mcp-gateway.ps1` — gateway de ciclo de vida: start/stop/status/reload
    con salida JSON para APIs.
  - `apps/web-dashboard/server/mcp-gateway-api.ts` — REST API con 3 endpoints:
    `GET /api/mcp/servers` (listado con estado), `POST /api/mcp/servers` (registro),
    `POST /api/mcp/servers/{name}/{start|stop}` (control).
  - `apps/web-dashboard/src/components/MCPServers.tsx` — UI completa: tabla de servidores con
    estado en tiempo real, botones start/stop, formulario Add Server, refresh.
  - `apps/web-dashboard/src/types/mcp.ts` — interfaces TypeScript (MCPServerInfo, MCPServerStatus,
    MCPRegistry).
  - **Session pipeline**: nuevo step `mcp-gateway-init` (lazy) que inicia servidores MCP
    automáticamente al iniciar sesión.
  - **Dashboard nav**: nueva ruta `/mcp` con icono Cpu en la barra de navegación.

### Changed

- **VERSION**: Updated from 6.3.0 to 6.4.0.
- **ROADMAP**: v6.4 marked as completed, moved to Current section.

## [6.3.0] - 2026-07-07

### Added

- **Dashboard Multi-Tenant (v6.3)**: Per-tenant metrics filtering and tenant selector UI.
  - `src/components/TenantSelector.tsx` — self-contained dropdown that fetches `/api/tenants` from
    `config/tenant-registry.json`, writes `?tenantId=` to URL search params, shows colored indicator
    per tenant.
  - `server/real-data.ts:getTenantScopedMetrics(tenantId)` — reads tenant-scoped
    `.session/tenants/<id>/` directories (tokens, traces, sessions) and returns filtered
    `DashboardData`.
  - `server/websocket-server.ts` — `/api/metrics` accepts `?tenantId=` query param;
    `/api/tenants` endpoint returns `config/tenant-registry.json`.
  - `src/hooks/useMetrics.ts` — accepts `initialTenantId`, passes `?tenantId=` to fetch URL,
    exposes `tenantId`/`setTenantId` state.
  - `src/types/tenant.ts` — `TenantInfo`, `TenantMetrics` interfaces.
  - **Schema**: Added `tenantId?` and `tenantName?` to `DashboardData`.
- **SDD**: `docs/sdd/v6.3-dashboard-multi-tenant-sdd.md` with full design, data flow, acceptance
  criteria.

### Changed

- **VERSION**: Updated from 6.2.0 to 6.3.0.
- **ROADMAP**: v6.3 marked as completed, moved to Current section.

## [6.2.0] - 2026-07-07

### Added

- **Cross-Org Federation (v6.2)**: Multi-organization mesh with trust and auth boundaries.
  - `scripts/utilities/FEDERATION/federation-auth.ps1` — RSA key pair generation, challenge-response
    handshake protocol, signature verification, delegation tokens with configurable expiry.
    Persists to `.session/federation/`.
  - `scripts/utilities/FEDERATION/org-registry.ps1` — org registration with public key + approved
    capabilities, seed-based discovery, trust status reporting, untrust/remove workflow.
    Registry stored in `.session/federation/org-registry.json`.
- **Mesh Extension**: `cross-workspace-mesh.ps1` updated with `-OrgId` parameter on all actions.
  `discover` filters by org and includes org-registry peers. `delegate` validates capability approval
  and trust before delegating. `status` shows known/trusted org count.
- **Config**: `config/federation-config.json` — local org identity, discovery settings, auth
  parameters, trust defaults (new orgs untrusted by default), capability tiers (public/protected/private).
- **Dashboard endpoint**: `/api/federation` returns real-time federation metrics: known/trusted orgs,
  pending handshakes, token expiry, per-org trust status and approved capabilities.

### Changed

- **VERSION**: Updated from 6.1.0 to 6.2.0.
- **ROADMAP**: v6.2 marked as completed, moved to Recent Milestones.
- **VERSION**: Updated from 6.1.0 to 6.2.0.

## [6.1.0] - 2026-07-07

### Added

- **AI Safety Layer (v6.1)**: Comprehensive safety framework for self-evolving agents.
  - `scripts/utilities/SAFETY/safety-guardrails.ps1` — validates mutations against 5 constitutional rules,
    6 blocked patterns, and 3 resource limits. Logs all decisions to `.session/safety/audit/`.
  - `scripts/utilities/SAFETY/prompt-injection-guard.ps1` — scans for prompt injection via pattern-based,
    structural, and entropy-based detection. Supports sanitization at low/medium/high strictness.
  - `scripts/utilities/SAFETY/mutation-safety-scorer.ps1` — multi-signal safety scoring (scope impact,
    capability drift, pattern violations, historical risk, similarity to bad mutations). Outputs risk
    level: low (auto-approve), medium (escalate), high (block).
- **Integration**: `self-evolve-engine.ps1` now calls safety guardrails + scorer before every mutation.
  Mutations violating constitutional rules or scoring high risk are blocked. Medium-risk mutations
  are escalated for human approval. Safety-aware `status` output shows blocked count.
- **Config**: `config/safety-layer.json` — full safety configuration. `config/evolution-config.json`
  updated with `safetyIntegration` section referencing all v6.1 safety scripts.
- **Dashboard endpoint**: `/api/safety` returns real-time safety metrics (guardrail checks, scorer
  evaluations, injection scans, blocked/allowed counts, last risk score/level).

### Changed

- **VERSION**: Updated from 5.1.0 to 6.1.0.
- **ROADMAP**: v6.1 marked as completed, moved to Recent Milestones.

## [5.1.0] - 2026-07-07

### Added

- **Multi-Tenant Isolation (v5.1)**: `scripts/utilities/TENANT/tenant-context.ps1` — tenant ID
  resolution via env var, workspace path, or config. Tenant-scoped `.session/`, `.codegraph/`,
  `.telemetry/` directories with isolation validation. Single-tenant backward compatible.
- **Eval/Benchmark Framework (v5.1)**: `scripts/utilities/EVAL/eval-runner.ps1` — test suite executor
  with configurable scorers. `eval-registry.ps1` — versioned result storage with list/compare/prune.
  `ab-prompt-runner.ps1` — A/B prompt variant testing with statistical delta. `eval-quality-gate.ps1`
  — threshold-based pipeline blocking. 3 test suites in `.eval/suites/`.
- **CI/CD Self-Healing (v5.1)**: `scripts/utilities/CI/ci-retry-engine.ps1` — exponential backoff
  retry with failure classification (TRANSIENT/PERMANENT/SECURITY). `ci-rollback-engine.ps1` — git
  revert + re-deploy with safe branch protection. `ci-incident-logger.ps1` — structured incident
  logging to `.session/audit/incidents/` + dashboard alerts. `.github/actions/self-heal/action.yml`
  — GitHub Actions composite action for workflow-level self-heal.
- **Autonomous Evolution (v6.0)**: `scripts/utilities/EVOLVE/self-evolve-engine.ps1` — agent
  self-mutation (prompt-tuning, skill-composition, tool-selection) based on eval feedback with A/B
  safety guard. `cross-workspace-mesh.ps1` — workspace discovery via manifest + task delegation.
  `auto-code-review.ps1` — pre-commit + PR review with style/security/performance/SDD checks and
  auto-fix. `predictive-incident-response.ps1` — anomaly detection (moving average + 3σ) with
  preemptive auto-heal and false-positive learning.
- **Configs**: `config/evolution-config.json`, `config/ci-self-heal.json`,
  `config/tenant-registry.json`, `config/eval-gates.json` — all with versioned schemas.

### Changed

- **Session pipeline**: `session-start-optimized.ps1` now resolves tenant context at startup and
  exports `GENTLE_TENANT_*` env vars for downstream scripts.
- **Pre-commit hooks**: `.lefthook.yml` added `auto-code-review` step for staged files.
- **VERSION**: Updated from 3.3.3 to 5.1.0 reflecting full v5.1+v6.0 feature set.

## [3.3.3] - 2026-06-19

### Fixed

- **Maintenance Watchtower**: Eliminado falso WARN por watchdog PID faltante cuando WS corre
  standalone. El check ahora reporta PASS "WS running standalone" si el servidor responde, aunque no
  haya watchdog. Autoheal optimizado: no reinicia el WS si ya está vivo (evita conflictos de puerto
  y procesos duplicados). Resultado: 74/74 PASS, 0 WARN, 0 FAIL.

### Changed

- **Dashboard real-data.ts**: Expansión de métricas y endpoints para monitoreo en tiempo real.
- **websocket-server.ts**: Mejoras de resiliencia en la conexión WebSocket.
- **Dashboard.tsx**: Nuevos paneles de monitoreo con indicadores de salud.
- **types/dashboard.ts**: Tipos extendidos para alertas y trazabilidad.
- **session-autostart.config.json**: Steps v4.0 integrados (tracing, checkpoint, audit,
  event-sourcing, cloud-connectors) todos con lazy: true.
- **docker-compose.yml**: Servicios adicionais para el stack de monitoreo.
- **session-scoring.ps1**: Algoritmo de scoring mejorado con pesos ajustables.

### Added

- **RBAC + CSP configs**: `config/rbac-policy.json` y `config/security-csp.json` para gobernanza.
- **Audit pipeline**: `scripts/security/audit-pipeline.ps1` con log JSONL diario.
- **State persistence**: Checkpoint/snapshot/rollback en `.session/`.
- **Tracing system**: OpenTelemetry spans en `.telemetry/` con export Prometheus.
- **Cloud connectors**: Hybrid executor + AWS/Azure delegators con circuit breaker.
- **Correction rules engine**: `scripts/adaptive/correction-rules-engine.ps1` para auto-corrección.
- **Engram auto-sync**: `scripts/utilities/memory/ENGRAM/engram-auto-sync.ps1`.
- **k8s/OpenTelemetry configs**: Despliegue Kubernetes y configs de tracing.
- **Integration tests**: Tests para cloud-connectors y phase-13-2-3.

## [3.3.2] - 2026-06-18

### Added

- **Dashboard i18n**: 3 idiomas (en/es/pt-BR) con `useLocale.ts` — 14 métricas localizadas.
- **Alert System**: 8 reglas configurables en `config/dashboard-alerts.json`, hook `useAlerts.ts`.
- **Maintenance Watchtower**: 60 checks en 11 componentes, 6 modos
  (health/rebuild/report/autoheal/continuous/all).
- **Info Popups**: Componente `InfoPopup.tsx` con animación fade-in + scale para descripción de
  métricas.
- **Dashboard lifecycle scripts**: `dashboard-common.ps1` (puertos dinámicos),
  `dashboard-start.ps1`, `dashboard-stop.ps1`, `dashboard-ws-autostart.ps1` (watchdog con
  auto-recovery).
- **Security & Tool Configs**: `SECURITY.md`, `.clinerules`, `.cursorrules`,
  `NORMATIVA-PNPM-SECURITY.md`, `NORMATIVAS-PERFORMANCE.md`.
- **norms-registry.json**: Schema versionado con hitCount, successRate.
- **Trace system**: `trace-logger.ps1` para depuración del pipeline pre-process-input.

### Changed

- **Dashboard server refactor**: WebSocket + REST API resiliente con HTTP polling fallback en
  `useMetrics.ts`.
- **Watchtower consolidation**: Unifica health-check.ps1, stack-health-check.ps1 y watchdog en un
  solo orquestador.
- **Dashboard components**: TracingDashboard con waterfall view mejorado, SessionTable
  refactorizado, MetricsCard con colores semánticos, ValidationPanel con info popups.

### Fixed

- **Pre-process pipeline**: Debug logging, health check integration, tool detection mejorado.
- **Dashboard health**: Integración end-to-end con el ecosistema de monitoreo.

## [3.3.1] - 2026-06-17

### Changed

- **CI/CD Consolidation**: 35 workflows reduced to 12 (6 reusable + 6 triggers + 4 retained).
  Reusable workflow_call pattern for lint, test, security, docker, release, governance.
- **Structured Logging**: New `Logger.psm1` module writes JSONL to `.session/logs/`. Integrated into
  all 5 adaptive scripts (correction-capture, session-scoring, pattern-detector, auto-norm-learner,
  auto-norm-enforcer).
- **Dual-Write Norms**: `auto-norm-learner.ps1` now writes both `LEARNED-NORMS.md` (backward
  compatible) and `norms-registry.json` (144 normas with versioned schema, hitCount, successRate).
- **Adapter Consolidation**: 3 JS adapters (antigravity, codex, windsurf) merged into one TypeScript
  `adapters/index.ts` (570→80 lines).
- **Docker Compose**: Root `docker-compose.yml` with 5 services (web-dashboard, mcp-server,
  websocket-server, health-api, pwsh-toolbox) — all with healthchecks.
- **Health Endpoint**: Expanded `/api/health` to report websocket, MCP, and adaptive component
  status (normsLoaded, sessionScore).

### Removed

- **skills-archive/**: Deleted ~1000 files of dead code (skills migrated to root `skills/` long
  ago).
- **29 legacy workflows**: Replaced by 6 reusable + 3 trigger workflows.
- **Root Python scripts**: 22 RLHF-related scripts moved to `research/rlhf-dataset-search/`.

### Fixed

- **package.json**: Version corrected from `"1.0.1"` to `"3.3.0"` (was out of sync).

## [3.3.0] - 2026-06-05

### Added

- **Community Skills**: Issue template for contributions, CI validation workflow, real marketplace
  API scanning `skills/` directory, `submit-community-skill.ps1` packaging script
- **Global Health Dashboard**: `GlobalHealth.tsx` component with cross-repo status,
  `global-health-api.ts` endpoint, integrated into Dashboard and WebSocket metrics
- **CI/CD Expansion**: Root `Dockerfile` (multi-stage MCP server), dashboard `Dockerfile`
  (Vite→nginx), `nginx.conf`, `docker-validate.yml`, `integration-tests.yml`, 14 API integration
  tests, 6-service `docker-compose.test.yml`
- **Auto-Update**: `check-version.ps1` (GitHub API semver comparison), `auto-update.ps1`
  (download/backup/restore), `gentle-vanguard.ps1` updated with `-Update`/`-CheckVersion` flags and
  dynamic version from `VERSION` file, `auto-update.yml` release workflow
- **CopilotKit Patterns (Fase 1-4)**: Native adoption of 5 CopilotKit patterns over MCP
- **AG-UI Protocol**: 7 ui_hints renderers (metric, datatable, chart, diff, form, list, alert) in
  AgentMessage component
- **Agent Chat Interface**: Conversational UI with @mentions autocomplete and suggested actions
- **Human-in-the-Loop**: 4-mode modal (confirmation, selection, form, review) with auto-detection
- **Shared State Bridge**: Event bus filesystem watcher with 3 WebSocket channels (state_history,
  state_event, state_tasks)
- **Task Control** (`/tasks`): Real-time task monitoring with status icons and quick dispatch
- **Session Timeline** (`/timeline`): Visual event timeline with expandable JSON payloads
- **Session Persistence**: File-based session history in `.event-bus/sessions-history.json`
- **useSharedState hook**: React hook for event bus state consumption
- **Route expansion**: `/tasks` and `/timeline` routes with dedicated wrapper pages

### Enhanced

- **AgentChat**: Empty state now shows suggested action chips + agent selector
- **AgentChat Sidebar**: Added History panel showing persistent sessions with timestamps
- **AgentChat Input**: Inline @mentions autocomplete with filtered dropdown
- **WebSocket Server**: Added `list_history` action, `agent_history` message type
- **WebSocket Server**: Session persistence with save/load from disk

### Technical

- `server/shared-state-bridge.ts` — New singleton for event bus filesystem polling
- `src/hooks/useSharedState.ts` — New React hook for shared state consumption
- `src/components/TaskControl.tsx` — New component for task monitoring UI
- `src/components/SessionTimeline.tsx` — New component for event timeline UI
- `server/websocket-server.ts` — Extended with history persistence, emit_event action
- `src/hooks/useAgentStream.ts` — Extended with historySessions state, listHistory method
- `src/components/AgentChat.tsx` — Rewritten with @mentions, suggested actions, history panel
- Build: `tsc --noEmit` 0 errors, `vite build` 3.01s
- No CopilotKit dependency added — all patterns implemented natively over MCP

## [3.1.0] - 2026-06-03

### Added

- **Dashboard v4**: OpenTelemetry tracing visualization with E2E traceability
- **Skill Marketplace**: Publishing, rating, and review system for skills
- **Interactive Documentation**: Guided tutorials with progress tracking
- **Performance Optimizations**: Code splitting with lazy loading and manual chunks
- **React Router**: Navigation between Dashboard, Tracing, Marketplace, and Docs

### Enhanced

- **Web Dashboard**: Modular architecture with separate chunks for vendor, charts, icons
- **Build Process**: Optimized bundle sizes with dynamic imports
- **User Experience**: Navigation bar with seamless view switching

### Technical

- Added `TracingDashboard.tsx` for OpenTelemetry trace visualization
- Added `Marketplace.tsx` with skill listings, search, and reviews
- Added `InteractiveDocs.tsx` with tutorial system
- Implemented code splitting in `vite.config.ts`
- Integrated React Router with lazy loading and Suspense

## [3.0.0] - 2026-06-03

### Added

- **Fase 3 Implementation**: MCP Native, Web UI, Multi-repo orchestration
- **MCP Server v2.0.0**: 5 tools + 3 prompts with native SDK
- **Web Dashboard v1.0.0**: React SPA with WebSocket real-time metrics
- **Multi-repo Engine v2.0.0**: 7 actions with Pester tests
- **Test Suite**: 16 tests (Pester + Vitest)
- **Skill Registry Sync**: 385 skills synchronized
- **CI/CD**: GitHub Action for skill registry validation

### Enhanced

- **Observability**: OpenTelemetry tracer with span management
- **Benchmarking**: Automated skill benchmark suite
- **Auto-update**: Launcher with rollback capability
- **Docker**: Containerized test environment
- **S3 Distribution**: CloudFront integration

## [2.30.0] - Previous

See previous changelog entries...
