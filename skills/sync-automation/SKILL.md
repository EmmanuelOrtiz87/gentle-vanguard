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
2. Run `src/engram-auto-sync.ts -Mode sync`
3. Validate sync with `git status` and `git log`
4. Report sync status to user

## Notes

- Supports auto-sync via git hooks or scheduled tasks
- Logs sync activity to `.runtime/sync-log.csv`

## Usage

Use **sync-automation** when a task matches its triggers (sync-automation).

Purpose: Auto-sync for Gentle-Vanguard.

## Examples

**Input:** a task matching `sync-automation` triggers.
**Action:** apply the workflow described above.
**Expected result:** Auto-sync for Gentle-Vanguard.
