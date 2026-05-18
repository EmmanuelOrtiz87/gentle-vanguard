<h1 align="center">Gentle-Vanguard</h1>

<p align="center">
  <strong>AI-powered development orchestrator · 17 agents · 133 skills · 10 tool-compatible</strong><br>
  <em>Tool-agnostic · SDD Lifecycle · Judgment Day · Persistent memory</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-2.18.0-brightgreen?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/Status-Production%20Ready-success?style=flat-square" alt="Status">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License">
  <img src="https://img.shields.io/badge/PowerShell-7+-purple?style=flat-square" alt="PowerShell">
  <img src="https://img.shields.io/badge/Agents-17-orange?style=flat-square" alt="Agents">
  <img src="https://img.shields.io/badge/Skills-133-teal?style=flat-square" alt="Skills">
  <img src="https://img.shields.io/badge/Workflows-16-blueviolet?style=flat-square" alt="Workflows">
</p>

<p align="center">
  <a href="docs/AGENTS.md">Bootstrap</a>
  ·
  <a href="CHANGELOG.md">Changelog</a>
  ·
  <a href="rules/DELEGATION-RULES.md">Delegation Rules</a>
  ·
  <a href="openspec/config.yaml">SDD Config</a>
</p>

---

## What is Gentle-Vanguard?

Gentle-Vanguard is an **AI orchestrator** that turns your CLI or IDE into a disciplined engineering team. It does one thing that chat bots don't: **structure**.

- **Routes work** through delegation rules — small changes stay inline, complex work goes to specialized subagents
- **Enforces SDD** (Spec-Driven Development) — concepts before code, artifacts over chat context
- **Guards reviewer workload** — prevents oversized PRs with automated line-budget checks
- **Assigns models per agent** — fast/cheap for exploration, strong reasoning for architecture, fresh context for review
- **Maintains a skill registry** — auto-scanned, always-current index of 133 skills
- **Persists memory** across sessions via Engram

```mermaid
flowchart TB
    YOU[You / CLI / IDE]
    YOU -->|request| PP[pre-process-input.ps1]
    PP --> ORC[Orchestrator]

    ORC -->|small| INLINE[Inline work]
    ORC -->|complex| DELEGATE{Delegation Rules}
    DELEGATE -->|4+ files| SCOUT[scout / context-builder]
    DELEGATE -->|2+ files| WORKER[worker]
    DELEGATE -->|PR / commit| REVIEWER[fresh reviewer]
    DELEGATE -->|architecture/risk| SDD[SDD Lifecycle]

    SDD --> BA[BA - Explore]
    SDD --> SAD[SAD - Design]
    SDD --> DEV[DEV - Apply]
    SDD --> QA[QA - Verify]

    BA --> SKILLS[133 Skills]
    DEV --> SKILLS
    QA --> SKILLS

    SKILLS --> MEM[Engram Memory]
```

---

## Architecture

### Work Routing Ladder

Every request is routed through the **smallest safe harness**:

```mermaid
flowchart LR
    subgraph ROUTE[Work Routing]
        A[Incoming Request] --> B{Size & Complexity}
        B -->|Small, local, known| C[Inline Direct]
        B -->|Context-heavy, 4+ files| D[scout delegation]
        B -->|Multi-file change| E[worker + reviewer]
        B -->|Ambiguous / architectural| F[SDD lifecycle]
    end

    subgraph SDD_PHASES[SDD Flow]
        F --> G[init]
        G --> H[explore]
        H --> I[proposal]
        I --> J[spec]
        J --> K[design]
        K --> L[tasks]
        L --> M[apply]
        M --> N[verify]
        N --> O[archive]
    end

    C --> P[Result]
    D --> P
    E --> P
    O --> P
```

### Delegation Rules (Mandatory)

| # | Rule | Trigger | Action |
|---|------|---------|--------|
| 1 | **4-file rule** | Understanding needs 4+ files | Delegate to scout/context-builder |
| 2 | **Multi-file write** | Touching 2+ non-trivial files | One worker + fresh reviewer |
| 3 | **PR rule** | Before commit/push/PR | Fresh-context reviewer |
| 4 | **Incident rule** | Git/tooling accident | Fresh audit before recovery |
| 5 | **Long-session** | ~20 calls without delegation | Pause and delegate |

See [rules/DELEGATION-RULES.md](rules/DELEGATION-RULES.md) for full details.

### Model Routing per Agent

Each agent type has a recommended model profile based on its role:

```mermaid
flowchart LR
    subgraph ROLES[Agent Roles + Model Assignment]
        BA[BA - Explore] --> M1[fast/cheap - thinking:off]
        SAD[SAD - Design] --> M2[strong reasoning - thinking:high]
        DEV[DEV - Code] --> M3[strong coding - thinking:medium]
        QA[QA - Verify] --> M4[fresh context - thinking:high]
        GOV[GOV - Audit] --> M5[thorough review - thinking:high]
        DOC[DOC - Docs] --> M6[fast/cheap - thinking:low]
        OPS[OPS - Infra] --> M7[fast/cheap - thinking:off]
    end
```

Configured in [config/model-routing.json](config/model-routing.json).

### 5-Layer Architecture

| Layer | Role | Components | Config |
|-------|------|-----------|--------|
| **1. Agents** | Task delegation | 1 orchestrator + 15 sub-agents | `config/auto-delegation.json` |
| **2. Commands** | CLI entry points | `gv.ps1`, `pre-process-input.ps1` | `config/orchestrator.json` |
| **3. MCP Servers** | Protocol bridge | Model Context Protocol, Engram MCP | `skills/*/SKILL.md` |
| **4. Skills** | Specialized execution | 133 skills (frontend, backend, DevOps, security, testing) | `config/skill-dependencies.json` |
| **5. Memory** | Persistent context | Engram (hot/warm/cold tiers) | `config/engram-config.json` |

---

## Agent Ecosystem

| Agent | Role | Model Profile | Delegates to |
|-------|------|--------------|-------------|
| Orchestrator | Main router | inherit | All agents below |
| BA | Requirements & analysis | fast/cheap | `sdd-lifecycle` (explore) |
| SAD | System design | strong-reasoning | `sdd-lifecycle` (design) |
| DEV | Code generation | strong-coding | `sdd-lifecycle` (apply) |
| QA | Testing & validation | strong-review | `sdd-lifecycle` (verify) |
| OPS | Deployment & CI/CD | fast/cheap | `docker-devops-skill` |
| DOC | Technical docs | fast/cheap | `documentation-governance` |
| GOV | Compliance & audit | strong-review | `judgment-day` |
| SESSION | Session management | fast/cheap | `session-workflow-skill` |
| PREMORTEM | Risk assessment | strong-reasoning | `premortem-skill` |
| FINANCE | Financial modeling | strong-reasoning | `finance-financial-analyst` |
| LEGAL | Regulatory compliance | strong-review | `legal-compliance-officer` |
| MKT | Marketing & SEO | fast/cheap | `marketing-content-writer` |
| SALES | Pipeline management | fast/cheap | `sales-account-executive` |
| HR | Talent acquisition | fast/cheap | `hr-talent-acquisition` |
| SELF-DIAG | Self-diagnosis | fast/cheap | `self-diagnosis-skill` |
| BUS-TELE | Business telemetry | fast/cheap | `business-telemetry-skill` |

> All sub-agents are `hidden: true` in `opencode.json` — only the Orchestrator is user-selectable. Sub-agents are managed autonomously via `config/auto-delegation.json`.

---

## Key Capabilities

### SDD / OpenSpec

Spec-Driven Development with a formal phase chain:

```mermaid
flowchart LR
    init --> explore --> proposal --> spec --> design
    design --> tasks --> apply --> verify --> archive
```

Config at [openspec/config.yaml](openspec/config.yaml):
- `strict_tdd`: forces RED/GREEN/TRIANGULATE/REFACTOR evidence
- `protect_review_workload`: blocks PRs exceeding 400 lines
- Per-phase rules: proposal requires problem statement, spec requires acceptance criteria

### SDD Preflight (Session-Level)

Before the first SDD flow in a session, configure:

| Setting | Options | Default |
|---------|---------|---------|
| Execution mode | interactive / auto | interactive |
| Artifact store | openspec / engram / both | openspec |
| PR strategy | auto-forecast / ask-always / single-pr-default / force-chained | ask-always |
| Review budget | Max lines per PR | 400 |
| Strict TDD | enabled / disabled | enabled |

### Review Workload Guard

Before multi-file implementation, estimate the review burden:

```powershell
.\scripts\utilities\review-workload-guard.ps1
```

- Checks `git diff main...` for additions + deletions
- If **>400 changed lines**, recommends chained PRs (see `skills/chained-pr/`)
- Splits oversized work into reviewable slices

### Skill Registry

Auto-maintained at `.atl/skill-registry.md`:

- Built on every session start
- Scans 10+ skill directories (project + user/tool)
- Generates **compact rules**: 5-15 line pre-digested summaries per skill
- Delegators inject compact rules into subagent prompts

Rebuild on demand:
```powershell
.\scripts\utilities\build-skill-registry.ps1
```

### Chain-Delivery Skills

| Skill | Purpose |
|-------|---------|
| `branch-pr` | Issue-first PR creation with template enforcement |
| `chained-pr` | Split >400-line changes into reviewable PR chains |
| `work-unit-commits` | Commits as self-contained, reviewable units |
| `judgment-day` | Blind dual review + re-judgment |
| `comment-writer` | Postable, warm collaboration comments |

### Cross-Tool Compatibility

Gentle-Vanguard detects and adapts to 10 AI coding tools:

| Tool | Detection | Adaptive Profile |
|------|-----------|-------------------|
| OpenCode | `$env:OPENCODE_SERVER_USERNAME` | Full (skill + mem tools) |
| Claude Code | `$env:CLAUDE_VSCODE_VERSION` | Full (native tools) |
| Cline | `.clinerules` file | Emulated skill/mem |
| Cursor | `.cursorrules` file | Emulated skill/mem |
| Windsurf | `.windsurf/` directory | Emulated skill/mem |
| Codex | `$env:CODEX` | Emulated skill/mem |
| Copilot | `$env:COPILOT` | Emulated skill/mem |
| Antigravity | `$env:ANTIGRAVITY` | Emulated skill/mem |
| Continue.dev | `.continue/` directory | Emulated skill/mem |
| Claude (generic) | Fallback | Emulated skill/mem |

---

## Quick Start

```powershell
git clone https://github.com/EmmanuelOrtiz87/gentle-vanguard.git
cd gentle-vanguard

# Full session start (autostart + session manager + engram + skill registry)
.\scripts\utilities\session-autostart.cmd

# Verify all quality gates
gv verify

# SDD preflight (before first SDD task)
.\scripts\utilities\sdd-preflight.ps1 -Interactive

# Check review workload before multi-file changes
.\scripts\utilities\review-workload-guard.ps1
```

---

## Development

| Action | Command |
|--------|---------|
| Run all tests | `Invoke-Pester tests/ -Output Detailed` |
| Run unit tests | `Invoke-Pester tests/unit/ -Output Detailed` |
| Run integration | `Invoke-Pester tests/integration/ -Output Detailed` |
| Quality gates | `gv verify` or `gv judgment-day` |
| Security audit | `.\scripts\security\audit.ps1` |
| Rebuild skill registry | `.\scripts\utilities\build-skill-registry.ps1` |
| Build installer | `pwsh -File build/create-installer.ps1` |
| SDD preflight | `.\scripts\utilities\sdd-preflight.ps1 -Interactive` |
| Review workload guard | `.\scripts\utilities\review-workload-guard.ps1` |

---

## CI/CD Pipeline (16 Workflows)

| Workflow | Purpose | Trigger |
|----------|---------|---------|
| `gentle-vanguard-quality-gate.yml` | Quality gates on PRs | Every PR |
| `test-suite.yml` | Full test suite | Every PR/push |
| `ps-lint.yml` | PSScriptAnalyzer lint | Every PR |
| `sdd-gate.yml` | Block PRs without SDD | Every PR |
| `script-governance.yml` | Script compliance | Every PR |
| `format-check.yml` | Prettier formatting | Every PR |
| `gitleaks.yml` | Secret scanning | Every PR |
| `security-scan.yml` | OWASP security scanning | Weekly |
| `codeql-analysis.yml` | CodeQL analysis | Weekly |
| `autonomous-validation.yml` | Full validation suite | Weekly |
| `dashboard-auto-refresh.yml` | Metrics dashboard | Daily |
| `monthly-management-report.yml` | Executive report | Monthly |
| `dependency-backup.yml` | Dependency backup | Weekly |
| `release.yml` | Release management | On tag |
| `labeler.yml` | Auto-label PRs | Every PR |
| `workflow-lint.yml` | Workflow syntax validation | On `.github/` change |
| `sync-public.yml` | Sync to `gentle-vanguard-public` | On push to `main` |

---

## Project Status

| Gate | Result |
|------|--------|
| Configuration | 3/3 |
| Skills | 133 validated |
| Tests | 40 test files |
| Hooks | 2/2 |
| Structure | 7/7 |
| **Total** | **Production Ready** |

---

## Key Documentation

| Resource | Description |
|----------|-------------|
| [AGENTS.md](docs/AGENTS.md) | Canonical bootstrap (tool-agnostic) |
| [Architecture](docs/architecture/README.md) | System design & decisions |
| [Delegation Rules](rules/DELEGATION-RULES.md) | When to delegate vs. work inline |
| [Model Routing](config/model-routing.json) | Per-agent model/effort assignments |
| [SDD Config](openspec/config.yaml) | SDD/OpenSpec phase configuration |
| [Skill Registry](.atl/skill-registry.md) | Auto-maintained skill index |
| [Build Pipeline](build/README.md) | Encrypt, compile, distribute |
| [Contributing](CONTRIBUTING.md) | How to contribute |
| [Changelog](CHANGELOG.md) | Version history |

---

<p align="center">
  <strong>Gentle-Vanguard v2.18.0</strong><br>
  <em>Local-First · Total Privacy · Production Ready</em>
</p>