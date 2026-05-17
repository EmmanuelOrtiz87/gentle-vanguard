---
name: project-scaffolding
description: Use when creating projects, scaffolding code, bootstrapping workspaces, applying templates, running validation scripts, or managing workspace infrastructure. Triggers for: "create project", "new project", "bootstrap", "scaffold", "template", "workspace setup", "initialize project", "gv CLI".
---

# Project Scaffolding

## Purpose

Use this skill to create projects, apply templates, and maintain workspace consistency across any
technology stack.

## When Activated

This skill activates when:

- User asks to create/initialize/bootstrap a new project
- User mentions scaffolding, templates, or workspace setup
- User wants to apply a project template
- User needs to run validation or cleanup scripts
- User asks about project structure or workspace organization

## Core Workflow

### 1. Assess the Request

Ask (or infer) these if not provided:

| Question     | Options                                                   | Purpose                     |
| ------------ | --------------------------------------------------------- | --------------------------- |
| Project name | User input                                                | Unique identifier           |
| Project type | service, cli, library, frontend, fullstack, microservices | Determines template         |
| Technology   | Node.js, Go, Python, Rust, etc.                           | Language-specific templates |
| Architecture | layered, clean, modular, microservices                    | Structure pattern           |
| AI mode      | none, local, cloud                                        | AI integration              |

### 2. Use the CLI

The primary interface is `gentle-vanguard.ps1` (PowerShell) or via `gentle-vanguard` alias (when PATH is configured).

```powershell
# Initialize workspace
gentle-vanguard init

# Create project (interactive wizard)
gentle-vanguard new --interactive

# Create project with options
gentle-vanguard new --name <name> --kind <type> --architecture <pattern>

# Validate workspace
gv validate

# Validate specific project
gv validate --project <name>

# Install tools
gentle-vanguard tools --install

# Clean runtime
gentle-vanguard clean --data --cache
```

### 3. Template Variables

Templates use mustache-style placeholders. Replace before applying:

| Variable           | Description   | Example           |
| ------------------ | ------------- | ----------------- |
| `{{project-name}}` | Project name  | my-api            |
| `{{namespace}}`    | K8s namespace | production        |
| `{{domain}}`       | Domain name   | api.example.com   |
| `{{versión}}`      | versión       | 1.0.0             |
| `{{image}}`        | Docker image  | ghcr.io/user/repo |

### 4. Available Templates

```
templates/
 project-root/           # Base template (all projects)
 project-types/
     service/           # API, backend, worker
     cli/              # Command-line tools
     library/          # Reusable packages
     frontend/         # Web apps (React, Vue, Angular)
     fullstack/        # Frontend + Backend
     microservices/    # Distributed systems
```

### 5. Apply Templates

After creating a project, apply technology-specific templates:

```powershell
# Apply React template
Copy-Item -Path "templates/project-types/frontend/package.json" -Destination "$projectPath/package.json"

# Apply Docker
Copy-Item -Path "templates/project-types/service/Dockerfile" -Destination "$projectPath/Dockerfile"

# Apply CI/CD
Copy-Item -Path "templates/project-types/service/.github/workflows/ci.yml" -Destination "$projectPath/.github/workflows/ci.yml"
```

### 6. Post-Creation Checklist

After scaffolding, always verify:

- [ ] `README.md` updated with project name and description
- [ ] `docs/project-context.md` contains project metadata
- [ ] `.env.example` created (no real secrets)
- [ ] `package.json` or `go.mod` has correct name/versión
- [ ] Git initialized: `git init`
- [ ] Initial commit: `git add . && git commit -m "Initial commit"`
- [ ] Run validation: `scripts/gentle-vanguard/gv.ps1 validate`

## Project Type Selection Guide

| Type            | When to Use                       | Default Stack     |
| --------------- | --------------------------------- | ----------------- |
| `service`       | REST APIs, gRPC, workers, daemons | Node.js/Express   |
| `cli`           | Tools, scripts, utilities         | Go                |
| `library`       | Reusable packages, SDKs           | TypeScript        |
| `frontend`      | Web apps (SPA/SSR)                | React/Vue/Angular |
| `fullstack`     | Frontend + Backend in monorepo    | Nx                |
| `microservices` | Distributed systems               | Multi-service     |

## Architecture Patterns

| Pattern         | Use When                     | Structure                     |
| --------------- | ---------------------------- | ----------------------------- |
| `layered`       | Traditional, simple projects | controller/service/repository |
| `clean`         | Complex business logic       | domain/adapters/ports         |
| `modular`       | Large monoliths to split     | bounded contexts              |
| `microservices` | Distributed teams/systems    | service-per-feature           |

## Validation Commands

Always run validation after project creation:

```powershell
# Workspace validation
.\scripts\gentle-vanguard\gv.ps1 validate

# Project validation
.\scripts\validation\validate-project.ps1 -ProjectPath "projects/my-project"

# Full validation with details
.\scripts\gentle-vanguard\gv.ps1 validate --project my-project --full
```

## Anti-Patterns to Avoid

1. **Don't hardcode values** - Use config files and env vars
2. **Don't skip validation** - Always verify after scaffolding
3. **Don't duplicate tools** - Use workspace tools, not vendored copies
4. **Don't skip .env.example** - Document required environment variables
5. **Don't forget docs** - Update README and project-context.md

## Quick Reference

```powershell
# Complete project creation flow
.\scripts\gentle-vanguard\gv.ps1 new --name my-api --kind service --architecture clean
cd projects\my-api
.\scripts\gentle-vanguard\gv.ps1 validate --project my-api
git add . && git commit -m "Initial commit"
```

## Skill Files

- `scripts/gentle-vanguard/gv.ps1` - Gentle-Vanguard scaffolding CLI
- `config/workspace.config.json` - Workspace configuration
- `templates/project-root/` - Base template
- `templates/project-types/*/` - Type-specific templates
- `skills/documentation-governance/` - Doc standards
- `skills/architecture-governance/` - Architecture standards

