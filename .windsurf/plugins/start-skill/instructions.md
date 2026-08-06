# start-skill

> Gentle-Vanguard Skill

## Description
>

## Triggers


## Instructions
# Start Command

> If you see unfamiliar placeholders or need to check which tools are connected, see
> [CONNECTORS.md](../../CONNECTORS.md).

Initialize the task and memory systems, then open the unified dashboard.

## Instructions

### 1. Check What Exists

Check the working directory for:

- `TASKS.md` — task list
- `CLAUDE.md` — working memory
- `memory/` — deep memory directory
- `dashboard.html` — the visual UI

### 2. Create What's Missing

**If `TASKS.md` doesn't exist:** Create it with the standard template (see task-management skill).
Place it in the current working directory.

**If `dashboard.html` doesn't exist:** Copy it from `${CLAUDE_PLUGIN_ROOT}/skills/dashboard.html` to
the current working directory.

**If `CLAUDE.md` and `memory/` don't exist:** This is a fresh setup — after opening the dashboard,
begin the memory bootstrap workflow (see `references/memory-bootstrap.md`).

### 3. Open the Dashboard

Do NOT use `open` or `xdg-open` — in Cowork, the agent runs in a VM and shell open commands won't
reach the user's browser. Instead, tell the user: "Dashboard is ready at `dashboard.html`. Open it
from your file browser to get started."

### 4. Orient the User

If everything was already initialized:

```
Dashboard open. Your tasks and memory are both loaded.
- /productivity:update to sync tasks and check memory
- /productivity:update --comprehensive for a deep scan of all activity
```

If memory hasn't been bootstrapped yet, see `references/memory-bootstrap.md`.

### 5. Bootstrap Memory (First Run Only)

Only do this if `CLAUDE.md` and `memory/` don't exist yet. See `references/memory-bootstrap.md`
for the full workflow: interactive task decoding → comprehensive scan → memory file creation.

### 6. Report Results

```
Productivity system ready:
- Tasks: TASKS.md (X items)
- Memory: X people, X terms, X projects
- Dashboard: open in browser

Use /productivity:update to keep things current (add --comprehensive for a deep scan).
```

## Notes

- If memory is already initialized, this just opens the dashboard
- Nicknames are critical — always capture how people are actually referred to
- If a source isn't available, skip it and note the gap
- Memory grows organically through natural conversation after bootstrap
