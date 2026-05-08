# 📃 Changelog#

<p align="center">
  <b>All notable changes to this project will be documented in this file.</b>
</p>

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]#

---

## [2.8.1] - 2026-05-08#

### ✨ Added#

- **ROADMAP.md**: Project vision with short/mid/long-term milestones
- **docs/guides/RELEASE-PROCESS.md**: Documented release checklist
- **docs/guides/BRANCH-STRATEGY.md**: Git flow conventions documented
- **format-check.yml**: Prettier formatting CI workflow (15 workflows total)
- **npm scripts**: `format:check`, `format:fix` added to package.json
- **prettier**: Added as devDependency

### 🔄 Changed#

- **CONTRIBUTING.md**: Complete rewrite — URLs fixed to `foundation-public`, test counts corrected (28), prerequisites updated
- **VERSION**: Synced from `2.6.5` to `2.8.0`
- **Stale branches**: 4 merged branches deleted (`feature/judgment-day`, `feature/security-system`, `pr/judgment-day-native`, `release/v1.0.0`)

---

## [2.8.0] - 2026-05-08#

### ✨ Added#

#### 🏗️ Project Infrastructure#
- **CODE_OF_CONDUCT.md**: Standard contributor covenant
- **PR template**: `.github/PULL_REQUEST_TEMPLATE.md` — conventional commit checklist
- **Dependabot**: `.github/dependabot.yml` — weekly GitHub Actions updates
- **CodeQL**: `.github/workflows/codeql-analysis.yml` — `actions` language only, `continue-on-error: true`
- **Labeler**: `.github/labeler.yml` — auto-labels PRs by changed paths
- **Linting configs**: `.markdownlint.json` (MD033 with allowed elements), `.prettierrc`
- **Security configs**: `.trivyignore`, `.secretlintrc.json`, `.secretlintignore`
- **Architecture Decision Records**: `docs/adr/ADR-0001-foundation-architecture-decisions.md` — 7 decisions documented

#### 🧪 CI/CD Pipeline#
- **test-suite.yml**: Full CI test workflow — runs on push/PR to main/develop, executes 28 tests, uploads results artifact
- **quality-gate.yml**: Central quality gate with `timeout-minutes` fixed (duplicate removed)
- **ps-lint.yml**: Caching enabled for PSScriptAnalyzer

#### 🔧 Git Hooks#
- **json-lint.ps1**: Pre-commit JSON validation script (replaces inline `-Command` to fix quoting)
- **workflow-lint.ps1**: Pre-commit workflow YAML validation — detects unsupported CodeQL languages, missing Trivy format/output

#### 🛠️ Installer Improvements#
- **Go auto-install**: `install-prerequisites.ps1` — checks via `go version`, installs via `winget install GoLang.Go`
- **Engram auto-install**: `install-prerequisites.ps1` — checks via `engram`, installs via `go install github.com/workspace-foundation/engram/cmd/engram@latest`
- **TUI installer**: Interactive prompts for Go and Engram installation post-clone
- **sync-to-public.ps1**: Now copies `CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md` to public repo

---

### 🔄 Changed#

#### 🔧 Lefthook v2 Migration#
- `.lefthook.yml`: Full rewrite to v2 syntax — `commands:` with `run:` for inline, `scripts:` without `run:` for script files
- Pre-commit: 3 hooks (json-lint, opencode-validation, workflow-lint)
- Pre-push: 4 hooks (audit-check, orchestrator-auto-fix, test-suite, trufflehog)
- commit-msg: commitlint via `@commitlint/cli`

#### 📚 Documentation#
- **README.md**: URLs updated from `anomalyco/workspace-foundation` to `EmmanuelOrtiz87/foundation-public`
- **BOARD-SUPPLEMENT.md**: Repo URLs updated — both public and private repos listed
- **CONTRIBUTING.md**: Clone URL updated to `foundation-public`
- **TESTING-STRATEGY.md**: Rewritten with actual test states (22 unit + 3 integration + 2 security + 1 perf)
- **tests/README.md**: Corrected test counts and categories
- **SECURITY-HARDENING.md**: Fixed corrupted accented characters (32 patterns restored)
- **COMPATIBILITY-MATRIX.md**: Updated with code quality standards checklist
- **Marketing URLs**: All 3 marketing files updated from `anomalyco/opencode` to `EmmanuelOrtiz87/foundation-public`
- **Bitbucket references**: SUITE-OVERVIEW.md URL fixed

#### 🧩 Skills Reorganization#
- 8 business skills moved to `skills/business/` subdirectory
- `skills/documentation-manager.ps1` → `skills/documentation-manager-skill/` with proper `SKILL.md`
- `skills/SKILL_INDEX.md`: Links updated to reflect new paths

#### 🧹 Workspace Homologation#
- 52 stale files at `C:\Workspace_local\` root archived to `_archive/`
- `C:\Workspace_local\` now contains only: `workspace-foundation`, `foundation-public`, `bitbucket-dashboard`, and system dirs

---

### ✅ Fixed#

#### 🐛 Pre-Push Hooks#
- **audit-check**: Path switched to forward slashes for cross-platform compatibility
- **config validator**: Changed from output regex to `$LASTEXITCODE` for reliability
- **trufflehog**: Flags updated to `--no-update`, `--since-commit origin/main`
- **orchestrator-auto-fix**: Reliable exit code detection

#### 🐛 Pre-Commit Hooks#
- **json-lint**: Moved from inline `-Command` (backtick escaping issues) to `hooks/json-lint.ps1` with `-File`
- **opencode-validation**: Required sections changed to Spanish to match actual NORMATIVAS docs

#### 🐛 CI/CD#
- **CodeQL**: Removed unsupported `powershell` language from matrix (kept `actions` only)
- **CodeQL**: Added `continue-on-error: true` for private repos without Advanced Security
- **Trivy**: Added explicit `format: json` + `output: trivy-report.json` + `if: always()` + `retention-days: 30` in OWASP and dependency-backup workflows
- **quality-gate**: Removed duplicate `timeout-minutes` line

#### 🐛 Documentation & Orphaned Files#
- **25 broken Markdown links**: Fixed across 10 documentation files
- **NORMATIVAS link**: Last broken link resolved
- **Dead code**: Removed Spanish duplicate section in `pre-commit-config-validation.ps1` (after `exit 0`)
- **Orphaned AI-TOOLS-COMPATIBILITY-MATRIX.md**: Removed from `foundation-public` (superseded by `COMPATIBILITY-MATRIX.md` v1.1.0)

#### 🐛 Installer#
- **NSIS case**: Fixed `Foundation-Installer.nsi` → `foundation-installer.nsi` in sync script

---

### 🧪 Tests#
- **Reorganized**: Tests split into unit (22), integration (3), security (2), performance (1) — 28 total, 100% PASS
- **tests/README.md**: Added with test documentation
- **categories updated**: `COMPATIBILITY-MATRIX.md` reflects new test structure
- **Pre-push test-suite**: Runs all 28 tests before push — 0 failures

---

## [2.7.0] - 2026-05-06#

### ✨ Added#

#### 🏗️ Documentation Standards & Visual Design#
- **New Default Behavior**: All official documentation now follows visual design standards
- **Badges**: shields.io badges for version, status, license, runtime
- **Emojis**: Strategic emojis in headers, list items, callouts
- **Tables**: Structured data presentation with emojis
- **ASCII Art**: Visual diagrams for architecture and reports
- **Section Separators**: Horizontal rules between major sections

#### 🎨 Marketing Materials#
- **docs/marketing/README.md**: Completely renovated with visual design
- **docs/marketing/FOUNDATION-STACK-SOCIAL.md**: Updated with emojis and tables
- **docs/marketing/foundation-stack-blog-post.md**: Enhanced with literary techniques

#### 📚 Core Documentation#
- **docs/README.md**: Hub document completely renovated (468 lines)
- **docs/getting-started/README.md**: Quick start guide with 3-step wizard
- **docs/architecture/README.md**: Architecture hub with 5-layer topology
- **docs/guides/README.md**: Navigation guide with all 40+ guides
- **docs/reference/README.md**: Technical reference hub
- **docs/audits/README.md**: Audit workflow documentation
- **docs/sessions/README.md**: Session lifecycle artifacts
- **docs/tasks/README.md**: Task briefs documentation
- **docs/specs/README.md**: Technical specifications

#### 🔧 Foundation Audit & Fixes#
- **audit-sweep.ps1**: Added null check for empty files
- **audit-sweep.ps1**: Exclude `.opencode/node_modules/` from link validation
- **auto-delegation-router.ps1**: Fixed PowerShell switch bug (now uses if/elseif)
- **auto-delegation-router.ps1**: Fixed confidence scoring logic
- **tests/integration**: Updated expectations to match actual behavior
- **CLAUDE.md**: Corrected path to `pre-process-input.ps1`
- **autonomous-validation.yml**: Added UTC mapping in cron comment
- **tools/ and projects/**: Created missing directories
- **125 skills**: All PASS validation
- **30 tests**: 20 unit + 10 integration — 100% PASS

---

### 🔄 Changed#

#### 📏 Documentation standards.md#
- Added **Section 7: Default Documentation Behavior**
- Defines visual design requirements for ALL official docs
- Enforcement via `agent-verify.ps1` and `wf validate`

#### 📂 Documentation Structure#
- **docs/README.md**: Now serves as documentation hub
- **docs/guides/README.md**: Lists all 40+ guides with emojis
- **docs/reference/README.md**: Technical reference with tables

---

### ✅ Fixed#

#### 🐛 Bug Fixes#
- **PowerShell switch bug**: `Calculate-ConfidenceScore` now uses if/elseif (not switch)
- **Audit false positives**: Excluded `.opencode/node_modules/` from link validation
- **CLAUDE.md**: Fixed wrong path `tools/` → `scripts/utilities/`
- **Missing directories**: Created `tools/` and `projects/`

---

## [2.6.5] - 2026-05-05#

### ✨ Added#

#### 🏢 Enterprise CI Hardening#
- `.github/workflows/ps-lint.yml`: PSScriptAnalyzer static analysis CI — Error severity blocks merge; warnings annotate PRs
- `.github/workflows/release.yml`: Automated GitHub Release creation on semver tag push; validates tag vs VERSION file
- `.github/dependabot.yml`: Weekly GitHub Actions version update automation (minor+patch grouped, max 5 PRs)
- `VERSION`: Single source of truth for current project version (`2.6.5`)
- `SECURITY.md`: Security policy — vulnerability reporting process, supported versions, 48h ack SLA, security controls table

#### 📋 Normativas (Rules)#
- `rules/POWERSHELL-STANDARDS.md`: Canonical PS1 coding standards — file headers, param declarations, error handling, output safety, path handling, security rules, naming conventions, PSSA configuration
- `rules/CI-HARDENING-STANDARDS.md`: Mandatory CI workflow requirements — permissions, concurrency, timeout defaults, action pinning, secrets handling, audit checklist
- `rules/TESTING-STANDARDS.md`: Testing pyramid, coverage targets, Pester 5 patterns, new-script test rule, quality gates

#### 🔧 wf CLI Improvements#
- `wf version`: New command — shows stack version from VERSION file, orchestrator version, PS version, and skill count#

#### 🧪 Tests#
- `tests/unit/v264-scripts.tests.ps1`: Existence + parse + behavior tests for FF-001/002/004/006 scripts#

### 🔄 Changed#
- `.gitignore`: Added entries for `reports/dashboard.html`, `reports/metrics-export.csv`, `reports/wf-benchmark.json`, `trivy-report.json`, `.event-bus/`, `.session/`
- `config/quality-gates.json`: Added `ps-lint`, `sdd-gate`, `owasp-scan` to `requiredWorkflows` (v1.1.0)

---

## [2.6.4] - 2026-05-05#

### ✨ Added#

#### 🔧 FF-001 — SDD CI Hardening (O-38)#
- `scripts/hooks/check-sdd-gate.ps1`: validates that at least one SDD doc with status `validated`, `done`, or `active` exists before committing/pushing to protected branches#
  - Blocking for `main`; advisory for `develop`; skipped on feature/bugfix branches#
  - Integrates with `hook-advisory-classifier.ps1` (Add-BlockingFinding/Add-AdvisoryFinding)#
- `.github/workflows/sdd-gate.yml`: CI workflow triggered on PRs to main/develop; runs `check-sdd-gate.ps1` on Windows runner#
- `wf.ps1`: `sdd-gate` command registered in ValidateSet + switch + help#

#### 🔧 FF-002 — SDD Process Metrics (O-39)#
- `scripts/utilities/TELEMETRY-METRICS/sdd-process-metrics.ps1`: computes spec coverage %, avg lead time (days), rework ratio %, and SDD document status breakdown#
  - Reads `docs/backlog/items.json` + `docs/sdd/*.md`#
  - Health signals: GREEN/YELLOW/RED per KPI; `-AsJson` for machine-readable output#
- `wf.ps1`: `sdd-metrics` command registered in ValidateSet + switch + help#

#### 🔧 FF-004 — Sync Drift Prevention (O-40)#
- `scripts/utilities/sync-drift-report.ps1`: compares declared config vs actual filesystem#
  - Checks: skills declared in `auto-delegation.json` vs `skills/` dirs; MCP servers vs local presence; done backlog `resolved_by` script refs vs actual files#
  - Outputs drift score + categorized findings; exits 1 when drift > 0#
  - `-AsJson` for machine-readable output#
- `wf.ps1`: `sync-drift` command registered in ValidateSet + switch + help#

#### 🔧 FF-006 — Local Workflow Performance (O-41)#
- `scripts/utilities/wf-benchmark.ps1`: profiles key `wf` commands with `Measure-Command` and compares against configurable SLO thresholds#
  - Default commands: `status`, `health`. Custom via `-Commands status,health,verify`#
  - PASS/WARN/FAIL per command; report persisted to `reports/wf-benchmark.json`#
  - SLO defaults: status ≤5 s, health ≤15 s, verify ≤30 s (override via `config/testing.config.json#benchmark.slo`)#
- `wf.ps1`: `benchmark [cmds]` command registered in ValidateSet + switch + help#

### 🔄 Changed#
- `docs/backlog/items.json`: all 7 backlog items now `done` — FF-001/002/004/006 resolved this release#

---

## [2.6.3] - 2026-05-05#

### ✨ Added#

#### 🔧 FF-013 — Runtime Router Gating (O-35)#
- `runtime-router.ps1` extended with `-Mode gate -TaskType (ai|heavy-ai|network|local|metrics|any)`:#
  - Exit 0=allowed, 1=warned, 2=blocked based on runtime mode + token status + event-bus rate limit#

---

<p align="center">
  <b>📃 Ready to see what changed?</b><br>
  <code>git log --oneline --since="2026-04-01" | Select-Object -First 30</code>
</p>
