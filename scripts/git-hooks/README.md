# Git Hooks

Git hooks for pre-commit validation and security.

## Files

| File          | Description                        |
| ------------- | ---------------------------------- |
| `pre-commit/` | Pre-commit hooks directory         |
| `*.sh`        | Shell alternatives for Linux/macOS |

## Pre-commit Hooks

The `pre-commit/` directory contains:

- `pre-commit.ps1` - PowerShell pre-commit hook
- Shell alternatives for cross-platform support

## Usage

Hooks are automatically installed by:

- `bootstrap-machine.ps1` (global)
- `setup-project.ps1` (project)

## Manual Installation

```powershell
# Configure git to use hooks
git config --global core.hooksPath "$env:USERPROFILE\.git-hooks"
```
