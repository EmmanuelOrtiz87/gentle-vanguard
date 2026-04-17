# Sessions

This directory stores generated session lifecycle artifacts.

## Purpose

1. Track session starts, context packs, and closure outputs.
2. Preserve continuity between work blocks and day-end handoffs.
3. Support orchestrator and operator workflows with concrete artifacts.

## Common Artifacts

- `*-session-start.md` - session brief snapshot
- `*-context-pack.md` - compact context handoff summary
- `*-delivery-closure.md` - operational closure output
- `closure-report-*.md` - day-end consolidated closure report

## Metrics

Session telemetry files are under `docs/sessions/metrics/`.

## Generation Commands

```powershell
.\scripts\utilities\wf.ps1 start-session
.\scripts\utilities\wf.ps1 compact-start "<objective>"
.\scripts\utilities\wf.ps1 end-session
.\scripts\utilities\wf.ps1 day-end-closure
```

## Related

- `docs/guides/SESSION-GUIDE.md`
- `docs/guides/DAY-END-CLOSURE.md`
- `docs/guides/ARTIFACT-RETENTION.md`
