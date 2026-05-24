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

The primary interface is `gentle-vanguard.ps1` (PowerShell) or via `gentle-vanguard` alias (when
PATH is configured).

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

---

> **Referencia detallada**: [eferences/detail.md](references/detail.md)