<h1 align="center">🚀 Workspace Foundation</h1>

<p align="center">
  <strong>🤖 AI-first development stack · Zero vendor lock-in · 127 skills</strong><br>
  <em>🔒 Local-first · 🛡️ Privacy-first · ⚡ Production Ready</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-2.9.1-brightgreen?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/Status-Production%20Ready-success?style=flat-square" alt="Status">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License">
  <img src="https://img.shields.io/badge/PowerShell-7+-purple?style=flat-square" alt="PowerShell">
  <img src="https://img.shields.io/badge/Skills-127-teal?style=flat-square" alt="Skills">
  <img src="https://img.shields.io/badge/Tests-33-passing-green?style=flat-square" alt="Tests">
</p>

> **📢 Public release**: [`foundation-public`](https://github.com/EmmanuelOrtiz87/foundation-public) — instalador, documentación pública y demos.

---

## ⚡ Quick Start

```powershell
.\scripts\utilities\session-autostart.cmd   # Iniciar sesión
wf verify                                    # Validar 14 quality gates
wf version                                   # Versión + skill count
wf start-session | wf dashboard | wf judgment-day
```

### Instalación

| Método | Comando | Para quién |
|--------|---------|------------|
| 📥 Instalador | `Foundation-Setup.exe` (desde foundation-public) | Usuarios finales |
| 🛠️ Bootstrap | `.\scripts\foundation\bootstrap.ps1` | Developers |
| 🔄 Multi-PC | `.\scripts\foundation\setup-multi-machine.ps1` | Enterprise |

---

## 🏛️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│  User Task                                              │
│   → wf.ps1 (CLI entry)                                  │
│     → pre-process-input.ps1 (auto-delegation routing)   │
│       → Agent (BA │ DEV │ QA │ OPS │ GOV │ DOC │ SAD)  │
│         → MCP Server (skill activation)                 │
│           → Skill execution (127 specialized skills)    │
│             → Engram (persistent memory)                │
│               ← Result                                  │
└─────────────────────────────────────────────────────────┘
```

| Capa | Rol | Componentes |
|------|-----|-------------|
| 🧭 Agents | Task delegation | 1 orchestrator + 15 sub-agents |
| ⌨️ Commands | CLI entry | `wf.ps1`, `pre-process-input.ps1` |
| 🔌 MCP | Protocol bridge | Model Context Protocol, Engram MCP |
| 🛠️ Skills | Specialized execution | 127 skills (frontend → DevOps → security) |
| 🧠 Memory | Persistent context | Engram (hot/warm/cold, 760+ observations) |

---

## 🤖 Agent Ecosystem

| Agente | Rol | Skill |
|--------|-----|-------|
| 🧭 Orchestrator | Router principal | `project-orchestrator-skill` |
| 🔍 BA | Requirements & analysis | `sdd-lifecycle` |
| 🏗️ DEV | Code generation | `sdd-lifecycle` |
| 🏛️ SAD | System design | `sdd-lifecycle` |
| ✅ QA | Testing & validation | `sdd-lifecycle` |
| 🚀 OPS | Deployment & CI/CD | `docker-devops-skill` |
| 📖 DOC | Technical docs | `documentation-governance` |
| 🛡️ GOV | Compliance & security | `judgment-day` |
| 🔮 PREMORTEM | Risk assessment | `premortem-skill` |
| 💰 FINANCE | Financial modeling | `finance-financial-analyst` |
| ⚖️ LEGAL | Regulatory compliance | `legal-compliance-officer` |
| 📢 MKT | Marketing & SEO | `marketing-content-writer` |
| 💼 SALES | Pipeline management | `sales-account-executive` |
| 👥 HR | Talent acquisition | `hr-talent-acquisition` |

> Auto-delegation vía `config/auto-delegation.json`. Sub-agentes son `hidden: true` — solo el Orchestrator expuesto al usuario.

---

## 🔄 CI/CD (15 workflows)

| Workflow | Propósito | Trigger |
|----------|-----------|---------|
| `foundation-quality-gate.yml` | Quality gates | Every PR |
| `test-suite.yml` | 33 tests | Every PR/push |
| `ps-lint.yml` | PSScriptAnalyzer | Every PR |
| `gitleaks.yml` | Secret scanning | Every PR |
| `codeql-analysis.yml` | CodeQL analysis | Weekly |
| `security-scan.yml` | OWASP scanning | Weekly |
| `sync-public.yml` | Sync → foundation-public | Push to develop |

---

## 📁 Project Structure

```
foundation/
├── config/          # orchestrator.json, auto-delegation.json, model-router.json
├── docs/            # Architecture, guides, reference, assets
├── scripts/         # Utilities, bootstrap, git-hooks, security
├── skills/          # 127 skill definitions (MCP servers)
├── tests/           # 33 tests (unit + integration)
├── .github/         # 15 CI/CD workflows
└── templates/       # Project scaffolding (frontend, backend, mobile, CLI...)
```

> Ver `docs/architecture/` para documentación detallada.

---

## ✅ Validation

| Gate | Resultado |
|------|-----------|
| ⚙️ CONFIG | ✅ 3/3 |
| 🛠️ SKILLS | ✅ 127 validadas |
| 🧪 TESTS | ✅ 33 passing |
| 🔗 HOOKS | ✅ 2/2 |
| 📁 STRUCTURE | ✅ 7/7 |
| **Total** | **✅ 14/14 PASS** |

---

## 📚 Docs clave

| Recurso | Descripción |
|---------|-------------|
| [AGENTS.md](docs/AGENTS.md) | Bootstrap canónico (tool-agnostic) |
| [Getting Started](docs/getting-started/README.md) | Guía de inicio |
| [Architecture](docs/architecture/README.md) | Diseño del sistema |
| [Skill Catalog](docs/reference/SKILL-ORGANIZATION.md) | 127 skills reference |
| [Changelog](CHANGELOG.md) | Versiones |
| [Contributing](CONTRIBUTING.md) | Cómo contribuir |
| [Public release](https://github.com/EmmanuelOrtiz87/foundation-public) | foundation-public |

---

<p align="center">
  <strong>🚀 Foundation v2.9.1</strong><br>
  <em>🔒 Local-First · 🛡️ Privacidad Total · ✅ Production Ready</em><br>
  <sub><a href="https://github.com/EmmanuelOrtiz87/foundation">github.com/EmmanuelOrtiz87/foundation</a></sub>
</p>
