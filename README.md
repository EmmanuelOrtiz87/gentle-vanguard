<p align="center">
  <img src="docs/brand/assets/banner-github.svg" alt="Gentle-Vanguard" width="100%"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-8.0.0-00BFFF?style=flat-square&labelColor=0D1117" alt="Version">
  <img src="https://img.shields.io/badge/Status-Public%20Release-22C55E?style=flat-square&labelColor=0D1117" alt="Status">
  <img src="https://img.shields.io/badge/License-MIT-4DCFFF?style=flat-square&labelColor=0D1117" alt="License">
  <img src="https://img.shields.io/badge/PowerShell-7+-A855F7?style=flat-square&labelColor=0D1117" alt="PowerShell">
  <img src="https://img.shields.io/badge/Zero_Dependency-%E2%9C%93-22C55E?style=flat-square&labelColor=0D1117" alt="Zero Dependency">
  <img src="https://img.shields.io/badge/Dashboard_Ready-%E2%9C%93-22C55E?style=flat-square&labelColor=0D1117" alt="Dashboard Ready">
</p>

<p align="center">
  <a href="docs/AGENTS.md">Agent Bootstrap</a> &nbsp;·&nbsp;
  <a href="CHANGELOG.md">Changelog</a> &nbsp;·&nbsp;
  <a href="docs/ROADMAP.md">Roadmap</a> &nbsp;·&nbsp;
  <a href="rules/NORMATIVES.md">Normatives</a> &nbsp;·&nbsp;
  <a href="docs/QUICK-COMMANDS.md">Quick Commands</a>
</p>

<p align="center">
  <strong>AI-powered development orchestrator — zero-dependency, auto-installable</strong><br>
  <em>Tool-agnostic · SDD Lifecycle · Hashline · Adaptive Feedback Loop · Engram Memory · Proactive Delivery</em>
</p>

---

## Quick Start

```powershell
# Clone anywhere — no dependencies required beyond PowerShell 7+
git clone https://github.com/EmmanuelOrtiz87/gentle-vanguard.git
cd gentle-vanguard

# Auto-install (checks prerequisites, builds dashboard, installs hooks)
.\scripts\setup-complete.ps1

# Or run the dashboard directly (WS server + Vite + auto-open browser)
.\scripts\utilities\dashboard\dashboard-start.ps1
```

That's it. One command installs everything. Works on Windows, macOS, and Linux.

---

## What is Gentle-Vanguard?

A full **AI orchestration layer** that gives structure, memory, and governance to AI-assisted
development. Works across any coding tool — OpenCode, Claude Code, Cline, Cursor, Windsurf, Codex,
GitHub Copilot, Continue.dev.

**No cloud services required. No API keys needed. Zero dependencies beyond PowerShell 7+.**

---

## Architecture

```mermaid
flowchart TB
  classDef layer fill:#1a2035,stroke:#a855f7,color:#e0e0e0,stroke-width:2px
  classDef agent fill:#1a2035,stroke:#00bfff,color:#e0e0e0
  classDef dash fill:#1a2035,stroke:#22c55e,color:#e0e0e0

  subgraph L5["Layer 5: AGENTS — 18 Specialized Agents"]
    A1[BA / SAD / DEV / QA / OPS / GOV / DOC / SEC]
  end
  subgraph L4["Layer 4: DASHBOARD — Real-time Observability"]
    D1[Multi-repo Mesh · Knowledge Panel · Tracing · Alerts]
    D2[WebSocket + HTTP API · i18n (en/es/pt-BR) · 14 metrics]
  end
  subgraph L3["Layer 3: MCP — Model Context Protocol"]
    M1[Gateway · Bridge · Registry · 8 pre-built templates]
    M2[Multi-language scaffold (ts/js/py/go/rs)]
  end
  subgraph L2["Layer 2: MEMORY & KNOWLEDGE"]
    K1[Engram · CodeGraph · Event Store · Checkpoints]
    K2[Unified knowledge query across all sources]
  end
  subgraph L1["Layer 1: ORCHESTRATION"]
    O1[SDD lifecycle · Auto-delegation · Adaptive feedback]
    O2[Session pipeline · Audit · Tracing · Cloud connectors]
  end

  L5 --> L4 --> L3 --> L2 --> L1
```

---

## Features

| Capability | Description |
|---|---|
| **Multi-repo Mesh** | Cross-workspace MCP orchestration with auto-discovery and template sync |
| **Dashboard UI** | Real-time observability: metrics, tracing, alerts, knowledge, multi-repo, MCP management |
| **Knowledge Base** | Unified search across events, traces, feedback, checkpoints, and Engram memory |
| **Engram Memory** | Persistent memory across sessions with hot/warm/cold tiers and auto-repair |
| **MCP Ecosystem** | Gateway, bridge, registry, 8 pre-built templates, multi-language SDK scaffold |
| **18 Specialized Agents** | BA, SAD, DEV, QA, OPS, GOV, DOC, SEC — each with model routing and enforcement |
| **SDD Lifecycle** | BA explore → SAD design → DEV implement → QA verify |
| **Adaptive Feedback** | Auto-learn norms from corrections, session scoring, pattern detection |
| **Governance** | 60+ normatives, pre-commit hooks, CI/CD, audit pipeline, safety layer |
| **Federation** | Cross-org auth with RSA handshake, capability-based authorization |
| **Multi-tenant** | Per-tenant isolation across session, engram, codegraph, audit, RBAC |
| **Zero-dependency** | Works with just PowerShell 7+ — no cloud, no API keys, no external services |

---

## Dashboard

The real-time observability dashboard is included and ready to run:

```
apps/web-dashboard/          # React + TypeScript + Vite + WebSocket
├── server/                  # WS + HTTP API (dynamic port, auto-recovery watchdog)
│   ├── websocket-server.ts  # 25+ REST endpoints + WebSocket push every 5s
│   ├── mesh-api.ts          # Multi-repo mesh endpoints
│   ├── knowledge-api.ts     # Knowledge query endpoint
│   ├── mcp-gateway-api.ts   # MCP server management
│   └── real-data.ts         # Real metrics from .session/ traces
└── src/components/          # 10 routes with code splitting
    ├── Dashboard.tsx        # 7-section main view
    ├── KnowledgePanel.tsx   # Unified knowledge search (events, traces, feedback, checkpoints, engram)
    ├── MultiRepoView.tsx    # Cross-workspace MCP orchestration (auto-refresh 30s)
    ├── TracingDashboard.tsx # Waterfall view with feedback
    ├── MCPServers.tsx       # MCP server registry management
    └── TenantSelector.tsx   # Multi-tenant filter
```

Start with one command: `.\scripts\utilities\dashboard\dashboard-start.ps1`

---

## Quick Commands

| Command | Description |
|---|---|
| `.\scripts\setup-complete.ps1` | Auto-install: prerequisites, hooks, dashboard build |
| `.\scripts\utilities\dashboard\dashboard-start.ps1` | Start dashboard (WS + Vite + browser) |
| `.\scripts\utilities\dashboard\dashboard-stop.ps1` | Stop dashboard gracefully |
| `.\scripts\maintenance\maintenance-watchtower.ps1 -Action health` | Run 79 health checks |
| `.\scripts\maintenance\maintenance-watchtower.ps1 -Action autoheal` | Health + auto-restart failed processes |

See [docs/QUICK-COMMANDS.md](docs/QUICK-COMMANDS.md) for the full reference.

---

## Documentation

| Resource | Path |
|---|---|
| Agent Bootstrap | `docs/AGENTS.md` |
| Quick Commands | `docs/QUICK-COMMANDS.md` |
| Normatives Index | `rules/NORMATIVES.md` |
| Changelog | `CHANGELOG.md` |
| Roadmap | `docs/ROADMAP.md` |

---

## Requirements

- **PowerShell 7+** — the only hard requirement
- **Node.js 18+** — optional, only needed for dashboard development (build step)
- **Git** — optional, only needed for clone and hooks

---

## License

MIT © 2026 Emmanuel Ortiz
