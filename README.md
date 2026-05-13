<h1 align="center">🚀 Workspace Foundation</h1>

<p align="center">
  <strong>🤖 The definitive AI-first development stack</strong><br>
  <em>🔒 Local-first · 🛡️ Privacy-first · 🧠 127 specialized skills · ⚡ Zero external dependencies</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-2.9.1-brightgreen?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/Status-Production%20Ready-success?style=flat-square" alt="Status">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License">
  <img src="https://img.shields.io/badge/PowerShell-7+-purple?style=flat-square" alt="PowerShell">
  <img src="https://img.shields.io/badge/Agents-16-orange?style=flat-square" alt="Agents">
  <img src="https://img.shields.io/badge/Skills-127-teal?style=flat-square" alt="Skills">
  <img src="https://img.shields.io/badge/Tests-33-green?style=flat-square" alt="Tests">
  <img src="https://img.shields.io/badge/Workflows-15-blueviolet?style=flat-square" alt="Workflows">
</p>

---

## ⚡ Quick Start

```powershell
# 🚀 Start a session
.\scripts\utilities\session-autostart.cmd

# ✅ Verify all 14 quality gates
wf verify

# ℹ️ Show version + skill count
wf version

# 📋 Available commands
wf start-session | wf dashboard | wf benchmark | wf judgment-day
```

### 📦 Installation Methods

| # | Method | Command / Source | Target Audience |
|---|--------|-----------------|-----------------|
| 1 | **📥 Installer (.exe)** | Download `Foundation-Setup.exe` from [`foundation-public`](https://github.com/EmmanuelOrtiz87/foundation-public) | 🧑‍💻 End users (public distribution) |
| 2 | **🛠️ Bootstrap** | `.\scripts\foundation\bootstrap.ps1` | 👨‍💻 Developers (full local environment) |
| 3 | **🔄 Multi-PC** | `.\scripts\foundation\setup-multi-machine.ps1` | 🏢 Enterprise (replicate across machines) |

> **💡 Note**: The `.exe` installer is built in this repo (`dist/`) and distributed via `foundation-public`. For development, use the Bootstrap method.

---

## 🏗️ Architecture

<img src="docs/assets/architecture-5-layers.svg" alt="5-Layer Architecture" width="960">

### 🔄 Data Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│  User Task                                                         │
│    → wf.ps1 (CLI entry)                                            │
│      → pre-process-input.ps1 (auto-delegation routing)             │
│        → Agent (BA │ DEV │ QA │ OPS │ GOV │ DOC │ SAD │ ...)      │
│          → MCP Server (skill activation)                           │
│            → Skill execution (127 specialized skills)              │
│              → Engram (read/write persistent memory)               │
│                ← Result returned to user                           │
└─────────────────────────────────────────────────────────────────────┘
```

### 🏛️ 5-Layer Architecture

| 🏆 | Layer | Role | Components | Config |
|---|-------|------|-----------|--------|
| 🧭 | **1. Agents** | Task delegation | 1 orchestrator + 15 sub-agents | `config/auto-delegation.json` |
| ⌨️ | **2. Commands** | CLI entry points | `wf.ps1`, `pre-process-input.ps1` | `config/orchestrator.json` |
| 🔌 | **3. MCP Servers** | Protocol bridge | Model Context Protocol, Engram MCP | `skills/*/SKILL.md` |
| 🛠️ | **4. Skills** | Specialized execution | 127 skills (frontend, backend, DevOps, security, testing) | `config/skill-dependencies.json` |
| 🧠 | **5. Memory** | Persistent context | Engram (hot/warm/cold tiers, 607+ observations) | `config/engram-config.json` |

---

## 🤖 Agent Ecosystem

### 🎯 Auto-Delegation

The orchestrator routes your request to the right agent automatically:

| 🆔 | Agent | Role | Skill |
|----|-------|------|-------|
| 🧭 | **Orchestrator** | ⚡ Main router — coordinates all agents | `project-orchestrator-skill` |
| 🔍 | **BA** *(sdd-explore)* | 📋 Requirements gathering & analysis | `sdd-lifecycle` |
| 🏗️ | **DEV** *(sdd-apply)* | 💻 Code generation & feature building | `sdd-lifecycle` |
| 🏛️ | **SAD** *(sdd-design)* | 📐 System design & API contracts | `sdd-lifecycle` |
| ✅ | **QA** *(sdd-verify)* | 🧪 Testing & validation | `sdd-lifecycle` |
| 🚀 | **OPS** | ⚙️ Deployment, CI/CD, infrastructure | `docker-devops-skill` |
| 📖 | **DOC** | 📝 Technical docs & guides | `documentation-governance` |
| 🛡️ | **GOV** | 🔒 Compliance, security, audit | `judgment-day` |
| ⚡ | **SESSION** | 🔄 Session lifecycle management | `session-workflow-skill` |
| 🔮 | **PREMORTEM** | ⚠️ Risk identification & stress testing | `premortem-skill` |
| 💰 | **FINANCE** | 📊 Financial modeling & calculations | `finance-financial-analyst` |
| ⚖️ | **LEGAL** | 📜 Regulatory & policy compliance | `legal-compliance-officer` |
| 📢 | **MKT** | ✍️ Marketing copywriting & SEO | `marketing-content-writer` |
| 💼 | **SALES** | 📈 Pipeline & account management | `sales-account-executive` |
| 👥 | **HR** | 🎯 Talent acquisition & people processes | `hr-talent-acquisition` |
| 📋 | **SCRIPT-GOV** | 📝 Script compliance governance | `script-governance-skill` |

> **📌 Note**: All sub-agents are `hidden: true` in `opencode.json` — only the Orchestrator is user-selectable. Sub-agents are managed autonomously via `config/auto-delegation.json`.

### 🧬 Model Router (v2.2.0)

| Model | Provider | Used By |
|-------|----------|---------|
| 🟢 **GLM-5** | `openrouter/z-ai/glm-5` | DEV, QA, OPS, PREMORTEM, FINANCE |
| 🟡 **Kimi K2.6** | `openrouter/moonshot/kimi-k2.6` | BA, SAD, GOV, LEGAL |
| 🔵 **Qwen 3.6 Plus** | `openrouter/qwen/qwen-3.6-plus` | Orchestrator, DOC, SESSION, MKT, SALES, HR |

---

## 🧰 Skill Catalog

| 📂 Category | 🔢 Count | 🏆 Key Skills |
|-------------|----------|--------------|
| 🎨 Frontend | 15 | `react-19-skill`, `angular-spa-skill`, `nextjs-15-skill`, `tailwind-4-skill`, `zustand-5-skill` |
| ⚙️ Backend | 12 | `golang-api-skill`, `django-drf-skill`, `api-design-skill`, `database-relational-skill` |
| 📱 Mobile | 8 | `flutter-skill`, `android-kotlin-skill`, `ios-swift-development`, `react-native-skill` |
| 🛡️ Security & Governance | 18 | `security-skill`, `judgment-day`, `architecture-governance`, `documentation-governance` |
| 🧪 Testing | 12 | `testing-skill`, `playwright-skill`, `pytest-skill`, `testing-strategy-skill` |
| 📊 Visualization | 3 | `fireworks-tech-graph`, `visual-content-skill`, `cognitive-doc-design` |
| 🚢 DevOps | 6 | `docker-devops-skill`, `terraform-skill`, `ci-cd-pipeline-skill` |
| 🌐 Accessibility | 1 | `accessibility-skill` (WCAG 2.2) |
| 🔎 SEO | 1 | `seo-skill` |
| 🏢 Business | 8 | `business`, `finance-financial-analyst`, `sales-account-executive`, `hr-talent-acquisition` |
| 📋 Governance | 8 | `script-governance-skill`, `release-management-skill`, `code-review-orchestrator-skill` |
| 🔄 Workflow | 6 | `gitflow-orchestrator-skill`, `daily-workflow`, `session-workflow-skill` |
| 📦 Other | 29 | Reporting, telemetry, project scaffolding, templates, security auditing |

> **📂 Full catalog**: `docs/reference/SKILL-ORGANIZATION.md` or `wf.ps1 skills`

---

## 🔄 CI/CD Pipeline (15 Workflows)

| ⚙️ Workflow | 🎯 Purpose | ⏰ Trigger |
|-------------|-----------|-----------|
| `foundation-quality-gate.yml` | ✅ Quality gates on PRs | Every PR |
| `test-suite.yml` | 🧪 33 tests (4 categories) | Every PR/push |
| `ps-lint.yml` | 🔍 PSScriptAnalyzer lint | Every PR |
| `sdd-gate.yml` | 🚫 Block PRs without SDD | Every PR |
| `script-governance.yml` | 📜 Script compliance | Every PR |
| `format-check.yml` | ✨ Prettier formatting | Every PR |
| `gitleaks.yml` | 🔐 Secret scanning | Every PR |
| `security-scan.yml` | 🛡️ OWASP security scanning | Weekly (Sun) |
| `codeql-analysis.yml` | 📊 CodeQL analysis | Weekly (Mon) |
| `autonomous-validation.yml` | 🔄 Full validation suite | Weekly (Mon) |
| `dashboard-auto-refresh.yml` | 📈 Metrics dashboard | Daily 07:00 UTC |
| `monthly-management-report.yml` | 📑 Executive report | Monthly |
| `dependency-backup.yml` | 💾 Dependency backup | Weekly (Sun) |
| `release.yml` | 📦 Release management | On tag |
| `labeler.yml` | 🏷️ Auto-label PRs | Every PR |
| `workflow-lint.yml` | ✅ Workflow syntax validation | On `.github/` change |
| `sync-public.yml` | 🔄 Sync to `foundation-public` | On push to `main` |

> **🌿 Branching model**: `develop` for active work, `main` for releases only.

---

## 📋 Session Management

| ⌨️ Command | 🎯 Purpose |
|-----------|-----------|
| `wf start-session` | 🚀 Initialize tracked session with Engram |
| `wf end-session` | 🛑 Close session and save summary |
| `wf dashboard` | 📊 Open HTML metrics dashboard |
| `wf benchmark` | ⏱️ SLO benchmark of key commands |
| `wf judgment-day` | ✅ Full QA gate (14 checks) |
| `wf skills` | 📚 List available skills |
| `wf version` | ℹ️ Show version + skill count |

> **🪙 Token Budget Guard**: Runs automatically within sessions, alerting at 80%/90%/95% thresholds.

---

## 📁 Project Structure

```
foundation/
├── 🤖 .agents/                    # Agent configurations (7 skill-based agents)
├── 🧠 .engram/                    # Persistent memory store
├── 📅 .session/                   # Session state and metrics
├── ⌨️ bin/                        # CLI tools (gf.ps1)
├── 📦 build/                      # NSIS installer definition
├── ⚙️ config/                     # All configuration files
│   ├── orchestrator.json          # Main orchestrator config
│   ├── auto-delegation.json       # 29 agent routing bindings
│   ├── model-router.json          # Model-to-agent assignments
│   ├── session-autostart.config.json  # 11-step pipeline
│   ├── security-policy.json       # Auth requirements
│   └── owner-auth.json            # Owner authentication (encrypted)
├── 🎬 demos/                      # Demo materials
├── 📦 dist/                       # Built installer (Foundation-Setup.exe)
├── 📚 docs/                       # Documentation + architecture diagrams
│   ├── assets/                    # SVG/PNG architecture diagrams
│   ├── architecture/              # Architecture docs
│   ├── reference/                 # Skill catalog, token tracking
│   └── getting-started/           # Onboarding guide
├── 🔗 hooks/                      # Git hooks (lefthook config)
├── 🔑 keys/                       # Encryption keys (master.key)
├── 📏 rules/                      # Normativas (coding, error handling, performance)
├── 📜 scripts/                    # All automation scripts
│   ├── adaptive/                  # Auto-orchestration
│   ├── diagnostics/               # Auto-learn, diagnostics
│   ├── foundation/                # Bootstrap, setup, sync-public
│   ├── git-hooks/                 # Commit/PR validation
│   ├── hooks/                     # Pre/post processing
│   ├── security/                  # Auth, token guard
│   └── utilities/                 # Core utilities (wf, session, auth, metrics)
├── 🛠️ skills/                     # 127 specialized skill definitions
├── 📋 templates/                  # Project templates
├── 🧪 tests/                      # 33 tests (4 categories)
└── 🛠️ tools/                      # Supplementary dev tools
```

---

## ⚙️ Configuration

| 📄 File | 🎯 Purpose |
|---------|-----------|
| `config/orchestrator.json` | 🧭 Main orchestrator (response mode, session, features) |
| `config/auto-delegation.json` | 🤖 Agent routing, profiles, 29 keyword mappings |
| `config/model-router.json` | 🧬 Model-to-agent bindings (29 entries) |
| `config/session-autostart.config.json` | 📋 11-step pipeline definition |
| `config/security-policy.json` | 🔒 Auth requirements for restricted ops |
| `config/owner-auth.json` | 🔑 Owner API key + security questions (encrypted) |
| `config/metrics-config.json` | 📊 Metrics collection and reporting config |
| `config/behavior-prompts.json` | 🧠 Agent behavior profiles |
| `CLAUDE.md` | 🤖 Claude-specific instructions |
| `docs/AGENTS.md` | 📖 Tool-agnostic bootstrap (canonical entry point) |

---

## ✅ Validation Status

| 🚦 Gate | 📊 Result |
|---------|----------|
| ⚙️ CONFIG | ✅ 3/3 PASS (json-syntax, auto-delegation, quality) |
| 🛠️ SKILLS | ✅ 1/1 PASS (127 validated) |
| 🧪 TESTS | ✅ 1/1 PASS (33 unit + integration) |
| 🔗 HOOKS | ✅ 2/2 PASS (hook-scripts, git-hook-installed) |
| 📁 STRUCTURE | ✅ 7/7 PASS (all checks) |
| **🎯 Total** | **✅ 14/14 PASS, 0 errors, 0 warnings** |

---

## 📋 Prerequisites

| 💻 Requirement | 📌 Version | ❓ Required? | 📝 Notes |
|---------------|-----------|-------------|---------|
| PowerShell | 7+ | ✅ Yes | Core runtime |
| Git | 2.50+ | ✅ Yes | Version control |
| Go | 1.26+ | ❌ Optional | Engram binary compilation |
| Node.js | 18+ | ❌ Optional | Some development tools |

---

## 🛡️ Defensive Patterns

All PowerShell scripts follow standardized defensive patterns documented in `scripts/DEFENSIVE-PATTERNS.md`:

- 🔒 Robust `repoRoot` resolution via `$env:FOUNDATION_BASE_DIR` + recursive config search
- 📝 BOM-free UTF-8 encoding
- 🔤 ASCII-only output (no Unicode in scripts)
- 🛠️ `Add-Member -Force` for `PSCustomObject` property assignment
- 📦 Quoted hashtable keys with hyphens
- 🚫 `$ErrorActionPreference = 'Stop'` at script entry
- 🔐 SHA256 integrity baselines for security-critical config

---

## 📚 Documentation

| 📖 Document | 📝 Description |
|------------|---------------|
| [AGENTS.md](docs/AGENTS.md) | 🚀 Tool-agnostic bootstrap (canonical entry) |
| [Getting Started](docs/getting-started/README.md) | 🏁 Setup guide |
| [Architecture](docs/architecture/README.md) | 🏗️ System design |
| [Skills Catalog](docs/reference/SKILL-ORGANIZATION.md) | 📚 127 skills reference |
| [Session Auth Flow](docs/SESSION-AUTH-FLOW.md) | 🔐 Authentication documentation |
| [Token Tracking](docs/reference/REAL-TOKEN-TRACKING.md) | 📊 Token monitoring |
| [Plugin System](docs/reference/PLUGIN-ARCHITECTURE.md) | 🔌 Plugin development |
| [Defensive Patterns](scripts/DEFENSIVE-PATTERNS.md) | 🛡️ PowerShell coding standards |
| [Changelog](CHANGELOG.md) | 📋 Version history |
| [Contributing](CONTRIBUTING.md) | 🤝 How to contribute |

---

## 🗺️ Roadmap

| ⏰ Horizon | 🎯 Milestone |
|-----------|-------------|
| 📅 Short-term | Enhanced agent memory, improved skill discovery |
| 📅 Mid-term | Multi-modal support, advanced analytics dashboard |
| 📅 Long-term | Fully autonomous development lifecycle |

> **📌 Full roadmap**: [ROADMAP.md](ROADMAP.md)

---

<p align="center">
  <strong>🚀 Workspace Foundation v2.9.0</strong><br>
  <em>🔒 100% Local-First · 🛡️ Privacy Total · ✅ Production Ready</em>
</p>

<p align="center">
  <sub>Built with ❤️ by the Foundation team · 🌐 <a href="https://github.com/EmmanuelOrtiz87/foundation">github.com/EmmanuelOrtiz87/foundation</a></sub>
</p>
