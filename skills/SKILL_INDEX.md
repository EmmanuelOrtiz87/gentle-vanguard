---
name: skill-index
description: >
  Master index of all available skills with triggers and usage guidelines.
  Trigger: "skills", "available skills", "what skill to use", "skill index".
---

## Skill Index

This is the master reference for all available skills.

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

## Skill Categories

| Category | Skills |
|----------|--------|
| **Orchestrators** | project-orchestrator, session-workflow |
| **Frontend** | angular-spa, react-19, nextjs-15, tailwind-4 |
| **State** | zustand-5 |
| **Validation** | zod-4 |
| **Backend** | golang-api, api-design, django-drf |
| **Database** | database-relational, database-nosql |
| **DevOps** | docker-devops |
| **Testing** | testing-strategy, testing-skill |
| **AI** | ai-sdk-5, mcp-skill |
| **Workflow** | github-pr, jira-task, jira-epic |
| **Quality** | typescript, code-review, security |
| **Governance** | project-scaffolding, documentation, architecture, git-workflow, foundation-manager |

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

## Testing

### testing-strategy-skill

**Trigger**: `testing strategy`, `test pyramid`, `what to test`, `coverage target`

**Use when**: Test strategy, coverage targets, test levels

---

### testing-skill

**Trigger**: `write test`, `add test`, `mock`, `AAA pattern`, `test framework`

**Use when**: Writing tests, mocking, test patterns, test organization

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
| **Orchestrator** | project-orchestrator (load first!) |
| **Frontend** | angular-spa, react-19, nextjs-15, tailwind-4 |
| **State** | zustand-5 |
| **Validation** | zod-4 |
| **Backend** | golang-api, api-design, django-drf |
| **Database** | database-relational, database-nosql |
| **DevOps** | docker-devops |
| **Testing** | testing-strategy, testing-skill |
| **AI** | ai-sdk-5, mcp-skill |
| **Workflow** | github-pr, jira-task, jira-epic |
| **Quality** | typescript, code-review, security |
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
