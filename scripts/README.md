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
| `new-project.ps1` | Create new project (canonical entrypoint) |
| `init-workspace.ps1` | Initialize workspace |
| `migrate.ps1` | Migrate existing project |

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
| `start-session.ps1` | Create session brief and task brief artifacts |
| `deploy.ps1` | Deploy project |
| `clean-runtime.ps1` | Clean runtime data |
| `generate-*.ps1` | Generate reports and audits |
| `run-*.ps1` | Run tools (engram, gga) |
| `aggregate-metrics.ps1` | Aggregate metrics |
| `orchestrator-status.ps1` | Comprobar orquestador + Engram |
| `install-engram.ps1` | Instalar o verificar Engram CLI |
| `custom-rules.ps1` | Load and report custom technical/business/review rules |
| `response-mode.ps1` | Manage communication language, detail level, and compression profile |
| `foundation-sync.ps1` | Sync managed Foundation assets into consumer repositories |

## Workflow CLI (wf.ps1)

Automated development workflow commands.

```powershell
# Show help
.\scripts\utilities\wf.ps1 help

# Show status
.\scripts\utilities\wf.ps1 status

# Start session with normalized artifacts
.\scripts\utilities\wf.ps1 start-session
.\scripts\utilities\wf.ps1 start-session auth-hardening

# Close session with verification and closure artifact
.\scripts\utilities\wf.ps1 end-session
.\scripts\utilities\wf.ps1 end-session auth-hardening

# Run code review
.\scripts\utilities\wf.ps1 review
.\scripts\utilities\wf.ps1 review security

# Generate audit document
.\scripts\utilities\wf.ps1 audit

# Create PR template
.\scripts\utilities\wf.ps1 pr

# Prepare to push
.\scripts\utilities\wf.ps1 push

# Full update alias
.\scripts\utilities\wf.ps1 update-all

# Update repository, foundation, skills, and tools
.\scripts\utilities\wf.ps1 update

# Homologation workflow
.\scripts\utilities\wf.ps1 homologate
.\scripts\utilities\wf.ps1 homologate apply

# Foundation managed-asset sync (consumer repos)
.\scripts\utilities\wf.ps1 foundation-sync
.\scripts\utilities\wf.ps1 foundation-sync apply
.\scripts\utilities\wf.ps1 foundation-sync apply -CreatePr
```

## Quick Reference

```powershell
# Install foundation
.\scripts\foundation\bootstrap-machine.ps1

# Bootstrap workspace locally
.\scripts\foundation\bootstrap.ps1

# Setup project
.\scripts\project\setup-project.ps1 -ProjectPath "path\to\project"

# Validate
.\scripts\validation\validate-project.ps1

# Check updates
.\scripts\validation\check-updates.ps1

# Run full foundation update
.\scripts\validation\update-all.ps1

# Check orchestrator status
.\scripts\utilities\orchestrator-status.ps1
.\scripts\utilities\wf.ps1 orchestrator-status

# Check loaded custom rules
.\scripts\utilities\custom-rules.ps1 -Mode status
.\scripts\utilities\wf.ps1 custom-rules-status

# Check or set communication mode
.\scripts\utilities\wf.ps1 response-mode
.\scripts\utilities\wf.ps1 response-mode list
.\scripts\utilities\wf.ps1 response-mode profile:ultra
.\scripts\utilities\wf.ps1 response-mode language:pt-BR
.\scripts\utilities\wf.ps1 response-mode detail:expanded

# Create or refresh task brief only
.\scripts\utilities\wf.ps1 task-brief auth-hardening

# Install or verify Engram
.\scripts\utilities\install-engram.ps1
.\scripts\utilities\wf.ps1 install-engram

# Code review
.\scripts\utilities\wf.ps1 review

# Audit document
.\scripts\utilities\wf.ps1 audit
```
