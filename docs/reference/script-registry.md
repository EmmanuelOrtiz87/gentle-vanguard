# Script Registry

## Purpose

Central inventory of automation scripts with ownership, risk level, and execution policy.

## Governance Levels

1. Level A (startup-safe): non-destructive checks allowed in auto-init paths.
2. Level B (session-ops): bounded mutations allowed with clear logging.
3. Level C (high-impact): explicit user intent required (`-Force` or direct command).

## Script Inventory

| Script                                                                                                                                             | Area              | Level | Auto Mode | Owner    | Notes                        |
| -------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- | ----- | --------- | -------- | ---------------------------- |
| scripts/utilities/detect-ide-session.ps1 <!-- REF-OBSOLETA: eliminado; candidato: src/core/detect-tool.ts / src/core/tool-detector-enhanced.ts --> | Session Detection | A     | yes       | platform | Detection only, no mutations |

<!-- REF-OBSOLETA: scripts/utilities/detect-ide-session.ps1 no tiene equivalente TS (migración PS1→TS) -->

| scripts/utilities/auto-init-dev-environment.ps1
<!-- REF-OBSOLETA: eliminado; existe scripts/utilities/utils/UTILITIES/auto-init-dev-environment.sh -->

| Startup | A | yes | platform | Quiet-safe activation checks |
<!-- REF-OBSOLETA: scripts/utilities/auto-init-dev-environment.ps1 no tiene equivalente TS (migración PS1→TS) -->

| scripts/utilities/ensure-tools-active.ps1 <!-- REF-OBSOLETA: eliminado en migración PS1→TS --> |
Tooling | B | yes | platform | Avoids heavy auto-installs unless forced |
<!-- REF-OBSOLETA: scripts/utilities/ensure-tools-active.ps1 no tiene equivalente TS (migración PS1→TS) -->

| scripts/utilities/run-engram.ps1 <!-- REF-OBSOLETA: eliminado; Engram vía tools/engram.exe --> |
Memory Runtime | B | manual | platform | Canonical launcher for Engram session persistence |
<!-- REF-OBSOLETA: scripts/utilities/run-engram.ps1 no tiene equivalente TS (migración PS1→TS) -->

| src/cli/gv.ts | Operator CLI | B | manual | dev-experience | Entrypoint for workflow commands | |
src/deployment/validate-release-homologation.ts
<!-- REF-OBSOLETA: src/deployment/ no existe; solo protected/scripts/utilities/DEPLOYMENT/validate-release-homologation.ps1.enc -->

| Release Governance | B | manual | dev-experience | Complementary pre-release multi-repo gate
(VERSION/branch/tag alignment) |
<!-- REF-OBSOLETA: scripts/utilities/DEPLOYMENT/validate-release-homologation.ps1 no tiene equivalente TS (migración PS1→TS) -->
<!-- REF-OBSOLETA: src/deployment/validate-release-homologation.ts no existe (ruta migrada o eliminada) -->

| scripts/utilities/enable-optional-post-commit.ps1
<!-- REF-OBSOLETA: eliminado; candidato: templates/project-root/scripts/enable-optional-post-commit.ts -->

| Optional Hook Coverage | B | manual | dev-experience | Enables/disables optional post-commit
automation (disabled by default) |
<!-- REF-OBSOLETA: scripts/utilities/enable-optional-post-commit.ps1 no tiene equivalente TS (migración PS1→TS) -->

| scripts/gentle-vanguard/setup.sh
<!-- REF-OBSOLETA: eliminado; candidato: scripts/core/setup.sh --> | Gentle-Vanguard Setup | B |

manual | platform | Cross-platform bootstrap entrypoint for Linux/macOS/WSL | | src/bootstrap.ts |
Gentle-Vanguard Setup | B | manual | platform | Canonical TypeScript bootstrap entrypoint for
workspace initialization | | scripts/gentle-vanguard/src/cli/gv.ts
<!-- REF-OBSOLETA: eliminado; migrado a src/cli/gv.ts --> | Gentle-Vanguard CLI | B | manual |

platform | Workspace bootstrap and scaffolding CLI (`init`, `new`, `validate`, `tools`, `skills`) |
| scripts/project/new-project.ps1
<!-- REF-OBSOLETA: eliminado; ver src/create-gentle-vanguard.ts --> | Project Scaffolding | B |

manual | dev-experience | Canonical new-project entrypoint backed by bootstrap-workspace |
<!-- REF-OBSOLETA: scripts/project/new-project.ps1 no tiene equivalente TS (migración PS1→TS) -->

| scripts/utilities/end-session.ps1
<!-- REF-OBSOLETA: eliminado; ver src/session-close-orchestrator.ts --> | Session Closure | B |

manual | dev-experience | Runs review/audit/governance checks and generates delivery closure
artifact |
<!-- REF-OBSOLETA: scripts/utilities/end-session.ps1 no tiene equivalente TS (migración PS1→TS) -->

| scripts/utilities/context-pack.ps1
<!-- REF-OBSOLETA: eliminado; candidato: templates/project-root/scripts/context-pack.ts --> |

Context Budgeting | B | manual | dev-experience | Generates compact continuation summary to reduce
token usage |
<!-- REF-OBSOLETA: scripts/utilities/context-pack.ps1 no tiene equivalente TS (migración PS1→TS) -->

| scripts/utilities/compact-start.ps1
<!-- REF-OBSOLETA: eliminado; candidato: templates/project-root/scripts/compact-start.ts --> |

Context Budgeting | B | manual | dev-experience | Generates context pack and compact prompt for new
thread |
<!-- REF-OBSOLETA: scripts/utilities/compact-start.ps1 no tiene equivalente TS (migración PS1→TS) -->

| scripts/utilities/context-metrics-report.ps1
<!-- REF-OBSOLETA: eliminado; candidato: templates/project-root/scripts/context-metrics-report.ts -->

| Context Budgeting | B | manual | dev-experience | Reports context-pack and compact-start usage
metrics |
<!-- REF-OBSOLETA: scripts/utilities/context-metrics-report.ps1 no tiene equivalente TS (migración PS1→TS) -->

| scripts/utilities/generate-audit-report.ps1
<!-- REF-OBSOLETA: eliminado; ver src/report-generator.ts --> | Audit Reporting | B | manual |

platform | Generates weekly/monthly/executive audit reports in markdown |
<!-- REF-OBSOLETA: scripts/utilities/generate-audit-report.ps1 no tiene equivalente TS (migración PS1→TS) -->

| scripts/utilities/generate-session-audit.ps1 <!-- REF-OBSOLETA: eliminado en migración PS1→TS -->
| Session Audit | B | manual | platform | Manages session lifecycle audit logging |
<!-- REF-OBSOLETA: scripts/utilities/generate-session-audit.ps1 no tiene equivalente TS (migración PS1→TS) -->

| scripts/utilities/aggregate-metrics.ps1
<!-- REF-OBSOLETA: eliminado; candidato: src/core/metrics-aggregator.ts --> | Metrics Aggregation |

B | manual | platform | Aggregates daily/weekly/monthly metrics |
<!-- REF-OBSOLETA: scripts/utilities/aggregate-metrics.ps1 no tiene equivalente TS (migración PS1→TS) -->

| scripts/validation/homologate-workspace.ps1
<!-- REF-OBSOLETA: eliminado; candidato: src/validate-readme.ts --> | Workspace Hygiene | B | manual

| dev-experience | Normalizes artifacts/docs, removes stale files, updates references |
<!-- REF-OBSOLETA: scripts/validation/homologate-workspace.ps1 no tiene equivalente TS (migración PS1→TS) -->

| scripts/git-hooks/pre-push <!-- REF-OBSOLETA: eliminado; hooks nativos en src/hooks/ --> | Git
Hook Runtime | B | git-event | platform | Runs governed pre-push checks (native review, governance
validation, homologation drift gate); post-commit hook intentionally not enabled in Gentle-Vanguard
| | scripts/utilities/stack-on-demand.ps1 <!-- REF-OBSOLETA: eliminado en migración PS1→TS --> |
Orchestration Mode | B | manual | platform | Activate/validate/deactivate flow |
<!-- REF-OBSOLETA: scripts/utilities/stack-on-demand.ps1 no tiene equivalente TS (migración PS1→TS) -->

| scripts/utilities/orchestrator-status.ps1 <!-- REF-OBSOLETA: eliminado en migración PS1→TS --> |
Status | A | manual | platform | Read-oriented orchestration checks |
<!-- REF-OBSOLETA: scripts/utilities/orchestrator-status.ps1 no tiene equivalente TS (migración PS1→TS) -->

| scripts/diagnostics/system-diagnostics.ps1
<!-- REF-OBSOLETA: eliminado; existe scripts/diagnostics/system-diagnostics.sh --> | Diagnostics | B

| manual | platform | Health and repair checks |
<!-- REF-OBSOLETA: scripts/diagnostics/system-diagnostics.ps1 no tiene equivalente TS (migración PS1→TS) -->

| scripts/diagnostics/validate-script-governance.ps1
<!-- REF-OBSOLETA: eliminado; candidato: src/stack-compliance.ts --> | Governance | B | manual |

platform | Validates script placement, naming, and governance policy compliance |
<!-- REF-OBSOLETA: scripts/diagnostics/validate-script-governance.ps1 no tiene equivalente TS (migración PS1→TS) -->

| scripts/diagnostics/validate-sdd-governance.ps1
<!-- REF-OBSOLETA: eliminado; candidato: src/check-sdd-gate.ts --> | Governance | B | ci-pr |

platform | Enforces SDD gate on PRs with branch-aware mandatory/advisory behavior |
<!-- REF-OBSOLETA: scripts/diagnostics/validate-sdd-governance.ps1 no tiene equivalente TS (migración PS1→TS) -->

| src/validate-gitflow.ts <!-- REF-OBSOLETA: eliminado; migrado a src/validate-gitflow.ts --> |
GitFlow Policy | B | manual | platform | Enforces branch naming, protected branch push policy, and
expected PR base |

## Execution Policy

1. Startup paths must remain idempotent and quiet-compatible.
2. Scripts must print actionable remediation commands on failure.
3. Non-critical failures must not block session progress.
4. Hooks block only for security-critical failures.
5. Gentle-Vanguard keeps hook scope minimal by design: pre-push only by default.
6. Post-commit automation is available as an opt-in profile and must be explicitly enabled.

## Optional Post-Commit Profile

Use this profile only when the project needs commit-time memory/session synchronization.

```TypeScript
# Enable optional post-commit coverage
# <!-- REF-OBSOLETA: enable-optional-post-commit.ps1 eliminado; candidato: templates/project-root/scripts/enable-optional-post-commit.ts o hooks nativos en src/hooks/ -->

# Disable optional post-commit coverage
# <!-- REF-OBSOLETA: enable-optional-post-commit.ps1 eliminado; candidato: templates/project-root/scripts/enable-optional-post-commit.ts o hooks nativos en src/hooks/ -->
```

Default for Gentle-Vanguard and generated projects remains disabled.

## Homologation Contract (Tools and Process)

| Item                           | Requirement | Enforcement                                   |
| ------------------------------ | ----------- | --------------------------------------------- |
| Engram memory                  | MUST        | Validator advisory by default, strict-capable |
| Orchestrator skill flow        | MUST        | Documented + validator file checks            |
| Session artifacts              | MUST        | Validator file checks                         |
| Native review command path     | MUST        | Validator policy check                        |
| Runtime router readiness       | SHOULD      | Validator advisory warning                    |
| Focused validation before push | MUST        | Validator execution + CI gate                 |

Default policy: keep development flow unblocked for advisory gaps, but never hide them.

## Validation Commands

```TypeScript
# IDE and session readiness
# REF-OBSOLETA: subcomando gv ide-status no existe en src/cli/gv.ts actual (comandos: check, validate, info, list, health, new, session, dashboard, status, etc.)

# Health + cleanup drift gate (CI-friendly)
.\src\cli\gv.ts health

# Startup path
.\scripts\utilities\utils\UTILITIES\auto-init-dev-environment.sh -Quiet <!-- REF-OBSOLETA: auto-init-dev-environment.ps1 eliminado; existe versión .sh -->

# Governance policy gate (legacy-safe advisory mode)
# <!-- REF-OBSOLETA: validate-script-governance.ps1 eliminado; candidato: src/stack-compliance.ts -->

# GitFlow policy gate
.\src\validate-gitflow.ts

# Canonical structure enforcement (enable only with explicit migration approval)
# <!-- REF-OBSOLETA: validate-script-governance.ps1 eliminado; candidato: src/stack-compliance.ts -->

# Guided migration of loose scripts (preflight + rollback)
# <!-- REF-OBSOLETA: subcomando gv migrate-structure no existe en src/cli/gv.ts actual; ver src/auto-ps1-fixer.ts -->

# Compact context pack for new chat thread (token optimization)
# <!-- REF-OBSOLETA: subcomando gv context-pack no existe en src/cli/gv.ts actual; ver src/handoff-compress.ts y context-engineering skill -->
<!-- REF-OBSOLETA: src/handoff-compress.ts no existe (ruta migrada o eliminada) -->

# One-step compact handoff (generates context pack + prompt)
# <!-- REF-OBSOLETA: subcomando gv compact-start no existe en src/cli/gv.ts actual -->

# Context usage metrics report (7 days default)
# <!-- REF-OBSOLETA: subcomando gv context-metrics no existe en src/cli/gv.ts actual -->

# Workspace homologation (dry-run / apply)
# <!-- REF-OBSOLETA: subcomando gv homologate no existe en src/cli/gv.ts actual -->

# Release homologation complementary gate (multi-repo)
# <!-- REF-OBSOLETA: subcomando gv release-homologation no existe en src/cli/gv.ts actual -->

# Context efficiency thresholds for audit semaphore
Get-Content .\config\context-efficiency.json
```
