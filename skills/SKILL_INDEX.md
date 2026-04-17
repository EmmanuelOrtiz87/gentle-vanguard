---
name: skill-index
description: >
  Master index of all available skills with triggers and usage guidelines.
  Trigger: "skills", "available skills", "what skill to use", "skill index".
---

# SKILL INDEX

## Multi-Agent Specialization Architecture

The orchestrator delegates tasks to specialized sub-agents for token efficiency:

```
ORCHESTRATOR (slim context)
├── AGENT-BA  → Business Analysis (BDD, requirements)
├── AGENT-SAD → Architecture (SDD, API design, DB)
├── AGENT-DEV → Development (code, features, refactor)
├── AGENT-QA  → Quality (testing, validation)
├── AGENT-OPS → DevOps (deploy, CI/CD, infra)
├── AGENT-GOV → Governance (security, audit, observability)
└── AGENT-DOC → Documentation (specs, guides, BDD/SDD)
```

**Quick commands:**
```powershell
.\scripts\utilities\wf.ps1 agent list           # List all agents
.\scripts\utilities\wf.ps1 agent status        # Check agent readiness
.\scripts\utilities\wf.ps1 agent DEV "implement login"  # Delegate to DEV agent
```

See [multi-agent-registry](multi-agent-registry/SKILL.md) for full agent definitions and skill mapping.

---

## Skill Index

This is the master reference for all available skills.

## Distribution Model

Skill lifecycle is on-demand and Foundation-first:

1. Skills are authored and updated in Foundation under `skills/`.
2. New and updated skills must be native (self-contained) and must not depend on external `references/` files for core operation.
3. Foundation changes are published to repository.
4. Consumer repositories update through `wf.ps1 foundation-sync apply`.
5. The orchestrator activates skills on-demand based on task context.

## MASTER ORCHESTRATORS

These skills coordinate everything. **ALWAYS ACTIVE** at session start.

### project-orchestrator-skill

**Status**: ALWAYS ACTIVE - No trigger needed

**This is the MASTER conductor.** It:
- Auto-detects project and stack
- Loads relevant skills
- Delegates to specialized sub-agents
- Questions suboptimal decisions

**Never wait to be called - always active.**

### multi-agent-registry-skill

**Trigger**: `agent`, `sub-agent`, `delegate`, `specialist`

**Use when**: Routing tasks to specialized agents (BA, SAD, DEV, QA, OPS, GOV, DOC)

**See**: [multi-agent-registry](multi-agent-registry/SKILL.md) for 7-agent delegation model.

### session-workflow-skill

**Trigger**: `iniciar sesion`, `guardar sesion`, `continuar`, `estado`

**Handles session mechanics:**
- Memory management (mem_context, mem_save)
- Todo tracking (todowrite)
- Session start/end execution

**Coordinate with project-orchestrator.**

---

### skill-creator-skill

**Trigger**: `create skill`, `new skill`, `add agent instructions`, `document patterns`

**Use when**: Creating new skills, adding AI guidance, documenting patterns

**See**: [skill-creator-skill](skill-creator-skill/SKILL.md)

---

## Skill Categories

| Category | Skills |
|----------|--------|
| **Orchestrators** | project-orchestrator, multi-agent-registry, session-workflow, skill-creator-skill |
| **Context & Process** | context-engineering, sdd, bdd-scenarios |
| **Frontend** | angular-spa, react-19, nextjs-15, tailwind-4 |
| **Mobile** | ios-swift-development, ios-swiftui-patterns, android-kotlin, android-kotlin-coroutines, android-architecture, android-jetpack-compose, flutter, react-native, ui-mobile, mobile-app-debugging |
| **State** | zustand-5 |
| **Validation** | zod-4 |
| **Backend** | golang-api, api-design, django-drf |
| **Database** | database-relational, database-nosql |
| **DevOps** | docker-devops, terraform-infrastructure, kubernetes-deployment |
| **Testing** | testing-strategy, testing-skill, playwright, pytest, go-testing |
| **AI** | ai-sdk-5, mcp-skill, cloud-agent-connector, pretool-format-hook |
| **Business** | business-telemetry, backlog-management |
| **Workflow** | github-pr, jira-task, jira-epic, release-management, skill-factory |
| **Quality** | typescript, code-review, security, technical-debt, web-performance-optimization, judgment-day |
| **Code Hygiene** | commit-hygiene, docs-alignment, shellcheck-standards, testing-coverage (GGA-native) |
| **Operations** | observability, incident-response-plan |
| **Guardian** | guardian-fallback (GGA-optional fallback when blocked) |
| **Governance** | project-scaffolding, documentation, architecture, git-workflow, foundation-manager |
| **SDD Lifecycle** | sdd-lifecycle (CONSOLIDATED - 9 phases in 1) |

---

## Context & Process

### script-runtime-engineering-skill

**Trigger**: `bash script`, `shell script`, `powershell script`, `hook`, `script parse error`, `cross-platform script`

**Use when**: Creating, editing, or validating operational scripts across Bash/PowerShell runtimes with parser-safe quoting and cross-shell compatibility.

---

### context-engineering-skill

**Trigger**: `context pack`, `compact start`, `session handoff`, `token efficiency`, `context budget`

**Use when**: Compacting sessions, restoring context, measuring token usage, handoff between sessions or agents

---

### bdd-scenarios-skill

**Trigger**: `BDD`, `gherkin`, `scenario`, `acceptance criteria`, `Given When Then`

**Use when**: Writing behavior scenarios and turning requirements into testable acceptance criteria

---

## Frontend

### angular-spa-skill

**Trigger**: `Angular`, `Angular component`, `signal`, `zoneless`, `@defer`, `standalone`

**Use when**: Angular 19+, standalone components, signals, zoneless, lazy loading

---

### react-19-skill

**Trigger**: `React`, `React 19`, `useActionState`, `useFormStatus`, `React Compiler`

**Use when**: React 19 features, React Compiler, form handling, optimistic updates

---

### nextjs-15-skill

**Trigger**: `Next.js`, `Next.js 15`, `App Router`, `Server Component`, `Server Action`

**Use when**: Next.js applications, App Router, data fetching, API routes

---

### tailwind-4-skill

**Trigger**: `Tailwind`, `Tailwind CSS`, `cn()`, `className`, `tailwind-4`

**Use when**: Tailwind styling, component classes, dark mode, responsive design

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

### flutter-development

**Trigger**: `Flutter`, `Dart`, `Provider`, `Widget`, `pubspec`

**Use when**: Cross-platform mobile development in Flutter

---

### flutter-skill

**Trigger**: `Flutter`, `Riverpod`, `GoRouter`, `Impeller`, `Dart`

**Use when**: Modern Flutter patterns, state management, navigation, and performance-sensitive mobile work

---

### react-native-skill

**Trigger**: `React Native`, `Expo`, `mobile app`, `native bridge`

**Use when**: Cross-platform React Native applications and mobile delivery workflows

---

### ui-mobile-skill

**Trigger**: `mobile UI`, `mobile UX`, `responsive mobile`, `touch target`

**Use when**: Mobile-specific UX and UI decisions across iOS, Android, Flutter, or React Native

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

**Trigger**: `REST API`, `design API`, `pagination`, `filtering`, `versioning`

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

### testing-strategy-skill

**Trigger**: `testing strategy`, `test pyramid`, `what to test`, `coverage target`

**Use when**: Test strategy, coverage targets, test levels

---

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

**Use when**: Connecting to external AI providers (AWS Bedrock, Difi, Azure, OpenAI, Anthropic, Gemini, Ollama)

**See**: [cloud-agent-connector-skill](cloud-agent-connector-skill/SKILL.md)

---

### pretool-format-hook-skill

**Trigger**: `auto-format`, `pretool`, `format hook`, `format before save`

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

### github-pr-skill

**Trigger**: `pull request`, `PR`, `commit message`, `conventional commit`

**Use when**: Pull requests, commits, PR descriptions, atomic commits

---

### jira-task-skill

**Trigger**: `jira`, `task`, `ticket`, `story`

**Use when**: Jira tasks, user stories, estimation

---

### jira-epic-skill

**Trigger**: `epic`, `large feature`, `initiative`

**Use when**: Epics, feature breakdown, planning

---

### release-management-skill

**Trigger**: `release`, `changelog`, `version bump`, `release notes`, `hotfix`

**Use when**: Planning releases, managing semver, updating changelogs, and documenting cutover steps

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

**Use when**: Frontend performance tuning, asset optimization, caching, and monitoring performance regressions

---

### technical-debt-skill

**Trigger**: `technical debt`, `refactor`, `code smell`, `anti-pattern`, `cleanup`

**Use when**: Debt assessment, maintainability reviews, remediation planning, and documenting debt records

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

### foundation-audit-skill

**Trigger**: `audit foundation`, `validate`, `sweep`, `check links`, `find duplicates`, `homologate`, `validation sweep`, `wf audit`, `judgment`, `pre-release audit`

**Use when**: Running comprehensive validation of Foundation, detecting duplicates, broken links, skill inconsistencies, and documentation issues. Zero agent tokens when using batch mode.

**Unified Workflow** (foundation-audit + judgment-day):
```powershell
# Batch validation only (0 tokens)
.\scripts\utilities\wf.ps1 audit sweep --scope quick    # 1s
.\scripts\utilities\wf.ps1 audit sweep --scope full     # 5s

# Batch + Adversarial review (tokens)
.\scripts\utilities\wf.ps1 audit judgment --mode full   # 15min

# Sync to local (standalone)
.\scripts\utilities\wf.ps1 audit sync
```

**Documentation**: See [docs/guides/AUDIT-WORKFLOW.md](../docs/guides/AUDIT-WORKFLOW.md) for full workflow diagram.

---

### foundation-manager-skill

**Trigger**: `update`, `sync`, `check`, `maintenance`, `tools`, `version`

**Use when**: Update foundation, sync skills, check versions, manage tools, maintenance

---

### architecture-governance-skill

**Trigger**: `architecture`, `design patterns`, `structure`

**Use when**: Architecture decisions, patterns, system design

---

### documentation-governance-skill

**Trigger**: `documentation`, `docs`, `readme`

**Use when**: Documentation standards, README, docs structure

---

### git-workflow-skill

**Trigger**: `git`, `branch`, `merge`, `workflow`

**Use when**: Git workflow, branching strategy, merge conflicts

---

### commit-hygiene-skill

**Trigger**: `commit`, `message`, `conventional`, `changelog`, `semantic`

**Use when**: Enforcing commit message conventions, generating changelogs (GGA-native)

---

### docs-alignment-skill

**Trigger**: `docs sync`, `documentation alignment`, `readme update`

**Use when**: Keeping documentation in sync with code changes (GGA-native)

---

### shellcheck-standards-skill

**Trigger**: `shellcheck`, `bash`, `shell script`, `lint`

**Use when**: Shell script linting and standards enforcement (GGA-native)

---

### testing-coverage-skill

**Trigger**: `coverage`, `test coverage`, `uncovered`

**Use when**: Analyzing and improving test coverage metrics (GGA-native)

---

### guardian-fallback-skill

**Trigger**: `guardian fallback`, `GGA blocked`, `agent fallback`

**Use when**: Alternative execution when GGA is blocked or unavailable

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

| Category | Skills |
|----------|--------|
| **Orchestrator** | project-orchestrator (load first!), session-workflow, skill-creator |
| **Audit** | foundation-audit (validate, sweep, check) |
| **Frontend** | angular-spa, react-19, nextjs-15, tailwind-4 |
| **Mobile** | ios-swift-development, ios-swiftui-patterns, android-kotlin, android-kotlin-coroutines, android-architecture, android-jetpack-compose, flutter, react-native, ui-mobile, mobile-app-debugging |
| **State** | zustand-5 |
| **Validation** | zod-4 |
| **Backend** | golang-api, api-design, django-drf |
| **Database** | database-relational, database-nosql |
| **DevOps** | docker-devops, terraform-infrastructure, kubernetes-deployment |
| **Testing** | testing-strategy, testing-skill, playwright, pytest, go-testing |
| **AI** | ai-sdk-5, mcp-skill |
| **Workflow** | github-pr, jira-task, jira-epic, release-management |
| **Quality** | typescript, code-review, security, technical-debt, web-performance-optimization |
| **Operations** | observability, incident-response-plan |
| **Governance** | foundation-manager, project-scaffolding, architecture, documentation, git-workflow, foundation-audit |

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
├── new-skill/
│   └── SKILL.md    # Required: name, description, triggers
```

See `skill-creator-skill` for creation guidelines.
