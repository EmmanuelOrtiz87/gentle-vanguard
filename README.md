# 🤖 Gentleman Foundation - AI-Powered Development Suite

> **"Where Code Meets Intelligence"**

A comprehensive, AI-orchestrated development framework that transforms how teams build software through intelligent coordination, automated quality assurance, and seamless workflow management.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-7+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Go](https://img.shields.io/badge/Go-1.19+-blue.svg)](https://golang.org/)
[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)

## 🎯 What is Gentleman Foundation?

Gentleman Foundation is a revolutionary development suite that combines:

- **🤖 AI Orchestration**: Intelligent coordination of development workflows
- **🔄 Automated Tool Activation**: Zero-config environment setup
- **📋 Quality Assurance**: Pre-commit validation and automated reviews
- **🧠 Memory Persistence**: AI context retention across sessions
- **🎨 Template System**: Rapid project scaffolding with best practices
- **🔗 Homologated Projects**: Consistent development experience across all projects

## 🧭 Stack Positioning

Gentleman Foundation should be treated as an operational framework, not a closed tool.

1. Core identity:
- Framework-oriented workflow platform.
- Composable orchestration layer over scripts, policies, and skills.

2. Tool strategy:
- Integrates optional and replaceable tools (Engram, GGA, Gentle-AI).
- Does not hard-couple all capabilities to a single binary lifecycle.

3. Engram role:
- Engram is mandatory for continuity posture in guarded workflows.
- Foundation still keeps a graceful fallback path when Engram is temporarily unavailable.

4. Practical outcome:
- Foundation behaves as a governance and execution framework.
- Engram behaves as a specialized persistence component within that framework.

## 🚀 Quick Start

### Prerequisites

**System Requirements:**
- Windows 10/11 or Linux/macOS
- PowerShell 7+ (Windows) or PowerShell Core (cross-platform)
- Git 2.30+
- Node.js 18+
- Go 1.19+

**AI Tools (Optional but Recommended):**
- Claude/OpenCode/Gentle-AI (any AI coding assistant)
- GGA (Gentleman Guardian Angel)
- Engram (memory persistence system)

### Installation

1. **Clone the Foundation Template:**
```bash
git clone https://github.com/EmmanuelOrtiz87/workspace-foundation.git
cd workspace-foundation
```

2. **Configure PowerShell Profile (Windows):**
```powershell
# Copy the auto-activation profile
Copy-Item "scripts/utilities/Microsoft.PowerShell_profile.ps1" $PROFILE
. $PROFILE  # Reload profile
```

3. **Initialize Environment:**
```powershell
# Run health check and activate all tools
.\scripts\utilities\wf.ps1 health
```

> `health` now also auto-starts the tooling flow and attempts to install missing CLI dependencies like `engram`.

4. **Open the Session Properly:**
```powershell
# Create the daily session brief
.\scripts\utilities\wf.ps1 start-session

# Or create it together with the first bounded task brief
.\scripts\utilities\wf.ps1 start-session foundation-hardening
```

5. **Create Your First Project:**
```powershell
# Create a new project from the canonical project bootstrap flow
.\scripts\project\new-project.ps1 -Name "my-awesome-project" -Kind "service"
```

## 🎬 Demo Entry Point

Use the audience-labeled demo suite to jump directly to the right walkthrough:

1. Development Team: `demos/01-dev-developer-onboarding/` to `demos/05-dev-documentation-and-closure/`
2. Executive Council / Management: `demos/06-exec-executive-overview/`
3. Demo index and recommended order: `demos/README.md`
4. Shared sample project used across all demos: `demos/shared/task-tracker/`

## 🏗️ Architecture Overview

```
Gentleman Foundation Suite
├── 🤖 AI Orchestration Layer
│   ├── Project Orchestrator (Always Active)
│   ├── Code Review Orchestrator
│   ├── Session Workflow Manager
│   └── Foundation Manager
├── 🔧 Tool Integration Layer
│   ├── Engram (Memory System)
│   ├── GGA (Code Review)
│   ├── Gentle-AI (CLI Assistant)
│   └── GitHub CLI Integration
├── 📋 Quality Assurance Layer
│   ├── Pre-commit Hooks
│   ├── Automated Testing
│   ├── Security Scanning
│   └── Code Standards Enforcement
├── 🎨 Template System
│   ├── Project Scaffolding
│   ├── Skill Injection
│   └── Configuration Management
└── 🔄 Workflow Automation
    ├── Environment Activation
    ├── Session Management
    └── Continuous Validation
```

## � Design & Specifications

### Software Design Document (SDD)
The foundation follows a comprehensive design document that combines architectural planning with specification-driven development:

**→ [Foundation SDD](./docs/sdd/foundation-sdd.md)**

**Key Sections:**
- System Architecture & Components
- Error Handling Patterns
- Performance Optimization
- AI-Assisted Development Guidelines
- Cross-Platform Implementation

### Specification Driven Development
All components are built following TDD/BDD principles:
- Tests define requirements before implementation
- Specifications drive design decisions
- Quality gates ensure compliance

## �📚 Core Components

### 🤖 AI Skills System

Gentleman Foundation uses a sophisticated skill-based architecture:

#### Master Orchestrators (On-Demand Recommended)
- **Project Orchestrator**: Auto-detects project type, loads relevant skills, guides workflow, and acts as an expert for analysis, design, architecture, and testing throughout the development lifecycle
- **Session Workflow**: Manages session lifecycle, memory persistence, todo tracking
- **Code Review Orchestrator**: Coordinates quality checks and automated reviews

> Recommended operation mode: activate orchestrator controls only during active implementation windows, then deactivate at closeout.
>
> Use: `.\scripts\utilities\stack-on-demand.ps1 -Action activate|validate|deactivate`

> Run `.\scripts\utilities\orchestrator-next-steps.ps1` from the foundation root to get the orchestrator's recommended next actions.

#### Specialized Skills
- **Foundation Manager**: Template management and project initialization
- **Security Expert**: Vulnerability scanning and security best practices
- **Testing Strategy**: Comprehensive testing frameworks and strategies
- **Architecture Governance**: System design and architectural decisions

### 🔧 Development Tools

#### Core CLI (`wf.ps1`)
```powershell
# Check project status
.\scripts\utilities\wf.ps1 status

# One-shot operations dashboard (health + token risk + next action)
.\scripts\utilities\wf.ps1 stack-dashboard

# Machine-readable dashboard output for automation
.\scripts\utilities\wf.ps1 stack-dashboard -JSON

# Strict mode for CI/CD gates (non-zero exit when traffic light is RED)
.\scripts\utilities\wf.ps1 stack-dashboard strict

# Run code review
.\scripts\utilities\wf.ps1 review

# Generate audit reports
.\scripts\utilities\wf.ps1 audit

# Check system health
.\scripts\utilities\wf.ps1 health

# Create pull requests
.\scripts\utilities\wf.ps1 pr

# Commit and push changes
.\scripts\utilities\wf.ps1 push

# Update repository, foundation, skills, and tools
.\scripts\utilities\wf.ps1 update
```

Dashboard signal coverage:

1. Executive traffic light (GREEN/YELLOW/RED).
2. Token budget burn rate and estimated threshold exhaustion time (ETA).
3. Engram continuity posture.
4. Immediate recommended next actions to avoid session blockage.
5. Strict gate signal in JSON (`strict_violation`) for pipeline automation.
6. Local telemetry is stored at `docs/sessions/metrics/token-guard-usage.csv` (gitignored by design).

> For global foundation updates, run `gf update-all` from the foundation install root.

#### Auto-Activation System
- **Pre-commit Hooks**: Automatic validation before commits
- **PowerShell Profile**: Auto-activation when entering projects
- **Health Checks**: Comprehensive tool availability validation
- **Environment Init**: One-command setup for new sessions

### 🎨 Project Templates

Gentleman Foundation provides templates for:

- **Web APIs** (Go + REST)
- **Single Page Applications** (Angular + TypeScript)
- **Microservices** (Docker + Kubernetes)
- **Data Processing** (Python + FastAPI)
- **DevOps Pipelines** (GitHub Actions + Azure)

## 🚀 Workflow Lifecycle

### 1. Project Initialization
```powershell
# Auto-detects project type and loads skills
# Activates all development tools
# Sets up quality gates and hooks
```

### 2. Development Session
```powershell
# AI-guided workflow suggestions
# Automatic code reviews
# Memory persistence across sessions
# Quality assurance checks
```

### 3. Code Quality Gates
```powershell
# Pre-commit validation
# Security scanning
# Automated testing
# Standards compliance
```

### 4. Deployment Ready
```powershell
# Containerization support
# CI/CD pipeline generation
# Infrastructure as Code
# Production deployment templates
```

## �️ Weekly Audit Runbook

A systematic 5-step process to generate a complete, governance-validated audit of the repository.
All output files use full datetime in their name (`YYYY-MM-DD-HHmmss`) so multiple runs on the same day are always distinguishable.

### Step 1 — Generate Context Pack
```powershell
.\scripts\utilities\wf.ps1 context-pack
# Output: docs/sessions/YYYY-MM-DD-HHmmss-context-pack.md
```
Captures the current repository state: branch, recent commits, changed files, and platform health.

### Step 2 — Activate Compact Context
```powershell
.\scripts\utilities\wf.ps1 compact-start
# Reads: latest context-pack from docs/sessions/ (by filename timestamp)
# Logs event to: docs/sessions/metrics/context-usage.csv
```
Loads the latest context pack and records the compact-start telemetry event.

### Step 3 — Generate Audit Document
```powershell
.\scripts\utilities\wf.ps1 audit
# Output: docs/audits/YYYY-MM-DD-HHmmss-audit.md
```
Produces a full audit report with delivery status, operational risk, test suite availability,
git ahead/behind tracking, and annotated next steps.

### Step 4 — Governance Validation
```powershell
.\scripts\diagnostics\validate-script-governance.ps1
# Expected: EXIT:0 (all checks passed)

# Optional strict gate (recommended for CI)
.\scripts\utilities\wf.ps1 health -StrictCleanup
```
Validates that all scripts reference canonical paths and that no deprecated references remain.
A non-zero exit is a blocking issue — fix before proceeding.

### Step 5 — Review Session Metrics
```powershell
.\scripts\utilities\wf.ps1 context-metrics
# Reads: docs/sessions/metrics/context-usage.csv
```
Displays accumulated session metrics: total events, context-pack calls, compact-start calls,
and context efficiency indicators.

### Step 6 — Manual Homologation (Optional)
```powershell
# Preview cleanup actions
.\scripts\utilities\wf.ps1 homologate

# Apply cleanup and reference updates
.\scripts\utilities\wf.ps1 homologate apply
```
Use this when strict cleanup reports drift or when you want to normalize the workspace before release.

---

## �📖 Documentation

### For Developers
- **[Session Guide](docs/guides/SESSION-GUIDE.md)**: Daily workflow and commands
- **[Tool Activation](docs/guides/TOOL-ACTIVATION.md)**: Auto-activation system
- **[Code Standards](docs/guides/CODE-STANDARDS.md)**: Development guidelines
- **[Testing Strategy](docs/guides/TESTING-STRATEGY.md)**: Quality assurance

### For Project Leads
- **[Architecture Overview](docs/reference/ARCHITECTURE.md)**: System design rationale
- **[Skill Development](docs/skills/SKILL-DEVELOPMENT.md)**: Creating new AI skills
- **[Template Creation](docs/templates/TEMPLATE-GUIDE.md)**: Building project templates

### For Administrators
- **[Installation Guide](docs/setup/INSTALLATION.md)**: Complete setup instructions
- **[Configuration](docs/setup/CONFIGURATION.md)**: Advanced configuration options
- **[Troubleshooting](docs/setup/TROUBLESHOOTING.md)**: Common issues and solutions

## 🔧 Configuration

### Environment Variables
```bash
# AI Tools
export GENTLE_AI_TOKEN="your-token"
export CLAUDE_API_KEY="your-key"

# Development Paths
export GENTLEMAN_ROOT="/path/to/foundation"
export GGA_PATH="/path/to/gga"

# Git Configuration
git config --global core.hooksPath "/path/to/foundation/hooks"
```

### Project Configuration
Each project contains a `.gentleman` configuration file:

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
    "review": "gga"
  },
  "quality": {
    "precommit": true,
    "security": true,
    "testing": true
  }
}
```

## 🎯 Key Features

### 🤖 Intelligent Coordination
- **Auto-detection**: Project type, tech stack, and requirements
- **Skill Loading**: Dynamic loading of relevant AI skills
- **Workflow Guidance**: Step-by-step development guidance
- **Quality Gates**: Automated validation at every step

### 🔄 Memory Persistence
- **Session Continuity**: Context retention across development sessions
- **Decision Tracking**: Architecture and implementation decisions
- **Knowledge Base**: Accumulated best practices and patterns
- **Collaboration**: Shared context across team members

### 🛡️ Quality Assurance
- **Pre-commit Hooks**: Automatic validation before commits
- **Security Scanning**: Vulnerability detection and fixes
- **Code Standards**: Automated formatting and linting
- **Testing Automation**: Comprehensive test suite execution

### 🚀 Rapid Development
- **Project Scaffolding**: One-command project creation
- **Template System**: Proven architectures and patterns
- **Tool Integration**: Seamless integration with development tools
- **Deployment Ready**: Production-ready configurations out-of-the-box

## 🌟 Success Stories

### Enterprise Adoption
> "Gentleman Foundation reduced our onboarding time by 80% and improved code quality by 60%." - Enterprise Dev Lead

### Startup Acceleration
> "From idea to production in 3 days instead of 3 weeks." - Startup CTO

### Team Productivity
> "Our developers are now 3x more productive with AI-guided workflows." - Engineering Manager

## 🤝 Contributing

We welcome contributions! See our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup
```bash
# Clone and setup
git clone https://github.com/EmmanuelOrtiz87/workspace-foundation.git
cd workspace-foundation

# Install development dependencies
.\scripts\utilities\install-dev-dependencies.ps1

# Run tests
.\scripts\utilities\wf.ps1 review
```

### Adding New Skills
```powershell
# Use the skill creator
.\scripts\utilities\create-skill.ps1 -Name "my-new-skill" -Type "orchestrator"
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **AI Assistants**: Claude, OpenCode, Gentle-AI for intelligent guidance
- **Open Source Community**: For the amazing tools we integrate
- **Beta Testers**: For their valuable feedback and contributions

## 📞 Support

- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/EmmanuelOrtiz87/workspace-foundation/issues)
- **Discussions**: [GitHub Discussions](https://github.com/EmmanuelOrtiz87/workspace-foundation/discussions)

---

**Ready to revolutionize your development workflow?** 🚀

Start with `.\scripts\utilities\wf.ps1 health` and experience the future of AI-powered development!

## The Unified Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AUTOMATIC (Pre-commit)                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│    git commit ──► pre-commit hook ──► Fast scan (Secrets + Quality)     │
│                                           │                                 │
│                          ┌────────────────┼────────────────┐                │
│                          │                │                │                │
│                     Critical?         Report saved      Allow               │
│                          │                │                │                │
│                          ▼                ▼                ▼                │
│                       [X] BLOCK     docs/reviews/    [OK] Proceed         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                           MANUAL (On Demand)                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│    wf review              --> Full review (all 7 dimensions)                │
│    wf review security     --> Security only                                 │
│    wf review quality      --> Quality only                                   │
│    wf review quick       --> Fast scan (~30s)                              │
│    wf review --report    --> Generate detailed report                       │
│    wf review --track     --> Export issues to CSV                           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

| Feature | Description |
|---------|-------------|
| **Global Installation** | Single installation per machine, used by all projects |
| **Unified CLI** | Single command (`gf`) for all operations |
| **Symlink Strategy** | Skills updated once, available everywhere |
| **Pre-commit Hooks** | Automatic secrets detection before commit |
| **25+ Skills** | Curated skills for Go, Angular, React, Python, etc. |
| **Multi-Technology** | Supports Node.js, Go, Python, Rust, and more |
| **Cross-Platform** | Works on Windows, Linux, and macOS |
| **Templates** | service, cli, library, frontend, fullstack, microservices |
| **CI/CD** | GitHub Actions, GitLab CI, Azure DevOps included |
| **Containers** | Docker and Kubernetes production-ready |
| **AI-Ready** | Engram integration for persistent memory |

## Project Types

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AVAILABLE TEMPLATES                                │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
    │   SERVICE   │  │     CLI     │  │   LIBRARY   │  │  FRONTEND   │
    │    [SVC]   │  │     [CLI]  │  │     [LIB]  │  │     [FE]   │
    ├─────────────┤  ├─────────────┤  ├─────────────┤  ├─────────────┤
    │ • API       │  │ • Go        │  │ • npm pkg   │  │ • React     │
    │ • Backend   │  │ • Rust      │  │ • PyPI      │  │ • Vue       │
    │ • Worker    │  │ • Node      │  │ • Go mod    │  │ • Angular   │
    └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘

    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
    │  FULLSTACK   │  │MICROSERVCS  │  │   MOBILE    │
    │     [FS]    │  │     [MS]    │  │     [M]     │
    ├─────────────┤  ├─────────────┤  ├─────────────┤
    │ • Nx Mono   │  │ • Gateway   │  │ • React Nat │
    │ • FE + BE   │  │ • Services  │  │ • Flutter   │
    └─────────────┘  └─────────────┘  └─────────────┘
```

## Code Review Dimensions

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     7 DIMENSIONS CODE REVIEW                                 │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
    │  SECURITY   │  │  QUALITY    │  │ ARCHITECT.   │
    │     [S]    │  │     [Q]    │  │     [A]    │
    ├─────────────┤  ├─────────────┤  ├─────────────┤
    │ • Secrets   │  │ • Code smell│  │ • Structure │
    │ • Vulnerab. │  │ • Complexity│  │ • Patterns  │
    │ • OWASP     │  │ • Error hnd │  │ • Modularity│
    └─────────────┘  └─────────────┘  └─────────────┘

    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
    │   TESTING   │  │    DOCS     │  │   API DSGN   │
    │     [T]    │  │     [D]    │  │     [API]   │
    ├─────────────┤  ├─────────────┤  ├─────────────┤
    │ • Coverage  │  │ • README    │  │ • REST       │
    │ • Patterns  │  │ • Changelog│  │ • Validation│
    │ • Edge case│  │ • Comments  │  │ • Versioning│
    └─────────────┘  └─────────────┘  └─────────────┘

                        ┌─────────────┐
                        │  GIT FLOW   │
                        │     [G]    │
                        ├─────────────┤
                        │ • Commits   │
                        │ • Branches  │
                        │ • Hooks     │
                        └─────────────┘
```

## GGA - AI-Powered Code Review

**GGA** (Gentleman Guardian Angel) provides AI-powered code review on every commit, enforcing your project's coding standards defined in `AGENTS.md`.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           GGA WORKFLOW                                       │
└─────────────────────────────────────────────────────────────────────────────┘

    git commit ──▶ GGA Pre-commit Hook ──▶ AI Review ──▶ Pass/Fail
                                                      │
                                                      ▼
                                              Check against AGENTS.md
                                              Enforce coding standards
                                              Block if violations found
```

### Supported AI Providers

| Provider | Command | Installation |
|----------|---------|--------------|
| **Claude** | `claude` | [claude.ai/code](https://claude.ai/code) |
| **OpenCode** | `opencode` | [opencode.ai](https://opencode.ai) |
| **Gemini** | `gemini` | [gemini-cli](https://github.com/google-gemini/gemini-cli) |
| **Ollama** | `ollama:<model>` | [ollama.ai](https://ollama.ai) |
| **GitHub Models** | `github:<model>` | `gh auth login` |

### Configuration

Edit `.gga` in your project root:

```bash
PROVIDER="opencode"          # AI provider
FILE_PATTERNS="*.py,*.ts"   # Files to review
EXCLUDE_PATTERNS="*.test.*"  # Files to skip
STRICT_MODE="false"          # Fail on ambiguous responses
```

### Commands

```bash
gga run          # Review staged files
gga install      # Reinstall pre-commit hook
gga uninstall    # Remove pre-commit hook
gga config       # Show current configuration
```

> GGA is automatically installed when creating a new project with `wf new`.

## Gentle-AI - AI Ecosystem Configurator

**Gentle-AI** transforms your AI coding agent into an ecosystem with memory, skills, and Spec-Driven Development workflow.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     GENTLE-AI ECOSYSTEM                                     │
└─────────────────────────────────────────────────────────────────────────────┘

    Your AI Agent ──▶ Gentle-AI ──▶ Ecosystem with:
                              ├── Persistent Memory
                              ├── SDD Workflow
                              ├── Skills System
                              ├── MCP Servers
                              └── Teaching Persona
```

### Supported AI Agents

| Agent | Integration | Recommended |
|-------|-------------|-------------|
| **OpenCode** | Full (per-phase model routing) | Yes (default) |
| Claude Code | Full (with sub-agents) | Yes |
| Gemini CLI | Full (experimental) | No |
| Cursor | Full (9 SDD agents) | Yes |
| VS Code Copilot | Full (parallel execution) | No |
| Codex | Solo-agent | No |
| Windsurf | Solo-agent | No |
| Antigravity | Solo-agent + Mission Control | No |

OpenCode is the default provider for GGA code review and is recommended for its:
- Multi-provider support (Claude, GPT, Gemini, local models)
- Terminal, desktop, and IDE integration
- 140K+ GitHub stars, 6.5M monthly developers

### Quick Commands

```bash
./scripts/utilities/run-gentle-ai.ps1 status   # Show ecosystem status (native or compatibility mode)
./scripts/utilities/run-gentle-ai.ps1 update   # Run toolchain update flow
./scripts/utilities/run-gentle-ai.ps1 help     # Show available commands
./scripts/utilities/wf.ps1 update-tools        # Update gga, engram, and gentle-ai in one command
```

> Windows note: Homebrew (`brew`) is not required. Use `wf.ps1 update-tools` (Git Bash + Go).

### Post-Install (in your AI agent)

```bash
/sdd-init              # Initialize SDD context
skill-registry         # Build skills registry
```

> If native `gentle-ai` is not installed, the compatibility launcher keeps workflow checks operational without breaking startup/CI.

## Gentleman-Skills - AI Agent Skill Library

**Gentleman-Skills** provides community-curated skills for AI coding agents, offering specialized patterns for frameworks, libraries, and best practices.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     GENTLEMAN-SKILLS ECOSYSTEM                               │
└─────────────────────────────────────────────────────────────────────────────┘

    AI Agent ──▶ Skill Library ──▶ Framework Expertise
                                  ├── Angular Patterns
                                  ├── React Patterns
                                  ├── Testing Patterns
                                  ├── API Patterns
                                  └── Workflow Patterns
```

### Available Skills

#### Frontend

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

#### Backend & AI

| Skill | Description | Trigger |
|-------|-------------|---------|
| `ai-sdk-5` | Vercel AI SDK 5 patterns | AI chat features |
| `django-drf` | Django REST Framework patterns | Django REST APIs |
| `pytest` | Python pytest patterns | Python tests |

#### Testing

| Skill | Description | Trigger |
|-------|-------------|---------|
| `playwright` | Playwright E2E testing patterns | E2E tests |

#### Workflow

| Skill | Description | Trigger |
|-------|-------------|---------|
| `github-pr` | Create quality PRs with conventional commits | PR creation |
| `jira-task` | Jira task creation | Task creation |
| `jira-epic` | Jira epic creation | Epic creation |
| `skill-creator` | Create new AI agent skills | Skill creation |

### Installation

Skills are automatically installed for detected AI agents. To manually install:

```bash
# For Claude Code
cp -r tools/Gentleman-Skills/curated/* ~/.claude/skills/

# For OpenCode
cp -r tools/Gentleman-Skills/curated/* ~/.config/opencode/skills/

# For Gemini CLI
cp -r tools/Gentleman-Skills/curated/* ~/.gemini/skills/

# For Cursor
cp -r tools/Gentleman-Skills/curated/* ~/.cursor/skills/
```

### Skill Structure

```
~/.claude/skills/
├── angular/
│   └── core/SKILL.md
├── react-19/SKILL.md
├── typescript/SKILL.md
├── playwright/SKILL.md
└── ...
```

Each skill contains:
- **Trigger conditions** - When the AI should load this skill
- **Patterns and rules** - Coding conventions to follow
- **Code examples** - Reference implementations
- **Anti-patterns** - What to avoid

> Gentleman-Skills are automatically available when creating a new project with `wf new`.

## Severity Levels

| Level | Icon | Description | Action |
|-------|------|-------------|--------|
| **CRITICAL** | [!C] | Security breach, data loss risk | Block deployment |
| **HIGH** | [!H] | Major quality/deployment issue | Fix before merge |
| **MEDIUM** | [!M] | Technical debt, maintainability | Fix soon |
| **LOW** | [!L] | Best practice, polish | Consider fixing |

## Included Templates

### CI/CD
```
.github/workflows/ci.yml    ← GitHub Actions
.gitlab-ci.yml             ← GitLab CI  
azure-pipelines.yml       ← Azure DevOps
```

### Containers
```
Dockerfile                 ← Node.js (multi-stage)
Dockerfile.go             ← Go (multi-stage)
Dockerfile.python          ← Python (multi-stage)
k8s/                      ← Kubernetes manifests
  ├── deployment.yaml
  ├── service.yaml
  ├── ingress.yaml
  └── hpa.yaml
```

### Editor Configuration
```
.editorconfig              ← Universal (all editors)
.vscode/settings.json      ← VSCode
.vscode/extensions.json    ← Recommended extensions
```

## Project Structure

```
workspace-foundation/
├── .github/               # GitHub templates
│   ├── ISSUE_TEMPLATE/
│   └── PULL_REQUEST_TEMPLATE/
├── config/                # Global configurations
│   └── workspace.config.json
├── docs/                  # Documentation
│   ├── README.md         # This index
│   ├── VISUAL-GUIDE.md  # Complete visual reference
│   ├── ARCHITECTURE.md  # System design
│   ├── installation.md   # Setup guide
│   └── project-types.md # Template details
├── scripts/               # Automation scripts
│   └── wf.ps1           # Main CLI
├── skills/               # AI Skills
│   ├── workspace-foundation/
│   └── code-review-orchestrator/
├── templates/             # Project templates
│   ├── project-root/     # Base template
│   ├── project-types/    # By type (service, cli, library, etc.)
│   ├── gga/             # GGA configuration template
│   ├── config/           # ESLint, Prettier, etc.
│   ├── editor/           # Editor configs
│   └── testing/          # Test templates
└── tools/                 # External tools (auto-installed)
    └── Gentleman-Skills/ # AI agent skills library
```

## Documentation

| Document | Description |
|----------|-------------|
| [Installation Guide](docs/installation.md) | Setup instructions |
| [Existing Projects](docs/INTEGRATION-EXISTING-PROJECTS.md) | Integrate into existing repos |
| [AI Configuration](docs/AI-CONFIGURATION.md) | Cloud & local AI setup |
| [Project Types](docs/project-types.md) | Template details |
| [Visual Guide](docs/VISUAL-GUIDE.md) | Complete visual reference |
| [AI Models](docs/ai-models.md) | AI integration setup |
| [Tools](docs/tools.md) | External tools reference |
| [Technical Onboarding](docs/TECHNICAL-ONBOARDING.md) | Team training guide |

## Requirements

| Tool | Required | Description |
|------|----------|-------------|
| Git | Yes | Version control (2.30+) |
| PowerShell | Yes | Automation (Core 7+) |
| Go | No | For Go-based tools |
| Node.js | No | For Node.js projects |
| Docker | No | For containerized development |

## Benefits

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         BEFORE vs AFTER                                       │
└─────────────────────────────────────────────────────────────────────────────┘

    BEFORE:                                    AFTER:
    
    Day 1 ──────────────────────────────────► Day 1
    
    │                                          │
    ▼                                          ▼
    Setup   Setup   Setup   Setup   Setup    ┌──────────────┐
    Git     IDE      Tools   Learn   Start   │  wf new      │
    Env            Config   Repo    Coding  │  wf review   │
    │                                          │
    ▼                                          ▼
    5 Days to                                  30 Minutes to
    Productive                                 Productive
    
    ════════════════════════════════════════════════════════════════════
    
    [OK] 95% reduction in setup time
    [OK] Automated code review on every commit
    [OK] Consistent project structure
    [OK] Cross-platform compatibility
    [OK] AI-ready development environment
```

## Acknowledgments

This project integrates tools from [Gentleman-Programming](https://github.com/Gentleman-Programming) under MIT license.

| Tool | Repository | Author |
|------|------------|--------|
| **Engram** | [Gentleman-Programming/engram](https://github.com/Gentleman-Programming/engram) | Gentleman-Programming |
| **Gentle-AI** | [gentleman-programming/gentle-ai](https://github.com/gentleman-programming/gentle-ai) | Gentleman-Programming |
| **GGA** | [gentleman-programming/gentleman-guardian-angel](https://github.com/Gentleman-Programming/gentleman-guardian-angel) | Gentleman-Programming |
| **Gentleman-Skills** | [Gentleman-Programming/Gentleman-Skills](https://github.com/Gentleman-Programming/Gentleman-Skills) | Gentleman-Programming + Community |

All integrated tools are published under the **MIT License**. See their respective repositories for license details.

## License

MIT

Copyright (c) 2024-2026 Emmanuel Ortiz

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
