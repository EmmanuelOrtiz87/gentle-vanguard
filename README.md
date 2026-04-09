# Workspace Foundation

> **Agnostic template for creating standardized development projects.**
> Regardless of seniority, technology, operating system, or IDE.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        WORKSPACE FOUNDATION v2.0                             │
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
│                           └─────────────┘         └──────────────┘         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

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

## The Unified Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AUTOMATIC (Pre-commit)                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│    git commit ──▶ pre-commit hook ──▶ Fast scan (Secrets + Quality)        │
│                                            │                                │
│                           ┌─────────────────┼─────────────────┐               │
│                           │                 │                 │               │
│                      Critical?          Report saved        Allow            │
│                           │                 │                 │               │
│                           ▼                 ▼                 ▼               │
│                       🚫 BLOCK          docs/reviews/     ✓ Proceed         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                           MANUAL (On Demand)                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│    wf review              → Full review (all 7 dimensions)                  │
│    wf review security     → Security only                                  │
│    wf review quality     → Quality only                                    │
│    wf review quick       → Fast scan (~30s)                                │
│    wf review --report    → Generate detailed report                         │
│    wf review --track     → Export issues to CSV                             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

| Feature | Description |
|---------|-------------|
| **Unified CLI** | Single command (`wf`) for all operations |
| **Code Review Orchestrator** | 7-dimensional automated code review |
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
├── docs/                  # Documentation
│   ├── VISUAL-GUIDE.md   # Complete visual reference
│   ├── installation.md
│   └── project-types.md
├── scripts/               # Automation scripts
│   └── wf.ps1            # Main CLI
├── skills/               # AI Skills
│   ├── workspace-foundation/
│   └── code-review-orchestrator/
├── templates/             # Project templates
│   ├── project-root/     # Base template
│   ├── project-types/    # By type
│   ├── config/           # ESLint, Prettier, etc.
│   ├── editor/           # Editor configs
│   └── testing/          # Test templates
└── tools/                 # External tools
```

## Documentation

| Document | Description |
|----------|-------------|
| [Installation Guide](docs/installation.md) | Setup instructions |
| [Project Types](docs/project-types.md) | Template details |
| [Visual Guide](docs/VISUAL-GUIDE.md) | Complete visual reference |
| [AI Models](docs/ai-models.md) | AI integration setup |
| [Tools](docs/tools.md) | External tools reference |

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

## License

MIT
