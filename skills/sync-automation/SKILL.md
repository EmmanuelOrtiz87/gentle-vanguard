---
name: sync-automation
description:
  Auto-sync for Gentle-Vanguard. Automates synchronization between local Gentle-Vanguard and public
  repository.
metadata:
  source: GV-native
---

# sync-automation

# Auto-sync for Gentle-Vanguard

## Trigger

"sync", "public repo", "auto-sync"

## Description

Automates synchronization between local Gentle-Vanguard and public repository.

## Execution

1. Check `config/sync-config.json` for settings
2. Run `scripts/utilities/gentle-vanguard-sync.ps1 -Mode sync`
3. Validate sync with `git status` and `git log`
4. Report sync status to user

## Notes

- Supports auto-sync via git hooks or scheduled tasks
- Logs sync activity to `.runtime/sync-log.csv`
