# External Tools

The gentle-vanguard keeps external tools outside each project and versióned independently.

## Start Here

1. Treat tools as external dependencies, not project files.
2. Install or expose them in `PATH`.
3. Let the workspace bootstrap verify them through config.
4. Keep their state outside repository checkouts.
5. Prefer `checkPath` for cloned repositories and `checkCommand` for executables.
6. Install the workspace skills separately so documentation and architecture rules stay reusable
   across projects.

## Tool Contract

- `engram` handles memory and session persistence.
- Gentle-Vanguard native review handles review and quality gates.
- `documentation-governance` standardizes README files, technical docs, code reviews, and script
  comments.
- `architecture-governance` standardizes project structure decisións, defaults, and decisión
  records.

## Installation Strategy

The repository does not vendor or patch these tools. Instead, the workspace bootstrap reads a config
file and uses one of these strategies:

- check whether the command already exists in `PATH`
- run a platform-specific installer command from config
- clone source into a sibling tools directory if the tool is distributed that way

## Platform Support

- Windows: PowerShell bootstrap with `pwsh` fallback to `powershell`
- Linux: use the shell wrapper or invoke the PowerShell script with `pwsh`
- macOS: use the shell wrapper or invoke the PowerShell script with `pwsh`

## Portability Notes

1. Tool installation metadata is resolved per platform from `config/workspace.config.json`.
2. `ensure-tools-active.ps1` and `update-tools.ps1` no longer assume platform-specific paths for
   home directories, PATH updates, or tool verification.
3. The stack is OS-aware and wrapper-friendly, but the canonical automation layer is still
   PowerShell.
4. Bash remains a useful cross-platform capability for shell-based helper utilities.

## Windows Note

- If optional shell-based tooling is unavailable, bootstrap warns and continues without blocking
  required capabilities.

## AI Tool Neutrality

1. The workspace can operate with different AI tools and editors.
2. `opencode`, `engram`, and related settings are configurable defaults, not exclusive runtime
   requirements.
3. Missing optional AI tools should degrade gracefully instead of blocking bootstrap.

## Engram Runtime State

- Run `scripts/project/init-workspace.ps1` or `scripts/git-hooks/init-workspace.sh` first so old
  embedded runtime state gets cleaned automatically.
- Use `scripts/utilities/run-engram.ps1` or `scripts/git-hooks/run-engram.sh` to launch Engram.
- The launcher creates the workspace data directory automatically and sets `ENGRAM_DATA_DIR` for
  that process.
- This keeps `.engram/` out of tool and project checkouts.

## Customization

Edit `config/workspace.config.json` directly or replace it with
`config/workspace.portable.example.json` if you want a portable baseline. If you want the bootstrap
to install tools automatically, fill the platform-specific commands for Windows, Linux, and macOS.
For repository-based skill packs, prefer `checkPath` so the bootstrap can verify the clone exists
instead of looking for a fake executable.

## Validation

Use `scripts/validation/validate-workspace.ps1` or the equivalent PowerShell command on Linux/macOS.

