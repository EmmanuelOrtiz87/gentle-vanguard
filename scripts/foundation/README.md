# Foundation Scripts

Scripts for installing and maintaining the foundation.

## Scripts

| Script | Description |
|--------|-------------|
| `bootstrap-machine.ps1` | Install foundation globally on machine |
| `bootstrap-workspace.ps1` | Bootstrap workspace with skills and tools |
| `bootstrap.ps1` | Main bootstrap script |
| `sync-skills.ps1` | Sync skills from source to global |
| `wf.ps1` | Main CLI entry point (alias: gf) |

## Usage

```powershell
# Install foundation globally (~/.gentleman/)
.\bootstrap-machine.ps1

# Sync skills to global installation
.\sync-skills.ps1 -Force

# Update everything
.\scripts\validation\update-all.ps1
```
