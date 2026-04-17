# Operating Decisions (2026-04-15)

Consolidated lessons learned, rules, mechanisms, and definitions agreed during hardening of the Workspace + Foundation operating flow.

## Global (Workspace-Level)

### Lessons Learned

- ACL drift on Windows can silently break `.git` write operations (`index.lock` creation), artifact rotation, and cleanup.
- Network/proxy warnings (for update checks) must not be treated as critical startup blockers.
- Session lifecycle reliability improves when startup and closure are handled by dedicated wrappers, not manual ad-hoc commands.

### Rules Adopted

- Always run startup through `tools/session-autostart.cmd`.
- Keep compatibility checks enabled by default (`strictCompatibilityChecks=true`).
- Use degraded mode only as temporary continuity fallback (`strictCompatibilityChecks=false`).
- Require closure execution via session manager (`session-manual-end.cmd` or idle auto-close flow).

### Mechanisms Implemented

- Idle auto-close timeout: 60 minutes.
- Session IDs follow `session-YYYY-MM-DD-XX`.
- Auto-close emits a user-facing re-entry message with explicit restart commands.
- Compatibility gate validates coexistence of:
  - native runtime router
  - `engram`
  - orchestrator status
  - agent registry status

### Definitions

- **Strict Mode**: startup stops if critical compatibility checks fail.
- **Degraded Continuity Mode**: startup continues with warnings when strict mode is disabled.
- **Compatibility Check**: operational readiness check for runtime + orchestration + memory + agent lanes.

## Foundation (Repository-Level)

### Lessons Learned

- Broken doc links and legacy path references create governance friction and onboarding confusion.
- Artifact rotation logic must fail loudly on filesystem errors to avoid false success.
- Governance requires at least one active `session-start` artifact under `docs/sessions`.

### Rules Adopted

- Documentation links must resolve to existing repository paths.
- Rotation categories must match canonical structure:
  - `docs/audits`
  - `docs/sessions`
  - `docs/code-reviews`
- Session lifecycle artifacts are governance-critical and cannot be omitted.

### Mechanisms Implemented

- Markdown link sweep and correction across docs.
- `rotate-artifacts.ps1` hardened with explicit error accounting and non-zero exit on failures.
- `wf day-end-closure`/`day-end-closure.ps1` invocation stabilized (named switch handling).
- Session startup compatibility checks integrated into workspace startup manager.

### Definitions

- **Governance Blocker**: a missing mandatory artifact or missing required script/policy signal.
- **Canonical Docs Structure**: approved folder layout referenced by scripts and validations.
- **Closure Artifact Set**: delivery closure + closure report + Engram session memory writes.

## Operational Defaults Kept

- `strictCompatibilityChecks=true`
- `autoStartPrimaryRuntime=true`
- `enableIdleAutoClose=true`
- `idleTimeoutMinutes=60`

## Continuity Commands

```powershell
.\tools\session-autostart.cmd
.\tools\session-manual-start.cmd
.\tools\session-manual-end.cmd
.\tools\validate-session-stack.ps1 -Quiet
```
