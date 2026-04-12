---
name: script-governance-skill
description: >
  Governance patterns for development scripts: lifecycle, naming, safety, observability, and automation boundaries.
  Trigger: "script", "automation", "hook", "startup", "auto-init", "orchestrator script", "powershell", "bash".
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Use this skill when:
1. Creating or refactoring scripts under `scripts/`, `hooks/`, or `.githooks/`.
2. Defining startup automation (IDE/session activation, auto-init, health checks).
3. Implementing git hooks, background tooling, or environment bootstrap flows.
4. Reviewing script reliability, side effects, and failure behavior.

## Script Architecture Rules

1. One clear entrypoint per concern:
- `wf.ps1` for operator commands.
- `auto-init` for startup activation.
- `ensure-tools-active` for dependency/tool checks.
- `detect-ide-session` for environment inference.

2. Keep scripts idempotent:
- Safe if executed multiple times.
- Do not duplicate heavy installs by default.
- Use explicit force flags for disruptive actions.

3. Explicit boundaries:
- Detection scripts should not mutate state.
- Activation scripts can mutate state but must log actions.
- Hooks should only block on security-critical failures.

## Safety and Stability

1. Prefer warning + remediation command over hard-fail for non-critical issues.
2. Avoid auto-install in startup paths unless `-Force` is passed.
3. Always validate file paths before execution.
4. Resolve repository root dynamically (`git rev-parse --show-toplevel`) in hooks.
5. Use fallback command recommendations when automatic detection is uncertain.

## Observability and UX

1. Every script must expose a clear status output.
2. Provide concise, actionable messages:
- what failed,
- why,
- exact command to fix.
3. Avoid noisy output in quiet/automation modes.
4. Keep logs deterministic for auditability.

## Naming and Location Convention

1. Use verb-noun names (`detect-ide-session.ps1`, `ensure-tools-active.ps1`).
2. Keep utility scripts in `scripts/utilities/`.
3. Keep hook installers near hook logic (`scripts/project/`, `scripts/git-hooks/`).
4. Document each script in `scripts/utilities/README.md`.

## Validation Checklist

Before publishing script changes:
1. Run script directly with expected args.
2. Run script in fallback mode (missing dependency scenario).
3. Confirm non-critical failures do not block session work.
4. Confirm repository stays clean after expected command runs.
5. Update docs and orchestrator guidance if behavior changes.

## Change Admission Criteria

Before adding new script behavior, governance checks, or startup automation:

1. State why this change is needed now.
2. Question whether existing flow already solves the need.
3. Prefer simpler change with lower operational burden.
4. Define measurable validation before codifying behavior.

Required evidence to promote a change into permanent script behavior:
1. At least one executable validation command was run.
2. Expected and observed outcomes are documented.
3. Rollback or disable path is explicit.

If any evidence is missing, keep the change as proposal/hypothesis and do not harden it into defaults.

## Toolchain Contract

Use this contract to keep governance behavior predictable and non-conflicting:

1. MUST persist durable decisions and session closure notes in Engram.
2. MUST follow orchestrator skill flow for assessment, validation, audit, and publication.
3. SHOULD use `gga` and `gentle-ai` when present; if absent, emit warnings with install/remediation commands.
4. MUST keep validators deterministic and quiet-safe in automation mode.
5. MUST avoid introducing startup behavior that changes state unexpectedly.
6. MUST classify new checks by severity: blocking only for reliability/security/integrity risks.
7. SHOULD keep style and maintainability checks advisory unless explicitly elevated by policy.

## Enforcement Automation

These controls must be validated before publication:

1. No loose operational scripts at `scripts/` root (except explicit allowlist files like `README.md`).
2. Deprecated command paths must not remain in docs/scripts once a canonical path is defined.
3. Script registry must reflect canonical locations used by current commands.
4. Generated-by-agent and manual changes follow the same governance checks.

Legacy-safe mode:
1. Existing repos can run advisory structure checks by default to avoid noisy, high-risk migrations.
2. Canonical structure enforcement should be explicitly enabled only when repository owners approve migration.
3. Any enforcement change must include rollback instructions.

Suggested command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\diagnostics\validate-script-governance.ps1
```

## Commands

```powershell
# IDE/session detection
.\scripts\utilities\wf.ps1 ide-status

# Health and activation
.\scripts\utilities\wf.ps1 health

# Session start
.\scripts\utilities\wf.ps1 start-session <task>

# On-demand orchestration fallback (if available)
.\scripts\utilities\stack-on-demand.ps1 -Action activate
```
