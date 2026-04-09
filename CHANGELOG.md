# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [1.0.0] - 2026-04-08

### Added

#### CLI (wf.ps1)
- New unified CLI with 16 commands: `init`, `new`, `validate`, `tools`, `skills`, `clean`, `info`, `doctor`, `list`, `search`, `config`, `update`, `completion`, `deploy`, `migrate`, `test`
- Interactive wizard for project creation
- Auto-completion support for PowerShell and Bash

#### Templates
- **Project Types**: service, cli, library, frontend, fullstack, microservices, mobile
- **Frontend Frameworks**: React + Vite, Vue 3 + Vite, Next.js 14, Angular + Nx
- **Mobile Frameworks**: React Native, Flutter
- **Configuration Templates**: ESLint, Prettier, TypeScript (tsconfig), Vitest, Jest, lint-staged
- **Testing Templates**: Playwright configs with specs for homepage, auth, API, responsive, and accessibility tests

#### CI/CD
- GitHub Actions workflows (CI, container, preview)
- GitLab CI configuration
- Azure DevOps pipelines

#### Container & Orchestration
- Dockerfiles (multi-stage): Node.js, Go, Python
- Kubernetes manifests: Deployment, Service, Ingress, HPA, PDB
- Docker Compose templates for fullstack and microservices

#### Observability
- Prometheus configuration
- Grafana dashboard templates
- Alert rules (error rate, latency, memory, CPU)

#### Git Workflow
- Pre-commit hook (linting, TypeScript, secrets detection)
- Pre-push hook (tests, protected branch checks)
- Commit-msg hook (conventional commits validation)

#### Editor Configuration
- `.editorconfig` (universal)
- VSCode settings (Node.js, Go, Python variants)
- JetBrains codestyle
- Vim/Neovim configuration
- Emacs configuration
- Sublime Text settings

#### Scripts
- `deploy.ps1` - Multi-target deployment (Docker, Kubernetes, AWS, Azure, GCP, Vercel, Fly.io)
- `migrate.ps1` - Database migrations (Prisma, TypeORM, Knex, Go-migrate)
- Makefile template

#### Skills
- `workspace-foundation` - Main skill for project scaffolding
- `testing-skill` - Testing best practices
- `security-skill` - Security checklist and patterns
- `git-workflow-skill` - Git workflow standards
- `api-design-skill` - REST API design
- `docker-devops-skill` - Container and DevOps practices

#### Documentation
- API specifications (OpenAPI 3.0 templates)
- Project type guides
- Installation guide

#### GitHub Templates
- Issue templates (bug, feature, question, documentation)
- Pull request template
- CODEOWNERS
- FUNDING configuration

### Changed
- Improved validation scripts with detailed output
- Enhanced project wizard with framework selection
- Consolidated frontend templates

### Fixed
- Docker multi-stage builds
- Kubernetes manifest syntax

### Security
- Secrets detection in pre-commit hook
- Non-root user in Dockerfiles
- Health checks in containers
