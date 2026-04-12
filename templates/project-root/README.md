# Project Name

Brief description of the project.

## Quick Start

1. Review `docs/project-context.md` for the selected defaults.
2. Replace the placeholder commands below with the project-specific ones.
3. Start each substantial session with:

```powershell
.\scripts\start-session.ps1
```

4. Run the validation or start command recorded for this project.
5. Ask the project orchestrator for the next steps:

```powershell
.\scripts\orchestrator-next-steps.ps1
```

6. Before opening a new chat thread, generate a compact handoff summary:

```powershell
.\scripts\compact-start.ps1 "current objective"
```

7. Paste the generated compact prompt (already copied to clipboard) in the new thread.

8. Review weekly usage metrics to monitor token/context optimization adoption:

```powershell
.\scripts\context-metrics-report.ps1
.\scripts\context-metrics-report.ps1 -Days 14
```

```text
<build-command>
<test-command>
<run-command>
```

## Notes

- External tools are consumed by command and not vendored in the repo.
- Keep data outside the project tree.
- Use `docs/project-context.md` to record the first architecture, scope, and AI model decisions.
- Use `docs/sessions/` and `docs/tasks/` to keep session and task scope explicit.
- Use `docs/sessions/*-context-pack.md` to keep token usage low while preserving continuity.
