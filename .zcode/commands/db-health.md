---
name: db-health
description: Check Nexus operational database health (integrity, WAL, tables, rows)
---

Verify the Nexus SQLite operational database (`.runtime/gentle-vanguard.db`):

1. `npm run db:health` — integrity, WAL mode, table count, row counts.
2. If health reports issues, run `npm run db:init` (idempotent, runs migrations) then re-check.
3. For deeper stack-wide health, suggest `npm run watchtower:health`.

Report status of each check and any corrective action taken.
