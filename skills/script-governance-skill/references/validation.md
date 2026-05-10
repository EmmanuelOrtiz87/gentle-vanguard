## Validation Checklist

Before publishing script changes:
1. Run script directly with expected args
2. Run script in fallback mode (missing dependency scenario)
3. Confirm non-critical failures do not block session work
4. Confirm repository stays clean after expected command runs
5. Update docs and orchestrator guidance if behavior changes

## Enforcement Automation

These controls must be validated before publication:
1. No loose operational scripts at `scripts/` root (except allowlist like README.md)
2. Deprecated command paths must not remain in docs/scripts once canonical path defined
3. Script registry must reflect canonical locations used by current commands
4. Generated-by-agent and manual changes follow same governance checks

Legacy-safe mode:
1. Existing repos run advisory structure checks by default
2. Canonical structure enforcement only when owners approve migration
3. Any enforcement change must include rollback instructions

Suggested command:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\diagnostics\validate-script-governance.ps1
```

## Toolchain Contract

1. MUST persist durable decisions and session closure notes in Engram
2. MUST follow orchestrator skill flow for assessment, validation, audit, and publication
3. SHOULD use available native tools; if absent, emit warnings with install/remediation
4. MUST keep validators deterministic and quiet-safe in automation mode
5. MUST avoid startup behavior that changes state unexpectedly
6. MUST classify new checks by severity: blocking only for reliability/security/integrity risks
7. SHOULD keep style and maintainability checks advisory unless explicitly elevated

## Change Admission Criteria

Before adding new script behavior, governance checks, or startup automation:
1. State why this change is needed now
2. Question whether existing flow already solves the need
3. Prefer simpler change with lower operational burden
4. Define measurable validation before codifying behavior

Required evidence to promote a change into permanent behavior:
1. At least one executable validation command was run
2. Expected and observed outcomes documented
3. Rollback or disable path is explicit

If any evidence missing: keep as proposal/hypothesis, do not harden into defaults.
