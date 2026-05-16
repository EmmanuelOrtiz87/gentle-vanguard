# Validation Scripts

Scripts for validating and checking the gentle-vanguard.

## Scripts

| Script                   | Description                          |
| ------------------------ | ------------------------------------ |
| `validate-project.ps1`   | Validate project setup               |
| `validate-workspace.ps1` | Validate workspace configuration     |
| `check-updates.ps1`      | Check for available updates          |
| `update-all.ps1`         | Update gentle-vanguard, skills, and tools |

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

These can also be accessed via `gv` CLI:

```powershell
gv validate    # Validate installation
gv check      # Check for updates
gv update-all # Update everything
```


