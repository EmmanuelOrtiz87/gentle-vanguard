<p align="center">
  <img src="docs/brand/assets/banner-github.svg" alt="Gentle-Vanguard" width="100%"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-3.8.0-00BFFF?style=flat-square&labelColor=0D1117" alt="Version">
  <img src="https://img.shields.io/badge/Status-Production%20Ready-22C55E?style=flat-square&labelColor=0D1117" alt="Status">
  <img src="https://img.shields.io/badge/License-MIT-4DCFFF?style=flat-square&labelColor=0D1117" alt="License">
  <img src="https://img.shields.io/badge/TypeScript-100%25-3178C6?style=flat-square&labelColor=0D1117" alt="TypeScript">
  <img src="https://img.shields.io/badge/Tests-367%2F367-22C55E?style=flat-square&labelColor=0D1117" alt="Tests">
  <img src="https://img.shields.io/badge/Health-95%2F95-22C55E?style=flat-square&labelColor=0D1117" alt="Health">
  <img src="https://img.shields.io/badge/Agents-21-00BFFF?style=flat-square&labelColor=0D1117" alt="Agents">
  <img src="https://img.shields.io/badge/Skills-88-4DCFFF?style=flat-square&labelColor=0D1117" alt="Skills">
  <img src="https://img.shields.io/badge/Dashboard_Ready-%E2%9C%93-22C55E?style=flat-square&labelColor=0D1117" alt="Dashboard Ready">
  <img src="https://img.shields.io/badge/Quick_Start-npm_run_start-22C55E?style=flat-square&labelColor=0D1117" alt="Quick Start">
</p>

<p align="center">
  <a href="docs/agents/AGENTS.md">Agent Bootstrap</a> &nbsp;·&nbsp;
  <a href="CHANGELOG.md">Changelog</a> &nbsp;·&nbsp;
  <a href="rules/NORMATIVES.md">Normatives</a> &nbsp;·&nbsp;
  <a href="docs/operations/procedures/QUICK-COMMANDS.md">Quick Commands</a> &nbsp;·&nbsp;
  <a href="rules/NEXUS-NORMATIVA.md">Nexus DB</a> &nbsp;·&nbsp;
  <a href="docs/adr/README.md">ADRs</a>
</p>

<p align="center">
  <strong>AI-powered development orchestrator — zero-dependency, self-healing, fully autonomous</strong><br>
  <em>SDD Lifecycle · Engram Memory · Adaptive Feedback · 111 Pipeline Steps · 95 Health Checks · 21 Agents · 88 Skills</em>
</p>

---

## ⚡ Quick Start

```TypeScript
# Clone anywhere — no dependencies required beyond TypeScript 7+
git clone https://github.com/EmmanuelOrtiz87/gentle-vanguard.git
cd gentle-vanguard

# Auto-install (prerequisites, hooks, dashboard build)
npx tsx src/setup-complete.ts

# Quick start (optimized)
npm run start

# Or run dashboard directly
npx tsx src/dashboard-start.ts
```

Works on Windows, macOS, and Linux.

> **¿Prefieres un instalador?** Descarga el ejecutable desde
> [Releases](https://github.com/EmmanuelOrtiz87/gentle-vanguard/releases) — un solo `.exe` que
> instala, configura y lanza todo el stack automáticamente (incluye auto-update).

---

## 🛡️ What is Gentle-Vanguard?

An **AI orchestration layer** that gives structure, memory, and governance to AI-assisted
development. Tool-agnostic across OpenCode, Claude Code, Cline, Cursor, Windsurf, Codex, Copilot,
Continue.dev — with **zero cloud services, zero API keys, zero external dependencies**.

The stack runs a **111-step autonomous pipeline** at session start, monitors **95 health checks**
across 13 components, persists state in a **SQLite operational database** (23 tables, 7 migrations),
and powers a **real-time observability dashboard** with WebSocket push.

---

## 📸 Dashboard

Real-time LLM observability dashboard — React + TypeScript + Vite + WebSocket:

<p align="center">
  <img src="docs/assets/dashboard.png" alt="Gentle-Vanguard Dashboard" width="85%"/>
</p>

**Start**: `npx tsx src/dashboard-start.ts`  
**Stop**: `npx tsx src/dashboard-stop.ts`

---

## 🏗️ Architecture

```mermaid
flowchart TB
  classDef layer fill:#1a2035,stroke:#a855f7,color:#e0e0e0,stroke-width:2px
  classDef agent fill:#1a2035,stroke:#00bfff,color:#e0e0e0
  classDef dash fill:#1a2035,stroke:#22c55e,color:#e0e0e0

  subgraph L6["Layer 6: EXECUTIVE — Autonomous Operations"]
    A1["Auto-Apply Safe · Circuit Breaker · Auto-Escalation · Session Scoring"]
    A2["Dynamic Dependency Graph · AB Testing · Predictive Governor · Convergence Monitor"]
  end
  subgraph L5["Layer 5: AGENTS — 21 Specialized Roles"]
    B1["BA · SAD · DEV · QA · OPS · GOV · DOC · SEC · PREMORTEM · SDD-EXPLORE"]
    B2["SDD-DESIGN · SDD-APPLY · SDD-VERIFY · SESSION · SELF-DIAG · SIA · MAINTENANCE"]
  end
  subgraph L4["Layer 4: DASHBOARD — Real-time Observability"]
    D1["7-section UI · WebSocket push / 5s · HTTP REST API"]
    D2["i18n en/es/pt-BR · 14 metrics · Tracing Waterfall · Alerts · Feedback"]
    D3["Nexus DB · 23 tables · WAL mode · Auto-prune"]
  end
  subgraph L3["Layer 3: MCP — Model Context Protocol"]
    M1["Gateway · Bridge · Registry · Multi-language SDK"]
    M2["8 pre-built templates · ts/js/py/go/rs"]
  end
  subgraph L2["Layer 2: MEMORY & KNOWLEDGE"]
    K1["Engram (hot/warm/cold) · CodeGraph · Event Store"]
    K2["Checkpoints · Snapshots · Knowledge Base · Findings Ledger"]
  end
  subgraph L1["Layer 1: ORCHESTRATION"]
    O1["111-step pipeline · 95 health checks · Auto-healing watchdog"]
    O2["SDD lifecycle · Audit · Tracing · Cloud connectors · Security orchestrator"]
  end

  L6 --> L5 --> L4 --> L3 --> L2 --> L1
```

<p align="center">
  <img src="docs/assets/architecture-5-layers.png" alt="Gentle-Vanguard 5-Layer Architecture" width="85%"/>
</p>

---

## ✨ Features

| Capability                   | Description                                                                                                                      |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| **Auto-Apply Safe**          | Executive engine — applies safe optimizations (budget, deprecations, norms) with rollback protection                             |
| **Circuit Breaker API**      | 5-failure → OPEN, 2-success → HALF_OPEN → CLOSED, with automatic fallback                                                        |
| **Auto-Escalation**          | Escalates unresolved issues through configured channels with SLA tracking                                                        |
| **Dynamic Dependency Graph** | Real-time dependency resolution and conflict detection across the stack                                                          |
| **AB Testing Framework**     | Session-scoped experiment framework with statistical significance testing                                                        |
| **Session Scoring**          | Auto-compare quality scores across sessions (delegations, corrections, proactive hits)                                           |
| **10 DAOs**                  | Database Repository pattern — Cache, Contract, ErrorMemory, Event, Housekeeping, Metrics, Session, Skill, Trace, MigrationRunner |
| **Cache LRU + WAL**          | SHA256 response cache with TTL + automatic WAL checkpoint when >5MB                                                              |
| **Parallel Watchtower**      | 95 health checks across 13 components — runs in parallel with auto-heal                                                          |
| **Session Consolidation**    | Context compaction engine — token-budget-aware, auto-summarize and wipe                                                          |
| **Engram Memory**            | Persistent memory across sessions with hot/warm/cold tiers and auto-repair                                                       |
| **Dashboard UI**             | Real-time: 7-section view, tracing waterfall, alerts, feedback, i18n (en/es/pt-BR)                                               |
| **Nexus Database**           | SQLite operational DB (WAL mode, FK ON) — 23 tables, auto-migrate, auto-prune                                                    |
| **111 Pipeline Steps**       | Session autostart pipeline with lazy/blocking phases, on-failure=continue                                                        |
| **21 Specialized Agents**    | BA, SAD, DEV, QA, OPS, GOV, DOC, SEC, SELF-DIAG, SIA — each with model routing                                                   |
| **88 Skills**                | On-demand skills: security, compliance, diagram-design, web-research, data-analyst, and more                                     |
| **SDD Lifecycle**            | Explore → Design → Implement → Verify — full spec-driven development                                                             |
| **Adaptive Feedback**        | Auto-learn norms from corrections, session scoring, pattern detection                                                            |
| **Governance**               | 60+ normatives, pre-commit hooks, CI/CD, audit pipeline, safety layer                                                            |
| **Predictive Governor**      | Anticipate load, prewarm resources, adjust token budgets proactively                                                             |
| **Container Scanning**       | Native Syft+Grype+Trivy scanner — SBOM, directory, and artifact scanning with CI gates                                           |
| **Content Operations**       | Offline-first content pipeline — manifest + state machine + CLI (21 real launch jobs, 11 platforms)                              |
| **Chaos Engineering**        | L4 automated — weekly resilience experiments in CI/CD with failure gates                                                         |
| **SLSA Provenance**          | Native DSSE/Ed25519 signing + SLSA provenance attestation for releases                                                           |
| **Auto-Update**              | Self-updating `.exe` launcher — detects new versions and updates in place                                                         |
| **Zero-dependency**          | Works with just TypeScript 7+ — no cloud, no API keys, no external services                                                      |

---

## 📊 Key Metrics

| Metric          | Value                                        |
| --------------- | -------------------------------------------- |
| Test Suites     | **367/367 passed**                           |
| Health Checks   | **95/95 PASS** — 13 components               |
| Pipeline Steps  | **111** (32 blocking + 79 lazy)              |
| Agents / Skills | **21 agents / 88 skills**                    |
| ADRs            | **18** (ADR-0001 → ADR-0018)                 |
| Nexus DB        | **23 tables, 7 migrations, ~7 MB**           |
| Autonomy        | **100%** — zero manual intervention required |
| CodeGraph       | **1,410 nodes / 1,763 edges / 133 files**    |
| Dashboard APIs  | **25+ REST endpoints + WebSocket**           |
| i18n Locales    | **3** — en, es, pt-BR                        |
| Uptime Recovery | **Auto-heal watchdog** — 10 restart attempts |
| Supply Chain    | **SBOM CycloneDX 1.7 + SLSA L2/L3 signing**  |

---

## 📈 Dashboard Structure

```
apps/web-dashboard/
├── server/
│   ├── websocket-server.ts    # WS push / 5s + 25+ REST endpoints
│   ├── real-data.ts           # Real metrics from .session/ traces
│   ├── database/
│   │   ├── manager.ts         # DatabaseManager singleton (SQLite WAL)
│   │   ├── metrics-writer.ts  # Time-series writer
│   │   └── repositories/      # 10 DAOs (Cache, Contract, Error, Event, etc.)
│   ├── mesh-api.ts            # Multi-repo mesh endpoints
│   ├── knowledge-api.ts       # Unified knowledge query
│   ├── mcp-gateway-api.ts     # MCP server management
│   ├── global-health-api.ts   # /api/health (7 components)
│   ├── marketplace-api.ts     # Skill marketplace
│   └── shared-state-bridge.ts # Cross-component state sync
└── src/components/
    ├── Dashboard.tsx           # 7-section main view
    ├── TracingDashboard.tsx    # Waterfall with feedback
    ├── KnowledgePanel.tsx      # Unified search (events, traces, feedback, engram)
    ├── MultiRepoView.tsx       # Cross-workspace MCP orchestration
    ├── MCPServers.tsx          # MCP registry management
    ├── TenantSelector.tsx      # Multi-tenant filter
    ├── InfoPopup.tsx           # Animated metric info (fade-in + scale)
    └── ...
```

---

## 📋 Quick Commands

| Command                                   | Description                                   |
| ----------------------------------------- | --------------------------------------------- |
| `npm start`                               | **Quick start** dashboard (optimized)         |
| `npm run start:complete`                  | Start with full verification checks           |
| `npm test`                                | Run all **367 test suites**                   |
| `npx tsx src/session-autostart.ts`        | Run the **111-step session pipeline**         |
| `npx tsx src/auto-apply-safe.ts --check`  | Check safe optimizations pending              |
| `npx tsx src/auto-apply-safe.ts --apply`  | Apply safe optimizations with rollback        |
| `npx tsx src/auto-apply-safe.ts --report` | Report optimization status                    |
| `npm run watchtower`                      | Run **95 health checks**                      |
| `npm run watchtower:health`               | Health-check only mode                        |
| `npm run db:health`                       | Nexus DB health (integrity, WAL, tables)      |
| `npm run db:init`                         | Init DB + run migrations (idempotent)         |
| `npm run db:backup`                       | Safe online backup                            |
| `npm run db:prune`                        | Prune old data (events >30d, cache >7d)       |
| `npm run container:scan`                  | Scan SBOM for vulnerabilities (Syft+Grype)    |
| `npm run container:db-update`             | Refresh grype vulnerability database          |
| `npx tsx src/chaos-engineering.ts run-all`| Run chaos experiments (resilience testing)    |
| `npm run content:list`                    | List content jobs (--date, --platform, --id)  |
| `npm run content:validate`                | Validate jobs against manifest + registry     |
| `npm run content:prepare`                 | Package validated jobs offline (idempotent)   |
| `npm run content:status`                  | Content pipeline status summary               |
| `npm run content:report`                  | Generate markdown content report              |
| `npm run content:export`                  | Export offline content kit ZIP                |
| `npm run content:test`                    | Content Operations Engine unit tests (15)     |
| `npm run sbom:generate`                   | Generate CycloneDX SBOM                       |
| `npm run sbom:validate`                   | Validate SBOM structure                       |
| `cd apps/web-dashboard && npm run build`  | Build dashboard for production                |
| `npm run graphify -- query "<question>"`  | Knowledge graph semantic search               |
| `npm run graphify -- update .`            | Update code graph snapshot                    |

Full reference:
[docs/operations/procedures/QUICK-COMMANDS.md](docs/operations/procedures/QUICK-COMMANDS.md)

---

## 📚 Documentation

| Resource                | Path                                           |
| ----------------------- | ---------------------------------------------- |
| Agent Bootstrap         | `docs/agents/AGENTS.md`                        |
| Quick Commands          | `docs/operations/procedures/QUICK-COMMANDS.md` |
| Normatives Index        | `rules/NORMATIVES.md`                          |
| Nexus DB Normativa      | `rules/NEXUS-NORMATIVA.md`                     |
| ADRs (Architecture)     | `docs/adr/README.md` (18 ADRs)                 |
| Changelog               | `CHANGELOG.md`                                 |
| Dashboard Skill         | `.opencode/skills/dashboard/SKILL.md`          |
| Vanguards (Stack Rules) | `rules/`                                       |

---

## 📦 Requirements

- **TypeScript 7+** — the only hard requirement
- **Node.js 18+** — optional, only for dashboard development
- **Git** — optional, only for clone and hooks

---

## 🔒 Security & Supply Chain

- **SBOM**: CycloneDX 1.7 generated natively (`npm run sbom:generate`)
- **SLSA**: Provenance attestation + DSSE/Ed25519 signing on releases
- **Container scanning**: Syft+Grype+Trivy native scanner with CI gates
- **Secret scanning**: 80+ patterns, entropy analysis, pre-commit hooks
- **Chaos engineering**: L4 automated — weekly resilience experiments in CI

---

## 📄 License

MIT © 2026 Emmanuel Ortiz

---

<p align="center">
  <sub>Gentle-Vanguard v3.8.0 — Don't let your mellow hustle be faded.</sub>
</p>