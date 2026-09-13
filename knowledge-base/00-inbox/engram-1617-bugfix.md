---
created: 2026-07-13 22:54:29
tags: [engram, bugfix]
engram_id: 1617
type: bugfix
---

# SQLite schema-integrity fix and recovery infrastructure

**What**: Fixed dangerous schema-integrity.ts script that was blindly adding 'data' columns to all SQLite tables, corrupting CodeGraph and Engram databases. Built complete recovery infrastructure.

**Why**: The error "no such column: 'data'" blocked the entire stack. The root cause was scripts/recovery/schema-integrity.ts which had an addColumn() function that added 'data TEXT' to any table missing it — this corrupted schemas by adding columns where they didn't belong.

**Where**: scripts/recovery/schema-integrity.ts (rewrote to read-only), scripts/recovery/db-health-check.ts (new), scripts/recovery/db-restore.ts (new), rules/RECOVERY-NORMATIVA.md (updated), config/session-autostart.config.json (added db-health-check step)

**Learned**:
- NEVER create scripts that auto-modify database schemas without per-table validation
- The 'data' column is NOT part of canonical CodeGraph schema — it was incorrectly added
- WAL checkpoint TRUNCATE compacts WAL files (CodeGraph had 4.7MB WAL)
- Always use PRAGMA integrity_check before any DB operations
- SQLite databases need periodic WAL checkpoint + REINDEX for health

---
*Imported from Engram on 2026-09-06*
