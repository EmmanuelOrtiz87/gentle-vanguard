# Roadmap

<p align="center">
  <b>Gentle-Vanguard — AI-First Development Workspace</b><br>
  <i>v8.0.1 · Updated 2026-07-08</i>
</p>

---

## Vision

Convertir Gentle-Vanguard en el workspace estándar para desarrollo asistido por IA: **local-first,
seguro, extensible, zero-drama.**

---

## Current (v6.4 — v8.0)

| Area                       | Feature                                                                                                                    | Status    |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------- | --------- |
| **Public Release**         | Zero-dependency, auto-installable stack. Updated README, badges, setup-complete.ps1, dynamic ports, watchdog auto-recovery | ✅ v8.0.0 |
| **Dashboard UI**           | Knowledge Panel + Multi-repo View UX refinement, live updates (auto-refresh 30s), engram source, relevance colors          | ✅ v7.1.0 |
| **Multi-repo Mesh**        | Mesh API REST endpoints, cross-workspace MCP orchestration, dashboard MultiRepoView with real mesh data                    | ✅ v7.0.0 |
| **Engram Integration**     | knowledge-query.ps1 queries mem_search CLI directly; fallback to file scan + context-log                                   | ✅ v7.0.0 |
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
| 1   | `scripts/security/security-orchestrator.ps1`                        | 22 KB  | Alta      | ✅ Done (`src/security-orchestrator.ts`)  |
| 2   | `scripts/utilities/ops/CLOUD-CONNECTORS/hybrid-executor.ps1`        | —      | Alta      | ✅ Done (`src/hybrid-executor.ts`)        |
| 3   | `scripts/utilities/ops/CLOUD-CONNECTORS/aws-delegator.ps1`          | —      | Alta      | 🔲 Pendiente                              |
| 4   | `scripts/utilities/ops/CLOUD-CONNECTORS/azure-delegator.ps1`        | —      | Alta      | 🔲 Pendiente                              |
| 5   | `scripts/utilities/ops/STATE-PERSISTENCE/checkpoint-manager.ps1`    | —      | Media     | ✅ Done (`src/checkpoint-manager.ts`)     |
| 6   | `scripts/utilities/ops/STATE-PERSISTENCE/snapshot-manager.ps1`      | —      | Media     | 🔲 Pendiente                              |
| 7   | `scripts/utilities/ops/STATE-PERSISTENCE/rollback-orchestrator.ps1` | —      | Media     | 🔲 Pendiente                              |
| 8   | `scripts/security/audit-pipeline.ps1`                               | —      | Media     | ✅ Done (`src/audit-pipeline.ts`)         |
| 9   | `scripts/utilities/ops/TRACING/tracing-instrument.ps1`              | —      | Media     | ✅ Done (`src/tracing-instrument.ts`)     |
| 10  | `scripts/utilities/ops/ADVANCED-PATTERNS/event-sourcing.ps1`        | —      | Media     | ✅ Done (`src/event-sourcing.ts`)         |
| 11  | `scripts/utilities/ops/ADVANCED-PATTERNS/saga-orchestrator.ps1`     | —      | Media     | ✅ Done (`src/saga-orchestrator.ts`)      |
| 12  | `scripts/utilities/session/session-autostart.ps1`                   | —      | Baja      | ✅ Done (`src/session-autostart.ts`)      |
| 13  | `scripts/maintenance/maintenance-watchtower.ps1`                    | —      | Baja      | ✅ Done (`src/maintenance-watchtower.ts`) |

## Backlog — Mejoras Local-First

| #   | Feature                               | Prioridad | Tiempo est. | Descripción                                                             |
| --- | ------------------------------------- | --------- | ----------- | ----------------------------------------------------------------------- |
| 1   | **Dashboard offline mode**            | Media     | ~2h         | Funcionar sin dependencia del WS server, datos cacheados localmente     |
| 2   | **Auto-update desde GitHub Releases** | Media     | ~1h         | El stack se actualiza solo: detecta nueva versión, descarga, aplica     |
| 3   | **create-gentle-vanguard template**   | Baja      | ~2h         | `npx create-gentle-vanguard` para bootstrap de proyectos                |
| 4   | **Plugin system local-first**         | Baja      | ~3h         | Plugins comunitarios sin dependencia cloud, solo git + archivos locales |
| 5   | **Dashboard modo offline completo**   | Baja      | ~2h         | Toda la funcionalidad del dashboard sin conexión a WS                   |

## Fase 1 — Consolidación corta (ahora)

| Acción                                                             | Objetivo                                           | Impacto |
| ------------------------------------------------------------------ | -------------------------------------------------- | ------- |
| Definir módulos core vs experimental                               | Reducir ambigüedad operativa                       | Alto    |
| Marcar módulos experimentales como opt-in                          | Evitar que se usen por defecto                     | Alto    |
| Añadir validación de configuración de madurez                      | Sustituir intuición por contrato                   | Medio   |
| Documentar la ruta de maduración del stack                         | Hacerla ejecutable y priorizada                    | Medio   |
| Aplicar política explícita de activación                           | Obligar opt-in para módulos riesgosos              | Alto    |
| Añadir gates de gobernanza antes de activar módulos experimentales | Evitar activaciones sin validación mínima          | Alto    |
| Definir workflow formal de activación de módulos experimentales    | Garantizar revisión y aprobación antes del rollout | Alto    |

## Guía de adopción

- Ver [docs/status/STACK-MATURITY-GUIDE.md](../status/STACK-MATURITY-GUIDE.md) para la política resumida de
  madurez del stack.

## Prioridad de migración PS1 → TS

- Ver [config/ps1-ts-migration.json](../../config/ps1-ts-migration.json) para la ola inicial de scripts
  críticos a migrar.
- Primera ola priorizada: security orchestrator, hybrid executor y checkpoint manager.

## Deprecado

| Feature                     | Motivo                                                                          |
| --------------------------- | ------------------------------------------------------------------------------- |
| **AGI Safety Layer (v9.0)** | Requiere infraestructura cloud/server — rompe principio local-first. No aplica. |

---

## Recent Milestones

| Version | Date       | Highlights                                                                                                                                                              |
| ------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| v8.0    | 2026-07-08 | Public Release: zero-dependency stack, auto-install, updated README, watchdog auto-recovery, dynamic ports                                                              |
| v7.1    | 2026-07-08 | Dashboard UI refinement: engram source in Knowledge Panel, auto-refresh 30s, relevance colors, error states                                                             |
| v7.0    | 2026-07-08 | Multi-repo Mesh API + Engram mem_search integration in knowledge-query                                                                                                  |
| v6.7    | 2026-07-07 | Knowledge Persistence Layer: unified query engine (knowledge-query.ps1) cruza events, traces, feedback, checkpoints                                                     |
| v6.6    | 2026-07-07 | MCP SDK Scaffolder: create action multi-lenguaje (ts, js, py, go, rs) con auto-build y auto-register                                                                    |
| v6.5    | 2026-07-07 | MCP Quickstart: pre-built server templates (sqlite, filesystem, browser, memory), 1-command enable via mcp-manager                                                      |
| v6.4    | 2026-07-07 | MCP Native: local MCP server registry, gateway, CLI manager (mcp-manager.ps1), dashboard management UI (MCPServers.tsx), 3 REST endpoints, session pipeline integration |
| v6.3    | 2026-07-07 | Dashboard Multi-Tenant: per-tenant metrics filtering, tenant selector UI, /api/tenants endpoint, /api/metrics?tenantId=                                                 |
| v6.2    | 2026-07-07 | Cross-Org Federation: federation auth with RSA handshake, org registry, capability-based authorization, /api/federation endpoint                                        |
| v6.1    | 2026-07-07 | AI Safety Layer: safety guardrails, prompt injection protection, mutation risk scoring, /api/safety endpoint                                                            |
| v6.0    | 2026-07-07 | Self-evolving agents, cross-workspace mesh, auto code review, predictive incident response                                                                              |
| v5.1    | 2026-07-07 | Multi-tenant isolation, eval/benchmark framework, CI/CD self-healing, 3 new configs, pipeline integration                                                               |
| v3.3.3  | 2026-06-19 | Watchtower 74/74 PASS, RBAC + CSP, audit pipeline, tracing, cloud connectors, Engram auto-sync                                                                          |
| v3.3.2  | 2026-06-18 | Dashboard i18n (3 idiomas), alert system, watchtower 60 checks, lifecycle scripts, trace system                                                                         |
| v3.3.1  | 2026-06-17 | CI/CD 35→12 workflows, structured logging, adapter consolidation, docker compose, health API                                                                            |
| v3.3.0  | 2026-06-05 | Community skills, CI validation, real marketplace                                                                                                                       |
