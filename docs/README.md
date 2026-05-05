# 🏗️ Gentleman Foundation — AI Development Stack

> **"Where governance, automation, and AI converge to empower modern development teams."**

Local-first platform for AI-assisted software development. Unifies agent orchestration, SDD enforcement, token governance, quality gates, and 125+ on-demand skills — all wired into a single CLI and automated CI pipeline.

[![Version](https://img.shields.io/badge/version-2.6.5-blue.svg)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-7+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![CI](https://img.shields.io/badge/CI-10_workflows-green.svg)](.github/workflows/)
[![Skills](https://img.shields.io/badge/skills-125-blueviolet.svg)](skills/)
[![Security](https://img.shields.io/badge/security-OWASP_%2B_dependabot-orange.svg)](SECURITY.md)

---

## 📖 What is Foundation?

Foundation is a **governance-first AI development stack** that unifies:

| Capability | What it does |
|------------|-------------|
| **7-agent orchestration** | Routes tasks automatically to BA, SAD, DEV, QA, OPS, GOV, DOC agents |
| **125+ on-demand skills** | Angular, React, Next.js, Go, Django, TypeScript, Zod, AI SDK, MCP, and more |
| **SDD enforcement** | Blocks commits without a validated spec — no specification, no code |
| **Token Budget Guard** | 30K tokens/day cap with 70%/90% soft/hard thresholds |
| **Event bus + telemetry** | 10 standard events with governance gate and distributed tracing |
| **Enterprise CI pipeline** | 10 workflows: quality gate, PSScriptAnalyzer, OWASP, SDD gate, automated releases |
| **7D validation hooks** | Pre-commit checks: security, quality, architecture, testing, API, docs, gitflow |
| **Persistent memory** | Engram — context survives session restarts |

---

## 🚀 Quick Start

### Prerequisites
- Windows 10/11 / Linux / macOS
- PowerShell 7+ (`winget install Microsoft.PowerShell`)
- Git 2.30+
- Node.js 18+ | Go 1.19+ (optional)

### Setup — 3 steps
```powershell
# 1. Clone
git clone https://github.com/EmmanuelOrtiz87/gentleman-foundation.git
cd gentleman-foundation

# 2. Bootstrap
.\scripts\foundation\bootstrap-machine.ps1

# 3. Start working
.\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1 start-session
```

### Daily usage
```powershell
wf verify          # Check all 14 quality gates
wf version         # Show stack version + skills count
wf start-session   # Begin tracked session
wf judgment-day    # Full QA gate before release
wf dashboard       # Open HTML metrics dashboard
wf benchmark       # SLO benchmark of key commands
wf sync-drift      # Detect drift between foundation and projects
```

---

## Architecture Overview

## Architecture

Foundation uses a layered, modular architecture with on-demand activation:

```
┌─────────────────────────────────────────────────────────────┐
│                     AI Agent Layer                          │
│  (OpenCode, Claude Code, Cursor, etc.)                     │
└───────────────────────────┬─────────────────────────────────┘
                             │ Integrates with
┌───────────────────────────▼─────────────────────────────────┐
│                  Orchestration Layer                        │
│  • Project Orchestrator (wf.ps1)                           │
│  • Sub-agent delegation                                    │
│  • Context management                                      │
└───────────────────────────┬─────────────────────────────────┘
                             │ Coordinates
┌───────────────────────────▼─────────────────────────────────┐
│                    Skill Layer                              │
│  • 25+ Curated Skills (Angular, React, Go, Python, etc.)   │
│  • 7D Validation (Security, Quality, Architecture, etc.)    │
│  • Adversarial Judgment Protocol                           │
└───────────────────────────┬─────────────────────────────────┘
                             │ Enforces
┌───────────────────────────▼─────────────────────────────────┐
│                  Governance Layer                           │
│  • SDD (Specification-Driven Development)                   │
│  • Persistent Memory (Engram)                               │
│  • Automated Hooks (pre-commit, pre-push)                   │
└───────────────────────────┬─────────────────────────────────┘
                             │ Runs on
┌───────────────────────────▼─────────────────────────────────┐
│                  Infrastructure Layer                       │
│  • Cross-platform (Windows, Linux, macOS)                   │
│  • Docker, Kubernetes, CI/CD integration                   │
│  • Project Templates & Scaffolding                         │
└─────────────────────────────────────────────────────────────┘
```

Refer to [docs/reference/ARCHITECTURE.md](docs/reference/ARCHITECTURE.md) for full details.

---

## 📋 Stack & Governance Policies

## 📋 Stack Policies

| Concept | Description | Enforcement |
|---------|-------------|-------------|
| **SDD-first** | No code without a validated specification | `sdd-gate.yml` + pre-commit hook |
| **Adversarial Judgment** | Dual-agent review for critical changes | `wf judgment-day` |
| **Token governance** | Hard budget cap — no runaway AI spend | Token Budget Guard |
| **Normativas vivas** | PS, CI, Testing standards enforced in CI | `ps-lint.yml` + agent-verify |
| **RBAC** | Owner-level ops require explicit auth | `config/access-control.json` |
| **Security** | OWASP + dependabot + PSScriptAnalyzer | Automated weekly |

---

## ⚙️ Skills & Automation

## ⚙️ Skills & CLI

**125 skills** activated on-demand by keyword trigger. Zero memory overhead for inactive skills.

### Core CLI — `wf.ps1` (44+ commands)

```powershell
# Session
wf start-session       wf end-session         wf day-end-closure

# Quality
wf verify              wf judgment-day        wf review
wf audit               wf sdd-gate            wf sdd-metrics

# Metrics & benchmarks
wf benchmark           wf sync-drift          wf export-metrics
wf dashboard           wf context-dashboard   wf token-guard

# Agents
wf dispatch DEV,QA "add unit tests for auth module"
wf agent SAD "design pagination API contract"
wf skills              # list all 125 skills

# Version & info
wf version             wf platform-info       wf health
```

### Dashboard Signal Coverage
### Dashboard (`wf dashboard`)

Generates `reports/dashboard.html` — open in any browser:

1. **KPI cards**: Sessions, Dispatches, Tokens Used, Events Emitted
2. **Event Distribution** bar chart (last 14 days)
3. **Token Usage** trend chart
4. **Recent Events** table with timestamp and governance status
5. Executive traffic light: GREEN / YELLOW / RED
6. Budget burn rate + exhaustion ETA

### Runtime Routing Model
1. `ai_orchestrated`: Orchestrator delegates to subagents and skills
2. `hybrid_guarded`: Selective AI with deterministic script fallback
3. `offline_deterministic`: Local scripts only (no network/AI dependency)

### Auto-Activation System
- **Pre-commit Hooks**: Automatic validation before commits
- **PowerShell Profile**: Auto-activation when entering project directories
- **Health Checks**: Comprehensive tool availability validation
- **Environment Init**: One-command setup for new sessions

### Project Templates
Foundation provides homologated templates for:
- **Web APIs** (Go + REST)
- **Single Page Applications** (Angular + TypeScript)
- **Microservices** (Docker + Kubernetes)
- **Data Processing** (Python + FastAPI)
- **DevOps Pipelines** (GitHub Actions + Azure)

---

## 🔄 Workflow Cycle
## 🔄 Development Workflow

```
START SESSION → pre-process-input.ps1 → trigger routing
                    │
          ┌─────────▼──────────┐
          │  Agent dispatched  │  (BA / SAD / DEV / QA / OPS / GOV / DOC)
          │  + skill loaded    │
          └─────────┬──────────┘
                    │ code produced
          ┌─────────▼──────────┐
          │  pre-commit hook   │  7D validation (security, quality, arch, tests, API, docs, gitflow)
          │  SDD gate check    │  blocks if no validated SDD spec
          └─────────┬──────────┘
                    │ commit passes
          ┌─────────▼──────────┐
          │  CI pipeline       │  10 workflows: lint, PSScriptAnalyzer, OWASP, quality gate
          └─────────┬──────────┘
                    │ CI passes
          ┌─────────▼──────────┐
          │  judgment-day      │  adversarial dual-agent review (optional for critical changes)
          └─────────┬──────────┘
                    │ approved
          tag v*.*.* → release.yml → GitHub Release (automated)
```

---

## 📅 Weekly Audit Runbook
Systematic 5-step process for governance-validated repository audits. All outputs use `YYYY-MM-DD-HHmmss` timestamps for unique identification.

### Step 1: Generate Context Pack
```powershell
.\scripts\wf.ps1 context-pack
# Output: docs/sessions/YYYY-MM-DD-HHmmss-context-pack.md
```
Captures current repository state: branch, recent commits, changed files, and platform health.

### Step 2: Activate Compact Context
```powershell
.\scripts\wf.ps1 compact-start
# Reads: latest context-pack from docs/sessions/ (by filename timestamp)
# Logs: docs/sessions/metrics/context-usage.csv
```
Loads latest context pack and records telemetry. Auto-activates on `wf.ps1 start-session` if health is RED.

### Step 3: Generate Audit Document
```powershell
.\scripts\wf.ps1 audit
# Output: docs/audits/YYYY-MM-DD-HHmmss-audit.md
```
Full audit report with delivery status, operational risk, test suite availability, and git tracking.

### Step 4: Governance Validation
```powershell
.\scripts\diagnostics\validate-script-governance.ps1
# Expected: EXIT:0 (all checks passed)

# Optional strict gate (CI)
.\scripts\wf.ps1 health -StrictCleanup
```
Validates canonical path references and no deprecated dependencies. Non-zero exit is blocking.

### Step 5: Review Session Metrics
```powershell
.\scripts\wf.ps1 context-metrics
# Reads: docs/sessions/metrics/context-usage.csv
```
Displays accumulated session metrics: total events, context-pack calls, compact-start calls, and efficiency indicators.

### Step 6: Manual Homologation (Optional)
```powershell
# Preview cleanup actions
.\scripts\wf.ps1 homologate

# Apply cleanup and reference updates
.\scripts\wf.ps1 homologate apply
```
Normalizes workspace before release or when strict cleanup reports drift.

---

## 📚 Documentation
## 📚 Documentation


### For Developers
- **[Session Guide](docs/guides/SESSION-GUIDE.md)**: Daily workflow and commands
- **[Tool Activation](docs/guides/TOOL-ACTIVATION.md)**: Auto-activation system
- **[Testing Standards](rules/TESTING-STANDARDS.md)**: Testing pyramid + coverage targets
- **[PowerShell Standards](rules/POWERSHELL-STANDARDS.md)**: PS1 coding standards

### For Project Leads
- **[Architecture Overview](docs/reference/ARCHITECTURE.md)**: System design rationale
- **[CI Hardening Standards](rules/CI-HARDENING-STANDARDS.md)**: Workflow requirements
- **[Status Report](docs/reports/FOUNDATION-STATUS-REPORT-2026-05-05.md)**: Full operational status v2.6.5

### For Administrators
- **[Installation Guide](docs/getting-started/installation.md)**: Complete setup instructions
- **[AI Configuration](docs/guides/AI-CONFIGURATION.md)**: AI provider setup
- **[Getting Started](docs/getting-started/README.md)**: All setup guides
- **[Security Policy](SECURITY.md)**: Vulnerability reporting + security controls

---

## ⚙️ Configuration

### Environment Variables
```bash
# AI Tools
export CLAUDE_API_KEY="your-key"

# Development Paths
export FOUNDATION_ROOT="/path/to/foundation"

# Git Configuration
git config --global core.hooksPath "/path/to/foundation/hooks"
```

### Project Configuration
Each project uses a `.foundation` configuration file:
```json
{
  "project": {
    "type": "web-api",
    "language": "go",
    "framework": "gin"
  },
  "ai": {
    "orchestrator": "project-orchestrator-skill",
    "memory": "engram",
    "review": "native-review"
  },
  "quality": {
    "precommit": true,
    "security": true,
    "testing": true
  }
}
```

---

## ✨ Key Features

| Feature | Description | Benefit |
|---------|-------------|---------|
| **🌍 Global Installation** | Single installation per machine | Available to all projects |
| **⚡ Unified CLI** | Single command (`wf.ps1`) | Simplified operations |
| **🔗 Symlink Strategy** | Skills updated once, available everywhere | Always synced |
| **🔒 Pre-commit Hooks** | Automatic secrets detection and 7D validation | Security-first workflow |
| **🎯 25+ Skills** | Curated for Go, Angular, React, Python, etc. | Expert patterns |
| **🔧 Multi-Technology** | Node.js, Go, Python, Rust support | Flexible stack |
| **💻 Cross-Platform** | Windows, Linux, macOS support | Universal compatibility |
| **📦 Templates** | Service, CLI, library, frontend, fullstack | Quick project start |
| **🚀 CI/CD Ready** | GitHub Actions, GitLab CI, Azure DevOps | Deployment ready |
| **🐳 Container Ready** | Docker and Kubernetes production manifests | Scalable infrastructure |
| **🧠 AI-Ready** | Engram integration for persistent memory | Session continuity |

---

## ✅ Validation & QA

> 🚨 **CRITICAL:** Hooks run automatically before every commit.

| Mechanism | Description | Status |
|-----------|-------------|--------|
| **Automated Hooks** | pre-commit, pre-push, 7D validation | ✅ Active |
| **Adversarial Review** | Judgment day protocol | ✅ Active |
| **Testing & Coverage** | `testing-strategy-skill` integration | ✅ Active |
| **SDD Enforcement** | Specification and criteria validation | ✅ Mandatory |

### Code Review Dimensions
| Dimension | Icon | Description | Focus |
|-----------|------|-------------|-------|
| **Security** | [S] | Secrets, vulnerabilities, OWASP | Critical protection |
| **Quality** | [Q] | Code smell, complexity, error handling | Maintainability |
| **Architecture** | [A] | Structure, patterns, modularity | Solid design |
| **Testing** | [T] | Coverage, patterns, edge cases | Complete validation |
| **Docs** | [D] | README, changelog, comments | Clear documentation |
| **API Design** | [API] | REST, validation, versioning | Clear contracts |
| **Git Flow** | [G] | Commits, branches, hooks | Ordered workflow |

### Review Flow

```
                            AUTOMATIC (Pre-commit)                               

      git commit → pre-commit hook → Fast scan (Secrets + Quality)     

                          Critical?         Report saved      Allow               
                          [X] BLOCK     docs/reviews/    [OK] Proceed         

                              MANUAL (On Demand)                                

      wf review              --> Full review (all 7 dimensions)                
      wf review security     --> Security only                                 
      wf review quality      --> Quality only                                   
      wf review quick       --> Fast scan (~30s)                              
      wf review --report    --> Generate detailed report                       
      wf review --track     --> Export issues to CSV                           
```

---

## 🤖 Supported AI Agents

| Agent | Integration | Recommended | Why |
|-------|-------------|-------------|-----|
| **OpenCode** | Full (per-phase routing) | ✅ Default | Multi-provider support |
| **Claude Code** | Full (sub-agents) | ✅ Yes | Native integration |
| **Cursor** | Full (9 SDD agents) | ✅ Yes | Parallel execution |
| **Gemini CLI** | Full (experimental) | ❌ No | Testing only |
| **VS Code Copilot** | Full (parallel) | ❌ No | IDE only |
| **Codex** | Solo-agent | ❌ No | Limited scope |
| **Windsurf** | Solo-agent | ❌ No | Limited scope |
| **Antigravity** | Solo-agent + Mission Control | ❌ No | Experimental |

---

## 🛠️ Available Skills

### Frontend
| Skill | Description | Trigger |
|-------|-------------|---------|
| `angular/core` | Standalone components, signals, inject, zoneless | Angular components |
| `angular/forms` | Signal Forms, Reactive Forms | Angular forms |
| `angular/performance` | NgOptimizedImage, @defer, lazy loading | Angular optimization |
| `angular/architecture` | Scope Rule, project structure, file naming | Angular projects |
| `react-19` | React 19 patterns with React Compiler | React components |
| `nextjs-15` | Next.js 15 App Router patterns | Next.js projects |
| `typescript` | TypeScript strict patterns | TypeScript code |
| `tailwind-4` | Tailwind CSS 4 patterns | Tailwind styling |
| `zod-4` | Zod 4 schema validation | Zod validation |
| `zustand-5` | Zustand 5 state management | React state |

### Backend & AI
| Skill | Description | Trigger |
|-------|-------------|---------|
| `ai-sdk-5` | Vercel AI SDK 5 patterns | AI chat features |
| `django-drf` | Django REST Framework patterns | Django REST APIs |
| `pytest` | Python pytest patterns | Python tests |
| `go-api` | Go REST API standards | Go backend |

### Workflow
| Skill | Description | Trigger |
|-------|-------------|---------|
| `github-pr` | Quality PRs with conventional commits | PR creation |
| `jira-task` | Jira task creation | Task creation |
| `jira-epic` | Jira epic creation | Epic creation |
| `project-scaffolding` | Project scaffolding and templates | New project setup |

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for full contribution guidelines.

### Development Setup
```bash
git clone https://github.com/EmmanuelOrtiz87/workspace-foundation.git
cd workspace-foundation
.\scripts\wf.ps1 update
.\scripts\wf.ps1 review
```

### Create New Skills
```powershell
.\scripts\utilities\create-skill.ps1 -Name "my-skill" -Type "orchestrator"
```

---

## 📄 License
MIT License - see [LICENSE](LICENSE) for details.

---

## 🆘 Support & Community
- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/EmmanuelOrtiz87/workspace-foundation/issues)
- **Discussions**: [GitHub Discussions](https://github.com/EmmanuelOrtiz87/workspace-foundation/discussions)

---

**Ready to operate with governance, automation, and real AI?**

Start with `.\scripts\wf.ps1 health` and consult the documentation for workflows, skills, and active policies.
