# Validation Scripts

Scripts for validating and checking the foundation.

## Scripts

| Script | Description |
|--------|-------------|
| `validate-project.ps1` | Validate project setup |
| `validate-workspace.ps1` | Validate workspace configuration |
| `check-updates.ps1` | Check for available updates |
| `update-all.ps1` | Update foundation, skills, and tools |

## Usage

```powershell
# Validate project
.\validate-project.ps1

# Check system status
.\check-updates.ps1 -All

# Update everything
.\update-all.ps1 -All -Force
```

## CLI Access

These can also be accessed via `gf` CLI:

```powershell
gf validate    # Validate installation
gf check      # Check for updates
gf update-all # Update everything
```
