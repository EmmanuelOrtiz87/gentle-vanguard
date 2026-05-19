---
name: daily-workflow
description: >
  Daily Gentle-Vanguard tasks: status check, context tracking, audit, and sync verification.
  Trigger: "daily check", "daily workflow", "morning routine", "start day", "daily tasks".
---

# Daily Workflow Skill

## Trigger

"daily check", "daily workflow", "morning routine", "start day", "daily tasks"

## Description

Automates daily Gentle-Vanguard tasks: status check, context tracking, audit, and sync verification.

## Workflow

### Morning Routine

1. Run `gv daily-check` - Quick status (git, stack health, context)
2. Run `gv compact-start "objective"` - Initialize context tracking
3. Check public repo sync: `cd gentle-vanguard-public && git pull`

### Daily Tasks

- **Check stack health**: `gv verify`
- **Review audits**: Check `docs/audits/` for recent reports
- **Sync public repo**: Ensure installer and docs are current
- **Context efficiency**: Monitor prompt chars and adoption rate

### Evening Routine

1. Run `gv status` - Final status check
2. Commit pending work with proper conventional commits
3. Push to private repo
4. Update public repo if needed

## Commands Reference

| Command                  | Purpose                                |
| ------------------------ | -------------------------------------- |
| `gv daily-check`         | Morning status (git + stack + context) |
| `gv compact-start "obj"` | Start context tracking                 |
| `gv verify`              | 14 quality gates                       |
| `gv status`              | Context efficiency + git status        |
| `gentle-vanguard audit`  | Generate audit report                  |

## Key Files

- `scripts/utilities/WORKFLOW-ORCHESTRATION/daily-check.ps1`
- `scripts/utilities/WORKFLOW-ORCHESTRATION/compact-start.ps1`
- `scripts/utilities/gv.ps1`
- `docs/audits/` - Audit reports

## Notes

- Keep $env:GENTLE_VANGUARD_VERBOSE empty for quiet operation
- Public repo: https://github.com/EmmanuelOrtiz87/gentle-vanguard-public
- Private repo: https://github.com/EmmanuelOrtiz87/gentle-vanguard
