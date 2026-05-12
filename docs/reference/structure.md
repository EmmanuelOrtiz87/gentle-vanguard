# Recommended Structure

The goal is to clearly separate:

- projects
- external tools
- local data
- documentation
- reusable skills

## Start Here

1. Keep the workspace root stable.
2. Keep tool repositories separate from project repositories.
3. Keep reusable skills in the workspace kit and install them into Codex when needed.
4. Keep runtime data in a workspace-resolved location so the setup remains portable across machines.
5. Keep documentation in the project tree.
6. Use the template structure consistently for new projects.

## Workspace Level

- `{workspaceRoot}/` (workspace root)
- `{workspaceRoot}/Workspace-Skills`
- `{workspaceRoot}/foundation`
- `{workspaceRoot}/foundation/.engram-data`
- `{workspaceRoot}/foundation/skills`

## Project Level

Every new project should contain:

- `README.md`
- `AGENTS.md`
- `ARCHITECTURE.md`
- `docs/project-context.md`
- `docs/`
- `scripts/`
- `config/` if the project uses declarative configuration
- `.env.example`
- `templates/` only if the project generates its own artifacts or scaffolding

## Templates

- `templates/project-root/` contains the shared base.
- `templates/project-types/` contains overlays for `service`, `cli`, and `library`.
- `scripts/new-project.ps1` and `scripts/new-project.sh` create projects with the same interface.
- `scripts/run-engram.ps1` and `scripts/run-engram.sh` launch Engram with isolated state.
- `skills/documentation-governance/` contains the reusable documentation skill.
- `skills/architecture-governance/` contains the reusable architecture skill.

## Golden Rule

No project should depend on an embedded local copy of external tools.

## Portable Runtime Note

1. `config/workspace.config.json` should prefer workspace-resolved paths such as
   `{workspaceRoot}/.engram-data`.
2. `scripts/utilities/run-engram.ps1` creates the Engram session directory on first use.
3. A missing `.engram-data/` directory on a fresh machine is normal and should not block demos.
