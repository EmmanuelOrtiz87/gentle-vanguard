# Agent Runtime Recipe

Practical setup guide to run agents consistently across local, cloud/self-hosted, and SaaS environments.

## Objective

Ensure these capabilities work together without conflicts:

- Orchestrator (`project-orchestrator-skill`)
- Skills registry / multi-agent lanes (`agent-router.ps1`)
- Memory (`engram`)
- Native runtime router (`runtime-router.ps1`)
- Session governance (start/closure, token guard, compatibility checks)

## Prerequisites

- `go`, `git`, `node` available
- `workspace-foundation` cloned
- `engram` installed and reachable in `PATH`

Quick validation:

```powershell
.\tools\validate-session-stack.ps1 -Quiet
.\workspace-foundation\scripts\utilities\wf.ps1 orchestrator-status
.\workspace-foundation\scripts\utilities\wf.ps1 runtime-route
.\workspace-foundation\scripts\utilities\agent-router.ps1 status
```

## Runtime Modes

### 1) Local (Developer Machine)

Use this for day-to-day coding in a local repo.

1. Configure startup policy in `scripts/utilities/session-autostart.config.json`:
   - `autoStartPrimaryRuntime: true`
   - `strictCompatibilityChecks: true` (recommended)
2. Start session:

```powershell
.\tools\session-autostart.cmd
```

3. If strict mode blocks startup:
   - Fix components and retry (recommended), or
   - Temporarily set `strictCompatibilityChecks: false` and rerun startup.

### 2) Cloud / Self-Hosted Runner

Use this for controlled infrastructure (VM, container host, internal runners).

Recommended pattern:

1. Provision required binaries (`engram`, AI agent CLI) in image/bootstrap.
2. Run preflight before work units:

```powershell
.\tools\validate-session-stack.ps1 -Quiet
```

3. Run session start + explicit checks in pipeline bootstrap:

```powershell
.\tools\session-autostart.cmd
```

4. End with closure artifact + memory save:

```powershell
.\tools\session-manual-end.cmd
```

Operational tip:

- Keep `strictCompatibilityChecks: true` in stable environments.
- If environment has intermittent outbound restrictions, classify network update warnings as non-blocking (already supported by current flow).

### 3) SaaS-Contracted Agent Environments

Use this when core reasoning/runtime is external but repo governance remains local.

Integration baseline:

1. Keep repository-side governance active:
   - `wf.ps1 start-session`
   - `wf.ps1 end-session` or `wf.ps1 day-end-closure`
2. Keep `engram` as shared memory source from repo side.
3. Use `agent-router.ps1 status` as readiness contract for role lanes.
4. Capture artifacts in `docs/sessions`, `docs/audits`, `docs/code-reviews`.

decisión rule:

- SaaS agent can execute reasoning, but repository remains source of truth for:
  - policy checks
  - session lifecycle
  - closure evidence
  - docs/spec updates

## Conflict Matrix

| Component A | Component B | Conflict Risk | Notes |
|---|---|---|---|
| Runtime router | Orchestrator skills | Low | Router selects native available runtime; orchestrator governs workflow/skills. |
| `engram` | Orchestrator memory integration | Low | Native complement; required by token guard policy. |
| Agent lanes (`agent-router`) | Session governance | Low | Registry status is used as readiness gate. |
| Update checks (network) | Strict startup | Medium | Treat as non-critical; avoid blocking startup on update warnings. |

## Recommended Default Policy

- `strictCompatibilityChecks: true`
- `autoStartPrimaryRuntime: true`
- `enableIdleAutoClose: true`
- `idleTimeoutMinutes: 60`

If startup fails in strict mode:

1. Run diagnostics:

```powershell
.\tools\validate-session-stack.ps1 -Quiet
.\workspace-foundation\scripts\utilities\wf.ps1 orchestrator-status
.\workspace-foundation\scripts\utilities\wf.ps1 runtime-route
.\workspace-foundation\scripts\utilities\agent-router.ps1 status
```

2. Resolve missing pieces and retry startup.
3. Use degraded mode only as temporary workaround.

## Operational Checklist

- [ ] Session starts via `session-autostart.cmd`
- [ ] Compatibility checks pass
- [ ] Orchestrator status is green
- [ ] Agent lanes are `READY`
- [ ] Engram memory path available
- [ ] Session closure artifact generated at end of cycle
