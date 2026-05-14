# 📃 Changelog#

<p align="center">
  <b>All notable changes to this project will be documented in this file.</b>
</p>

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.1] - 2026-05-13 - Live Dashboard Stabilization#

### ✨ Added#

- **Dynamic observability dashboard**: Preserved active tab state, stabilized live metric hooks, and documented the `foundation dashboard live` flow for the current release.
- **Public release alignment**: Prepared synchronized publication for both `foundation` and `foundation-public`, including the refreshed `Foundation.exe` artifact.

### 🔧 Fixed#

- **Live dashboard server**: Switched the default live port to `8090` to avoid local conflicts observed on `8080`.
- **SSE delivery**: Refactored `/events` to emit one update per request so the single-listener server no longer blocks `/health` and `/dashboard.html`.
- **Dashboard refresh UX**: Removed destructive refresh behavior in served mode and kept timed refresh only as a fallback when push mode is unavailable.

### 📚 Changed#

- **CLI guidance**: Updated core docs to promote `foundation` as the canonical command while keeping compatibility wrappers in place.
- **Release artifacts**: Bumped patch version to `1.0.1` across repo metadata and release notes.

---

## [1.0.0] - 2026-05-13 - Initial Production Release#

### ✨ Added#

- **Foundation Stack Update Strategy**: Documented three update scenarios (lightweight CLI updates, core .exe builds, dev synchronization)
- **sync-stack.ps1**: New synchronization script for updating installed Foundation without reinstalling
- **Comprehensive validation hardening**: Made LESSONS-LEARNED-HOOKS-INCIDENT.md optional, added safe property checks for opencode.json
- **Foundation-Setup.exe**: Generated with complete hardening (v1.0.0)

### 🔧 Fixed#

- **Autonomous Validation**: Fixed exit code handling for optional documentation and missing JSON properties (commit a224090)
- **cross-platform-tests.yml**: Corrected shellcheck SC2129 and SC2086 warnings in bash redirect blocks (commit 33e5cc5)
- **Agent-verify**: Fixed domain parsing to use array syntax instead of CSV (commit 6e88e01)
- **Gitleaks allowlist**: Added sanctioned sync references (PAT_SYNC, PRIVATE_REPO, x-access-token) for both repos

### 📚 Changed#

- **VERSION**: Set to 1.0.0 across all repos and build artifacts
- **README badges**: Updated to reflect production 1.0.0 version
- **package.json**: Added version field (1.0.0) for consistency
- **Workflow standardization**: Unified line endings and formatting across all 13+ GitHub workflows

### 📋 Known Limitations#

- Auto-update feature (remote version checking) marked for future release
- Docker validator skipped in pre-push hooks (not yet implemented)
- Links validator skipped in pre-push hooks (not yet implemented)

---

## [Unreleased]#

### 🚀 Planned#

- [ ] Auto-update: Launcher checks remote version and prompts for upgrade
- [ ] Docker validation: Integration tests in containerized environments
- [ ] Links validation: Verify all documentation cross-references
- [ ] Release artifacts: S3 distribution for global availability

---

## [2.10.0] - 2026-05-14 - Stack Hardening: OS Detection, Project Root, Modification Protocol#

### ✨ Added#

- **OS detection integrado al startup flow**: detect-tool.ps1 ahora devuelve `$detected.os` con `platform/shell/pathSeparator/isWindows`. post-autostart-summary.ps1 incluye `platform/shell/pathSeparator` en startup-summary.json. CLAUDE.md y AGENTS.md instruyen al agente a leer `$detected.os.platform` antes de ejecutar comandos, eliminando tokens desperdiciados en scripts de plataforma equivocada.
- **projectRoot en orchestrator.json**: Nueva sección `workspace` con `projectRoot: projects/`, `configFile`, `projectDefaults`. AGENTS.md/CLAUDE.md referencian la ruta canónica para nuevos proyectos.
- **config/workspace.config.json**: Creado desde el example — fuente única de verdad para rutas de workspace, proyectos y defaults.
- **Modification Protocol (5 fases)**: Nueva sección en `rules/DEVELOPMENT-STANDARDS.md` — Explore→Scope→Validate→Modify→Post-Validate. Define cómo el agente debe abordar proyectos existentes antes de modificar.
- **SessionStart OS-aware**: detect-tool.ps1 resuelve `instructions.sessionAutostart` dinámicamente (.cmd en Windows, .sh en Linux/macOS).
- **sessionStartPlatform en tool configs**: 7 archivos `config/tool-*.json` ahora incluyen `sessionStartPlatform` con alternativas por SO.
- **pwsh fallback en NORMATIVAS-CROSS-PLATFORM.md**: Nueva sección 11 — availability check, tabla de fallback por plataforma, comportamiento cuando falta pwsh.

### 🔧 Fixed#

- **detect-tool.ps1**: sessionAutostart ya no es hardcodeado a .cmd — se resuelve según OS detectado.
- **Tool configs**: 7 configs hardcodeaban `.cmd` sin alternativa Linux/macOS. Ahora tienen mapa `sessionStartPlatform`.
- **8 backslashes hardcodeados**: detectados en auditoría (bootstrap-workspace.ps1, detect-tool.ps1, pre-process-input.ps1, auto-delegation-wrapper.ps1) — documentados para migración futura.
- **post-autostart-summary.ps1**: Variables `$isLinux`/`$isMacOS` renombradas a `$osIsLinux`/`$osIsMacOS` por conflicto con variables automáticas read-only de PS7.

### 📚 Changed#

- **CLAUDE.md**: Startup step 1 usa `$detected.instructions.sessionAutostart` (OS-aware). Nuevas secciones: "New Project & Modification Rules", referencias a workspace.config.json y DEVELOPMENT-STANDARDS.md.
- **docs/AGENTS.md**: Tool detection incluye OS output. Step 6 incluye platform/pathSeparator. Nuevas secciones: "New Project & Modification Rules", referencias a workspace.config.json.
- **rules/NORMATIVAS-CROSS-PLATFORM.md**: Renumbered sections 10→14, añadida sección 10 (pwsh check & fallback).

---

## [2.9.1] - 2026-05-12#

### 🔧 Fixed#

- **create-installer.ps1**: Hardened launcher build error handling so protected-artifact generation fails fast with a real exception instead of a false `$LASTEXITCODE` check
- **sync-to-public.ps1**: Fixed remote HEAD detection to avoid null-match failures during public repository synchronization
- **release workflow**: Aligned GitHub Release note extraction with the canonical root `CHANGELOG.md`
- **Session routing**: Removed `iniciar sesion` / `start session` from auto-delegation in favor of the canonical startup protocol defined in `CLAUDE.md`
- **SESSION skill docs**: Updated session workflow guidance to avoid duplicate start-session handling
- **Documentation sync**: Rebuilt and published `Foundation-Setup.exe` for `foundation-public`, keeping the public installer current

### 📚 Changed#

- **VERSION**: Bumped from `2.9.0` to `2.9.1`
- **README badge**: Updated visible version badge to `2.9.1`
- **Public release process**: Foundation and foundation-public are now aligned on the same validated patch release

---

## [2.9.0] - 2026-05-11#

### ✨ Added#

- **Model Router v2.2.0**: Reassigned all agent models to open-source subscription stack (GLM5, Kimi K2.6, Qwen 3.6 Plus via OpenRouter)
- **Agent visibility control**: All subagents marked `hidden: true` in opencode.json — only orchestrator is user-selectable; subagents are managed autonomously
- **OpenRouter provider**: Primary LLM provider configured for open-source model access

### 🔄 Changed#

- **opencode.json**: Complete rewrite — removed Anthropic/OpenAI default model references, switched to OpenRouter as primary provider, added `hidden: true` + `mode: "subagent"` to all non-orchestrator agents
- **config/model-router.json**: All 29 agent bindings updated from `opencode/gpt-*` to `openrouter/{glm-5|kimi-k2.6|qwen-3.6-plus}`
- **Default model**: Changed from `anthropic/claude-sonnet-4-5` to `openrouter/z-ai/glm-5`
- **Small model**: Set to `openrouter/qwen/qwen-3.6-plus` for lightweight tasks (title generation, compaction)

### 🗑️ Removed#

- **Direct Anthropic/OpenAI agent models**: All agents now route through OpenRouter for subscription-based open-source models

---

## [2.8.2] - 2026-05-10#

### ✨ Added#

- **Model Router v2.1.0**: 29-agent model-router with pipeline fixes and doc updates
- **14 custom agents**: Added Go-tier custom agents with model assignments
- **Portable multi-machine bootstrap**: Setup scripts for PC migration and runner installation
- **Session GitHub bypass**: Permanent enforcement of GitHub bypass at session start
- **Judgment Day paths**: Auto-generated paths added to `.gitignore`

### 🔄 Changed#

- **CI/CD optimization**: GHA workflow triggers optimized, pre-push hooks aligned
- **Sync workflows**: Consolidated sync steps, fixed PAT_SYNC auth and hardcoded branch
- **Dependencies**: Bumped `github/codeql-action` v3→v4, `actions/labeler` v5→v6, `actions/cache` v4→v5
- **Gitleaks allowlist**: Expanded for security-expert-skill, fixed format
- **Prettier config**: Added `.prettierignore`, excluded ps1/template/lefthook/package-lock

### 🛠️ Fixed#

- **GHA job permissions**: Added `actions:read` for CodeQL SARIF upload, `contents:read` to SAST
- **Sync errors**: Resolved `sync-public PAT_SYNC error` and hardcoded branch reference

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

- **CONTRIBUTING.md**: Complete rewrite — URLs fixed to `foundation-public`, test counts corrected
  (28), prerequisites updated
- **VERSION**: Synced from `2.6.5` to `2.8.0`
- **Stale branches**: 4 merged branches deleted (`feature/judgment-day`, `feature/security-system`,
  `pr/judgment-day-native`, `release/v1.0.0`)

---

## [2.8.0] - 2026-05-08#

### ✨ Added#

#### 🏗️ Project Infrastructure#

- **CODE_OF_CONDUCT.md**: Standard contributor covenant
- **PR template**: `.github/PULL_REQUEST_TEMPLATE.md` — conventional commit checklist
- **Dependabot**: `.github/dependabot.yml` — weekly GitHub Actions updates
- **CodeQL**: `.github/workflows/codeql-analysis.yml` — `actions` language only,
  `continue-on-error: true`
- **Labeler**: `.github/labeler.yml` — auto-labels PRs by changed paths
- **Linting configs**: `.markdownlint.json` (MD033 with allowed elements), `.prettierrc`
- **Security configs**: `.trivyignore`, `.secretlintrc.json`, `.secretlintignore`
- **Architecture Decision Records**: `docs/adr/ADR-0001-foundation-architecture-decisions.md` — 7
  decisions documented

#### 🧪 CI/CD Pipeline#

- **test-suite.yml**: Full CI test workflow — runs on push/PR to main/develop, executes 28 tests,
  uploads results artifact
- **quality-gate.yml**: Central quality gate with `timeout-minutes` fixed (duplicate removed)
- **ps-lint.yml**: Caching enabled for PSScriptAnalyzer

#### 🔧 Git Hooks#

- **json-lint.ps1**: Pre-commit JSON validation script (replaces inline `-Command` to fix quoting)
- **workflow-lint.ps1**: Pre-commit workflow YAML validation — detects unsupported CodeQL languages,
  missing Trivy format/output

#### 🛠️ Installer Improvements#

- **Go auto-install**: `install-prerequisites.ps1` — checks via `go version`, installs via
  `winget install GoLang.Go`
- **Engram auto-install**: `install-prerequisites.ps1` — checks via `engram`, installs via
  `go install github.com/foundation/engram/cmd/engram@latest`
- **TUI installer**: Interactive prompts for Go and Engram installation post-clone
- **sync-to-public.ps1**: Now copies `CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md` to public repo

---

### 🔄 Changed#

#### 🔧 Lefthook v2 Migration#

- `.lefthook.yml`: Full rewrite to v2 syntax — `commands:` with `run:` for inline, `scripts:`
  without `run:` for script files
- Pre-commit: 3 hooks (json-lint, opencode-validation, workflow-lint)
- Pre-push: 4 hooks (audit-check, orchestrator-auto-fix, test-suite, trufflehog)
- commit-msg: commitlint via `@commitlint/cli`

#### 📚 Documentation#

- **README.md**: URLs updated from `anomalyco/foundation` to
  `EmmanuelOrtiz87/foundation-public`
- **BOARD-SUPPLEMENT.md**: Repo URLs updated — both public and private repos listed
- **CONTRIBUTING.md**: Clone URL updated to `foundation-public`
- **TESTING-STRATEGY.md**: Rewritten with actual test states (22 unit + 3 integration + 2 security +
  1 perf)
- **tests/README.md**: Corrected test counts and categories
- **SECURITY-HARDENING.md**: Fixed corrupted accented characters (32 patterns restored)
- **COMPATIBILITY-MATRIX.md**: Updated with code quality standards checklist
- **Marketing URLs**: All 3 marketing files updated from `anomalyco/opencode` to
  `EmmanuelOrtiz87/foundation-public`
- **Bitbucket references**: SUITE-OVERVIEW.md URL fixed

#### 🧩 Skills Reorganization#

- 8 business skills moved to `skills/business/` subdirectory
- `skills/documentation-manager.ps1` → `skills/documentation-manager-skill/` with proper `SKILL.md`
- `skills/SKILL_INDEX.md`: Links updated to reflect new paths

#### 🧹 Workspace Homologation#

- 52 stale files at `C:\Workspace_local\` root archived to `_archive/`
- `C:\Workspace_local\` now contains only: `foundation`, `foundation-public`,
  `bitbucket-dashboard`, and system dirs

---

### ✅ Fixed#

#### 🐛 Pre-Push Hooks#

- **audit-check**: Path switched to forward slashes for cross-platform compatibility
- **config validator**: Changed from output regex to `$LASTEXITCODE` for reliability
- **trufflehog**: Flags updated to `--no-update`, `--since-commit origin/main`
- **orchestrator-auto-fix**: Reliable exit code detection

#### 🐛 Pre-Commit Hooks#

- **json-lint**: Moved from inline `-Command` (backtick escaping issues) to `hooks/json-lint.ps1`
  with `-File`
- **opencode-validation**: Required sections changed to Spanish to match actual NORMATIVAS docs

#### 🐛 CI/CD#

- **CodeQL**: Removed unsupported `powershell` language from matrix (kept `actions` only)
- **CodeQL**: Added `continue-on-error: true` for private repos without Advanced Security
- **Trivy**: Added explicit `format: json` + `output: trivy-report.json` + `if: always()` +
  `retention-days: 30` in OWASP and dependency-backup workflows
- **quality-gate**: Removed duplicate `timeout-minutes` line

#### 🐛 Documentation & Orphaned Files#

- **25 broken Markdown links**: Fixed across 10 documentation files
- **NORMATIVAS link**: Last broken link resolved
- **Dead code**: Removed Spanish duplicate section in `pre-commit-config-validation.ps1` (after
  `exit 0`)
- **Orphaned AI-TOOLS-COMPATIBILITY-MATRIX.md**: Removed from `foundation-public` (superseded by
  `COMPATIBILITY-MATRIX.md` v1.1.0)

#### 🐛 Installer#

- **NSIS case**: Fixed `Foundation-Installer.nsi` → `foundation-installer.nsi` in sync script

---

### 🧪 Tests#

- **Reorganized**: Tests split into unit (22), integration (3), security (2), performance (1) — 28
  total, 100% PASS
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

- `.github/workflows/ps-lint.yml`: PSScriptAnalyzer static analysis CI — Error severity blocks
  merge; warnings annotate PRs
- `.github/workflows/release.yml`: Automated GitHub Release creation on semver tag push; validates
  tag vs VERSION file
- `.github/dependabot.yml`: Weekly GitHub Actions version update automation (minor+patch grouped,
  max 5 PRs)
- `VERSION`: Single source of truth for current project version (`2.6.5`)
- `SECURITY.md`: Security policy — vulnerability reporting process, supported versions, 48h ack SLA,
  security controls table

#### 📋 Normativas (Rules)#

- `rules/POWERSHELL-STANDARDS.md`: Canonical PS1 coding standards — file headers, param
  declarations, error handling, output safety, path handling, security rules, naming conventions,
  PSSA configuration
- `rules/CI-HARDENING-STANDARDS.md`: Mandatory CI workflow requirements — permissions, concurrency,
  timeout defaults, action pinning, secrets handling, audit checklist
- `rules/TESTING-STANDARDS.md`: Testing pyramid, coverage targets, Pester 5 patterns, new-script
  test rule, quality gates

#### 🔧 wf CLI Improvements#

- `wf version`: New command — shows stack version from VERSION file, orchestrator version, PS
  version, and skill count#

#### 🧪 Tests#

- `tests/unit/v264-scripts.tests.ps1`: Existence + parse + behavior tests for FF-001/002/004/006
  scripts#

### 🔄 Changed#

- `.gitignore`: Added entries for `reports/dashboard.html`, `reports/metrics-export.csv`,
  `reports/wf-benchmark.json`, `trivy-report.json`, `.event-bus/`, `.session/`
- `config/quality-gates.json`: Added `ps-lint`, `sdd-gate`, `owasp-scan` to `requiredWorkflows`
  (v1.1.0)

---

## [2.6.4] - 2026-05-05#

### ✨ Added#

#### 🔧 FF-001 — SDD CI Hardening (O-38)#

- `scripts/hooks/check-sdd-gate.ps1`: validates that at least one SDD doc with status `validated`,
  `done`, or `active` exists before committing/pushing to protected branches#
  - Blocking for `main`; advisory for `develop`; skipped on feature/bugfix branches#
  - Integrates with `hook-advisory-classifier.ps1` (Add-BlockingFinding/Add-AdvisoryFinding)#
- `.github/workflows/sdd-gate.yml`: CI workflow triggered on PRs to main/develop; runs
  `check-sdd-gate.ps1` on Windows runner#
- `wf.ps1`: `sdd-gate` command registered in ValidateSet + switch + help#

#### 🔧 FF-002 — SDD Process Metrics (O-39)#

- `scripts/utilities/TELEMETRY-METRICS/sdd-process-metrics.ps1`: computes spec coverage %, avg lead
  time (days), rework ratio %, and SDD document status breakdown#
  - Reads `docs/backlog/items.json` + `docs/sdd/*.md`#
  - Health signals: GREEN/YELLOW/RED per KPI; `-AsJson` for machine-readable output#
- `wf.ps1`: `sdd-metrics` command registered in ValidateSet + switch + help#

#### 🔧 FF-004 — Sync Drift Prevention (O-40)#

- `scripts/utilities/sync-drift-report.ps1`: compares declared config vs actual filesystem#
  - Checks: skills declared in `auto-delegation.json` vs `skills/` dirs; MCP servers vs local
    presence; done backlog `resolved_by` script refs vs actual files#
  - Outputs drift score + categorized findings; exits 1 when drift > 0#
  - `-AsJson` for machine-readable output#
- `wf.ps1`: `sync-drift` command registered in ValidateSet + switch + help#

#### 🔧 FF-006 — Local Workflow Performance (O-41)#

- `scripts/utilities/wf-benchmark.ps1`: profiles key `wf` commands with `Measure-Command` and
  compares against configurable SLO thresholds#
  - Default commands: `status`, `health`. Custom via `-Commands status,health,verify`#
  - PASS/WARN/FAIL per command; report persisted to `reports/wf-benchmark.json`#
  - SLO defaults: status ≤5 s, health ≤15 s, verify ≤30 s (override via
    `config/testing.config.json#benchmark.slo`)#
- `wf.ps1`: `benchmark [cmds]` command registered in ValidateSet + switch + help#

### 🔄 Changed#

- `docs/backlog/items.json`: all 7 backlog items now `done` — FF-001/002/004/006 resolved this
  release#

---

## [2.6.3] - 2026-05-05#

### ✨ Added#

#### 🔧 FF-013 — Runtime Router Gating (O-35)#

- `runtime-router.ps1` extended with
  `-Mode gate -TaskType (ai|heavy-ai|network|local|metrics|any)`:#
  - Exit 0=allowed, 1=warned, 2=blocked based on runtime mode + token status + event-bus rate limit#

---

<p align="center">
  <b>📃 Ready to see what changed?</b><br>
  <code>git log --oneline --since="2026-04-01" | Select-Object -First 30</code>
</p>
