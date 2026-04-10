# Scripts Directory

Automation scripts for Gentleman Foundation.

## Structure

```
scripts/
├── foundation/      # Installation and bootstrap
├── project/         # Project creation and setup
├── validation/      # Validation and checks
├── git-hooks/       # Git hooks (PowerShell and Shell)
└── utilities/       # Utility scripts
```

## Foundation

| Script | Purpose |
|--------|---------|
| `bootstrap-machine.ps1` | Install foundation globally on machine |
| `bootstrap-workspace.ps1` | Bootstrap workspace with skills |
| `bootstrap.ps1` | Main bootstrap script |
| `sync-skills.ps1` | Sync skills to global |
| `wf.ps1` | Main CLI entry point |

## Project

| Script | Purpose |
|--------|---------|
| `setup-project.ps1` | Setup existing project with foundation |
| `create-new-project.ps1` | Create new project from template |
| `init-workspace.ps1` | Initialize workspace |
| `migrate.ps1` | Migrate existing project |
| `new-project.ps1` | Create new project |

## Validation

| Script | Purpose |
|--------|---------|
| `validate-project.ps1` | Validate project setup |
| `validate-workspace.ps1` | Validate workspace |
| `check-updates.ps1` | Check for updates |
| `update-all.ps1` | Update everything |

## Utilities

| Script | Purpose |
|--------|---------|
| `wf.ps1` | Workflow CLI - review, audit, pr, push |
| `deploy.ps1` | Deploy project |
| `clean-runtime.ps1` | Clean runtime data |
| `generate-*.ps1` | Generate reports and audits |
| `run-*.ps1` | Run tools (engram, gga) |
| `aggregate-metrics.ps1` | Aggregate metrics |

## Workflow CLI (wf.ps1)

Automated development workflow commands.

```powershell
# Show help
.\wf.ps1 help

# Show status
.\wf.ps1 status

# Run code review
.\wf.ps1 review
.\wf.ps1 review security

# Generate audit document
.\wf.ps1 audit

# Create PR template
.\wf.ps1 pr

# Prepare to push
.\wf.ps1 push
```

## Quick Reference

```powershell
# Install foundation
.\scripts\foundation\bootstrap-machine.ps1

# Setup project
.\scripts\project\setup-project.ps1 -ProjectPath "path\to\project"

# Validate
.\scripts\validation\validate-project.ps1

# Check updates
.\scripts\validation\check-updates.ps1

# Code review
.\wf.ps1 review

# Audit document
.\wf.ps1 audit
```
