---
name: gentle-vanguard-manager-skill
description:
  "Trigger: 'auto-update', 'self-update', 'update skill', 'sync workspace', 'maintenance', 'manage
  workspace'. Auto-update and self-maintenance for the gentle-vanguard workspace. Integrates with
  session-autostart to keep skills current and workspace aligned."
---

# gentle-vanguard-manager-skill (FF-017)

Auto-update and self-maintenance skill for the gentle-vanguard workspace.

## Description

Manages skill updates, workspace synchronization, and auto-maintenance workflows. Integrates with
session-autostart to keep skills current and workspace aligned.

## Triggers

- auto-update
- self-update
- update skill
- sync workspace
- maintenance

## Dependencies

- git (for pulling updates)
- session-autostart (for lifecycle hooks)

## Auto-Update Pattern

1. On session start, check skills/ for outdated entries
2. If git remote available, `git pull` to refresh
3. Rebuild skill registry via build-skill-registry.ps1
4. Log any conflicts or changes
5. Verify integrity of updated skills and validate no broken references

## Maintenance Tasks

- Skill registry rebuild
- Cross-reference validation
- Workspace homologation
- Config sync from remote
