---
name: skill-index
description: >
  Master index of all available skills with triggers and usage guidelines. Trigger: "skills",
  "available skills", "what skill to use", "skill index".
---

# SKILL INDEX

## Multi-Agent Specialization Architecture

The orchestrator delegates tasks to specialized sub-agents for token efficiency:

```
ORCHESTRATOR (slim context)
 AGENT-BA   Business Analysis (BDD, requirements)
 AGENT-SAD  Architecture (SDD, API design, DB)
 AGENT-DEV  Development (code, features, refactor)
 AGENT-QA   Quality (testing, validation)
 AGENT-OPS  DevOps (deploy, CI/CD, infra)
 AGENT-GOV  Governance (security, audit, observability)
 AGENT-DOC  Documentation (specs, guides, BDD/SDD)
```

**Quick commands:**

```powershell
.\scripts\utilities\gv.ps1 agent list           # List all agents
.\scripts\utilities\gv.ps1 agent status        # Check agent readiness
.\scripts\utilities\gv.ps1 agent DEV "implement login"  # Delegate to DEV agent
```

See [multi-agent-registry](multi-agent-registry/SKILL.md) for full agent definitions and skill
mapping.

---

## Skill Index

This is the master reference for all available skills.

## Distribution Model

Skill lifecycle is on-demand and Gentle-Vanguard-first:

1. Skills are authored and updated in Gentle-Vanguard under `skills/`.
2. New and updated skills must be native (self-contained) and must not depend on external
   `references/` files for core operation.
3. Gentle-Vanguard changes are published to repository.
4. Consumer repositories update through `gv.ps1 gentle-vanguard-sync apply`.
5. The orchestrator activates skills on-demand based on task context.

## MASTER ORCHESTRATORS

These skills coordinate everything. **ALWAYS ACTIVE** at session start.

### architecture-governance (replaces architecture-skill)

**Trigger**: `architecture`, `structure`, `layers`

**Use when**: Architecture governance, project structure, layer separation, architecture decisions

---

### backup-orchestrator

**Trigger**: `backup`, `restore`, `snapshot`

**Use when**: Backup management, disaster recovery

---

### cross-workspace-sync

**Trigger**: `sync`, `cross-workspace`, `synchronization`

**Use when**: Syncing across multiple workspaces

---

### documentation-governance (replaces documentation-skill)

**Trigger**: `documentation`, `docs`, `readme`

**Use when**: Documentation standards, quality, and governance

---

### gitflow-orchestrator-skill (replaces gitflow-skill)

**Trigger**: `gitflow`, `branch`, `merge`

**Use when**: Git workflow validation, branching strategy, and orchestration

---

### monitoring-aggregator

**Trigger**: `monitoring`, `metrics`, `aggregate`

**Use when**: Aggregating monitoring data

---

### quality-skill

**Trigger**: `quality`, `linter`, `formatter`

**Use when**: Code quality and linting

---

### workflow-orchestrator

**Trigger**: `workflow`, `automation`, `orchestrate`

**Use when**: Workflow automation and orchestration

---

### project-orchestrator-skill

**Status**: ALWAYS ACTIVE - No trigger needed

**This is the MASTER conductor.** It:

- Auto-detects project and stack
- Loads relevant skills
- Delegates to specialized sub-agents
- Questions suboptimal decisións

**Never wait to be called - always active.**

### adaptive-orchestrator

**Trigger**: `adaptive`, `auto-optimization`, `mode`, `performance` **Use when**: Adaptive mode,
on-demand optimization, performance tuning

---

### multi-agent-registry-skill

**Trigger**: `agent`, `sub-agent`, `delegate`, `specialist`

**Use when**: Routing tasks to specialized agents (BA, SAD, DEV, QA, OPS, GOV, DOC)

**See**: [multi-agent-registry](multi-agent-registry/SKILL.md) for 7-agent delegation model.

### session-workflow-skill

**Trigger**: `iniciar sesión`, `guardar sesión`, `continuar`, `estado`

**Handles session mechanics:**

- Memory management (mem_context, mem_save)
- Todo tracking (todowrite)
- Session start/end execution

**Coordinate with project-orchestrator.**

---

### skill-creator-skill

**Trigger**: `create skill`, `new skill`, `add agent instructions`, `document patterns`

**Use when**: Creating new skills, adding AI guidance, documenting patterns

## **See**: [skill-creator-skill](skill-creator-skill/SKILL.md)

### skill-registry

**Trigger**: `update skills`, `skill registry`, `actualizar skills`, `update registry` **Use when**:
Creating or updating the skill registry for the current project

---

### github-pr-skill

## **Trigger**: github, PR, pull request, pr creation`n**Use when**: Creating GitHub pull requests with conventional commits and proper descriptions

### gitflow-orchestrator-skill

## **Trigger**: gitflow, gitflow-orchestrator, ranch creation, git hooks`n**Use when**: GitFlow workflow validation, branch creation, pre-push hooks

### incident-response-skill

**Trigger**: incident, outage, production issue, unbook, mitigation`n**Use when**: Handling
incidents, response coordination, mitigation, and recovery planning

---

### issue-creation

## **Trigger**: issue, create issue, github issue, ug report`n**Use when**: Creating GitHub issues, reporting bugs, requesting features

## Skill Categories

| Category              | Skills                                                                                                                                                                                        |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Orchestrators**     | project-orchestrator, multi-agent-registry, session-workflow, skill-creator-skill                                                                                                             |
| **Context & Process** | context-engineering, sdd, bdd-scenarios, optimizador-prompts                                                                                                                                  |
| **Content & Comms**   | content-output-skill, humanizador-skill, presentaciones-visuales-skill                                                                                                                        |
| **Frontend & Web**    | angular-spa, react-19, nextjs-15, tailwind-4, firecrawl-web, web-artifacts-builder, seo-audit, brand-guide                                                                                    |
| **Mobile**            | ios-swift-development, ios-swiftui-patterns, android-kotlin, android-kotlin-coroutines, android-architecture, android-jetpack-compose, flutter, react-native, ui-mobile, mobile-app-debugging |
| **State**             | zustand-5                                                                                                                                                                                     |
| **Validation**        | zod-4                                                                                                                                                                                         |
| **Backend**           | golang-api, api-design, django-drf                                                                                                                                                            |
| **Database**          | database-relational, database-nosql                                                                                                                                                           |
| **DevOps**            | docker-devops, terraform-infrastructure, kubernetes-deployment                                                                                                                                |
| **Testing**           | testing-strategy, testing-skill, playwright, pytest, go-testing                                                                                                                               |
| **AI**                | ai-sdk-5, mcp-skill, cloud-agent-connector, pretool-format-hook, codegraph-skill                                                                                                              |
| **Business**          | business-telemetry, backlog-management                                                                                                                                                        |
| **Workflow**          | github-pr, jira-task, jira-epic, release-management, skill-factory                                                                                                                            |
| **Quality**           | typescript, code-review, security, technical-debt, web-performance-optimization, judgment-day, verificador-datos                                                                              |
| **Operations**        | observability, incident-response-plan                                                                                                                                                         |
| **Governance**        | project-scaffolding, documentation-governance, architecture-governance, git-workflow, gentle-vanguard-manager                                                                                 |
| **SDD Lifecycle**     | sdd-lifecycle (CONSOLIDATED - 9 phases in 1)                                                                                                                                                  |
| **Reasoning & Frameworks** | cynefin, first-principles, socratic, systems-thinking, ooda-loop, bayesian, debiasing, fermi, second-order, inversion, red-team, five-whys, feedback-loops, model-router, leverage-points, systematic-debugging, subagent-driven-dev, writing-plans, executing-plans |

---

## Context & Process

### script-runtime-engineering-skill

**Trigger**: `bash script`, `shell script`, `powershell script`, `hook`, `script parse error`,
`cross-platform script`

**Use when**: Creating, editing, or validating operational scripts across Bash/PowerShell runtimes
with parser-safe quoting and cross-shell compatibility.

---

### context-engineering-skill

**Trigger**: `context pack`, `compact start`, `session handoff`, `token efficiency`,
`context budget`

**Use when**: Compacting sessions, restoring context, measuring token usage, handoff between
sessions or agents

---

### bdd-scenarios-skill

**Trigger**: `BDD`, `gherkin`, `scenario`, `acceptance criteria`, `Given When Then`

**Use when**: Writing behavior scenarios and turning requirements into testable acceptance criteria

---

### optimizador-prompts-skill

**Trigger**: `mejora este prompt`, `conviértelo en un prompt`, `ordena esta idea`,
`hazme un prompt para`, `optimiza esto para`, `improve this prompt`, `optimize prompt`,
`structure this idea`, `create a prompt for`

**Use when**: Transforming messy ideas, voice notes, or incomplete instructions into clear,
structured prompts for any AI tool (Claude, ChatGPT, Midjourney, n8n, etc.)

---

## Content & Comms

### humanizador-skill

**Trigger**: `humaniza este texto`, `humanize text`, `de-ai text`, `make it sound natural`,
`rewrite this`

**Use when**: Rewriting AI-generated text to sound natural and human by removing generic phrases,
inflated tone, and artificial patterns

---

### presentaciones-visuales-skill

**Trigger**: `crea una presentación`, `convierte esto en slides`, `deck`, `diapositivas`,
`presentación visual`, `create presentation`, `make slides`, `slide deck`, `HTML presentation`

**Use when**: Creating self-contained HTML presentations from any content with professional design
and clear narrative

---

## Frontend

### tailwind-4-skill

**Trigger**: `Tailwind`, `Tailwind CSS`, `cn()`, `className`, `tailwind-4`, `frontend`, `UI`,
`interface` **Use when**: Tailwind styling, component classes, dark mode, production-grade UI

---

### angular-spa-skill

**Trigger**: `Angular`, `Angular component`, `Angular service`, `Angular signal`, `Angular SPA`,
`@defer`, `standalone component` **Use when**: Angular 19+ SPA patterns: signals, zoneless,
standalone components, defer loading

---

### nextjs-15-skill

**Trigger**: `Next.js`, `Next.js 15`, `App Router`, `Server Action`, `next.config` **Use when**:
Next.js 15 App Router patterns: Server Components, Server Actions, data fetching

---

### angular-spa-skill

**Trigger**: `Angular`, `Angular component`, `Angular service`, `Angular signal`, `Angular SPA`,
`@defer`, `standalone component` **Use when**: Angular 19+ SPA patterns: signals, zoneless,
standalone components, defer loading

---

### firecrawl-web-skill

**Trigger**: `web scrape`, `extract data`, `crawl website`, `markdown`, `screenshot`, `web search`,
`firecrawl`

**Use when**: Web scraping, data extraction, competitive analysis

---

### web-artifacts-builder-skill

**Trigger**: `web artifact`, `html component`, `interactive demo`, `prototype`, `single page`,
`runnable code`

**Use when**: Building interactive web artifacts, prototypes, single-page demos

---

### work-unit-commits

**Trigger**: `commit splitting`, `work unit`, `atomic commits`, `chained PR`, `review workload`

**Use when**: Planning commits as reviewable work units with SDD integration

---

### seo-specialist

**Trigger**: `SEO`, `keyword research`, `technical SEO`, `site audit`, `backlinks`, `SERP`

**Use when**: Technical SEO auditing, keyword research, site optimization, rankings

---

### brand-guide-skill

**Trigger**: `brand`, `brand guide`, `brand identity`, `branding`, `voice`, `tone`,
`visual identity`

**Use when**: Brand consistency, visual identity, voice and tone

---

## Mobile

### ios-swift-development

**Trigger**: `iOS`, `Swift`, `SwiftUI`, `UIKit`, `Xcode`, `TestFlight`

**Use when**: Native iOS development, architecture, networking, persistence, release preparation

---

### ios-swiftui-patterns-skill

**Trigger**: `SwiftUI`, `@State`, `@Binding`, `ObservableObject`, `View`

**Use when**: Building declarative iOS UI and managing SwiftUI state correctly

---

### android-kotlin-skill

**Trigger**: `Android`, `Kotlin`, `Jetpack Compose`, `Hilt`, `Room`, `Gradle`

**Use when**: Native Android development with Kotlin and production mobile architecture

---

### android-kotlin-coroutines-skill

**Trigger**: `coroutines`, `async`, `suspend`, `flow`, `channels`, `structured concurrency`

**Use when**: Async programming in Kotlin, background processing, reactive streams

---

### go-testing

**Trigger**: `go test`, `testing`, `testify`, `benchmark`, `coverage`

**Use when**: Writing and running Go tests, test suites, coverage analysis

---

### android-architecture-skill

**Trigger**: `Android architecture`, `MVVM`, `MVI`, `repository`, `ViewModel`

**Use when**: Structuring Android modules and enforcing maintainable Android boundaries

---

### android-jetpack-compose-skill

**Trigger**: `Jetpack Compose`, `Composable`, `remember`, `Modifier`

**Use when**: Building Android UI in Compose and applying modern Android UI patterns

---

### flutter-skill (consolidated, replaces flutter-development)

**Trigger**: `Flutter`, `Dart`, `Riverpod`, `Provider`, `GoRouter`

**Use when**: Cross-platform mobile development in Flutter with Riverpod state management

**Trigger**: `Flutter`, `Riverpod`, `GoRouter`, `Impeller`, `Dart`

**Use when**: Modern Flutter patterns, state management, navigation, and performance-sensitive
mobile work

---

### react-native-skill

**Trigger**: `React Native`, `Expo`, `mobile app`, `native bridge`

**Use when**: Cross-platform React Native applications and mobile delivery workflows

---

### ui-mobile-skill

**Trigger**: `mobile UI`, `mobile UX`, `responsive mobile`, `touch target`

**Use when**: Mobile-specific UX and UI decisións across iOS, Android, Flutter, or React Native

---

### mobile-app-debugging

**Trigger**: `mobile debug`, `device logs`, `simulator`, `emulator`, `crash`

**Use when**: Debugging native or cross-platform mobile applications across iOS and Android

---

## State Management

### zustand-5-skill

**Trigger**: `Zustand`, `state management`, `store`, `useStore`, `persistence`

**Use when**: React state management, global state, persistence

---

## Validation

### zod-4-skill

**Trigger**: `Zod`, `schema validation`, `input validation`, `type safety`

**Use when**: API validation, form validation, type inference, env vars

---

## Backend & API

### golang-api-skill

**Trigger**: `Go API`, `Go backend`, `REST endpoint`, `JSON response`, `SPA backend`

**Use when**: Go REST APIs, JSON responses, middleware, SPA serving

---

### api-design-skill

**Trigger**: `REST API`, `design API`, `pagination`, `filtering`, `versióning`

**Use when**: REST API design, pagination, filtering, OpenAPI

---

### django-drf-skill

**Trigger**: `Django`, `Django REST Framework`, `DRF`, `ViewSet`, `Serializer`

**Use when**: Django REST APIs, ViewSets, serializers, permissions

---

## Databases

### database-relational-skill

**Trigger**: `PostgreSQL`, `MySQL`, `SQL`, `SQLAlchemy`, `migration`, `transaction`

**Use when**: PostgreSQL/MySQL, SQLAlchemy, migrations, transactions

---

### database-nosql-skill

**Trigger**: `MongoDB`, `Redis`, `NoSQL`, `document database`, `caching`

**Use when**: MongoDB, Redis caching, document models, session storage

---

## DevOps & Deployment

### docker-devops-skill

**Trigger**: `Docker`, `Kubernetes`, `CI/CD`, `deployment`, `docker-compose`, `k8s`

**Use when**: Docker, Kubernetes, CI/CD pipelines, deployments

---

### terraform-infrastructure

**Trigger**: `Terraform`, `IaC`, `infrastructure as code`, `tfvars`, `module`

**Use when**: Authoring Terraform modules, infrastructure plans, and deployment configuration

---

### kubernetes-deployment

**Trigger**: `Kubernetes`, `k8s`, `deployment`, `service`, `ingress`, `helm`

**Use when**: Kubernetes manifests, RBAC, workloads, and deployment hardening

---

## Testing

### testing-skill

**Trigger**: `write test`, `add test`, `mock`, `AAA pattern`, `test framework`

**Use when**: Writing tests, mocking, test patterns, test organization

---

### playwright-skill

**Trigger**: `Playwright`, `E2E`, `browser test`, `page object`

**Use when**: End-to-end browser testing and pre-production validation flows

---

### pytest-skill

**Trigger**: `pytest`, `fixture`, `parametrize`, `monkeypatch`

**Use when**: Python unit and integration tests using pytest

---

## AI & SDKs

### ai-sdk-5-skill

**Trigger**: `AI SDK`, `AI SDK 5`, `streamText`, `generateText`, `AI provider`

**Use when**: AI chat, streaming, tool use, multi-provider AI

---

### mcp-skill

**Trigger**: `MCP`, `Model Context Protocol`, `MCP server`, `MCP tool`

**Use when**: MCP servers, AI tools, resource management, prompt templates

---

### cloud-agent-connector-skill

**Trigger**: `cloud agent`, `bedrock`, `difi`, `external model`, `invoke cloud`

**Use when**: Connecting to external AI providers (AWS Bedrock, Difi, Azure, OpenAI, Anthropic,
Gemini, Ollama)

**See**: [cloud-agent-connector-skill](cloud-agent-connector-skill/SKILL.md)

---

### pretool-format-hook-skill

**Trigger**: `auto-format`, `pretool`, `format hook`, `format before save`

### codegraph-skill

**Trigger**: `codegraph`, `code graph`, `symbol search`, `call graph`, `impact analysis`,
`find callers`, `find callees`, `code structure`, `codebase index`, `semantic search`,
`affected tests`

**Use when**: Exploring codebase structure, finding symbols, tracing call chains, impact analysis,
understanding architecture before modifications, finding affected tests for CI

**Key tools**: `codegraph_context` (task context), `codegraph_explore` (exploration),
`codegraph_query` (symbol search), `codegraph_affected` (impact analysis)

**See**: [codegraph-skill](codegraph-skill/SKILL.md)

**Use when**: Running linter/formatter before AI agent accesses files to save tokens

**See**: [pretool-format-hook-skill](pretool-format-hook-skill/SKILL.md)

---

## Business & Operations

### business-telemetry-skill

**Trigger**: `telemetry`, `metrics`, `management report`, `roi analysis`

**Use when**: Capturing and reporting business-relevant telemetry data

**See**: [business-telemetry-skill](business-telemetry-skill/SKILL.md)

---

### backlog-management-skill

**Trigger**: `backlog`, `manage backlog`, `task list`, `prioritize`

**Use when**: Managing project backlog with JSON-based source of truth

**See**: [backlog-management-skill](backlog-management-skill/SKILL.md)

---

## Workflow & Process

### auto-delegation-router

**Trigger**: `auto-delegation`, `delegate`, `route`, `orchestrate`

**Use when**: Task routing, agent delegation, orchestration

**Trigger**: `gitflow`, `gitflow-orchestrator`, `branch creation`, `git hooks`

**Use when**: GitFlow workflow validation, branch creation, pre-push hooks

---

### distributed-tracing-skill

**Trigger**: `tracing`, `telemetry`, `distributed tracing`, `correlation`, `span`

**Use when**: Distributed tracing, OpenTelemetry, session correlation

---

### adaptive-mode-orchestrator

**Trigger**: `adaptive`, `auto-optimization`, `mode`, `performance`

**Use when**: Adaptive mode, on-demand optimization, performance tuning

**Trigger**: `pull request`, `PR`, `commit message`, `conventional commit`

**Use when**: Pull requests, commits, PR descriptions, atomic commits

---

<!-- jira-task-skill and jira-epic-skill: planned but not yet implemented -->

### release-management-skill

**Trigger**: `release`, `changelog`, `versión bump`, `release notes`, `hotfix`

**Use when**: Planning releases, managing semver, updating changelogs, and documenting cutover steps

---

### daily-workflow

**Trigger**: `daily`, `daily workflow`, `start day`, `session start`

**Use when**: Starting a daily coding session, running morning checks, loading session context

**See**: [daily-workflow](daily-workflow/SKILL.md)

---

### skill-factory-skill

**Trigger**: `create skill`, `skill factory`, `new skill`, `generate skill`

**Use when**: Automated skill generation with templates and conventions

**See**: [skill-factory-skill](skill-factory-skill/SKILL.md)

---

## Code Quality

### typescript-skill

**Trigger**: `TypeScript`, `interface`, `type`, `generic`, `utility types`

**Use when**: TypeScript types, generics, utility types, type guards

---

### code-review-orchestrator-skill

**Trigger**: `code review`, `review dimensions`, `quality check`

**Use when**: Code reviews, quality dimensions, review reports

---

### security-skill

**Trigger**: `security`, `vulnerability`, `secrets`, `OWASP`

**Use when**: Security audits, secret detection, vulnerabilities

---

### web-performance-optimization

**Trigger**: `performance`, `LCP`, `CLS`, `TTFB`, `bundle size`, `web vitals`

**Use when**: Frontend performance tuning, asset optimization, caching, and monitoring performance
regressions

---

### technical-debt-skill

**Trigger**: `technical debt`, `refactor`, `code smell`, `anti-pattern`, `cleanup`

**Use when**: Debt assessment, maintainability reviews, remediation planning, and documenting debt
records

---

### verificador-datos-skill

**Trigger**: `verifica este texto`, `fact check`, `comprueba afirmaciones`, `revisa errores`,
`verify claims`, `check for errors`, `validate information`, `verify this text`

**Use when**: Fact-checking texts, detecting errors, exaggerations, and unverifiable claims before
publishing or sending

---

## Operations

### observability-skill

**Trigger**: `observability`, `monitoring`, `metrics`, `logs`, `tracing`, `OpenTelemetry`

**Use when**: Instrumenting systems, designing dashboards, defining alerts, and production triage

---

### incident-response-plan

**Trigger**: `incident`, `outage`, `production issue`, `runbook`, `mitigation`

**Use when**: Handling incidents, response coordination, mitigation, and recovery planning

---

## Governance

### project-scaffolding-skill

**Trigger**: `workspace`, `bootstrap`, `new project`, `initialize`, `scaffold`, `template`

**Use when**: Project setup, scaffolding, templates, workspace configuration

---

### gentle-vanguard-audit-skill

**Trigger**: `audit gentle-vanguard`, `validate`, `sweep`, `check links`, `find duplicates`,
`homologate`, `validation sweep`, `gentle-vanguard audit`, `judgment`, `pre-release audit`

**Use when**: Running comprehensive validation of Gentle-Vanguard, detecting duplicates, broken
links, skill inconsistencies, and documentation issues. Zero agent tokens when using batch mode.

**Unified Workflow** (gentle-vanguard-audit + judgment-day):

```powershell
# Batch validation only (0 tokens)
.\scripts\utilities\gv.ps1 audit sweep --scope quick    # 1s
.\scripts\utilities\gv.ps1 audit sweep --scope full     # 5s

# Batch + Adversarial review (tokens)
.\scripts\utilities\gv.ps1 audit judgment --mode full   # 15min

# Sync to local (standalone)
.\scripts\utilities\gv.ps1 audit sync
```

**Documentation**: See [docs/guides/AUDIT-WORKFLOW.md](../docs/guides/AUDIT-WORKFLOW.md) for full
workflow diagram.

---

### gentle-vanguard-manager-skill

**Trigger**: `update`, `sync`, `check`, `maintenance`, `tools`, `versión`

**Use when**: Update gentle-vanguard, sync skills, check versións, manage tools, maintenance

---

### premortem-skill

**Trigger**: `premortem`, `risk analysis`, `failure mode`, `what could go wrong`, `Klein`,
`prospective hindsight`

**Use when**: Running premortem analysis using Klein + Kahneman methods to identify risks before
starting significant work

**See**: [premortem-skill](premortem-skill/SKILL.md)

---

### architecture-governance-skill

**Trigger**: `architecture`, `design patterns`, `structure`

**Use when**: Architecture decisións, patterns, system design

---

### documentation-governance-skill

**Trigger**: `documentation`, `docs`, `readme`

**Use when**: Documentation standards, README, docs structure

---

### git-workflow-skill

**Trigger**: `git`, `branch`, `merge`, `workflow`

**Use when**: Git workflow, branching strategy, merge conflicts

---

### comment-writer

**Trigger**: `PR feedback`, `comment`, `review`, `collaboration`, `feedback`

**Use when**: Writing warm and direct collaboration comments for PRs, issues, and reviews

---

### commit-hygiene-skill

**Trigger**: `commit`, `message`, `conventional`, `changelog`, `semantic`

**Use when**: Enforcing commit message conventions, generating changelogs (-native)

---

### docs-alignment-skill

**Trigger**: `docs sync`, `documentation alignment`, `readme update`

**Use when**: Keeping documentation in sync with code changes (-native)

---

### shellcheck-standards-skill

**Trigger**: `shellcheck`, `bash`, `shell script`, `lint`

**Use when**: Shell script linting and standards enforcement (-native)

---

### testing-coverage-skill

**Trigger**: `coverage`, `test coverage`, `uncovered`

**Use when**: Analyzing and improving test coverage metrics (-native)

---

### guardian-fallback-skill

**Trigger**: `guardian fallback`, ` blocked`, `agent fallback`

**Use when**: Alternative execution when is blocked or unavailable

---

### script-governance-skill

**Trigger**: `script governance`, `validate script`, `script standards`

**Use when**: Validating script conventions and governance compliance

---

### security-expert-skill

**Trigger**: `security scan`, `vulnerability`, `CVE`, `SAST`, `DAST`

**Use when**: Deep security analysis, penetration testing, compliance audits

---

## Quick Reference

| Category         | Skills                                                                                                                                                                                        |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Orchestrator** | project-orchestrator (load first!), session-workflow, skill-creator                                                                                                                           |
| **Audit**        | gentle-vanguard-audit (validate, sweep, check)                                                                                                                                                |
| **Frontend**     | angular-spa, react-19, nextjs-15, tailwind-4                                                                                                                                                  |
| **Mobile**       | ios-swift-development, ios-swiftui-patterns, android-kotlin, android-kotlin-coroutines, android-architecture, android-jetpack-compose, flutter, react-native, ui-mobile, mobile-app-debugging |
| **State**        | zustand-5                                                                                                                                                                                     |
| **Validation**   | zod-4                                                                                                                                                                                         |
| **Backend**      | golang-api, api-design, django-drf                                                                                                                                                            |
| **Database**     | database-relational, database-nosql                                                                                                                                                           |
| **DevOps**       | docker-devops, terraform-infrastructure, kubernetes-deployment                                                                                                                                |
| **Testing**      | testing-strategy, testing-skill, playwright, pytest, go-testing                                                                                                                               |
| **AI**           | ai-sdk-5, mcp-skill, codegraph-skill                                                                                                                                                          |
| **Workflow**     | github-pr, jira-task, jira-epic, release-management                                                                                                                                           |
| **Quality**      | typescript, code-review, security, technical-debt, web-performance-optimization                                                                                                               |
| **Operations**   | observability, incident-response-plan                                                                                                                                                         |
| **Governance**   | gentle-vanguard-manager, project-scaffolding, architecture-governance, documentation-governance, git-workflow, gentle-vanguard-audit                                                          |
| **Reasoning**    | cynefin, first-principles, socratic, systems-thinking, ooda-loop, bayesian, debiasing, fermi, second-order, inversion, red-team, five-whys, feedback-loops, model-router, leverage-points     |
| **Methodologies**| systematic-debugging, subagent-driven-dev, writing-plans, executing-plans                                                                                                                      |

## Skill Loading

**Important**: Always load `project-orchestrator-skill` first for new projects.

Skills load automatically based on:

1. File patterns in context
2. Keywords in conversation
3. Explicit request

For manual loading:

```
Use the skill tool to load a specific skill
```

## Adding New Skills

Create skills following this structure:

```
skills/
 new-skill/
    SKILL.md    # Required: name, description, triggers
```

See `skill-creator-skill` for creation guidelines.

### parallel-execution-limits

Advanced parallel execution management with dependency graphs, resource pooling, and token budget
circuit breaker.

- **Trigger**: "parallel execution", "ejecucin paralela", "execution limits"
- **Use when**: Complex workflows with >10 tasks, GPU/CPU constraints, token budget protection
- **Key Functions**:
  - Initialize-ParallelExecutor - Initialize all components
  - Plan-ParallelExecution - Create execution plan
  - Invoke-ParallelExecution - Execute tasks in parallel
  - Get-ExecutionStatus - Monitor execution
  - Export-ExecutionReport - Generate reports

**Path**: skills/parallel-execution-limits/ **Documentation**:
skills/parallel-execution-limits/SKILL.md

---

### adaptive-mode-orchestrator

**Trigger**: `adaptive`, `auto-optimization`, `mode`, `performance`

**Use when**: Adaptive mode, on-demand optimization, performance tuning

---

### auto-delegation-router

**Trigger**: `auto-delegation`, `delegate`, `route`, `orchestrate`

**Use when**: Task routing, agent delegation, orchestration

---

### backlog-management-skill

**Trigger**: `backlog`, `manage backlog`, `task list`, `prioritize`

**Use when**: Managing project backlog with JSON-based source of truth

**See**: [backlog-management-skill](backlog-management-skill/SKILL.md)

---

### business-telemetry-skill

**Trigger**: `telemetry`, `metrics`, `management report`, `roi analysis`

**Use when**: Capturing and reporting business-relevant telemetry data

**See**: [business-telemetry-skill](business-telemetry-skill/SKILL.md)

---

### content-output-skill

**Trigger**: `content output`, `format output`, `output template`

**Use when**: Standardizing output formats, templates, and content generation patterns

---

### monitoring-aggregator

**Trigger**: `monitoring`, `metrics`, `aggregate`

**Use when**: Aggregating monitoring data

---

### react-19-skill

**Trigger**: `React`, `React 19`, `useActionState`, `useFormStatus`, `React Compiler`

**Use when**: React 19 patterns with React Compiler: no useMemo/useCallback needed, useActionState,
useFormStatus

---

### reporting-skill

**Trigger**: `reporting`, `generate report`, `metrics report`

**Use when**: Generating structured reports from telemetry and metrics data

---

### sdd-lifecycle

**Trigger**: `sdd`, `spec-driven`, `lifecycle`, `openspec`

**Use when**: Full SDD lifecycle management: explore propose spec design tasks apply verify archive

**See**: [sdd-lifecycle](sdd-lifecycle/SKILL.md)

---

### sync-automation

**Trigger**: `sync`, `automation`, `cross-workspace`

**Use when**: Automating sync between workspaces and repositories

---

### visual-content-skill

**Trigger**: `visual`, `content`, `images`, `media`

**Use when**: Managing visual content, images, and media assets in documentation

---

### semantic-skill-matcher

**Trigger**: `semantic`, `skill match`, `similarity`

**Use when**: Semantic matching of skills based on context and task requirements

---

### backend-engineer

**Trigger**: `backend`, `server-side`, `API development`

**Use when**: Backend development, server-side logic, API implementation

---

### chained-pr

**Trigger**: `chained PR`, `PR chain`, `dependent PR`

**Use when**: Creating chained pull requests with dependencies

---

### cognitive-doc-design

**Trigger**: `cognitive`, `doc design`, `documentation design`

**Use when**: Designing documentation with cognitive load principles

---

### config-risk-analyzer

**Trigger**: `config risk`, `configuration analysis`, `risk assessment`

**Use when**: Analyzing configuration risks and security implications

---

### content-strategist

**Trigger**: `content strategy`, `content planning`, `editorial`

**Use when**: Planning content strategy and editorial guidelines

---

### customer-success-manager

**Trigger**: `customer success`, `CSM`, `customer health`

**Use when**: Managing customer success metrics and health scores

---

### customer-support-lead

**Trigger**: `support`, `customer support`, `ticket management`

**Use when**: Leading customer support operations and ticket management

---

### data-analyst

**Trigger**: `data analysis`, `analytics`, `reporting`

**Use when**: Analyzing data and generating insights

---

### data-scientist

**Trigger**: `data science`, `ML`, `machine learning`, `models`

**Use when**: Building machine learning models and data science workflows

---

### design-md

**Trigger**: `design md`, `markdown design`, `document design`

**Use when**: Designing markdown documents with visual hierarchy

---

### design-ui-designer

**Trigger**: `UI design`, `interface design`, `mockups`

**Use when**: Creating user interface designs and mockups

---

### design-ux-researcher

**Trigger**: `UX research`, `user research`, `usability`

**Use when**: Conducting user experience research and usability studies

---

### devops-sre

**Trigger**: `DevOps`, `SRE`, `site reliability`, `operations`

**Use when**: Site reliability engineering and DevOps operations

---

### finance-financial-analyst

**Trigger**: `finance`, `financial analysis`, `budget`

**Use when**: Financial analysis, budgeting, and forecasting

---

### frontend-engineer

**Trigger**: `frontend`, `UI development`, `client-side`

**Use when**: Frontend development and client-side implementation

---

### game-designer

**Trigger**: `game design`, `game mechanics`, `gameplay`

**Use when**: Designing game mechanics and gameplay systems

---

### hr-talent-acquisition

**Trigger**: `HR`, `talent`, `recruiting`, `hiring`

**Use when**: Talent acquisition and recruiting processes

---

### karpathy-guidelines

**Trigger**: `karpathy`, `AI guidelines`, `LLM best practices`

**Use when**: Following Karpathy's guidelines for AI/LLM development

---

### legal-compliance-officer

**Trigger**: `legal`, `compliance`, `regulatory`

**Use when**: Legal compliance and regulatory requirements

---

### marketing-content-writer

**Trigger**: `marketing`, `content writing`, `copywriting`

**Use when**: Writing marketing content and copywriting

---

### marketing-growth-hacker

**Trigger**: `growth hacking`, `marketing growth`, `acquisition`

**Use when**: Growth hacking and user acquisition strategies

---

### mobile-developer

**Trigger**: `mobile`, `iOS`, `Android`, `mobile app`

**Use when**: Mobile application development

---

### operations-manager

**Trigger**: `operations`, `ops management`, `business ops`

**Use when**: Managing business operations and operational efficiency

---

### product-manager

**Trigger**: `product`, `product management`, `roadmap`

**Use when**: Product management and roadmap planning

---

### project-manager

**Trigger**: `project management`, `PM`, `project planning`

**Use when**: Project management and planning

---

### sales-account-executive

**Trigger**: `sales`, `account executive`, `AE`

**Use when**: Sales and account executive activities

---

### sales-outbound-strategist

**Trigger**: `outbound`, `sales strategy`, `lead generation`

**Use when**: Outbound sales strategy and lead generation

---

### security-pentester

**Trigger**: `pentest`, `penetration testing`, `security audit`

**Use when**: Penetration testing and security audits

---

### seo-specialist

**Trigger**: `SEO`, `search engine`, `organic traffic`

**Use when**: Search engine optimization and organic traffic growth

---

### testing-evidence-qa

**Trigger**: `QA`, `testing evidence`, `quality assurance`

**Use when**: Quality assurance and testing evidence collection

---

## Imported Skills (mercury-agent-skills)

### prompt-engineering-skill

**Trigger**: `prompt engineering`, `prompt design`, `system prompt`, `few-shot`, `chain of thought`

**Use when**: Designing effective prompts, system prompts, few-shot examples, and chain-of-thought reasoning

---

### ai-agent-design-skill

**Trigger**: `agent design`, `agent architecture`, `tool use`, `agent orchestration`

**Use when**: Designing AI agent architecture, tool-use patterns, orchestration, and planning systems

---

### memory-management-skill

**Trigger**: `memory management`, `context window`, `vector database`, `RAG`, `summarization`

**Use when**: Managing agent memory, context windows, vector databases, RAG, and memory consolidation

---

### token-budget-tracking-skill

**Trigger**: `token budget`, `cost optimization`, `token tracking`, `LLM costs`

**Use when**: Tracking token usage, optimizing LLM costs, and managing token budgets

---

### agent-audit-logging-skill

**Trigger**: `audit logging`, `compliance`, `observability`, `agent tracing`

**Use when**: Implementing audit logging, compliance tracking, agent tracing, and forensic analysis

---

### security-audit-skill

**Trigger**: `security audit`, `vulnerability assessment`, `OWASP`, `security review`

**Use when**: Conducting security audits, vulnerability assessments, OWASP reviews, and threat modeling

---

### clean-code-skill

**Trigger**: `clean code`, `code quality`, `refactoring`, `readability`, `maintainability`

**Use when**: Writing clean, maintainable code with best practices for naming, functions, and error handling

---

### adr-skill

**Trigger**: `ADR`, `architecture decision`, `decision record`, `architecture governance`

**Use when**: Creating Architecture Decision Records with standard or lightweight templates

---

### e2e-testing-skill

**Trigger**: `e2e test`, `end-to-end`, `Playwright`, `Cypress`, `visual testing`

**Use when**: Writing end-to-end tests with Playwright or Cypress, visual testing, and CI integration

---

### api-testing-skill

**Trigger**: `API test`, `REST testing`, `GraphQL testing`, `contract testing`

**Use when**: Testing REST APIs, GraphQL endpoints, contract testing, and API monitoring

---

### accessibility-testing-skill

**Trigger**: `accessibility test`, `a11y`, `WCAG`, `axe-core`

**Use when**: Testing web accessibility, WCAG compliance, screen reader testing, and inclusive design

---

### monitoring-observability-skill

**Trigger**: `monitoring`, `observability`, `Prometheus`, `Grafana`, `alerting`

**Use when**: Setting up monitoring, observability dashboards, alerting rules, and SLO tracking

---

### shell-scripting-skill

**Trigger**: `shell script`, `bash`, `scripting`, `automation script`

**Use when**: Writing production-grade shell scripts with error handling, argument parsing, and portability

---

### accessibility-design-skill

**Trigger**: `accessibility`, `WCAG`, `inclusive design`, `ARIA`, `a11y`

**Use when**: Designing accessible interfaces following WCAG guidelines, ARIA patterns, and inclusive design

---

### data-storytelling-skill

**Trigger**: `data storytelling`, `data viz`, `charts`, `dashboard`, `analytics presentation`

**Use when**: Creating data stories, visualizations, chart selections, and presentation narratives

---

## Imported Skills (cc-thinking-skills)

### cynefin-skill

**Trigger**: `cynefin`, `complexity classification`, `problem domain`, `complicated vs complex`

**Use when**: Classifying problems using Cynefin framework: simple, complicated, complex, chaotic, and disorder domains

---

### first-principles-skill

**Trigger**: `first principles`, `fundamental reasoning`, `break down problem`, `physics thinking`

**Use when**: Breaking down problems to fundamental truths using first-principles reasoning and building solutions from the ground up

---

### socratic-skill

**Trigger**: `socratic`, `questioning`, `critical inquiry`, `dialectical`

**Use when**: Applying Socratic method of questioning to examine beliefs, expose contradictions, and reach deeper understanding

---

### systems-thinking-skill

**Trigger**: `systems thinking`, `system dynamics`, `emergent behavior`, `interconnections`

**Use when**: Analyzing systems through interconnections, feedback loops, emergent behavior, and dynamic modeling

---

### ooda-loop-skill

**Trigger**: `ooda`, `observe orient decide act`, `rapid iteration`, `decision cycle`

**Use when**: Applying the OODA loop (Observe-Orient-Decide-Act) for rapid decision-making and iterative adaptation

---

### bayesian-skill

**Trigger**: `bayesian`, `probability`, `belief update`, `prior evidence`, `posterior`

**Use when**: Applying Bayesian reasoning for probabilistic thinking, belief updates, and evidence-based decision-making

---

### debiasing-skill

**Trigger**: `debiasing`, `cognitive bias`, `bias awareness`, `decision bias`

**Use when**: Identifying and mitigating cognitive biases in decisions, analysis, and reasoning processes

---

### fermi-skill

**Trigger**: `fermi`, `estimation`, `order of magnitude`, `back of envelope`, `approximation`

**Use when**: Making quick order-of-magnitude estimates using Fermi estimation techniques and dimensional analysis

---

### second-order-skill

**Trigger**: `second order`, `consequences`, `ripple effects`, `unintended consequences`

**Use when**: Analyzing second-order effects, unintended consequences, and ripple effects of decisions and actions

---

### inversion-skill

**Trigger**: `inversion`, `invert problem`, `reverse thinking`, `avoid failure`

**Use when**: Applying inversion thinking to solve problems by considering how to cause or avoid failure

---

### red-team-skill

**Trigger**: `red team`, `adversarial review`, `attack simulation`, `penetration thinking`

**Use when**: Conducting adversarial reviews, red-team analysis, and stress-testing plans against potential failures

---

### five-whys-skill

**Trigger**: `five whys`, `root cause`, `why analysis`, `cause analysis`

**Use when**: Performing root cause analysis by iteratively asking "why" to trace problems to their fundamental cause

---

### feedback-loops-skill

**Trigger**: `feedback loop`, `reinforcing loop`, `balancing loop`, `system dynamics`

**Use when**: Identifying and analyzing reinforcing and balancing feedback loops in complex systems

---

### model-router-skill

**Trigger**: `model router`, `thinking model`, `which model`, `reasoning framework`

**Use when**: Selecting the appropriate reasoning model or thinking framework for a given problem context

---

### leverage-points-skill

**Trigger**: `leverage point`, `high impact`, `intervention point`, `system change`

**Use when**: Identifying high-leverage intervention points in systems where small changes produce large effects

---

## Imported Skills (superpowers)

### systematic-debugging-skill

**Trigger**: `systematic debugging`, `root cause`, `debug process`, `investigate fix verify defend`

**Use when**: Following a systematic debugging methodology: investigate, fix, verify, and defend the root cause

---

### subagent-driven-dev-skill

**Trigger**: `subagent`, `fresh agent per task`, `two-stage review`, `agent isolation`

**Use when**: Using dedicated sub-agents with fresh context per task and two-stage review for complex development work

---

### writing-plans-skill

**Trigger**: `write plan`, `task breakdown`, `implementation plan`, `plan tasks`

**Use when**: Creating detailed implementation plans with task breakdown, dependencies, and execution order

---

### executing-plans-skill

**Trigger**: `execute plan`, `batch tasks`, `checkpoint`, `plan execution`

**Use when**: Executing pre-written implementation plans with batch processing, checkpoints, and progress tracking

---


## Imported Skills

---

### Academic Research Skills

- **academic-paper-reviewer-skill** — Imported from academic-research-skills. Profile: BA
- **academic-paper-skill** — Imported from academic-research-skills. Profile: BA
- **academic-pipeline-skill** — Imported from academic-research-skills. Profile: BA
- **deep-research-skill** — Imported from academic-research-skills. Profile: BA

---

### Anthropic Official Skills (anthropics/skills)

- **algorithmic-art-skill** — Imported from anthropic-skills. Profile: DEV
- **brand-guidelines-skill** — Imported from anthropic-skills. Profile: DEV
- **canvas-design-skill** — Imported from anthropic-skills. Profile: DEV
- **claude-api-skill** — Imported from anthropic-skills. Profile: DEV
- **doc-coauthoring-skill** — Imported from anthropic-skills. Profile: DEV
- **docx-skill** — Imported from anthropic-skills. Profile: DEV
- **frontend-design-skill** — Imported from anthropic-skills. Profile: DEV
- **internal-comms-skill** — Imported from anthropic-skills. Profile: DEV
- **mcp-builder-skill** — Imported from anthropic-skills. Profile: DEV
- **pdf-skill** — Imported from anthropic-skills. Profile: DEV
- **pptx-skill** — Imported from anthropic-skills. Profile: DEV
- **skill-creator-skill** — Imported from anthropic-skills. Profile: DEV
- **slack-gif-creator-skill** — Imported from anthropic-skills. Profile: DEV
- **theme-factory-skill** — Imported from anthropic-skills. Profile: DEV
- **web-artifacts-builder-skill** — Imported from anthropic-skills. Profile: DEV
- **webapp-testing-skill** — Imported from anthropic-skills. Profile: DEV
- **xlsx-skill** — Imported from anthropic-skills. Profile: DEV

---

### Claude BugHunter — Security/Bug Bounty

- **apk-redteam-pipeline-skill** — Imported from claude-bughunter. Profile: GOV
- **bb-local-toolkit-skill** — Imported from claude-bughunter. Profile: GOV
- **bb-methodology-skill** — Imported from claude-bughunter. Profile: GOV
- **bug-bounty-skill** — Imported from claude-bughunter. Profile: GOV
- **bugcrowd-reporting-skill** — Imported from claude-bughunter. Profile: GOV
- **cloud-iam-deep-skill** — Imported from claude-bughunter. Profile: GOV
- **enterprise-vpn-attack-skill** — Imported from claude-bughunter. Profile: GOV
- **evidence-hygiene-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-api-misconfig-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-aspnet-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-ato-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-auth-bypass-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-business-logic-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-cache-poison-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-cloud-misconfig-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-csrf-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-dispatch-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-file-upload-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-graphql-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-http-smuggling-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-idor-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-llm-ai-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-mfa-bypass-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-misc-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-ntlm-info-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-oauth-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-race-condition-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-rce-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-saml-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-sharepoint-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-sqli-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-ssrf-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-ssti-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-subdomain-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-xss-skill** — Imported from claude-bughunter. Profile: GOV
- **hunt-xxe-skill** — Imported from claude-bughunter. Profile: GOV
- **m365-entra-attack-skill** — Imported from claude-bughunter. Profile: GOV
- **meme-coin-audit-skill** — Imported from claude-bughunter. Profile: GOV
- **mid-engagement-ir-detection-skill** — Imported from claude-bughunter. Profile: GOV
- **offensive-osint-skill** — Imported from claude-bughunter. Profile: GOV
- **okta-attack-skill** — Imported from claude-bughunter. Profile: GOV
- **osint-methodology-skill** — Imported from claude-bughunter. Profile: GOV
- **redteam-mindset-skill** — Imported from claude-bughunter. Profile: GOV
- **redteam-report-template-skill** — Imported from claude-bughunter. Profile: GOV
- **report-writing-skill** — Imported from claude-bughunter. Profile: GOV
- **security-arsenal-skill** — Imported from claude-bughunter. Profile: GOV
- **supply-chain-attack-recon-skill** — Imported from claude-bughunter. Profile: GOV
- **triage-validation-skill** — Imported from claude-bughunter. Profile: GOV
- **vmware-vcenter-attack-skill** — Imported from claude-bughunter. Profile: GOV
- **web2-recon-skill** — Imported from claude-bughunter. Profile: GOV
- **web3-audit-skill** — Imported from claude-bughunter. Profile: GOV

---

### Knowledge Work Plugins (Anthropic)


#### bio-research Department

- **instrument-data-to-allotrope-skill** — Imported from knowledge-work-plugins. Profile: BA
- **nextflow-development-skill** — Imported from knowledge-work-plugins. Profile: BA
- **scientific-problem-selection-skill** — Imported from knowledge-work-plugins. Profile: BA
- **scvi-tools-skill** — Imported from knowledge-work-plugins. Profile: BA
- **single-cell-rna-qc-skill** — Imported from knowledge-work-plugins. Profile: BA

#### cowork-plugin-management Department

- **cowork-plugin-customizer-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **create-cowork-plugin-skill** — Imported from knowledge-work-plugins. Profile: DEV

#### customer-support Department

- **customer-escalation-skill** — Imported from knowledge-work-plugins. Profile: BA
- **customer-research-skill** — Imported from knowledge-work-plugins. Profile: BA
- **draft-response-skill** — Imported from knowledge-work-plugins. Profile: BA
- **kb-article-skill** — Imported from knowledge-work-plugins. Profile: BA
- **ticket-triage-skill** — Imported from knowledge-work-plugins. Profile: BA

#### data Department

- **analyze-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **build-dashboard-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **create-viz-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **data-context-extractor-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **data-visualization-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **explore-data-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **sql-queries-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **statistical-analysis-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **validate-data-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **write-query-skill** — Imported from knowledge-work-plugins. Profile: DEV

#### design Department

- **accessibility-review-skill** — Imported from knowledge-work-plugins. Profile: DOC
- **design-critique-skill** — Imported from knowledge-work-plugins. Profile: DOC
- **design-handoff-skill** — Imported from knowledge-work-plugins. Profile: DOC
- **design-system-skill** — Imported from knowledge-work-plugins. Profile: DOC
- **research-synthesis-skill** — Imported from knowledge-work-plugins. Profile: DOC
- **user-research-skill** — Imported from knowledge-work-plugins. Profile: DOC
- **ux-copy-skill** — Imported from knowledge-work-plugins. Profile: DOC

#### engineering Department

- **architecture-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **code-review-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **debug-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **deploy-checklist-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **documentation-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **incident-response-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **standup-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **system-design-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **technical-debt-skill** — GV-native. Profile: DEV (consolidated from tech-debt-skill)

#### enterprise-search Department

- **digest-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **knowledge-synthesis-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **search-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **search-strategy-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **source-management-skill** — Imported from knowledge-work-plugins. Profile: DEV

#### finance Department

- **audit-support-skill** — Imported from knowledge-work-plugins. Profile: FINANCE
- **close-management-skill** — Imported from knowledge-work-plugins. Profile: FINANCE
- **financial-statements-skill** — Imported from knowledge-work-plugins. Profile: FINANCE
- **journal-entry-prep-skill** — Imported from knowledge-work-plugins. Profile: FINANCE
- **journal-entry-skill** — Imported from knowledge-work-plugins. Profile: FINANCE
- **reconciliation-skill** — Imported from knowledge-work-plugins. Profile: FINANCE
- **sox-testing-skill** — Imported from knowledge-work-plugins. Profile: FINANCE
- **variance-analysis-skill** — Imported from knowledge-work-plugins. Profile: FINANCE

#### human-resources Department

- **comp-analysis-skill** — Imported from knowledge-work-plugins. Profile: HR
- **draft-offer-skill** — Imported from knowledge-work-plugins. Profile: HR
- **interview-prep-skill** — Imported from knowledge-work-plugins. Profile: HR
- **onboarding-skill** — Imported from knowledge-work-plugins. Profile: HR
- **org-planning-skill** — Imported from knowledge-work-plugins. Profile: HR
- **people-report-skill** — Imported from knowledge-work-plugins. Profile: HR
- **performance-review-skill** — Imported from knowledge-work-plugins. Profile: HR
- **policy-lookup-skill** — Imported from knowledge-work-plugins. Profile: HR
- **recruiting-pipeline-skill** — Imported from knowledge-work-plugins. Profile: HR

#### legal Department

- **brief-skill** — Imported from knowledge-work-plugins. Profile: LEGAL
- **compliance-check-skill** — Imported from knowledge-work-plugins. Profile: LEGAL
- **legal-response-skill** — Imported from knowledge-work-plugins. Profile: LEGAL
- **legal-risk-assessment-skill** — Imported from knowledge-work-plugins. Profile: LEGAL
- **meeting-briefing-skill** — Imported from knowledge-work-plugins. Profile: LEGAL
- **signature-request-skill** — Imported from knowledge-work-plugins. Profile: LEGAL
- **triage-nda-skill** — Imported from knowledge-work-plugins. Profile: LEGAL
- **vendor-check-skill** — Imported from knowledge-work-plugins. Profile: LEGAL

#### marketing Department

- **brand-review-skill** — Imported from knowledge-work-plugins. Profile: MKT
- **campaign-plan-skill** — Imported from knowledge-work-plugins. Profile: MKT
- **content-creation-skill** — Imported from knowledge-work-plugins. Profile: MKT
- **draft-content-skill** — Imported from knowledge-work-plugins. Profile: MKT
- **email-sequence-skill** — Imported from knowledge-work-plugins. Profile: MKT
- **performance-report-skill** — Imported from knowledge-work-plugins. Profile: MKT
- **seo-specialist** — GV-native. Profile: MKT (consolidated from seo-audit-skill)

#### operations Department

- **capacity-plan-skill** — Imported from knowledge-work-plugins. Profile: OPS
- **change-request-skill** — Imported from knowledge-work-plugins. Profile: OPS
- **compliance-tracking-skill** — Imported from knowledge-work-plugins. Profile: OPS
- **process-doc-skill** — Imported from knowledge-work-plugins. Profile: OPS
- **process-optimization-skill** — Imported from knowledge-work-plugins. Profile: OPS
- **risk-assessment-skill** — Imported from knowledge-work-plugins. Profile: OPS
- **runbook-skill** — Imported from knowledge-work-plugins. Profile: OPS
- **status-report-skill** — Imported from knowledge-work-plugins. Profile: OPS
- **vendor-review-skill** — Imported from knowledge-work-plugins. Profile: OPS

#### pdf-viewer Department

- **view-pdf-skill** — Imported from knowledge-work-plugins. Profile: DEV

#### product-management Department

- **competitive-brief-skill** — Imported from knowledge-work-plugins. Profile: BA
- **metrics-review-skill** — Imported from knowledge-work-plugins. Profile: BA
- **product-brainstorming-skill** — Imported from knowledge-work-plugins. Profile: BA
- **roadmap-update-skill** — Imported from knowledge-work-plugins. Profile: BA
- **sprint-planning-skill** — Imported from knowledge-work-plugins. Profile: BA
- **stakeholder-update-skill** — Imported from knowledge-work-plugins. Profile: BA
- **synthesize-research-skill** — Imported from knowledge-work-plugins. Profile: BA
- **write-spec-skill** — Imported from knowledge-work-plugins. Profile: BA

#### productivity Department

- **memory-management-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **start-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **task-management-skill** — Imported from knowledge-work-plugins. Profile: DEV
- **update-skill** — Imported from knowledge-work-plugins. Profile: DEV

#### sales Department

- **account-research-skill** — Imported from knowledge-work-plugins. Profile: SALES
- **call-prep-skill** — Imported from knowledge-work-plugins. Profile: SALES
- **call-summary-skill** — Imported from knowledge-work-plugins. Profile: SALES
- **competitive-intelligence-skill** — Imported from knowledge-work-plugins. Profile: SALES
- **create-an-asset-skill** — Imported from knowledge-work-plugins. Profile: SALES
- **daily-briefing-skill** — Imported from knowledge-work-plugins. Profile: SALES
- **draft-outreach-skill** — Imported from knowledge-work-plugins. Profile: SALES
- **forecast-skill** — Imported from knowledge-work-plugins. Profile: SALES
- **pipeline-review-skill** — Imported from knowledge-work-plugins. Profile: SALES

#### small-business Department

- **business-pulse-skill** — Imported from knowledge-work-plugins. Profile: BA
- **call-list-skill** — Imported from knowledge-work-plugins. Profile: BA
- **canva-creator-skill** — Imported from knowledge-work-plugins. Profile: BA
- **cash-flow-snapshot-skill** — Imported from knowledge-work-plugins. Profile: BA
- **close-month-skill** — Imported from knowledge-work-plugins. Profile: BA
- **content-strategy-skill** — Imported from knowledge-work-plugins. Profile: BA
- **contract-review-skill** — Imported from knowledge-work-plugins. Profile: BA
- **crm-cleanup-skill** — Imported from knowledge-work-plugins. Profile: BA
- **crm-maintenance-skill** — Imported from knowledge-work-plugins. Profile: BA
- **customer-pulse-check-skill** — Imported from knowledge-work-plugins. Profile: BA
- **customer-pulse-skill** — Imported from knowledge-work-plugins. Profile: BA
- **friday-brief-skill** — Imported from knowledge-work-plugins. Profile: BA
- **handle-complaint-skill** — Imported from knowledge-work-plugins. Profile: BA
- **invoice-chase-skill** — Imported from knowledge-work-plugins. Profile: BA
- **job-post-builder-skill** — Imported from knowledge-work-plugins. Profile: BA
- **lead-triage-skill** — Imported from knowledge-work-plugins. Profile: BA
- **margin-analyzer-skill** — Imported from knowledge-work-plugins. Profile: BA
- **monday-brief-skill** — Imported from knowledge-work-plugins. Profile: BA
- **month-end-prep-skill** — Imported from knowledge-work-plugins. Profile: BA
- **month-heads-up-skill** — Imported from knowledge-work-plugins. Profile: BA
- **plan-payroll-skill** — Imported from knowledge-work-plugins. Profile: BA
- **price-check-skill** — Imported from knowledge-work-plugins. Profile: BA
- **quarterly-review-skill** — Imported from knowledge-work-plugins. Profile: BA
- **review-contract-skill** — Imported from knowledge-work-plugins. Profile: BA
- **run-campaign-skill** — Imported from knowledge-work-plugins. Profile: BA
- **sales-brief-skill** — Imported from knowledge-work-plugins. Profile: BA
- **smb-onboard-skill** — Imported from knowledge-work-plugins. Profile: BA
- **smb-router-skill** — Imported from knowledge-work-plugins. Profile: BA
- **tax-prep-skill** — Imported from knowledge-work-plugins. Profile: BA
- **tax-season-organizer-skill** — Imported from knowledge-work-plugins. Profile: BA
- **ticket-deflector-skill** — Imported from knowledge-work-plugins. Profile: BA

---

### Taste/Design Quality Skills (taste-skill)

- **brandkit-skill** — Imported from taste-skill. Profile: DOC
- **brutalist-skill** — Imported from taste-skill. Profile: DOC
- **gpt-tasteskill-skill** — Imported from taste-skill. Profile: DOC
- **image-to-code-skill** — Imported from taste-skill. Profile: DOC
- **imagegen-frontend-mobile-skill** — Imported from taste-skill. Profile: DOC
- **imagegen-frontend-web-skill** — Imported from taste-skill. Profile: DOC
- **minimalist-skill** — Imported from taste-skill. Profile: DOC
- **output-skill** — Imported from taste-skill. Profile: DOC
- **redesign-skill** — Imported from taste-skill. Profile: DOC
- **soft-skill** — Imported from taste-skill. Profile: DOC
- **stitch-skill** — Imported from taste-skill. Profile: DOC
- **taste-skill** — Imported from taste-skill. Profile: DOC
- **taste-skill-v1-skill** — Imported from taste-skill. Profile: DOC
