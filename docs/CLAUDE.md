# CLAUDE.md - Local-First Policy

> 💡 **Workspace:** You are operating in **workspace-foundation** - a local-first workspace.

## 📋 Core Rules

| Rule | Description |
|------|-------------|
| **🏠 LOCAL-FIRST** | Use project knowledge before external sources |
| **🚫 NO web search** | Unless orchestrator explicitly requires it |
| **📜 NO codesearch** | Use local grep and project skills |
| **🚫 NO webfetch** | Rely on local documentation |

## ✅ Allowed External Tools

Only enable when explicitly requested:

| Tool | Requirement |
|------|-------------|
| `websearch` | Requires `@orchestrator` prefix or explicit user authorization |
| `codesearch` | Use Context7 MCP only if local skills insufficient |
| `webfetch` | Only for specific URLs provided by user |

## 📖 Preferred Workflow

1. Check `skills/` directory for relevant patterns
2. Query engram memory: `mem_search` or `mem_context`
3. Use `grep` and `read` for code exploration
4. Only if insufficient: request orchestrator to enable external tools

## 🤖 Embedded Skill Triggers (Manual Detection)

When you detect these keywords, manually load the corresponding skill using available tools:

### 8️⃣ Governance Layers (from auto-delegation.json)

| Trigger Keywords | Layer | Skill to Load |
|---------------|-------|---------------|
| governance, compliance, metrics, monitoring, observability, incident, security audit, review, audit | **GOV** | `project-orchestrator-skill` |
| architecture, design, sdd, api design, database, schema, technical decision, system design, microservice, integration | **SAD** | `sdd-design` |
| implement, code, develop, feature, refactor, bug fix, component, endpoint, frontend, backend, security, performance | **DEV** | `sdd-apply` |
| test, testing, qa, validation, e2e, unit test, integration test, playwright, pytest, quality, judgment day | **QA** | `sdd-verify` |
| deploy, ci/cd, docker, kubernetes, infrastructure, terraform, helm, release, devops, pipeline | **OPS** | `docker-devops-skill` |
| documentation, docs, readme, guide, runbook, specification, bdd specs, sdd specs | **DOC** | `documentation-governance` |
| script, powershell, parser error, syntax error, validate script, governance script, hook, pre-push, pre-commit, fix script, autofix, script error, correct script | **SCRIPT-GOV** | `sdd-apply` |
| informe, report, reporte, metricas, metrics, analytics, analisis, dashboard, resumen ejecutivo, gerencia, tokens, costos, consumo, sesiones, telemetry, telemetria, estadisticas, stats, resumen de sesion | **REPORT** | `management-reporting-skill` |

### 🎯 Core Skills

| Trigger Keywords | Skill to Load |
|---------------|---------------|
| Angular, Angular component, Angular service, @defer, standalone component | `angular-spa-skill` |
| React, React 19, useActionState, React Compiler | `react-19-skill` |
| Next.js, App Router, Server Component, next.config | `nextjs-15-skill` |
| Go API, Go backend, REST endpoint, Go HTTP handler | `golang-api-skill` |
| TypeScript, interface, type, generic, utility types | `typescript-skill` |
| Zod, schema validation, input validation, type safety | `zod-4-skill` |
| Zustand, state management, store, useStore, persistence | `zustand-5-skill` |
| Tailwind, Tailwind CSS, cn(), className, tailwind-4 | `tailwind-4-skill` |
| AI SDK, AI SDK 5, streamText, generateText, AI provider | `ai-sdk-5-skill` |
| MCP, Model Context Protocol, MCP server, MCP tool, MCP resource | `mcp-skill` |
| Docker, container, kubernetes, k8s, deployment, docker-compose, dockerfile, pod, ingress, helm | `docker-devops-skill` |
| MongoDB, Redis, NoSQL, document database, caching, cache | `database-nosql-skill` |
| PostgreSQL, MySQL, SQL, database, SQLAlchemy, migration, transaction | `database-relational-skill` |
| Django, Django REST Framework, DRF, ViewSet, Serializer, APIView | `django-drf-skill` |
| security, authentication, authorization, vulnerability, CVE, OWASP, XSS, SQL injection, secrets, encryption | `security-skill` |
| test, write test, test coverage, unit test, integration test, e2e test, testing framework, test setup | `testing-skill` |
| testing strategy, test pyramid, what to test, coverage target, unit test, integration test | `testing-strategy-skill` |
| iniciar sesion, session, start session | `session-lifecycle` |
| audit foundation, validate docs, sweep project, check links, find duplicates, fix references, homologate, validation sweep, wf audit | `foundation-audit-skill` |
| new project, assess project, setup project, migrate, refactor decision, organize docs | `project-orchestrator-skill` |
| create project, new project, bootstrap, scaffold, template, workspace setup, initialize project, wf CLI | `project-scaffolding` |
| sdd init, iniciar sdd, openspec init | `sdd-init` |

### 🔄 7 GitFlow Capabilities

| Trigger Keywords | GitFlow Layer | Action |
|---------------|----------------|--------|
| create branch, feature branch, bugfix branch, hotfix branch, release branch | **Branch Management** | `create-gitflow-branch.ps1` |
| pull request, PR, create PR, open PR | **PR Management** | `create-pull-request.ps1` |
| pre-commit, pre-push, git hook, hook validation | **Hooks** | `pre-commit-validation.ps1` |
| post-merge, merge sync, sync after merge | **Merge Sync** | `post-merge-sync.ps1` |
| gitflow, workflow, checkout, branch switching | **Workflow** | `git-workflow-skill` |
| commit, conventional commit, commit message | **Commit** | `git-workflow-skill` |
| conflict, merge conflict, resolve conflict | **Conflict Resolution** | `git-workflow-skill` |

## 🤝 Orchestrator Delegation

When trigger detected but cannot auto-load (no skill tool available):

1. Respond: "Trigger detected for [skill-name]. This feature requires @orchestrator for full functionality."
2. Suggest: "Use OpenCode or another supported tool for full feature parity."
3. Delegate complex tasks: "Delegating to @orchestrator for execution."

## ⚙️ Efficiency Settings

| Setting | Value |
|---------|-------|
| **Temperature** | 0.3 (focused, deterministic) |
| **Max tokens** | 4500 |
| **Response caching** | Enabled where possible |
| **Prompt caching** | setCacheKey: true |

## 🧠 Memory & Context

| Parameter | Value |
|-----------|--------|
| **Project** | `workspace-foundation` |
| **Engram project** | `workspace_local` |
| **Session pattern** | `session-YYYY-MM-DD-XX` |
| **Memory tiering** | Hot (active) → Warm (1 day) → Cold (7 days) |

## 🌐 Language Preference

| Context | Language |
|---------|----------|
| **Responses** | Spanish (es) |
| **Technical terms** | English (preserve original) |

---

## 📋 Documentation Governance Policy

### Mandatory Rules for Markdown Files (Spanish/English)

| Rule | Description |
|------|-------------|
| **🇪 Spanish Accents** | Always use proper accents (automatización, configuración, revisión, activación) |
| **🔧 Code Blocks** | MUST specify language (```powershell, ```bash, ```json) |
| **📄 UTF-8 Encoding** | All markdown files must be UTF-8 (without BOM) |
| **📏 Blank Lines** | Use blank lines before/after headers and code blocks |
| **📝 Scannable Content** | Convert dense text to bullet points |
| **🎨 Emojis** | Use for visual scanning (🚀, ⚙️, 🤖, 💡, 🚨, ✅) |
| **📊 Tables** | Use for structured data |
| **📢 Visual Callouts** | Use blockquotes (> 💡 **TIP:**) |
| **✍ Friendly Writing** | Short paragraphs, bullet points, bold text |

### 🚨 Anti-Ambiguity Rule (CRITICAL)

When editing markdown files:

- **Prefer `write` over `edit`** for large changes (avoids "multiple matches" errors)
- **Use `replaceAll: true`** only when you want to change ALL instances
- **Read entire file first**, then write corrected content

### ✅ Pre-Commit Validation

Before committing markdown changes, verify:

- [ ] All Spanish words have proper accents
- [ ] All code blocks have language specified
- [ ] No broken links (run `wf.ps1 audit`)
- [ ] UTF-8 encoding
- [ ] Proper spacing around headers and code blocks

> 💡 **Reference:** `skills/documentation-governance/SKILL.md` and `references/TOKEN-CONTEXT-STANDARDS.md`
