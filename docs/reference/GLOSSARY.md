# Gentle-Vanguard — Canonical Technical Glossary

> Single source of truth for stack terminology inside the repository. Presentation and
> Academy material (GENTLE_VANGUARD_MASTER) derives from this file; update here first.
> Format: what it is, why it exists, how it works, where it lives.

## Operating model

### Local-First / Server-Optional (ADR-0017)
- **What**: the official operating model — local operation is the supported default; server,
  Kubernetes, cloud and SaaS are opt-in evolution paths.
- **Why**: the stack must run fully on one machine without external dependencies; external
  promotion must never be presented as a local prerequisite.
- **How**: four operating profiles (`local-default`, `local-multi-tenant`,
  `server-promotion`, `saas-federated`) with distinct identity and data boundaries.
- **Where**: `docs/adr/ADR-0017-local-first-operating-model.md`, `docs/status/CANONICAL-STATUS.md`.

### Operating profile
The deployment shape a run takes (see ADR-0017). Defines whether authentication is
deployment-scoped, whether tenants apply, and which promotion gates become blocking.

## Core services

### Nexus
- **What**: the operational SQLite database (WAL mode) that converges all stack state.
- **Why**: one local, inspectable, backup-able store instead of scattered files and SaaS.
- **How**: singleton `DatabaseManager` with repositories per domain and numbered migrations
  (currently 27 tables, 15 migrations). Managed via `npm run db:*` commands.
- **Where**: `.runtime/gentle-vanguard.db`, `apps/web-dashboard/server/database/`.

### Engram
- **What**: persistent semantic memory across sessions (observations, verdicts, session summaries).
- **Why**: sessions that start from zero waste tokens and repeat decisions.
- **How**: MCP tools (`mem_save`, `mem_search`, `mem_judge`, ...) write observations with
  provenance; conflicts get explicit verdicts instead of silent overwrites.
- **Where**: `.engram-data/`, MCP server config in `.zcode/config.json`.

### CodeGraph / graphify
- **What**: two complementary code-knowledge indexes. graphify is the native AST graph
  (deterministic, no LLM); CodeGraph is the queried index used by tooling.
- **Why**: answer "where/how does X work" without re-reading the repo into context —
  the single largest token saving in daily operation.
- **How**: `npm run graphify -- build|update|query|explain`; MCP codegraph tools for
  callers/callees/impact.
- **Where**: `graphify-out/` (graph.json, GRAPH_REPORT.md, optional wiki).

### Watchtower
- **What**: health and auto-healing orchestrator — 97 checks across 21 components, 6 modes.
- **Why**: detect drift and degradation before it becomes a failed session.
- **How**: `npm run watchtower:health` (expected 97/97 PASS); `autoheal` runs lazily at
  session start. The dashboard probe uses the public `/api/health` endpoint.
- **Where**: `src/core/maintenance-watchtower.ts`.

### Dashboard
- **What**: local observability UI (React/TS/Vite) over real traces — no mock data.
- **Why**: see tokens, traces, alerts, routing and health in real time, locally.
- **How**: `npx tsx src/dashboard-start.ts` starts WS server + Vite; frontend tolerates WS
  drops via HTTP polling; watchdog auto-restarts.
- **Where**: `apps/web-dashboard/`, docs in `docs/dashboard/DASHBOARD.md`.

## Data and tenancy

### Tenant
A logical data boundary inside one deployment. All Nexus domain tables carry `tenant_id`;
reads and writes are tenant-scoped in SQL, not filtered in memory. Default local tenant:
`gentle-vanguard` (`GENTLE_TENANT_ID`).

### Source provenance (dashboard)
Classification of where dashboard data comes from: `database` (tenant-scoped, explicit),
`filesystem` (must declare `system-wide` or `deployment-tenant`; tenant-owned filesystem
data without an explicit `tenantId` is rejected). See
`apps/web-dashboard/server/dashboard-source-provenance.ts`.

### Routing learning loop
Per-tenant outcome recording for agent routing: every delegation records success/failure
(`recordRoutingOutcome`), `routing_rules` accumulates `success_count`/`success_rate`
(migration 015), and `recommend-agent` treats Nexus as the authority with legacy fallbacks.

## Security and identity

### RBAC v1
Dashboard role model `viewer < operator < admin`: reads need `viewer.read`, mutations
`operator.write`, `/api/admin/*` needs `admin`. Sessions are opaque, SQLite-backed,
CSRF double-submit protected; first principal bootstraps as admin. Deployment-scoped —
does not claim OIDC/LDAP/SSO.
- **Where**: `apps/web-dashboard/server/{auth,rbac}.ts`, `docs/security/DASHBOARD-ADMIN-STATUS.md`.

### Promotion gates
Opt-in contracts for external deployment: image digest pinning, Cosign signing evidence,
CNI/NetworkPolicy evidence, MCP sandbox evidence (`src/ci/deployment-prerequisites.ts`).
Local mode is informational (exit 0); `--promotion` mode is blocking. Missing external
inputs are operator-owned and never fabricated.

### Secret scanner
80-pattern entropy-aware scanner integrated into pre-commit and watchtower
(`npm run scan:secrets`), with redaction.

## Process and quality

### SDD lifecycle
Spec-Driven Development pipeline BA → SAD → DEV → QA with CI gates; PRs to protected
branches require a validated/done SDD (`sdd-gate`).

### Process lock / hidden spawns
Windows-specific discipline: every spawned process must be invisible (`windowsHide`,
direct `node --import tsx` execution so the PID is the real script PID). Regression test:
`tests/unit/run-command-hidden.test.ts`.

### Token tracking
Real, tool-agnostic usage accounting: `token-ingest` reads persisted usage from opencode,
zcode, codex and minimax, consolidating into Nexus (`token_usage`, `token_transactions`,
`token_savings`). Budgets live in `config/token-budget-guard.json`.

### Structural compression
Five strategies for context compression; `mode:'input'` is lossless-only (protects
reasoning), `mode:'output'` allows lossy. `src/compression/structural-compression.ts`.

### Circuit breaker v2
Shared failure-isolation wrapper for delegations and cloud connectors with per-circuit
config resolution (`agent_delegation`, `aws_lambda`, `azure_function`).

## External references

Curated external research supporting these designs: `docs/research/EXTERNAL-BEST-PRACTICES-2026-08.md`.
