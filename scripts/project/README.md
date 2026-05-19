# Project Scripts

Scripts for creating and managing projects.

## Scripts

| Script               | Description                                 |
| -------------------- | ------------------------------------------- |
| `setup-project.ps1`  | Setup existing project with gentle-vanguard |
| `new-project.ps1`    | Create new project (canonical entrypoint)   |
| `init-workspace.ps1` | Initialize workspace                        |
| `migrate.ps1`        | Migrate existing project to gentle-vanguard |

## Usage

```powershell
# Setup existing project
.\setup-project.ps1 -ProjectPath "C:\my-project"

# Create new project
.\new-project.ps1 -Name "my-api" -Kind "service"

# Initialize workspace
.\init-workspace.ps1
```
