# Roadmap

<p align="center">
  <b>Gentle-Vanguard — AI-First Development Workspace</b><br>
  <i>v6.7.0 · Updated 2026-07-07</i>
</p>

---

## Vision

Convertir Gentle-Vanguard en el workspace estándar para desarrollo asistido por IA: **local-first,
seguro, extensible, zero-drama.**

---

## Current (v6.4 — v6.7)

| Area                     | Feature                                                   | Status      |
| ------------------------ | --------------------------------------------------------- | ----------- |
| **MCP Native**           | MCP protocol as first-class citizen, local server registry, gateway, dashboard UI | ✅ v6.4.0   |
| **MCP Quickstart**       | Pre-built MCP server templates (sqlite, filesystem, browser, memory) — enable with 1 command | ✅ v6.5.0   |
| **MCP SDK**              | Multi-language scaffold (ts, js, py, go, rs), auto-build, auto-register | ✅ v6.6.0   |
| **Knowledge Layer**      | Unified query: events, traces, feedback, checkpoints with relevance scoring | ✅ v6.7.0   |
| **Multi-Tenant**         | Tenant isolation: session, engram, codegraph, audit, RBAC | ✅ v5.1.0   |
| **Eval/Benchmark**       | Eval runner, registry, A/B prompt testing, quality gates  | ✅ v5.1.0   |
| **CI/CD Self-Healing**   | Retry engine, rollback, incident logger, GitHub Action    | ✅ v5.1.0   |
| **Self-Evolving Agents** | Agent mutation via eval feedback with A/B safety guard    | ✅ v6.0     |
| **Cross-Workspace Mesh** | Workspace discovery, manifest, task delegation            | ✅ v6.0     |
| **Auto Code Review**     | Pre-commit + PR review, style/security/SDD checks, autofix| ✅ v6.0     |
| **Predictive Incidents** | Anomaly detection (3σ), preemptive heal, false-positive learning | ✅ v6.0 |
| **Dashboard Multi-Tenant** | Per-tenant metrics, tenant selector in UI                | ✅ v6.3.0   |

## Next (v7.0+)

| Version | Feature                                                    | Priority | Descripción |
| ------- | ---------------------------------------------------------- | -------- | ----------- |
| v7.0    | **Multi-repo Orchestration**                               | Medium   | mcp-mesh-scan creado, faltan dashboard MultiRepoView + endpoints REST |

## Future

| Version | Feature                                                    | Priority | Descripción |
| ------- | ---------------------------------------------------------- | -------- | ----------- |
| v7.1    | **Dashboard UI**                                           | Medium   | Knowledge Panel + Multi-repo View en dashboard |
| v7.2    | **Engram Integration**                                     | Low      | Integrar mem_search directamente en knowledge-query |
| v8.0    | **Public Release**                                         | Low      | Auto-instalable, auto-configurable, zero-dependency |

## Long Term

| Area                         | Vision                                                          |
| ---------------------------- | --------------------------------------------------------------- |
| **Public Release**           | Auto-instalable, auto-configurable, zero-dependency setup       |
| **Full AGI Safety**          | Alignment layer for autonomous code generation and deployment   |

---

## Recent Milestones

| Version | Date       | Highlights                                                                                      |
| ------- | ---------- | ----------------------------------------------------------------------------------------------- |
| v6.7    | 2026-07-07 | Knowledge Persistence Layer: unified query engine (knowledge-query.ps1) cruza events, traces, feedback, checkpoints |
| v6.6    | 2026-07-07 | MCP SDK Scaffolder: create action multi-lenguaje (ts, js, py, go, rs) con auto-build y auto-register |
| v6.5    | 2026-07-07 | MCP Quickstart: pre-built server templates (sqlite, filesystem, browser, memory), 1-command enable via mcp-manager |
| v6.4    | 2026-07-07 | MCP Native: local MCP server registry, gateway, CLI manager (mcp-manager.ps1), dashboard management UI (MCPServers.tsx), 3 REST endpoints, session pipeline integration |
| v6.3    | 2026-07-07 | Dashboard Multi-Tenant: per-tenant metrics filtering, tenant selector UI, /api/tenants endpoint, /api/metrics?tenantId= |
| v6.2    | 2026-07-07 | Cross-Org Federation: federation auth with RSA handshake, org registry, capability-based authorization, /api/federation endpoint |
| v6.1    | 2026-07-07 | AI Safety Layer: safety guardrails, prompt injection protection, mutation risk scoring, /api/safety endpoint |
| v6.0    | 2026-07-07 | Self-evolving agents, cross-workspace mesh, auto code review, predictive incident response      |
| v5.1    | 2026-07-07 | Multi-tenant isolation, eval/benchmark framework, CI/CD self-healing, 3 new configs, pipeline integration |
| v3.3.3  | 2026-06-19 | Watchtower 74/74 PASS, RBAC + CSP, audit pipeline, tracing, cloud connectors, Engram auto-sync  |
| v3.3.2  | 2026-06-18 | Dashboard i18n (3 idiomas), alert system, watchtower 60 checks, lifecycle scripts, trace system |
| v3.3.1  | 2026-06-17 | CI/CD 35→12 workflows, structured logging, adapter consolidation, docker compose, health API   |
| v3.3.0  | 2026-06-05 | Community skills, CI validation, real marketplace                                               |
