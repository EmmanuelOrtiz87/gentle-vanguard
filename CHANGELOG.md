# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

#### OpenCode Integration (v2.2.0)
- OpenCode CLI added as recommended AI agent
- Default AI provider set to OpenCode for GGA
- Multi-provider support: Claude, GPT, Gemini, local models
- Desktop app, terminal, and IDE integration available
- 140K+ GitHub stars, 6.5M monthly developers

#### Gentleman-Skills Integration (v2.2.0)
- Automatic Gentleman-Skills repository installation
- 20+ curated skills for AI agents (Angular, React, Next.js, TypeScript, etc.)
- Auto-detection and installation of skills for available AI agent
- Skills for: Frontend, Backend/AI, Testing, Workflow
- Bootstrap integration with auto-install for Claude, OpenCode, Gemini, Cursor

#### Gentle-AI Integration (v2.2.0)
- Automatic Gentle-AI installation on project creation
- AI ecosystem configurator with SDD workflow
- Support for 8 AI agents (Claude Code, OpenCode, Gemini CLI, Cursor, etc.)
- Persistent memory, skills system, and MCP servers
- Teaching persona with security-first permissions

#### GGA Integration (v2.1.0)
- Automatic GGA installation on project creation
- Pre-configured .gga file with project settings
- AGENTS.md template for coding standards
- Pre-commit hook for AI-powered code review
- Support for multiple AI providers (Claude, OpenCode, Gemini, Ollama, GitHub Models)
- Global GGA installation for new projects

#### Code Review Orchestrator (v2.0.0)
- Unified code review system that orchestrates all technical skills
- Multi-dimensional analysis: Security, Quality, Architecture, Testing, Documentation, API Design, Git Workflow
- Pre-commit hook integration for automatic scanning
- Interactive mode with actionable feedback
- Issue tracking and CSV export
- Comprehensive markdown reports

#### CLI Commands
- `wf review` - Full comprehensive code review
- `wf review --scope <type>` - Scope-specific reviews (security, quality, testing, docs, quick)
- `wf review --report` - Generate detailed report
- `wf review --track` - Export issues to CSV

#### Pre-commit Hook
- Automatic code scanning before each commit
- Critical issues block commits
- Fast scan mode for performance
- Reentrant protection to avoid infinite loops

### Changed

#### Skills Consolidation
- All specialized skills (security, testing, docs, etc.) now orchestrated by code-review-orchestrator
- Single skill installation instead of multiple
- Centralized configuration in `configs/review-config.json`

#### Bootstrap Updates
- Projects automatically install code-review-orchestrator skill
- Pre-commit hook automatically configured on project creation

### Deprecated

- `wf security` commands - Use `wf review --scope security` instead

### Removed

- security-expert-skill as standalone (integrated into orchestrator)
- Duplicate security commands from CLI

### Fixed

### Security

- Pre-commit hook blocks commits with exposed secrets
- Pattern-based secret detection (AWS keys, GitHub tokens, API keys, etc.)
- Vulnerability pattern scanning

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
