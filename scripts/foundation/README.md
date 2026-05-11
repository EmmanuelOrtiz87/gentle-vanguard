# Foundation Scripts

Scripts for installing and maintaining the foundation.

## Scripts

| Script                    | Description                                                  |
| ------------------------- | ------------------------------------------------------------ |
| `setup.sh`                | Cross-platform foundation setup entrypoint (Linux/macOS/WSL) |
| `bootstrap-machine.ps1`   | Install foundation globally on machine                       |
| `bootstrap-workspace.ps1` | Bootstrap workspace with skills and tools                    |
| `bootstrap.ps1`           | Main bootstrap script                                        |
| `sync-skills.ps1`         | Sync skills from source to global                            |
| `wf.ps1`                  | Main CLI entry point (alias: gf)                             |
| `export-profile.ps1`      | Export user profile (engram, opencode, binarios) to ZIP for migration |
| `import-profile.ps1`      | Import user profile from ZIP on a new PC                    |
| `setup-multi-machine.ps1`| Clone and bootstrap repos on a new PC                        |

## Usage

```powershell
# Install foundation globally (~/.gentleman/)
.\bootstrap-machine.ps1

# Sync skills to global installation
.\sync-skills.ps1 -Force

# Update everything
.\scripts\validation\update-all.ps1
```
