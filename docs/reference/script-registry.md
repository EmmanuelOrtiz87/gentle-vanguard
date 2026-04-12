# Script Registry

## Purpose

Central inventory of automation scripts with ownership, risk level, and execution policy.

## Governance Levels

1. Level A (startup-safe): non-destructive checks allowed in auto-init paths.
2. Level B (session-ops): bounded mutations allowed with clear logging.
3. Level C (high-impact): explicit user intent required (`-Force` or direct command).

## Script Inventory

| Script | Area | Level | Auto Mode | Owner | Notes |
|---|---|---|---|---|---|
| scripts/utilities/detect-ide-session.ps1 | Session Detection | A | yes | platform | Detection only, no mutations |
| scripts/utilities/auto-init-dev-environment.ps1 | Startup | A | yes | platform | Quiet-safe activation checks |
| scripts/utilities/ensure-tools-active.ps1 | Tooling | B | yes | platform | Avoids heavy auto-installs unless forced |
| scripts/utilities/run-gentle-ai.ps1 | Tooling Bridge | B | manual | platform | Compatibility launcher when native `gentle-ai` is unavailable |
| scripts/utilities/wf.ps1 | Operator CLI | B | manual | dev-experience | Entrypoint for workflow commands |
| scripts/utilities/stack-on-demand.ps1 | Orchestration Mode | B | manual | platform | Activate/validate/deactivate flow |
| scripts/utilities/orchestrator-status.ps1 | Status | A | manual | platform | Read-oriented orchestration checks |
| scripts/diagnostics/system-diagnostics.ps1 | Diagnostics | B | manual | platform | Health and repair checks |

## Execution Policy

1. Startup paths must remain idempotent and quiet-compatible.
2. Scripts must print actionable remediation commands on failure.
3. Non-critical failures must not block session progress.
4. Hooks block only for security-critical failures.

## Homologation Contract (Tools and Process)

| Item | Requirement | Enforcement |
|---|---|---|
| Engram memory | MUST | Validator advisory by default, strict-capable |
| Orchestrator skill flow | MUST | Documented + validator file checks |
| Session artifacts | MUST | Validator file checks |
| `gga` command | SHOULD | Validator advisory warning |
| `gentle-ai` command | SHOULD | Validator advisory warning |
| Focused validation before push | MUST | Validator execution + CI gate |

Default policy: keep development flow unblocked for advisory gaps, but never hide them.

## Validation Commands

```powershell
# IDE and session readiness
.\scripts\utilities\wf.ps1 ide-status

# Startup path
.\scripts\utilities\auto-init-dev-environment.ps1 -Quiet

# Governance policy gate
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\diagnostics\validate-script-governance.ps1
```
