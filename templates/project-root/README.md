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
