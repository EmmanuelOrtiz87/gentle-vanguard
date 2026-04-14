# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.1] - 2026-04-13

### Fixed

#### CI Stability and Governance Reliability
- Fixed shallow-checkout edge cases in `scripts/diagnostics/validate-sdd-governance.ps1` to avoid false failures in GitHub Actions.
- Added resilient fallback logic for changed-file detection when PR history is limited.
- Backported CI stability fixes to `develop` to keep governance behavior consistent across base branches.

#### Script Governance Workflow Noise Reduction
- Updated `.github/workflows/script-governance.yml` with workflow `concurrency` and `cancel-in-progress` to reduce duplicate runs.
- Restricted `pull_request` trigger types to active review events (`opened`, `synchronize`, `reopened`, `ready_for_review`) to reduce mobile notification noise.
- Set full checkout history (`fetch-depth: 0`) for reliable diff-based validations.

### Changed

- Normalized release governance so `main` remains default public branch and `develop` stays integration branch with aligned CI checks.
- Cleaned up historical failed Action runs that were no longer representative of current repository state.

## [1.0.0] - 2026-04-13

**First Stable Release: Foundation Ready for Production**

This marks the first official, stable release of Gentleman Foundation. All preview features are now formalized with governance, versioning, and release strategy.

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

#### Release & Versioning (v1.0.0)

- Formal release strategy document: `docs/guides/RELEASE-STRATEGY.md`
- Release checklist with pre-release validation: `docs/guides/RELEASE-CHECKLIST.md`
- Migration guide: `MIGRATION.md`
- Semantic versioning (SemVer 2.0.0) compliance
- GitHub release automation with release notes

#### Governance Formalization (v1.0.0)

- Spec-Driven Design (SDD) enforcement via CI gates: `.github/workflows/script-governance.yml`
- SDD governance policy: `docs/reference/SDD-GOVERNANCE-POLICY.md`
- SDD validation script: `scripts/diagnostics/validate-sdd-governance.ps1`
- SDD spec template: `docs/specs/SPEC-TEMPLATE.md`
- Mandatory spec validation on protected branch PRs

#### Orchestrator Protocols (v1.0.0)

- **Deferred-Work Registry Protocol**: `skills/project-orchestrator-skill/SKILL.md#DEFERRED-WORK-REGISTRY-PROTOCOL`
  - Structured backlog for deferred features
  - Confirmation rules for ambiguous items
  - Status tracking (pending, scheduled, in-progress, done, discarded)
  - Futures registry at `docs/reference/FUTURE-FEATURES-BACKLOG.md`

- **Global vs Repository Boundary Protocol**: `skills/project-orchestrator-skill/SKILL.md#GLOBAL-VS-REPOSITORY-BOUNDARY-PROTOCOL`
  - Separation of coordination artifacts from implementation artifacts
  - Explicit replication checks (global ↔ repo)
  - Decision outcomes (global-only, repo-only, both)
  - Workspace reference at `c:/Workspace_local/docs/reference/WORKSPACE-FUTURE-FEATURES-BACKLOG.md`

- **Skill Distribution Model (On-Demand)**
  - Foundation as single source of truth for skills
  - On-demand activation vs full-catalog preload
  - Foundation-sync manifest for consumers
  - No external dependency chains in core skills

#### Foundation-Dashboard Homologation (v1.0.0)

- Skills synchronized and aligned across both repos
- Orchestrator skill protocols replicated
- Sync manifest and runner restored in Dashboard
- Foundation-sync flow operational in both repos
- Consistent governance boundaries in both deployments

### Changed

- **Orchestrator Skill Enhanced**
  - Updated `skills/project-orchestrator-skill/SKILL.md` with deferred-work and boundary protocols
  - Foundation and Dashboard homologated (identical orchestrator guidance)
  - Skill distribution model clarified

- Improved validation scripts with detailed output
- Enhanced project wizard with framework selection
- Consolidated frontend templates

### Fixed

- Docker multi-stage builds
- Kubernetes manifest syntax
- Pre-push hook output noise reduced (verbose env dumps removed)
- Foundation-Dashboard sync drift resolved
- Orchestrator skill bootstrapping in consumer repos

### Deprecated

- Deprecated: Using custom deferred-work tracking outside `docs/reference/FUTURE-FEATURES-BACKLOG.md`
  - New: Use centralized registry protocol (Foundation) or boundary-aware replication (Dashboard)

---

## Previous Milestones

### v2.2.1 - Pre-Release

### v2.2.0 - Pre-Release

### v2.0.0 - Code Review Orchestrator (Pre-Release)

### v1.0.0 (Old Placeholder) - 2026-04-08

*This entry superseded by v1.0.0 - 2026-04-13 stable release above.*
