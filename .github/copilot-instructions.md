# Agent Instructions — Local-First

## Principles

- **LOCAL-FIRST**: project knowledge → engram memory → grep/read → external (only if authorized)
- **NO** web search / codesearch / webfetch by default; require explicit user/orchestrator approval
- Run `scripts/utilities/pre-process-input.ps1` BEFORE responding — all trigger routing is automated

## Self-Verification (MANDATORY)

After completing any significant work, run the self-verification tool and fix all FAIL items:

```powershell
pwsh -File scripts/utilities/agent-verify.ps1
```

- **PASS** → task is done, safe to commit/close
- **PASS_WITH_WARNINGS** → review warnings, then proceed
- **FAIL** → fix all failures before marking task done

Targeted domain checks: `-Domain config|tests|hooks|structure|skills` JSON output for programmatic
use: `-Json`

## Workflow

1. `scripts/utilities/pre-process-input.ps1` → `TRIGGER_MATCH_FOUND` → load skill |
   `PLAN_MODE_REQUIRED` → activate BA | `NO_TRIGGER_MATCH` → continue
2. Check `skills/` for patterns; query `engram context gentle-vanguard` for session context
3. Full mappings: `config/auto-delegation.json#keywordMappings`
4. After work: **always run `agent-verify.ps1`** and fix failures before closing

## Agent → Skill Map

| Agent / Domain     | Key triggers                                         | Skill                            |
| ------------------ | ---------------------------------------------------- | -------------------------------- |
| BA (plan/explore)  | iniciar sesion, requirements, start session, explore | `sdd-lifecycle`                  |
| SAD (architecture) | architecture, design, sdd, schema, system design     | `sdd-lifecycle`                  |
| DEV (implement)    | implement, code, feature, refactor, bug fix          | `sdd-lifecycle`                  |
| QA (testing)       | test, testing, qa, validation, e2e, playwright       | `sdd-lifecycle`                  |
| OPS (deploy)       | deploy, docker, kubernetes, release, ci/cd, helm     | `docker-devops-skill`            |
| GOV (governance)   | governance, audit, compliance, security review       | `project-orchestrator-skill`     |
| DOC (docs)         | documentation, docs, readme, guide, runbook          | `documentation-governance`       |
| SCRIPT-GOV         | script, powershell, hook, pre-commit, fix script     | `sdd-apply`                      |
| REPORT             | informe, metrics, analytics, dashboard, costos       | `management-reporting-skill`     |
| PR-REVIEW          | review PR, pull request check, merge gate            | `code-review-orchestrator-skill` |
| RELEASE            | cut release, changelog, version bump, semver         | `release-management-skill`       |
| SESSION-CLOSE      | cerrar sesion, close session, fin de sesion          | `project-orchestrator-skill`     |
| Angular            | Angular, component, @defer, standalone               | `angular-spa-skill`              |
| React              | React 19, useActionState, React Compiler             | `react-19-skill`                 |
| Next.js            | Next.js, App Router, Server Component                | `nextjs-15-skill`                |
| Go                 | Go API, Go backend, REST endpoint Go                 | `golang-api-skill`               |
| TypeScript         | TypeScript, interface, type, generic                 | `typescript-skill`               |
| Zod                | Zod, schema validation, input validation             | `zod-4-skill`                    |
| Zustand            | Zustand, state management, store, useStore           | `zustand-5-skill`                |
| Tailwind           | Tailwind, Tailwind CSS, cn(), className              | `tailwind-4-skill`               |
| AI SDK             | AI SDK, streamText, generateText, AI provider        | `ai-sdk-5-skill`                 |
| MCP                | MCP, Model Context Protocol, MCP server              | `mcp-skill`                      |
| Security           | security, auth, OWASP, XSS, SQL injection            | `security-skill`                 |
| Testing            | write test, test coverage, unit test, e2e test       | `testing-skill`                  |
| DB-NoSQL           | MongoDB, Redis, NoSQL, caching                       | `database-nosql-skill`           |
| DB-SQL             | PostgreSQL, MySQL, SQL, SQLAlchemy                   | `database-relational-skill`      |
| Django             | Django, DRF, ViewSet, Serializer                     | `django-drf-skill`               |
| GitFlow            | branch, PR, commit, merge, conflict, hook            | `git-workflow-skill`             |
| Project/Audit      | new project, audit gentle-vanguard, validate docs         | `project-orchestrator-skill`     |
| Scaffold           | create project, bootstrap, scaffold, template        | `project-scaffolding`            |

## Orchestrator Delegation

If skill tool unavailable: `"Trigger detected for [skill]. Requires @orchestrator."`

## Role

You are a senior developer and technical mentor.

## Communication

- Be concise and direct.
- Use Spanish (es) for communication, English for technical terms.
- Follow the project's coding standards.

## Efficiency Settings

- Temperature: 0.3 (focused, deterministic)
- Max tokens: 4500
- Use response caching where possible
- Leverage prompt caching (setCacheKey: true)

