# Roadmap

<p align="center">
  <b>Gentle-Vanguard — AI-First Development Workspace</b><br>
  <i>v3.5.0 · Updated 2026-08-02</i>
</p>

---

## Vision

Convertir Gentle-Vanguard en el workspace estándar para desarrollo asistido por IA: **local-first,
seguro, extensible, zero-drama.**

---

## Current (v6.4 — v8.0)

| Area                       | Feature                                                                                                                    | Status    |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------- | --------- |
| **Public Release**         | Zero-dependency, auto-installable stack. Updated README, badges, setup-complete.ps1 <!-- REF-OBSOLETA: setup-complete.ps1 eliminado; migrado a src/setup-complete.ts -->, dynamic ports, watchdog auto-recovery | ✅ v8.0.0 |
| **Dashboard UI**           | Knowledge Panel + Multi-repo View UX refinement, live updates (auto-refresh 30s), engram source, relevance colors          | ✅ v7.1.0 |
| **Multi-repo Mesh**        | Mesh API REST endpoints, cross-workspace MCP orchestration, dashboard MultiRepoView with real mesh data                    | ✅ v7.0.0 |
| **Engram Integration**     | knowledge-query.ps1 queries mem_search CLI directly; fallback to file scan + context-log <!-- REF-OBSOLETA: knowledge-query.ps1 eliminado; ver src/engram-rag-reindex.ts y tests/unit/knowledge-query.test.ts -->                                   | ✅ v7.0.0 |
| **MCP Native**             | MCP protocol as first-class citizen, local server registry, gateway, dashboard UI                                          | ✅ v6.4.0 |
| **MCP Quickstart**         | Pre-built MCP server templates (sqlite, filesystem, browser, memory) — enable with 1 command                               | ✅ v6.5.0 |
| **MCP SDK**                | Multi-language scaffold (ts, js, py, go, rs), auto-build, auto-register                                                    | ✅ v6.6.0 |
| **Knowledge Layer**        | Unified query: events, traces, feedback, checkpoints with relevance scoring                                                | ✅ v6.7.0 |
| **Multi-Tenant**           | Tenant isolation: session, engram, codegraph, audit, RBAC                                                                  | ✅ v5.1.0 |
| **Eval/Benchmark**         | Eval runner, registry, A/B prompt testing, quality gates                                                                   | ✅ v5.1.0 |
| **CI/CD Self-Healing**     | Retry engine, rollback, incident logger, GitHub Action                                                                     | ✅ v5.1.0 |
| **Self-Evolving Agents**   | Agent mutation via eval feedback with A/B safety guard                                                                     | ✅ v6.0   |
| **Cross-Workspace Mesh**   | Workspace discovery, manifest, task delegation                                                                             | ✅ v6.0   |
| **Auto Code Review**       | Pre-commit + PR review, style/security/SDD checks, autofix                                                                 | ✅ v6.0   |
| **Predictive Incidents**   | Anomaly detection (3σ), preemptive heal, false-positive learning                                                           | ✅ v6.0   |
| **Dashboard Multi-Tenant** | Per-tenant metrics, tenant selector in UI                                                                                  | ✅ v6.3.0 |

## Backlog — Migración PS1 → TS

| #   | Script                                                              | Tamaño | Prioridad | Estado                                    |
| --- | ------------------------------------------------------------------- | ------ | --------- | ----------------------------------------- |
| 1   | `src/security/security-orchestrator.ts`                        | 22 KB  | Alta      | ✅ Done (`src/security/security-orchestrator.ts`)  |
| 2   | `src/hybrid-executor.ts`        | —      | Alta      | ✅ Done (`src/hybrid-executor.ts`)        |
| 3   | `src/aws-delegator.ts`          | —      | Alta      | ✅ Done (`src/aws-delegator.ts`)          |
| 4   | `src/azure-delegator.ts`        | —      | Alta      | ✅ Done (`src/azure-delegator.ts`)        |
| 5   | `src/checkpoint-manager.ts`    | —      | Media     | ✅ Done (`src/checkpoint-manager.ts`)     |
| 6   | `src/snapshot-manager.ts`      | —      | Media     | ✅ Done (`src/snapshot-manager.ts`)       |
| 7   | `src/rollback-orchestrator.ts` | —      | Media     | ✅ Done (`src/rollback-orchestrator.ts`)  |
| 8   | `src/infrastructure/audit-pipeline.ts`                               | —      | Media     | ✅ Done (`src/infrastructure/audit-pipeline.ts`)         |
| 9   | `src/tracing-instrument.ts`              | —      | Media     | ✅ Done (`src/tracing-instrument.ts`)     |
| 10  | `src/event-sourcing.ts`        | —      | Media     | ✅ Done (`src/event-sourcing.ts`)         |
| 11  | `src/saga-orchestrator.ts`     | —      | Media     | ✅ Done (`src/saga-orchestrator.ts`)      |
| 12  | `src/session-autostart.ts`                   | —      | Baja      | ✅ Done (`src/session-autostart.ts`)      |
| 13  | `src/core/maintenance-watchtower.ts`                    | —      | Baja      | ✅ Done (`src/core/maintenance-watchtower.ts`) |

## Backlog — Mejoras Local-First

| #   | Feature                               | Prioridad | Tiempo est. | Descripción                                                             | Estado                          |
| --- | ------------------------------------- | --------- | ----------- | ----------------------------------------------------------------------- | ------------------------------- |
| 1   | **Dashboard offline mode**            | Media     | ~2h         | Funcionar sin dependencia del WS server, datos cacheados localmente     | ✅ Done                         |
| 2   | **Auto-update desde GitHub Releases** | Media     | ~1h         | El stack se actualiza solo: detecta nueva versión, descarga, aplica     | ✅ Done                         |
| 3   | **create-gentle-vanguard template**   | Baja      | ~2h         | `npx create-gentle-vanguard` para bootstrap de proyectos                | ✅ Done                         |
| 4   | **Plugin system local-first**         | Baja      | ~3h         | Plugins comunitarios sin dependencia cloud, solo git + archivos locales | ✅ Done                         |
| 5   | **Dashboard modo offline completo**   | Baja      | ~2h         | Toda la funcionalidad del dashboard sin conexión a WS                   | ✅ Done (metrics/traces/alerts) |

**Entregables Backlog Local-First (2026-08-09):**

- `apps/web-dashboard/src/lib/offlineCache.ts` — caché localStorage por-key (cap 200KB, staleness 5
  min).
- `apps/web-dashboard/src/hooks/useMetrics.ts` + `useAlerts.ts` + `Dashboard.tsx` +
  `TracingDashboard.tsx` — modo offline: `isOffline`, `lastUpdated`, banner amber "Offline mode —
  cached data".
- `src/check-version.ts` — fix: apunta al repo público `EmmanuelOrtiz87/gentle-vanguard-public` (el
  privado devolvía 404), override vía `GENTLE_VANGUARD_GH_REPO`. `src/auto-update.ts` +
  `npm run update:check` OK.
- `src/create-gentle-vanguard.ts` + `tests/unit/create-gentle-vanguard.test.ts` (12 tests) +
  `docs/product/CREATE-GENTLE-VANGUARD.md` — bootstrap
  `npx tsx src/create-gentle-vanguard.ts --name <app>`.
- `src/plugin-manager.ts` + `plugins/example-hello/` + `config/plugin-manifest-schema.json` +
  `config/plugin-registry.json` + `docs/product/PLUGIN-SYSTEM.md` — plugins local-first con hooks en
  procesos separados (seguridad), step lazy `plugin-registry-load`.

## Fase 1 — Consolidación corta (ahora)

| Acción                                                             | Objetivo                                           | Impacto | Estado  |
| ------------------------------------------------------------------ | -------------------------------------------------- | ------- | ------- |
| Definir módulos core vs experimental                               | Reducir ambigüedad operativa                       | Alto    | ✅ Done |
| Marcar módulos experimentales como opt-in                          | Evitar que se usen por defecto                     | Alto    | ✅ Done |
| Añadir validación de configuración de madurez                      | Sustituir intuición por contrato                   | Medio   | ✅ Done |
| Documentar la ruta de maduración del stack                         | Hacerla ejecutable y priorizada                    | Medio   | ✅ Done |
| Aplicar política explícita de activación                           | Obligar opt-in para módulos riesgosos              | Alto    | ✅ Done |
| Añadir gates de gobernanza antes de activar módulos experimentales | Evitar activaciones sin validación mínima          | Alto    | ✅ Done |
| Definir workflow formal de activación de módulos experimentales    | Garantizar revisión y aprobación antes del rollout | Alto    | ✅ Done |

**Entregables Fase 1:**

- `config/module-maturity.json` — registro de 24 módulos: 14 core, 8 experimental (opt-in) y 2
  deprecated, con criterios de activación y owner.
- `src/module-maturity.ts` — CLI y API de validación/gates:
  `list | --status | --validate <id> | --gate <id> [--run-checks]`.
- `docs/governance/MODULE-ACTIVATION-WORKFLOW.md` — proceso formal propuesta → revisión gov → gates
  mínimos → aprobación → activación/rollout.
- `docs/governance/activation-decisions/` — registro de aprobaciones (8 decisiones registradas, 1
  por módulo experimental activado).

**Estado de activación (2026-08-10):** los **8 módulos experimentales** están activados con 6/6
gates satisfied (tests, typecheck, lint, security-scan, governance-approval, owner-signoff):

| Módulo                 | Madurez      | Riesgo | Owner           | Gates |
| ---------------------- | ------------ | ------ | --------------- | ----- |
| root-cause-correlator  | beta         | medium | self-diag-agent | 6/6   |
| convergence-monitor    | experimental | medium | orchestrator    | 6/6   |
| fine-tuning-collector  | experimental | high   | ops-agent       | 6/6   |
| predictive-governor    | experimental | high   | ops-agent       | 6/6   |
| proactive-intelligence | experimental | high   | orchestrator    | 6/6   |
| trust-layer-stage8     | beta         | high   | gov-agent       | 6/6   |
| skill-evolution-engine | beta         | medium | orchestrator    | 6/6   |
| cross-workspace-mesh   | experimental | high   | ops-agent       | 6/6   |

Commits: `5a75d2ab` (3 módulos) + `4be9c891` (5 módulos). Todos los scripts validados
operacionalmente y ya integrados como steps lazy en `session-autostart.config.json`.

```bash
npx tsx src/module-maturity.ts --status
npx tsx src/module-maturity.ts --validate <module-id> --run-checks
npx tsx src/module-maturity.ts --gate <module-id>
```

## Guía de adopción

- Ver [docs/status/STACK-MATURITY-GUIDE.md](../status/STACK-MATURITY-GUIDE.md) para la política
  resumida de madurez del stack.

## Prioridad de migración PS1 → TS

- Ver [config/ps1-ts-migration.json](../../config/ps1-ts-migration.json) para la ola inicial de
  scripts críticos a migrar.
- Primera ola priorizada: security orchestrator, hybrid executor y checkpoint manager.

## Deprecado

| Feature                     | Motivo                                                                          |
| --------------------------- | ------------------------------------------------------------------------------- |
| **AGI Safety Layer (v9.0)** | Requiere infraestructura cloud/server — rompe principio local-first. No aplica. |

---

## Recent Milestones

| Version | Date       | Highlights                                                                                                                                                                                                                              |
| ------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| v9.0    | 2026-08-10 | Gobernanza de madurez completa: 8/8 módulos experimentales activados con gates 6/6 (MODULE-ACTIVATION-WORKFLOW), SBOM CycloneDX 1.7 integrado (464 componentes, validación nativa), ADR-002 MCP workspace, roadmap de optimización 100% |
| v8.0    | 2026-07-08 | Public Release: zero-dependency stack, auto-install, updated README, watchdog auto-recovery, dynamic ports                                                                                                                              |
| v7.1    | 2026-07-08 | Dashboard UI refinement: engram source in Knowledge Panel, auto-refresh 30s, relevance colors, error states                                                                                                                             |
| v7.0    | 2026-07-08 | Multi-repo Mesh API + Engram mem_search integration in knowledge-query                                                                                                                                                                  |
| v6.7    | 2026-07-07 | Knowledge Persistence Layer: unified query engine (knowledge-query.ps1) cruza events, traces, feedback, checkpoints <!-- REF-OBSOLETA: knowledge-query.ps1 eliminado en migración PS1→TS -->                                                                                                                     |
| v6.6    | 2026-07-07 | MCP SDK Scaffolder: create action multi-lenguaje (ts, js, py, go, rs) con auto-build y auto-register                                                                                                                                    |
| v6.5    | 2026-07-07 | MCP Quickstart: pre-built server templates (sqlite, filesystem, browser, memory), 1-command enable via src/mcp/mcp-manager.ts <!-- REF-OBSOLETA: mcp-manager.ps1 eliminado; migrado a src/mcp/mcp-manager.ts -->                                                                                                                      |
| v6.4    | 2026-07-07 | MCP Native: local MCP server registry, gateway, CLI manager (src/mcp/mcp-manager.ts), dashboard management UI (MCPServers.tsx), 3 REST endpoints, session pipeline integration <!-- REF-OBSOLETA: mcp-manager.ps1 eliminado; migrado a src/mcp/mcp-manager.ts -->                                                                 |
| v6.3    | 2026-07-07 | Dashboard Multi-Tenant: per-tenant metrics filtering, tenant selector UI, /api/tenants endpoint, /api/metrics?tenantId=                                                                                                                 |
| v6.2    | 2026-07-07 | Cross-Org Federation: federation auth with RSA handshake, org registry, capability-based authorization, /api/federation endpoint                                                                                                        |
| v6.1    | 2026-07-07 | AI Safety Layer: safety guardrails, prompt injection protection, mutation risk scoring, /api/safety endpoint                                                                                                                            |
| v6.0    | 2026-07-07 | Self-evolving agents, cross-workspace mesh, auto code review, predictive incident response                                                                                                                                              |
| v5.1    | 2026-07-07 | Multi-tenant isolation, eval/benchmark framework, CI/CD self-healing, 3 new configs, pipeline integration                                                                                                                               |
| v3.3.3  | 2026-06-19 | Watchtower 74/74 PASS, RBAC + CSP, audit pipeline, tracing, cloud connectors, Engram auto-sync                                                                                                                                          |
| v3.3.2  | 2026-06-18 | Dashboard i18n (3 idiomas), alert system, watchtower 60 checks, lifecycle scripts, trace system                                                                                                                                         |
| v3.3.1  | 2026-06-17 | CI/CD 35→12 workflows, structured logging, adapter consolidation, docker compose, health API                                                                                                                                            |
| v3.3.0  | 2026-06-05 | Community skills, CI validation, real marketplace                                                                                                                                                                                       |
