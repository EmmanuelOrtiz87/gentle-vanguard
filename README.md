# 🏗️ Foundation - Development Stack

> **💡 Mission Statement:** "Donde la gobernanza, la automatización y la IA convergen para equipos modernos"

Framework de orquestación, automatización y gobernanza para desarrollo profesional, con integración nativa de skills, hooks, revisión adversarial, SDD, y memoria persistente (Engram).

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-7+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Go](https://img.shields.io/badge/Go-1.19+-blue.svg)](https://golang.org/)
[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)

---

## 🏗️ ¿Qué es Foundation?

> 💡 **Visión:** Plataforma integral para equipos modernos que buscan excelencia operativa.

Foundation - Development Stack es un marco operativo para equipos que requieren:

| Característica | Descripción | Beneficio |
|---------------|-------------|-----------|
| **🤖 Orquestación AI** | Coordinación inteligente de flujos y sub-agentes | Eficiencia máxima |
| **✅ Validación 7D** | Hooks automáticos (seguridad, calidad, arquitectura, testing, API, docs, gitflow) | Calidad garantizada |
| **⚖️ Juicio adversarial** | Protocolo de doble revisión paralela ("judgment day") | Seguridad crítica |
| **🧠 Memoria persistente** | Engram para continuidad y decisiones entre sesiones | Continuidad total |
| **📜 SDD y gobernanza** | Enforcement de especificaciones y criterios | Trazabilidad completa |
| **⚡ Activación bajo demanda** | Stack y skills activos sólo cuando se requiere | Optimización de recursos |
| **📦 Plantillas y scaffolding** | Arranque rápido de proyectos y módulos homologados | Tiempo reducido |

---

## 📋 Stack y Normativas Vigentes

> 💡 **Nota:** Foundation es un framework de gobernanza, no una herramienta cerrada.

| Concepto | Descripción | Estado |
|-----------|-------------|--------|
| **Identidad** | Framework de gobernanza, no herramienta cerrada | ✅ Activo |
| **Estrategia** | Orquestación nativa, skills modulares, 7 dimensiones | ✅ Activo |
| **Engram** | Obligatorio para continuidad y memoria | ✅ Obligatorio |
| **SDD** | Especificaciones y criterios obligatorios | ✅ Obligatorio |
| **Juicio adversarial** | Siempre disponible para cambios críticos | ✅ Activo |
| **Backlog** | Unificado, exportable a CSV, auditado | ✅ Activo |

---

## Quick Start

### Requirements

- Windows 10/11, Linux, or macOS
- PowerShell 7+
- Git 2.30+
- Node.js 18+
- Engram (persistent memory)

### Installation

1. Clone:
   ```bash
   git clone https://github.com/EmmanuelOrtiz87/workspace-foundation.git
   cd workspace-foundation
   ```
2. Initialize:
   ```powershell
   .\scripts\foundation\bootstrap-machine.ps1
   ```
3. Start session:
   ```powershell
   .\wf.ps1 start-session
   ```

---

## Architecture

Ver [docs/reference/ARCHITECTURE.md](docs/reference/ARCHITECTURE.md) para el diagrama y dependencias.

**Capas principales:**
- Orquestador AI y sub-agentes (siempre activo bajo demanda)
- Hooks automáticos (pre-commit, pre-push, validación 7D)
- Skills modulares (seguridad, calidad, arquitectura, testing, API, docs, gitflow)
- Protocolo de juicio adversarial (scripts/utilities/judgment-day.ps1)
- SDD y enforcement de especificaciones (docs/specs, skills/sdd-*)
- Engram (memoria, decisiones, continuidad)


## 🎨 Diseño y SDD

> 📖 **SDD Obligatorio:** Para features, cambios de API y arquitectura.

| Recurso | Descripción | Enlace |
|----------|-------------|--------|
| **Documento SDD** | Diseño y arquitectura Foundation | [foundation-sdd.md](docs/sdd/foundation-sdd.md) |
| **SDD Init** | Inicializar contexto SDD | `/sdd-init` |
| **Skill Registry** | Construir registro de skills | `skill-registry` |

✅ **Validación y cierre** solo con criterios y artefactos completos.


## ⚙️ Skills, Hooks y Automatización

- Skills alineados a 7 dimensiones (ver [docs/code-reviews/REVIEW-INDEX.md](docs/code-reviews/REVIEW-INDEX.md))
- Hooks automáticos: scripts/hooks/check-*.ps1 (pre-commit, pre-push)
- Protocolo juicio adversarial: scripts/utilities/judgment-day.ps1, skills/judgment-day/SKILL.md
- Orquestador y sub-agentes: scripts/utilities/wf.ps1 agent <NAME> <TASK>


### CLI principal (`wf.ps1`)
```powershell
# Estado del proyecto
.\scripts\utilities\wf.ps1 status
# Dashboard de operaciones
.\scripts\utilities\wf.ps1 stack-dashboard
# Validación y revisión
.\scripts\utilities\wf.ps1 review
.\scripts\utilities\wf.ps1 audit
# Health check y activación
.\scripts\utilities\wf.ps1 health
# PR y push
.\scripts\utilities\wf.ps1 pr
.\scripts\utilities\wf.ps1 push
# Actualizacin de stack y skills
.\scripts\utilities\wf.ps1 update
```

Dashboard signal coverage:

1. Executive traffic light (GREEN/YELLOW/RED).
2. Token budget burn rate and estimated threshold exhaustion time (ETA).
3. Engram continuity posture.
4. Immediate recommended next actions to avoid session blockage.
5. Strict gate signal in JSON (`strict_violation`) for pipeline automation.
6. Local telemetry is stored at `docs/sessions/metrics/token-guard-usage.csv` (gitignored by design).

Runtime routing model:

1. `ai_orchestrated`: orchestrator delegates to subagents and skills.
2. `hybrid_guarded`: orchestrator keeps selective AI plus deterministic script fallback.
3. `offline_deterministic`: orchestrator delegates to local scripts only (no network/AI dependency).

> For global foundation updates, run `gf update-all` from the foundation install root.

#### Auto-Activation System
- **Pre-commit Hooks**: Automatic validation before commits
- **PowerShell Profile**: Auto-activation when entering projects
- **Health Checks**: Comprehensive tool availability validation
- **Environment Init**: One-command setup for new sessions

###  Project Templates

Foundation provides templates for:

- **Web APIs** (Go + REST)
- **Single Page Applications** (Angular + TypeScript)
- **Microservices** (Docker + Kubernetes)
- **Data Processing** (Python + FastAPI)
- **DevOps Pipelines** (GitHub Actions + Azure)


## 🔄 Ciclo de Trabajo

1. Inicialización: stack, skills y hooks activos sólo cuando se requiere
2. Sesión: orquestador y memoria persistente, revisión y validación automática
3. Cierre: revisión adversarial, artefactos de sesión, cierre y publicación

## 📅 Weekly Audit Runbook

A systematic 5-step process to generate a complete, governance-validated audit of the repository.
All output files use full datetime in their name (`YYYY-MM-DD-HHmmss`) so multiple runs on the same day are always distinguishable.

### Step 1  Generate Context Pack
```powershell
.\scripts\utilities\wf.ps1 context-pack
# Output: docs/sessions/YYYY-MM-DD-HHmmss-context-pack.md
```
Captures the current repository state: branch, recent commits, changed files, and platform health.

### Step 2  Activate Compact Context
```powershell
.\scripts\utilities\wf.ps1 compact-start
# Reads: latest context-pack from docs/sessions/ (by filename timestamp)
# Logs event to: docs/sessions/metrics/context-usage.csv
```
Loads the latest context pack and records the compact-start telemetry event.

Live guidance is enabled by default: when context efficiency health is WARN/YELLOW/RED,
`wf.ps1` commands like `status`, `health`, `start-session`, `review`, `audit`, and `publish`
show a contextual nudge with the recommended `compact-start` command.

Orchestrator auto-action is also enabled by default: if health is RED on `wf.ps1 start-session`,
Foundation runs `compact-start` automatically before creating the session brief. Manual execution
remains available with `wf.ps1 compact-start "<objective>"`.

### Step 3  Generate Audit Document
```powershell
.\scripts\utilities\wf.ps1 audit
# Output: docs/audits/YYYY-MM-DD-HHmmss-audit.md
```
Produces a full audit report with delivery status, operational risk, test suite availability,
git ahead/behind tracking, and annotated next steps.

### Step 4  Governance Validation
```powershell
.\scripts\diagnostics\validate-script-governance.ps1
# Expected: EXIT:0 (all checks passed)

# Optional strict gate (recommended for CI)
.\scripts\utilities\wf.ps1 health -StrictCleanup
```
Validates that all scripts reference canonical paths and that no deprecated references remain.
A non-zero exit is a blocking issue  fix before proceeding.

### Step 5  Review Session Metrics
```powershell
.\scripts\utilities\wf.ps1 context-metrics
# Reads: docs/sessions/metrics/context-usage.csv
```
Displays accumulated session metrics: total events, context-pack calls, compact-start calls,
and context efficiency indicators.

### Step 6  Manual Homologation (Optional)
```powershell
# Preview cleanup actions
.\scripts\utilities\wf.ps1 homologate

# Apply cleanup and reference updates
.\scripts\utilities\wf.ps1 homologate apply
```
Use this when strict cleanup reports drift or when you want to normalize the workspace before release.

---

## 📚 Documentation

### For Developers
- **[Session Guide](docs/guides/SESSION-GUIDE.md)**: Daily workflow and commands
- **[Tool Activation](docs/guides/TOOL-ACTIVATION.md)**: Auto-activation system
- **[Testing Strategy](skills/testing-strategy-skill/SKILL.md)**: Quality assurance (see also `testing-strategy-skill`)

### For Project Leads
- **[Architecture Overview](docs/reference/ARCHITECTURE.md)**: System design rationale
- **[Skill Development](skills/SKILL-DEVELOPMENT.md)**: Creating new AI skills (see `skill-creator-skill`)

### For Administrators
- **[Installation Guide](docs/getting-started/installation.md)**: Complete setup instructions
- **[AI Configuration](docs/guides/AI-CONFIGURATION.md)**: AI provider setup
- **[Getting Started](docs/getting-started/README.md)**: All setup guides

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
Each project contains a `.foundation` configuration file:

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

## ✨ Key Features

> 💡 **Highlight:** Foundation combina IA, gobernanza y automatización en una sola plataforma.

### 🤖 Intelligent Coordination
| Feature | Benefit |
|---------|---------|
| **Auto-detection** | Project type, tech stack, requirements |
| **Skill Loading** | Dynamic loading of relevant AI skills |
| **Workflow Guidance** | Step-by-step development guidance |
| **Quality Gates** | Automated validation at every step |

### 🧠 Memory Persistence
| Feature | Benefit |
|---------|---------|
| **Session Continuity** | Context retention across sessions |
| **Decision Tracking** | Architecture and implementation decisions |
| **Knowledge Base** | Accumulated best practices |
| **Collaboration** | Shared context across team members |


## ✅ Validación y QA

> 🚨 **CRITICAL:** Los hooks se ejecutan automáticamente antes de cada commit.

| Mecanismo | Descripción | Estado |
|------------|-------------|--------|
| **Hooks automáticos** | pre-commit, pre-push, 7D | ✅ Activo |
| **Revisión adversarial** | judgment-day protocol | ✅ Activo |
| **Testing y cobertura** | skills/testing-strategy-skill | ✅ Activo |
| **SDD enforcement** | Especificaciones y criterios | ✅ Obligatorio |


---


## 🤝 Contribuciones

Ver [CONTRIBUTING.md](CONTRIBUTING.md) para detalles y flujos de contribución.

### Setup de desarrollo
```bash
git clone https://github.com/EmmanuelOrtiz87/workspace-foundation.git
cd workspace-foundation
.\scripts\utilities\wf.ps1 update
.\scripts\utilities\wf.ps1 review
```

### Crear nuevos skills
```powershell
.\scripts\utilities\create-skill.ps1 -Name "mi-skill" -Type "orchestrator"
```


## 📄 Licencia

MIT  ver [LICENSE](LICENSE)

## 🆘 Soporte y Documentación

- Documentación: [docs/](docs/)
- Issues: [GitHub Issues](https://github.com/EmmanuelOrtiz87/workspace-foundation/issues)
- Discusiones: [GitHub Discussions](https://github.com/EmmanuelOrtiz87/workspace-foundation/discussions)

---

**Listo para operar con gobernanza, automatización y AI real?**

Inicia con `.\scripts\utilities\wf.ps1 health` y consulta la documentación para flujos, skills y normativas vigentes.

```text

                          AUTOMATIC (Pre-commit)                               

                                                                              
    git commit  pre-commit hook  Fast scan (Secrets + Quality)     
                                                                             
                                           
                                                                           
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

                         AUTOMATIC (Pre-commit)                               

                                                                             
    git commit  pre-commit hook  Fast scan (Secrets + Quality)     
                                                                            
                                          
                                                                          
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

## 🎁 Features

> 💡 **Highlights:** Foundation combina lo mejor de IA, gobernanza y automatización.

| Feature | Description | Benefit |
|---------|-------------|---------|
| **🌍 Global Installation** | Single installation per machine | All projects |
| **⚡ Unified CLI** | Single command (`gf`) | Simple operation |
| **🔗 Symlink Strategy** | Skills updated once, available everywhere | Always synced |
| **🔒 Pre-commit Hooks** | Automatic secrets detection | Security first |
| **🎯 25+ Skills** | Curated for Go, Angular, React, Python | Expert patterns |
| **🔧 Multi-Technology** | Node.js, Go, Python, Rust | Flexible stack |
| **💻 Cross-Platform** | Windows, Linux, macOS | Universal |
| **📦 Templates** | service, cli, library, frontend, fullstack | Quick start |
| **🚀 CI/CD** | GitHub Actions, GitLab CI, Azure DevOps | Ready to deploy |
| **🐳 Containers** | Docker and Kubernetes production-ready | Scalable |
| **🧠 AI-Ready** | Engram integration for persistent memory | Continuity |

## 📦 Project Types

> 📋 **Available Templates:** Foundation provides ready-to-use project scaffolding.

| Type | Technologies | Use Case |
|------|-------------|---------|
| **🖥️ Web APIs** | Go + REST, Gin | Backend services |
| **📱 SPA** | Angular + TypeScript | Modern frontends |
| **🐳 Microservices** | Docker + Kubernetes | Scalable systems |
| **📊 Data Processing** | Python + FastAPI | Analytics & ETL |
| **🚀 DevOps Pipelines** | GitHub Actions + Azure | CI/CD automation |

### 📋 Template Structure
```text
PROJECT TYPES AVAILABLE:

  SERVICE    CLI        LIBRARY    FRONTEND
    [SVC]      [CLI]      [LIB]      [FE]
    API        Go         npm pkg    React
    Backend    Rust       PyPI       Vue
    Worker     Node       Go mod     Angular

  FULLSTACK  MICROSERVCS  MOBILE
    [FS]       [MS]        [M]
    Nx Mono    Gateway    React Nat
    FE+BE      Services   Flutter
```

## 🔍 Code Review Dimensions

> 💡 **7 Dimensions:** Cobertura completa de calidad para cada cambio.

| Dimensión | Icon | Descripción | Enfoque |
|-----------|------|-------------|----------|
| **SECURITY** | [S] | Secrets, Vulnerabilities, OWASP | Protección crítica |
| **QUALITY** | [Q] | Code smell, Complexity, Error handling | Mantenibilidad |
| **ARCHITECT.** | [A] | Structure, Patterns, Modularity | Diseño sólido |
| **TESTING** | [T] | Coverage, Patterns, Edge cases | Validación completa |
| **DOCS** | [D] | README, Changelog, Comments | Documentación clara |
| **API DSGN** | [API] | REST, Validation, Versioning | Contratos claros |
| **GIT FLOW** | [G] | Commits, Branches, Hooks | Flujo ordenado |

### 🔍 Quick Reference
```
        SECURITY       QUALITY       ARCHITECT.   
           [S]           [Q]           [A]    
       Secrets       Code smell    Structure 
       Vulnerab.     Complexity    Patterns  

        TESTING         DOCS          API DSGN   
          [T]           [D]           [API]   
       Coverage      README        REST       
       Patterns      Changelog    Validation

                           GIT FLOW   
                              [G]    
                           Commits   
                           Branches  
                           Hooks     
```

## 🤖 Native Runtime and Review

> 💡 **Core:** Foundation provides native orchestration and review through CLI and skills.

### 🤖 Supported AI Agents

| Agent | Integration | Recommended | Why |
|-------|-------------|-------------|-----|
| **OpenCode** | Full (per-phase routing) | ✅ Default | Multi-provider, 140K+ stars |
| Claude Code | Full (sub-agents) | ✅ Yes | Native integration |
| Gemini CLI | Full (experimental) | ❌ No | Testing only |
| Cursor | Full (9 SDD agents) | ✅ Yes | Parallel execution |
| VS Code Copilot | Full (parallel) | ❌ No | IDE only |
| Codex | Solo-agent | ❌ No | Limited scope |
| Windsurf | Solo-agent | ❌ No | Limited scope |
| Antigravity | Solo-agent + Mission Control | ❌ No | Experimental |

### 🚀 Quick Commands

| Command | Description |
|---------|-------------|
| `wf.ps1 status` | Show workflow status |
| `wf.ps1 review` | Run native review |
| `wf.ps1 update-tools` | Update toolchain |

> 💡 **Windows:** Homebrew (`brew`) not required. Use `wf.ps1 update-tools` (Git Bash + Go).

### 📥 Post-Install (in your AI agent)

```bash
/sdd-init              # Initialize SDD context
skill-registry         # Build skills registry
```

## 🛠️ Foundation Skills (Optional) - External Skill Library

**Foundation Skills** is an optional external skill source. Foundation ships with native local skills under `skills/`.

```text

                      FOUNDATION SKILLS ECOSYSTEM                              



    AI Agent  Skill Library  Framework Expertise
                                    Angular Patterns
                                    React Patterns
                                    Testing Patterns
                                    API Patterns
                                    Workflow Patterns
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
| `skill-creator-skill` | Create new AI agent skills | Skill creation |

### Installation

Skills are automatically installed for detected AI agents. To manually install:

```bash
# For Claude Code
cp -r tools/Foundation-Skills/curated/* ~/.claude/skills/

# For OpenCode
cp -r tools/Foundation-Skills/curated/* ~/.config/opencode/skills/

# For Gemini CLI
cp -r tools/Foundation-Skills/curated/* ~/.gemini/skills/

# For Cursor
cp -r tools/Foundation-Skills/curated/* ~/.cursor/skills/
```

### Skill Structure

```text
~/.claude/skills/
 angular/
    core/SKILL.md
 react-19/SKILL.md
 typescript/SKILL.md
 playwright/SKILL.md
 ...
```

Each skill contains:
- **Trigger conditions** - When the AI should load this skill
- **Patterns and rules** - Coding conventions to follow
- **Code examples** - Reference implementations
- **Anti-patterns** - What to avoid

> Foundation Skills are automatically available when creating a new project with `wf new`.

## ⚠️ Severity Levels

| Level | Icon | Description | Action |
|-------|------|-------------|--------|
| **CRITICAL** | [!C] | Security breach, data loss risk | Block deployment |
| **HIGH** | [!H] | Major quality/deployment issue | Fix before merge |
| **MEDIUM** | [!M] | Technical debt, maintainability | Fix soon |
| **LOW** | [!L] | Best practice, polish | Consider fixing |

## 📦 Included Templates

### CI/CD

```text
.github/workflows/ci.yml     GitHub Actions
.gitlab-ci.yml              GitLab CI
azure-pipelines.yml        Azure DevOps
```

### Containers

```text
Dockerfile                  Node.js (multi-stage)
Dockerfile.go              Go (multi-stage)
Dockerfile.python           Python (multi-stage)
k8s/                       Kubernetes manifests
    deployment.yaml
    service.yaml
    ingress.yaml
    hpa.yaml
```

### Editor Configuration

```text
.editorconfig               Universal (all editors)
.vscode/settings.json       VSCode
.vscode/extensions.json     Recommended extensions
```

## 📂 Project Structure

```text
workspace-foundation/

 .github/               # GitHub templates
    ISSUE_TEMPLATE/
    PULL_REQUEST_TEMPLATE/
 config/                # Global configurations
    workspace.config.json
 docs/                  # Documentation
    README.md         # This index
    VISUAL-GUIDE.md  # Complete visual reference
    ARCHITECTURE.md  # System design
    installation.md   # Setup guide
    project-types.md # Template details
 scripts/               # Automation scripts
    wf.ps1           # Main CLI
 skills/               # AI Skills
    workspace-foundation/
    code-review-orchestrator/
 templates/             # Project templates
    project-root/     # Base template
    project-types/    # By type (service, cli, library, etc.)
    reviews/         # Native review configuration template
    config/           # ESLint, Prettier, etc.
    editor/           # Editor configs
    testing/          # Test templates
 tools/                 # External tools (auto-installed)
     Foundation-Skills/ # AI agent skills library
```

## Documentation

| Document | Description |
|----------|-------------|
| [Installation Guide](docs/getting-started/installation.md) | Setup instructions |
| [AI Configuration](docs/guides/AI-CONFIGURATION.md) | Cloud & local AI setup |
| [Visual Guide](docs/guides/VISUAL-GUIDE.md) | Complete visual reference |
| [Developer Communication Policy](docs/guides/DEVELOPER-COMMUNICATION-POLICY.md) | Response-mode contract and enforcement |
| [Technical Onboarding](docs/guides/TECHNICAL-ONBOARDING.md) | Team training guide |
| [Getting Started](docs/getting-started/README.md) | All setup guides |

## Requirements

| Tool | Required | Description |
|------|----------|-------------|
| Git | Yes | Version control (2.30+) |
| PowerShell | Yes | Script automation (7+) |
| Node.js | Recommended | JavaScript/TypeScript runtime (18+) |
| Go | Optional | Backend development (1.19+) |
