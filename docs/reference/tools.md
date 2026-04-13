# External Tools

The workspace foundation keeps external tools outside each project and versioned independently.

## Start Here

1. Treat tools as external dependencies, not project files.
2. Install or expose them in `PATH`.
3. Let the workspace bootstrap verify them through config.
4. Keep their state outside repository checkouts.
5. Prefer `checkPath` for cloned repositories and `checkCommand` for executables.
6. Install the workspace skills separately so documentation and architecture rules stay reusable across projects.

## Tool Contract

- `engram` handles memory and session persistence.
- `gga` handles review and quality gates.
- `gentleman-skills` provides reusable skills and rules as a cloned skills repository, not as a CLI.
- `documentation-governance` standardizes README files, technical docs, code reviews, and script comments.
- `architecture-governance` standardizes project structure decisions, defaults, and decision records.

## Installation Strategy

The repository does not vendor or patch these tools.
Instead, the workspace bootstrap reads a config file and uses one of these strategies:

- check whether the command already exists in `PATH`
- run a platform-specific installer command from config
- clone source into a sibling tools directory if the tool is distributed that way

## Platform Support

- Windows: PowerShell bootstrap with `pwsh` fallback to `powershell.exe`
- Linux: use the shell wrapper or invoke the PowerShell script with `pwsh`
- macOS: use the shell wrapper or invoke the PowerShell script with `pwsh`

## Windows Note

- `gga` can be installed automatically on Windows only if `bash` is available through Git Bash, WSL, or a similar environment.
- If `bash` is missing, the bootstrap warns and skips that installer instead of failing the whole setup.

## Engram Runtime State

- Run `scripts/project/init-workspace.ps1` or `scripts/git-hooks/init-workspace.sh` first so old embedded runtime state gets cleaned automatically.
- Use `scripts/utilities/run-engram.ps1` or `scripts/git-hooks/run-engram.sh` to launch Engram.
- The launcher creates the workspace data directory automatically and sets `ENGRAM_DATA_DIR` for that process.
- This keeps `.engram/` out of `engram-tool` and out of project checkouts.

## Customization

Edit `config/workspace.config.json` directly or replace it with `config/workspace.portable.example.json` if you want a portable baseline.
If you want the bootstrap to install tools automatically, fill the platform-specific commands for Windows, Linux, and macOS.
For repository-based skill packs, prefer `checkPath` so the bootstrap can verify the clone exists instead of looking for a fake executable.

## Validation

Use `scripts/validation/validate-workspace.ps1` or the equivalent PowerShell command on Linux/macOS.
