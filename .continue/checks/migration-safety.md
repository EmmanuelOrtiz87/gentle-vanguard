---
name: Migration Safety
description: Catch destructive database or config migrations
---

If no migration files were added or changed, no action is needed.

When migrations are present, look for:

- `DROP TABLE` or `DROP COLUMN` without preceding backup/migration step -- add data migration step
- Column type narrowing (e.g., `TEXT` to `VARCHAR(50)`, `BIGINT` to `INT`) without backfill -- add backfill/guard
- `NOT NULL` constraint added to existing column without `DEFAULT` value -- add default or backfill
- Renaming a column/table referenced by code without updating references in same PR -- update references
- Destructive + constructive changes in same migration file -- split for safe rollback
- Config JSON schema changes without backward-compatible defaults
