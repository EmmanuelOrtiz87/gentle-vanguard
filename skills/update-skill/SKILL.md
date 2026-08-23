---
name: update-skill
description: >
  Knowledge work plugin from productivity department.
metadata:
  source: knowledge-work-plugins
  original-name: update
  department: productivity
---

# Update Command

> If you see unfamiliar placeholders or need to check which tools are connected, see
> [CONNECTORS.md](../../CONNECTORS.md).

Keep your task list and memory current. Two modes:

- **Default:** Sync tasks from external tools, triage stale items, check memory for gaps
- **`--comprehensive`:** Deep scan chat, email, calendar, docs — flag missed todos and suggest new
  memories

## Usage

```bash
/productivity:update
/productivity:update --comprehensive
```

## Default Mode

1. [Load Current State](references/default-mode.md#1-load-current-state)
2. [Sync Tasks from External Sources](references/default-mode.md#2-sync-tasks-from-external-sources)
3. [Triage Stale Items](references/default-mode.md#3-triage-stale-items)
4. [Decode Tasks for Memory Gaps](references/default-mode.md#4-decode-tasks-for-memory-gaps)
5. [Fill Gaps](references/default-mode.md#5-fill-gaps)
6. [Capture Enrichment](references/default-mode.md#6-capture-enrichment)
7. [Report](references/default-mode.md#7-report)

## Comprehensive Mode (`--comprehensive`)

Everything in Default Mode, plus:

1. [Scan Activity Sources](references/comprehensive-mode.md#1-scan-activity-sources)
2. [Flag Missed Todos](references/comprehensive-mode.md#2-flag-missed-todos)
3. [Suggest New Memories](references/comprehensive-mode.md#3-suggest-new-memories)

## Notes

- Never auto-add tasks or memories without user confirmation
- External source links are preserved when available
- Fuzzy matching on task titles handles minor wording differences
- Safe to run frequently — only updates when there's new info
- `--comprehensive` always runs interactively

## Examples

Concrete usage drawn from this skill's own documentation:

```bash
/productivity:update
/productivity:update --comprehensive
```
