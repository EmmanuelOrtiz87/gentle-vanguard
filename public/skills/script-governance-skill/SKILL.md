---
name: script-governance-skill
description:
  'Trigger: script, automation, hook, startup, auto-init, orchestrator script, powershell, bash.
  Governance patterns for development scripts: lifecycle, naming, safety, observability, and
  automation boundaries.'
metadata:
  source: GV-native
---

## Activation Contract

Use when creating or refactoring scripts under scripts/, hooks/, or .githooks/; defining startup
automation; implementing git hooks or environment bootstrap; or reviewing script reliability and
failure behavior.

## Hard Rules

- MUST use verb-noun naming (e.g., detect-ide-session.ps1)
- MUST keep utility scripts in scripts/utilities/
- MUST keep scripts idempotent — safe to run multiple times
- MUST NOT mutate state in detection scripts
- MUST log all state mutations in activation scripts
- MUST resolve repository root dynamically with git rev-parse --show-toplevel in hooks
- MUST expose clear status output (what failed, why, exact command to fix)
- MUST validate file paths before execution
- MUST keep logs deterministic for auditability

## Decision Gates

| Gate         | Condition                            | Action                                   |
| ------------ | ------------------------------------ | ---------------------------------------- |
| Script type  | Detection-only?                      | Must not mutate state                    |
| Script type  | Activation?                          | May mutate; must log all actions         |
| Script type  | Hook?                                | Block only on security-critical failures |
| Installation | Auto-init path?                      | Require -Force flag                      |
| Failure      | Non-critical?                        | Warn + suggest remediation, do not block |
| Severity     | Reliability/security/integrity risk? | Blocking allowed                         |
| Severity     | Style/maintainability?               | Advisory only                            |

## Execution Steps

1. Determine script purpose: detection, activation, or hook
2. Apply verb-noun naming with .ps1 or .sh extension
3. Place in correct directory (scripts/utilities/ for tools, scripts/git-hooks/ for hooks)
4. Implement idempotent behavior with -Force flag for destructive operations
5. Add clear status output with actionable error messages
6. Validate: run directly, run in fallback mode, confirm no side effects
7. Document in scripts/utilities/README.md

## Output Contract

Return script path, type, purpose, usage example, and validation results (direct execution +
fallback scenario).

## References

- `references/commands.md` — Common script commands reference
- `references/validation.md` — Validation checklist, enforcement, and change admission criteria
