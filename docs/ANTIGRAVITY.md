# Antigravity - Local-First Policy

## MANDATORY PRE-PROCESSING RULE (ALWAYS ACTIVE)

**BEFORE responding to ANY user input:**

1. **Run trigger detection** - Execute: `powershell -File scripts/utilities/pre-process-input.ps1 -UserInput "USER_INPUT_HERE" -WorkspaceRoot "."`
2. **Parse output**:
   - If `TRIGGER_MATCH_FOUND` → Load indicated skill using `skill` tool BEFORE any other action
   - If `NO_TRIGGER_MATCH` → Continue with normal behavior
3. **Session start** - Always run `scripts/utilities/session-autostart.cmd` on Windows for notifications, optimizations, validations
4. **Special case "iniciar sesion"** - Load `session-workflow-skill`, then follow its workflow

**This rule is MANDATORY and MUST be followed automatically. Do NOT wait to be asked.**

## Principle: LOCAL-FIRST

Prioritize local project knowledge over external searches.

## Tool Restrictions

- **websearch**: DENY - Do not search the web
- **codesearch**: DENY - Use local grep and project skills
- **webfetch**: DENY - Use local documentation

## Allowed by Default

✅ `grep` - Search local files
✅ `read` - Read local files
✅ `glob` - Find local files
✅ `mem_search` - Query engram memory
✅ `mem_context` - Get session context
✅ `bash` - Run local scripts

## When External Tools Are Allowed

Only when:

1. User explicitly requests external research
2. Orchestrator agent requires it for complex tasks
3. Local knowledge is proven insufficient after checking:
   - Project skills (`skills/`)
   - Engram memory (`mem_search`)
   - Project documentation (`docs/`, `README.md`)

## Efficiency Guidelines

- Use cached responses when available
- Leverage prompt caching (setCacheKey: true)
- Batch non-urgent operations
- Prefer local context over external API calls

## Response Style

- Language: Spanish (es) for communication
- Technical terms: Keep in English
- Be concise and direct, <4 lines
- No unnecessary explanations

## 8 Governance Layers (from auto-delegation.json)
When trigger detected, load corresponding skill:
- **GOV**: governance, compliance, metrics, monitoring, observability, incident, security audit, review, audit → `project-orchestrator-skill`
- **SAD**: architecture, design, sdd, api design, database, schema, technical decision, system design, microservice, integration → `sdd-design`
- **DEV**: implement, code, develop, feature, refactor, bug fix, component, endpoint, frontend, backend, security, performance → `sdd-apply`
- **QA**: test, testing, qa, validation, e2e, unit test, integration test, playwright, pytest, quality, judgment day → `sdd-verify`
- **OPS**: deploy, ci/cd, docker, kubernetes, infrastructure, terraform, helm, release, devops, pipeline → `docker-devops-skill`
- **DOC**: documentation, docs, readme, guide, runbook, specification, bdd specs, sdd specs → `documentation-governance`
- **SCRIPT-GOV**: script, powershell, parser error, syntax error, validate script, governance script, hook, pre-push, pre-commit, fix script, auto fix, autofix, script error, correct script → `sdd-apply`
- **REPORT**: informe, report, reporte, metricas, metrics, analytics, analisis, dashboard, resumen ejecutivo, gerencia, tokens, costos, consumo, sesiones, telemetry, telemetria, estadisticas, stats, resumen de sesion → `management-reporting-skill`

## 7 GitFlow Capabilities

| Trigger Keywords | GitFlow Layer | Action |
|------------------|---------------|--------|
| create branch, feature branch, bugfix branch, hotfix branch, release branch | **Branch Management** | `create-gitflow-branch.ps1` |
| pull request, PR, create PR, open PR | **PR Management** | `create-pull-request.ps1` |
| pre-commit, pre-push, git hook, hook validation | **Hooks** | `pre-commit-validation.ps1` |
| post-merge, merge sync, sync after merge | **Merge Sync** | `post-merge-sync.ps1` |
| gitflow, workflow, checkout, branch switching | **Workflow** | `git-workflow-skill` |
| commit, conventional commit, commit message | **Commit** | `git-workflow-skill` |
| conflict, merge conflict, resolve conflict | **Conflict Resolution** | `git-workflow-skill` |

## Configuration Files

See also:

- `opencode.json` - OpenCode configuration
- `AGENTS.md` - Workspace bootstrap rules
- `.clinerules` - Cline-specific rules
- `.cursorrules` - Cursor IDE rules
- `.windsurf/config.json` - Windsurf configuration
