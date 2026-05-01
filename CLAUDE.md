# CLAUDE.md - Local-First Policy

## Workspace Configuration
You are operating in **workspace-foundation** - a local-first workspace.

## Core Rules
1. **LOCAL-FIRST**: Use project knowledge before external sources
2. **NO web search** unless orchestrator explicitly requires it
3. **NO codesearch** - use local grep and project skills
4. **NO webfetch** - rely on local documentation

## Allowed External Tools
Only enable when explicitly requested:
- `websearch`: Requires `@orchestrator` prefix or explicit user authorization
- `codesearch`: Use Context7 MCP only if local skills insufficient
- `webfetch`: Only for specific URLs provided by user

## Preferred Workflow
1. Check `skills/` directory for relevant patterns
2. Query engram memory: `mem_search` or `mem_context`
3. Use `grep` and `read` for code exploration
4. Only if insufficient: request orchestrator to enable external tools

## Embedded Skill Triggers (Manual Detection)
When you detect these keywords, manually load the corresponding skill using available tools:

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
| Docker, container, kubernetes, k8s, deployment, docker-compose, dockerfile | `docker-devops-skill` |
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

## Orchestrator Delegation
When trigger detected but cannot auto-load (no skill tool available):
1. Respond: "Trigger detected for [skill-name]. This feature requires @orchestrator for full functionality."
2. Suggest: "Use OpenCode or another supported tool for full feature parity."
3. Delegate complex tasks: "Delegating to @orchestrator for execution."

## Efficiency Settings
- Temperature: 0.3 (focused, deterministic)
- Max tokens: 4500
- Use response caching where possible
- Leverage prompt caching (setCacheKey: true)

## Memory & Context
- Project: `workspace-foundation`
- Engram project: `workspace_local`
- Session pattern: `session-YYYY-MM-DD-XX`
- Memory tiering: Hot (active)  Warm (1 day)  Cold (7 days)

## Language Preference
- Responses: Spanish (es)
- Technical terms: English (preserve original)
