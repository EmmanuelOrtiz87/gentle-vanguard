<p align="center">
  <img src="docs/brand/assets/banner-github.svg" alt="Gentle-Vanguard" width="100%"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-3.2.0-00BFFF?style=flat-square&labelColor=0D1117" alt="Version">
  <img src="https://img.shields.io/badge/Status-Production%20Ready-22C55E?style=flat-square&labelColor=0D1117" alt="Status">
  <img src="https://img.shields.io/badge/License-MIT-4DCFFF?style=flat-square&labelColor=0D1117" alt="License">
  <img src="https://img.shields.io/badge/PowerShell-7+-A855F7?style=flat-square&labelColor=0D1117" alt="PowerShell">
  <img src="https://img.shields.io/badge/Agents-18-00BFFF?style=flat-square&labelColor=0D1117" alt="Agents">
  <img src="https://img.shields.io/badge/Skills-386-4DCFFF?style=flat-square&labelColor=0D1117" alt="Skills">
  <img src="https://img.shields.io/badge/Workflows-27-A855F7?style=flat-square&labelColor=0D1117" alt="Workflows">
</p>

<p align="center">
  <a href="docs/AGENTS.md">Agent Bootstrap</a> &nbsp;·&nbsp;
  <a href="docs/AGENTS.md#mandatory-startup-sequence">Startup</a> &nbsp;·&nbsp;
  <a href="docs/QUICK-COMMANDS.md">Quick Commands</a> &nbsp;·&nbsp;
  <a href="rules/DELEGATION-RULES.md">Delegation</a> &nbsp;·&nbsp;
  <a href="rules/NORMATIVES.md">Normatives</a> &nbsp;·&nbsp;
  <a href="docs/MANIFESTO.md">Manifesto</a> &nbsp;·&nbsp;
  <a href="CHANGELOG.md">Changelog</a>
</p>

<p align="center">
  <strong>AI-powered development orchestrator · 18 agents · 386 skills · 10 tool-compatible</strong><br>
  <em>Tool-agnostic · SDD Lifecycle · Hashline · Team Mode · Skill MCPs · Feedback Loop · Proactive Delivery · Persistent memory</em>
</p>

> _"Construyendo el puente definitivo entre la alta ingeniería de software y la estrategia
> corporativa."_ — [Read the Manifesto](docs/MANIFESTO.md)

---

## What is Gentle-Vanguard?

A full AI orchestration layer that gives structure, memory, and governance to AI-assisted
development across any coding tool (OpenCode, Claude Code, Cline, Cursor, Windsurf, Codex, Copilot,
Continue.dev, Antigravity).

### Stack Architecture

```
Layer 5: AGENTS     — 18 agents (BA, SAD, DEV, QA, OPS, GOV, DOC, etc.)
Layer 4: COMMANDS   — gv.ps1, pre-process-input.ps1, detect-tool.ps1
Layer 3: MCP        — skill-server.ts (MCP protocol), mcp-bridge.ps1
Layer 2: SKILLS     — 386 skills (SDD, security, web, mobile, AI/ML, etc.)
Layer 1: MEMORY     — Engram persistent memory (tools/engram.exe)
```

### Core Capabilities

- **Intelligent Routing**: `pre-process-input.ps1` → trigger matching → agent dispatch (inline,
  delegate, or SDD)
- **18 Specialized Agents**: Each with narrow role, model profile, and delegation rules
- **386 On-Demand Skills**: Angular, React, Next.js, Go, Django, Python, TypeScript, Docker, K8s,
  Playwright, Security, API Design
- **Persistent Memory**: Engram — decisions, bugs, and patterns across sessions with hot/warm/cold
  tiers
- **Cost-Aware Router**: Fast/cheap, strong-reasoning, or strong-coding profiles per agent
- **SDD Lifecycle**: BA explore → SAD design → DEV implement → QA verify
- **Governance**: 7D validation, judgment-day adversarial review, pre-commit hooks, 27 CI/CD
  workflows
- **Session Management**: 10-phase autostart, orphan cleanup, token budget tracking
- **Proactive Security**: AES-256 encryption, TruffleHog scanning, Gitleaks integration
- **Auto-Delegation**: ML-based routing with 80%+ direct, 60%+ confirmation threshold
- **Fine-Tuning**: LoRA adapters for BA and DEV agents
- **Adaptive Profiles**: Auto-detect tool and adjust config per tool capabilities

---

## Latest Release: v3.2.0

**Download**:
[gentle-vanguard-3.2.0.exe](https://github.com/EmmanuelOrtiz87/gentle-vanguard/releases/download/v3.2.0/gentle-vanguard-3.2.0.exe)

### New in v3.2.0 — CopilotKit Native Patterns

- **Agent Chat** (`/agents`): Conversational interface with 6 agents, @mentions autocomplete,
  suggested actions
- **AG-UI Protocol**: 7 interactive UI hints from agent responses (metric, datatable, chart, diff,
  form, list, alert)
- **Human-in-the-Loop**: 4-mode modal (confirmation, selection, form, review) with auto-detection
- **Task Control** (`/tasks`): Real-time agent task monitoring with status icons and quick dispatch
- **Session Timeline** (`/timeline`): Visual event timeline with expandable JSON payloads
- **Session Persistence**: Chat history saved across restarts
- **Shared State Bridge**: Event bus connected to dashboard via WebSocket
- **No CopilotKit dependency**: All patterns implemented natively over MCP

---

## Quick Start

```powershell
# Clone the repo
git clone https://github.com/EmmanuelOrtiz87/gentle-vanguard.git
cd gentle-vanguard

# Run the bootstrap
./gentle-vanguard.ps1 -Dashboard

# Or use the session start pipeline
pwsh -NoProfile -File scripts/utilities/session-start-optimized.ps1
```

---

## Documentation

- [Agent Bootstrap](docs/AGENTS.md) — workspace init, tool detection, startup sequence
- [Architecture](docs/reference/ARCHITECTURE.md) — system design, component relationships
- [Quick Commands](docs/QUICK-COMMANDS.md) — CLI reference
- [Delegation Rules](rules/DELEGATION-RULES.md) — agent dispatch and routing
- [Normatives](rules/NORMATIVES.md) — governance standards index
- [Stack Status](docs/STACK-STATUS-REPORT.md) — component health and automation status
- [Getting Started](docs/getting-started/README.md)
- [Roadmap](docs/ROADMAP.md)
- [Changelog](CHANGELOG.md)

### Reference Documentation

| Area                | Path                                      |
| ------------------- | ----------------------------------------- |
| Architecture        | `docs/reference/ARCHITECTURE.md`          |
| Agent Architecture  | `docs/reference/SUBAGENT-ARCHITECTURE.md` |
| Skill Organization  | `docs/reference/SKILL-ORGANIZATION.md`    |
| Token Tracking      | `docs/reference/REAL-TOKEN-TRACKING.md`   |
| Context Engineering | `rules/CONTEXT-ENGINEERING.md`            |
| Model Routing       | `config/model-routing.json`               |
| Auto-Delegation     | `config/auto-delegation.json`             |
| SDD Config          | `openspec/config.yaml`                    |

---

## Project Structure

```
gentle-vanguard/
├── apps/                   # Applications (web-dashboard, API)
├── build/                  # Build artifacts (compiled, protected, public)
├── client/                 # Client modules
├── config/                 # Centralized configuration
├── deprecated/             # Deprecated components
├── dist/                   # Distribution artifacts
├── docs/                   # Documentation
│   ├── AGENTS.md           # Agent bootstrap
│   ├── reference/          # Technical reference
│   ├── getting-started/    # Onboarding guides
│   └── supplementary/      # Supplementary materials
├── hooks/                  # Custom hooks
├── rules/                  # Normatives and standards (60 rules)
├── scripts/                # PowerShell scripts
│   ├── adaptive/           # Adaptive learning and enforcement
│   ├── core/               # Core bootstrap
│   ├── utilities/          # Utility scripts
│   ├── security/           # Security tools
│   └── monitoring/         # Monitoring and metrics
├── skills/                 # MCP skills (386)
├── reports/                # Generated reports
└── tests/                  # Tests
    ├── unit/               # Unit tests
    └── go-tests/           # Go tests
```

---

## Normatives & Standards

This project is governed by [60 normatives](rules/NORMATIVES.md) covering:

- **Architecture** — NORMATIVAS-ARCHITECTURE.md
- **Code** — NORMATIVAS-CODIGO.md
- **Configuration** — NORMATIVAS-CONFIG.md, NORMATIVAS-CONFIG-SAFETY.md
- **Documentation** — NORMATIVAS-DOCS.md
- **Security** — NORMATIVAS-AI-SAFETY.md, NORMATIVAS-SOC2.md, NORMATIVAS-GDPR.md
- **DevOps** — NORMATIVAS-DEVOPS.md
- **Performance** — NORMATIVAS-PERFORMANCE.md
- **Error Handling** — NORMATIVAS-ERROR-HANDLING.md
- **Enforcement** — NORMATIVAS-ENFORCEMENT.md
- **And more**: Cross-platform, Disaster Recovery, Incident Management, etc.

Enforcement is layered: pre-response hook (every turn), pre-commit hooks (Lefthook), CI/CD (27
workflows), and adaptive enforcement (session start/close).

---

## License

MIT © 2026 Emmanuel Ortiz

---

_Gentle-Vanguard v3.2.0 — Don't let your mellow hustle be faded_
