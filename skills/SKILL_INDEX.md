---
name: skill-index
description: >
  Master index of all available skills with triggers and usage guidelines.
  Trigger: "skills", "available skills", "what skill to use", "skill index".
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
- Guides workflow
- Questions suboptimal decisions

**Never wait to be called - always active.**

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
| **Orchestrators** | project-orchestrator, session-workflow, skill-creator |
| **Context & Process** | context-engineering, sdd, bdd-scenarios |
| **Frontend** | angular-spa, react-19, nextjs-15, tailwind-4 |
| **Mobile** | ios-swift-development, ios-swiftui-patterns, android-kotlin, android-architecture, android-jetpack-compose, flutter, react-native, ui-mobile, mobile-app-debugging |
| **State** | zustand-5 |
| **Validation** | zod-4 |
| **Backend** | golang-api, api-design, django-drf |
| **Database** | database-relational, database-nosql |
| **DevOps** | docker-devops, terraform-infrastructure, kubernetes-deployment |
| **Testing** | testing-strategy, testing-skill, playwright, pytest |
| **AI** | ai-sdk-5, mcp-skill |
| **Workflow** | github-pr, jira-task, jira-epic, release-management |
| **Quality** | typescript, code-review, security, technical-debt, web-performance-optimization |
| **Operations** | observability, incident-response-plan |
| **Governance** | project-scaffolding, documentation, architecture, git-workflow, foundation-manager |
| **Script Engineering** | script-governance |

---

## Context & Process

### context-engineering-skill

**Trigger**: `context pack`, `compact start`, `session handoff`, `token efficiency`, `context budget`

**Use when**: Compacting sessions, restoring context, measuring token usage, handoff between sessions or agents

---

### sdd-skill

**Trigger**: `spec`, `spec-driven`, `SDD`, `acceptance criteria`, `docs/specs`, `feature spec`

**Use when**: Writing specs before code, defining acceptance criteria, validating implementation against specs. Governance policy: `docs/reference/SDD-GOVERNANCE-POLICY.md`

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

## Quick Reference

| Category | Skills |
|----------|--------|
| **Orchestrator** | project-orchestrator (load first!), session-workflow, skill-creator |
| **Context & Process** | context-engineering, sdd, bdd-scenarios |
| **Frontend** | angular-spa, react-19, nextjs-15, tailwind-4 |
| **Mobile** | ios-swift-development, ios-swiftui-patterns, android-kotlin, android-architecture, android-jetpack-compose, flutter, react-native, ui-mobile, mobile-app-debugging |
| **State** | zustand-5 |
| **Validation** | zod-4 |
| **Backend** | golang-api, api-design, django-drf |
| **Database** | database-relational, database-nosql |
| **DevOps** | docker-devops, terraform-infrastructure, kubernetes-deployment |
| **Testing** | testing-strategy, testing-skill, playwright, pytest |
| **AI** | ai-sdk-5, mcp-skill |
| **Workflow** | github-pr, jira-task, jira-epic, release-management |
| **Quality** | typescript, code-review, security, technical-debt, web-performance-optimization |
| **Operations** | observability, incident-response-plan |
| **Governance** | foundation-manager, project-scaffolding, architecture, documentation, git-workflow |

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
