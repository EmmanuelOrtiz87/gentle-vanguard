# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.6.5] - 2026-05-05

### Added

#### Enterprise CI Hardening
- `.github/workflows/ps-lint.yml`: PSScriptAnalyzer static analysis CI — Error severity blocks merge; warnings annotate PRs
- `.github/workflows/release.yml`: Automated GitHub Release creation on semver tag push; validates tag vs VERSION file
- `.github/dependabot.yml`: Weekly GitHub Actions version update automation (minor+patch grouped, max 5 PRs)
- `VERSION`: Single source of truth for current project version (`2.6.5`)
- `SECURITY.md`: Security policy — vulnerability reporting process, supported versions, 48h ack SLA, security controls table

#### Normativas (Rules)
- `rules/POWERSHELL-STANDARDS.md`: Canonical PS1 coding standards — file headers, param declarations, error handling, output safety, path handling, security rules, naming conventions, PSSA configuration
- `rules/CI-HARDENING-STANDARDS.md`: Mandatory CI workflow requirements — permissions, concurrency, timeout defaults, action pinning, secrets handling, audit checklist
- `rules/TESTING-STANDARDS.md`: Testing pyramid, coverage targets, Pester 5 patterns, new-script test rule, quality gates

#### wf CLI Improvements
- `wf version`: New command — shows stack version from VERSION file, orchestrator version, PS version, and skill count

#### Tests
- `tests/unit/v264-scripts.tests.ps1`: Existence + parse + behavior tests for FF-001/002/004/006 scripts

### Fixed
- `.github/workflows/script-governance.yml`: Added missing `permissions: contents: read`, `timeout-minutes: 25`, `concurrency` block
- `.editorconfig` copied to workspace root (was only in `templates/editor/`)

### Changed
- `.gitignore`: Added entries for `reports/dashboard.html`, `reports/metrics-export.csv`, `reports/wf-benchmark.json`, `trivy-report.json`, `.event-bus/`, `.session/`
- `config/quality-gates.json`: Added `ps-lint`, `sdd-gate`, `owasp-scan` to `requiredWorkflows` (v1.1.0)

## [2.6.4] - 2026-05-05

### Added

#### FF-001 — SDD CI Hardening (O-38)
- `scripts/hooks/check-sdd-gate.ps1`: validates that at least one SDD doc with status `validated`, `done`, or `active` exists before committing/pushing to protected branches.
  - Blocking for `main`; advisory for `develop`; skipped on feature/bugfix branches.
  - Integrates with `hook-advisory-classifier.ps1` (Add-BlockingFinding/Add-AdvisoryFinding).
- `.github/workflows/sdd-gate.yml`: CI workflow triggered on PRs to main/develop; runs `check-sdd-gate.ps1` on Windows runner.
- `wf.ps1`: `sdd-gate` command registered in ValidateSet + switch + help.

#### FF-002 — SDD Process Metrics (O-39)
- `scripts/utilities/TELEMETRY-METRICS/sdd-process-metrics.ps1`: computes spec coverage %, avg lead time (days), rework ratio %, and SDD document status breakdown.
  - Reads `docs/backlog/items.json` + `docs/sdd/*.md`.
  - Health signals: GREEN/YELLOW/RED per KPI; `-AsJson` for machine-readable output.
- `wf.ps1`: `sdd-metrics` command registered in ValidateSet + switch + help.

#### FF-004 — Sync Drift Prevention (O-40)
- `scripts/utilities/sync-drift-report.ps1`: compares declared config vs actual filesystem.
  - Checks: skills declared in `auto-delegation.json` vs `skills/` dirs; MCP servers vs local presence; done backlog `resolved_by` script refs vs actual files.
  - Outputs drift score + categorized findings; exits 1 when drift > 0.
  - `-AsJson` for machine-readable output.
- `wf.ps1`: `sync-drift` command registered in ValidateSet + switch + help.

#### FF-006 — Local Workflow Performance (O-41)
- `scripts/utilities/wf-benchmark.ps1`: profiles key `wf` commands with `Measure-Command` and compares against configurable SLO thresholds.
  - Default commands: `status`, `health`. Custom via `-Commands status,health,verify`.
  - PASS/WARN/FAIL per command; report persisted to `reports/wf-benchmark.json`.
  - SLO defaults: status ≤5 s, health ≤15 s, verify ≤30 s (override via `config/testing.config.json#benchmark.slo`).
- `wf.ps1`: `benchmark [cmds]` command registered in ValidateSet + switch + help.

### Changed
- `docs/backlog/items.json`: all 7 backlog items now `done` — FF-001/002/004/006 resolved this release.

## [2.6.3] - 2026-05-05

### Added

#### FF-013 — Runtime Router Gating (O-35)
- `runtime-router.ps1` extended with `-Mode gate -TaskType (ai|heavy-ai|network|local|metrics|any)`:
  - Exit 0=allowed, 1=warned, 2=blocked based on runtime mode + token status + event-bus rate limit.
  - `Get-RateLimitLoad` reads `.event-bus/rate-limit-state.json` dynamically; contributes to gate decision.
  - `Invoke-Gate` function encodes all gating logic: offline blocks network/AI; HARD_LIMIT blocks AI; SOFT_LIMIT warns AI, blocks heavy-AI.
- `wf.ps1`: `runtime-gate [type]` command registered in ValidateSet + switch + help.
- Bug fix: `runtime-router.ps1` was pointing to wrong `token-budget-guard.ps1` path (fixed to `../TELEMETRY-METRICS/`).
- `runtime-router.ps1 status` output now includes `rate_limit_pct` and `rate_limit_near` fields.

#### FF-003 — Check Noise Reduction (O-36)
- `scripts/hooks/hook-advisory-classifier.ps1` — shared module with `Add-BlockingFinding`, `Add-AdvisoryFinding`, `Exit-HookCheck`.
  - `Exit-HookCheck` exits 1 only when blocking findings exist; advisories print warnings but do not block the commit.
- `check-quality.ps1` updated: prettier and golint → advisory; eslint and gofmt → blocking.

#### FF-005 — PR Template Quality (O-37)
- `.github/PULL_REQUEST_TEMPLATE.md` extended with:
  - `SDD / Spec Reference` input field.
  - `Spec Status` dropdown (N/A | draft | validated | done).
  - `Validation Evidence` textarea for agent-verify output, test results, smoke test notes.

### Changed
- `docs/backlog/items.json`: FF-003/FF-005/FF-013 marked `done` with `resolved_by`; FF-001/FF-002/FF-004/FF-006 defer reasons updated (trigger not met).

## [2.6.2] - 2026-05-05

### Added

#### Item 7 — Static HTML Dashboard (O-31)
- `scripts/utilities/TELEMETRY-METRICS/generate-dashboard.ps1` — generates `reports/dashboard.html` from telemetry JSON.
- Self-contained: no CDN dependency; minimal bar chart renderer embedded in HTML.
- Sources: `metrics-config.json`, `.event-bus/history.json`, `.event-bus/rate-limit-state.json`, `token-guard-usage.csv`.
- Registered as `wf dashboard [open]` — optional `open` argument auto-opens browser.

#### Item 8 — MQ Adapter for Event Bus (O-32)
- `scripts/utilities/WORKFLOW-ORCHESTRATION/mq-adapter.ps1` — pluggable MQ backend for team environments.
- Supports three adapters: `file` (default, always available), `redis` (pub/sub via redis-cli), `webhook` (HTTP POST relay).
- Graceful fallback: if redis/webhook unreachable, falls back to file adapter automatically.
- Config: `config/mq-config.json` (adapter, redis host/port/channel, webhook url/secret_env).
- Registered as `wf mq [action]` — actions: `status | publish | consume | test`.

#### Item 9 — Native Linux/macOS Support (O-33)
- `scripts/utilities/platform-compat.ps1` — cross-platform helpers: `Get-Platform`, `Join-NativePath`, `Get-RepoRoot`,
  `Invoke-NativeOpen`, `Get-PwshPath`, `Test-CommandAvailable`, `Get-TempDir`, `ConvertTo-NativePath`, `Get-PlatformInfo`.
- `wf.sh` extended: `run_pwsh` helper, `verify-full`, `dashboard`, `mq`, `export-metrics`, `events` commands added.
  All new commands delegate to PS1 scripts via `pwsh` with graceful error if not installed.
- Registered as `wf platform-info`.

#### Item 10 — Metrics Export to Analytical Store (O-34)
- `scripts/utilities/TELEMETRY-METRICS/export-metrics.ps1` — unified metrics exporter.
- Sources: event history, token-guard CSV, override audit log, runtime state snapshot.
- Formats: `csv` (default), `jsonl`, `sqlite` (requires sqlite3 CLI), `all`.
- Registered as `wf export-metrics [fmt]`.



### Added

#### Agent Execution Context (FF-013 partial)
- `agent-router.ps1` builds a real `execution_context.prompt` loading up to 30 lines per SKILL.md for each resolved skill.
- New functions: `Get-SkillSummary`, `Build-ExecutionContext` — generates ~7.9 K chars / ~2 K tokens per typical DEV task.
- `auto-delegation-wrapper.ps1` now exposes `exec_ctx_chars`, `exec_ctx_tokens`, `skills_in_ctx` in the JSON output.

#### FF-014: Homologation Command
- `homologate-workspace.ps1` extended with Step 6 (broken internal link scanner) and Step 7 (persistent action log).
- Broken-link scanner regex detects relative Markdown links resolving outside their directory; skips anchors and external URLs.
- Action log written to `.logs/homologation/YYYY-MM-DD_HHmmss.log` in YAML-style format after every run.
- Summary table now includes: Mode, Moved/Renamed, Removed, Ref updates, Empty dirs, Broken links (color-coded), Action log path.

#### FF-015: Git Hook Output Safety
- New module `scripts/hooks/hook-output-safety.ps1` with three exported functions:
  - `Write-SafeHook` — drop-in `Write-Host` replacement with automatic pattern-based redaction.
  - `Protect-HookOutput` — pipeline filter for external command output.
  - `Test-HookOutputSafe` — returns bool, safe to use as a guard before printing.
- Sensitive patterns covered: API_KEY, SECRET, AWS_KEY, PRIVATE_KEY, GITHUB_TOKEN, STRIPE_KEY, absolute home and windir paths.
- Integrated via dot-source in `hooks/pre-commit.ps1` and `scripts/hooks/pre-push-normalization.ps1`.

#### Event Bus Governance (Phase 2)
- `event-bus.ps1`: full `Invoke-EventGovernance` pipeline on every emit (schema validation, required fields, payload size, rate limiting).
- Rate limiting via sliding window 60 s with per-event configurable limits.
- `execution_id` normalization across history entries for cross-event telemetry correlation.
- `agent.dispatched` and `agent.completed` emitted per agent in both parallel and sequential dispatch.
- `dispatch.completed` now includes required `status` field.

#### Token Budget Guard Unification (Phase 1)
- Single canonical source: `config/orchestrator.json#subagent_orchestration.token_budget_guard`.
- Canonical estimation rule: `chars / 4 = tokens` applied uniformly in budget-guard, dispatch, and router.
- Legacy `token-guard.ps1` formally deprecated.

#### Context Dashboard (Phase 3)
- New script `scripts/utilities/TELEMETRY-METRICS/context-dashboard.ps1` with `wf context-dashboard [chars]` command.
- Displays: prompt chars vs thresholds, token %, budget daily usage, autopilot status, blocked events in last 60 s.
- `-AsJson` flag for programmatic integration.

#### CI Hardening
- New workflows: `foundation-quality-gate.yml`, `workflow-lint.yml`.
- `quality-gates.json` canonical config for required checks.
- All scheduled workflows include `permissions`, `concurrency`, `timeout-minutes` and UTC/GMT-3 cron comments.

#### Override Governance (Phase 3)
- `governed_override_profiles` in `orchestrator.json`: `verbose-debug` and `executive-review` profiles with max-turn enforcement.
- `agent-verify.ps1` evaluates override abuse by time window using configurable thresholds.
- Audit log at `.logs/override-audit.jsonl`.

#### Metrics Persistence
- `metrics-config.json#runtime_state` persists cumulative metrics cross-session.
- Incremental updates after each session without full overwrite.

#### Auto-Delegation Chain Unified
- `auto-delegate-orchestrator.ps1` now delegates through `auto-delegation-wrapper.ps1` (no more internal simulation).
- `auto-delegation-wrapper.ps1` unified: supports both legacy positional and parametrized invocation.
- `agent-router.ps1` repoRoot path corrected to 3 levels up (was 2), fixing false `blocked` status for local skills.

### Fixed
- `agent-router.ps1`: repoRoot resolved incorrectly (`..\..` → `..\..\..`), causing local skills to not be found.
- `dispatch.completed` event missing required `status` field — now always included.
- `auto-delegate-orchestrator.ps1`: null-ref on missing keys (`concurrencyLimits`, `routingBindings`, `features.tieredRouting`).

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
- Default AI provider set to OpenCode for 
- Multi-provider support: Claude, GPT, Gemini, local models
- Desktop app, terminal, and IDE integration available
- 140K+ GitHub stars, 6.5M monthly developers

#### Workspace-Skills Integration (v2.2.0)
- Automatic workspace-skills repository installation
- 20+ curated skills for AI agents (Angular, React, Next.js, TypeScript, etc.)
- Auto-detection and installation of skills for available AI agent
- Skills for: Frontend, Backend/AI, Testing, Workflow
- Bootstrap integration with auto-install for Claude, OpenCode, Gemini, Cursor

#### Native AI Integration (v2.2.0)
- Automatic native AI tooling installation on project creation
- AI ecosystem configurator with SDD workflow
- Support for 8 AI agents (Claude Code, OpenCode, Gemini CLI, Cursor, etc.)
- Persistent memory, skills system, and MCP servers
- Teaching persona with security-first permissions

####  Integration (v2.1.0)
- Automatic  installation on project creation
- AGENTS.md template for coding standards
- Pre-commit hook for AI-powered code review
- Support for multiple AI providers (Claude, OpenCode, Gemini, Ollama, GitHub Models)
- Global  installation for new projects

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
  - Explicit replication checks (global  repo)
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
