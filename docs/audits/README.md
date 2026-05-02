# Audits

This directory stores generated audit reports produced by `wf.ps1 audit` and session/day-end closure workflows.

## Purpose

1. Provide operational and governance visibility for current repository state.
2. Capture delivery readiness, risk posture, and context-efficiency indicators.
3. Preserve an auditable timeline for release and retrospective decisións.

## File Naming

- `YYYY-MM-DD-HHmmss-audit.md`

## Generation Commands

```powershell
.\scripts\utilities\wf.ps1 audit
.\scripts\utilities\wf.ps1 day-end-closure
```

## Retention

- Repo retention is managed by `scripts/utilities/rotate-artifacts.ps1`.
- Current policy keeps the latest repo artifacts and archives older ones under `docs/.local-archive/`.

## Related

- `docs/guides/AUDIT-WORKFLOW.md`
- `docs/guides/ARTIFACT-RETENTION.md`

