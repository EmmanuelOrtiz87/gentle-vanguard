---
name: daily-workflow
description: >
  Daily Foundation tasks: status check, context tracking, audit, and sync verification.
  Trigger: "daily check", "daily workflow", "morning routine", "start day", "daily tasks".
---

# Daily Workflow Skill

## Trigger
"daily check", "daily workflow", "morning routine", "start day", "daily tasks"

## Description
Automates daily Foundation tasks: status check, context tracking, audit, and sync verification.

## Workflow

### Morning Routine
1. Run `wf daily-check` - Quick status (git, stack health, context)
2. Run `wf compact-start "objective"` - Initialize context tracking
3. Check public repo sync: `cd foundation-public && git pull`

### Daily Tasks
- **Check stack health**: `wf verify`
- **Review audits**: Check `docs/audits/` for recent reports
- **Sync public repo**: Ensure installer and docs are current
- **Context efficiency**: Monitor prompt chars and adoption rate

### Evening Routine
1. Run `wf status` - Final status check
2. Commit pending work with proper conventional commits
3. Push to private repo
4. Update public repo if needed

## Commands Reference
| Command | Purpose |
|---------|---------|
| `wf daily-check` | Morning status (git + stack + context) |
| `wf compact-start "obj"` | Start context tracking |
| `wf verify` | 14 quality gates |
| `wf status` | Context efficiency + git status |
| `wf audit` | Generate audit report |

## Key Files
- `scripts/utilities/WORKFLOW-ORCHESTRATION/daily-check.ps1`
- `scripts/utilities/WORKFLOW-ORCHESTRATION/compact-start.ps1`
- `scripts/utilities/wf.ps1`
- `docs/audits/` - Audit reports

## Notes
- Keep $env:FOUNDATION_VERBOSE empty for quiet operation
- Public repo: https://github.com/EmmanuelOrtiz87/foundation-public
- Private repo: https://github.com/EmmanuelOrtiz87/gentleman-foundation
