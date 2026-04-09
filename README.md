# Workspace Foundation

> **Agnostic template for creating standardized development projects.**
> Regardless of seniority, technology, operating system, or IDE.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        WORKSPACE FOUNDATION v2.2                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│    ┌─────────────┐         ┌─────────────┐         ┌─────────────┐         │
│    │   Developer │         │     CLI     │         │  Orchestrator│         │
│    │    Input    │────────▶│   (wf.ps1)  │────────▶│   (Review)   │         │
│    └─────────────┘         └──────┬──────┘         └──────┬──────┘         │
│                                  │                        │                  │
│                           ┌──────▼──────┐         ┌──────▼──────┐         │
│                           │  Bootstrap  │         │ 7 Dimensions │         │
│                           │   Engine    │         │   Scanned    │         │
│                           └──────┬──────┘         └──────────────┘         │
│                                  │                                          │
│         ┌───────────────────────┼───────────────────────┐                  │
│         │                       │                       │                  │
│         ▼                       ▼                       ▼                  │
│  ┌─────────────┐         ┌─────────────┐         ┌─────────────┐         │
│  │ Gentle-AI   │         │ Gentleman-  │         │   Engram    │         │
│  │ Ecosystem   │         │   Skills    │         │   Memory    │         │
│  └─────────────┘         └─────────────┘         └─────────────┘         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

### New Projects

```powershell
# 1. Initialize workspace
.\scripts\wf.ps1 init

# 2. Create a new project (interactive wizard)
.\scripts\wf.ps1 new --interactive

# 3. Or create project with parameters
.\scripts\wf.ps1 new --name my-api --kind service --architecture clean

# 4. Run code review
.\scripts\wf.ps1 review
```

### Existing Projects

Workspace Foundation integrates into existing repositories without modifying your code:

```powershell
# 1. Navigate to your existing project
cd C:\my-existing-project

# 2. Integrate Foundation
.\scripts\init-workspace.ps1

# 3. That's it - Foundation adds capabilities
#    - .audit/ directory
#    - AI tools configured
#    - Code review hooks
#    - Audit system

# See docs/INTEGRATION-EXISTING-PROJECTS.md for full guide
```

**Key point:** Foundation is **additive**. It never overwrites existing files.

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
| **Unified CLI** | Single command (`wf`) for all operations |
| **Code Review Orchestrator** | 7-dimensional automated code review |
| **GGA Integration** | AI-powered code review on every commit |
| **Gentle-AI** | AI ecosystem configurator with SDD workflow |
| **Gentleman-Skills** | 20+ curated skills for AI agents |
| **Pre-commit Security** | Automatic secrets detection before commit |
| **Multi-Technology** | Supports Node.js, Go, Python, Rust, and more |
| **Cross-Platform** | Works on Windows, Linux, and macOS |
| **Templates** | service, cli, library, frontend, fullstack, microservices, mobile |
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
gentle-ai              # Interactive TUI
gentle-ai status       # Show ecosystem status
gentle-ai update       # Update all components
gentle-ai backup       # Backup configuration
```

### Post-Install (in your AI agent)

```bash
/sdd-init              # Initialize SDD context
skill-registry         # Build skills registry
```

> Gentle-AI is automatically installed when creating a new project with `wf new`.

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
    
    ✓ 95% reduction in setup time
    ✓ Automated code review on every commit
    ✓ Consistent project structure
    ✓ Cross-platform compatibility
    ✓ AI-ready development environment
```

## Acknowledgments

This project integrates tools from [Gentleman-Programming](https://github.com/Gentleman-Programming) under MIT license.

| Tool | Repository | Author |
|------|------------|--------|
| **Engram** | [gentleman-programming/engram](https://github.com/gentleman-programming/engram) | Gentleman-Programming |
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
