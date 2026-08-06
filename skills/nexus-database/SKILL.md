---
name: nexus-database
description: >
  Manage Nexus — the operational SQLite database of Gentle-Vanguard. Init, health check, backup,
  restore, prune, optimize, and monitor the 12-table schema. Nexus stores all operational data:
  metrics, sessions, traces, events, alerts, feedback, cache, contracts, scoring, and routing rules.
metadata:
  source: GV-native
  trigger: nexus, db, database, operational-db, gentle-vanguard.db
---

# Nexus Database Skill

## Overview

**Nexus** is the central operational database of the Gentle-Vanguard stack
(`.runtime/gentle-vanguard.db`). It replaces the fragmented JSON-file persistence with a single ACID
SQLite database in WAL mode.

This skill teaches agents how to manage Nexus autonomously: init, health check, backup, restore,
prune, optimize, and interpret the watchtower monitoring.

## When to Use

- **Session start**: Nexus auto-initializes via `db-init` lazy step — no action needed
- **Health check**: When investigating DB issues, performance degradation, or before/after schema
  changes
- **Backup**: Before any risky operation, or for offsite/cloud backup
- **Restore**: When corruption is detected or rollback needed
- **Prune**: When disk space is low or data retention policy needs enforcement
- **Schema changes**: Contact the DatabaseManager migration system — never raw SQL on production
  data

## Quick Commands

```bash
# Init + run all pending migrations (idempotent)
npm run db:init

# Health check (6-point: file, size, WAL, integrity, tables, rows, migrations)
npm run db:health
npm run db:health -- --json     # Machine-readable for automation

# Online safe backup
npm run db:backup
npm run db:backup -- --dir D:\backups   # Custom path

# List available backups
npm run db:list

# Restore latest or specific backup
npm run db:restore                     # Latest
npm run db:restore -- <backup-name>    # Specific

# Optimize (WAL checkpoint + REINDEX + VACUUM)
npm run db:optimize

# Prune old data (events >30d, cache >7d, tokens >90d, orphaned skills)
npm run db:prune

# Prune backups (keep 10 most recent)
npm run db:prune:backup
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Nexus DB                            │
│              .runtime/gentle-vanguard.db                  │
│                   (WAL mode, FK ON)                      │
│                                                          │
│  ┌─── 001_initial_schema ───────────────────────────┐    │
│  │ metric_snapshots │ sessions │ traces │ events    │    │
│  │ alerts │ feedback                                   │    │
│  └──────────────────────────────────────────────────────┘    │
│  ┌─── 002_stack_tables ───────────────────────────────┐    │
│  │ response_cache │ contract_results │ skill_usage   │    │
│  │ token_usage │ routing_rules                          │    │
│  └──────────────────────────────────────────────────────┘    │
│  ┌─── 003_session_scoring ───────────────────────────┐    │
│  │ session_scoring                                      │    │
│  └──────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

## DatabaseManager API

The `DatabaseManager` singleton (`apps/web-dashboard/server/database/manager.ts`) is the
authoritative interface for all Nexus operations:

| Method                 | Purpose                                      |
| ---------------------- | -------------------------------------------- |
| `getInstance()`        | Get singleton (auto-creates DB + migrations) |
| `runMigrations()`      | Apply pending migrations (idempotent)        |
| `insertMetricSnapshot` | Record time-series metrics                   |
| `upsertSession`        | Create or update session record              |
| `insertTrace`          | Record distributed tracing span              |
| `insertEvent`          | Append event to event store                  |
| `insertAlert`          | Record alert evaluation                      |
| `insertFeedback`       | Record user feedback                         |
| `pruneAll()`           | Delete old data per retention policy         |
| `housekeeping()`       | Compact metric_snapshots, alerts, vacuum     |
| `close()`              | Close connection gracefully                  |
| `getDb()`              | Raw better-sqlite3 instance for advanced use |

## Retention Policy

| Table              | Retention | Why                               |
| ------------------ | --------- | --------------------------------- |
| `events`           | 30 days   | Event sourcing — debugging window |
| `response_cache`   | 7 days    | Fast-changing data                |
| `token_usage`      | 90 days   | Cost trending needs history       |
| `metric_snapshots` | 1000 rows | Sufficient for trend analysis     |
| `alerts`           | 500 rows  | Latest alerts only                |
| Others             | ∞         | Permanent operational data        |

## Watchtower Monitoring

The `gentle-vanguard-db` component in maintenance-watchtower checks:

1. **database file** — exists, size in MB
2. **WAL file** — size (>5MB = WARN, needs checkpoint)
3. **integrity check** — PRAGMA integrity_check
   - `PASS` → DB is clean
   - `WARN` → Transient issue (DB locked by another process, sqlite3 CLI unavailable)
   - `FAIL` → Definite corruption detected
4. **size** — table count and total rows

If integrity check FAILs:

```bash
# 1. Run detailed health check
npm run db:health -- --json

# 2. Try WAL checkpoint + REINDEX
npm run db:optimize

# 3. If still failing, restore from backup
npm run db:restore latest

# 4. If no backup, re-init (creates empty DB, reruns migrations)
npm run db:init
```

## Pipeline Integration

Nexus runs in the session autostart pipeline via 3 lazy steps:

| Step              | Script                                | When                |
| ----------------- | ------------------------------------- | ------------------- |
| `db-init`         | `src/database/db-init.ts`             | Every session start |
| `db-health-check` | `scripts/recovery/db-health-check.ts` | Every session start |
| `db-prune`        | `scripts/database/db-prune.ts`        | Every session start |

These are non-blocking (`lazy: true`, `onStepFailure: continue`).

## Guardrails

1. **Always use DatabaseManager** — never raw SQL migrations outside the manager
2. **Prefer `.backup`/`.restore` CLI** — safe for live databases (online backup)
3. **Check health before/after** any schema or data operation
4. **Prune regularly** — the lazy pipeline step handles this automatically
5. **Monitor WAL size** — large WAL = performance degradation
6. **Handle transient locks** — integrity check WARN does not mean corruption
7. **Backup before restore** — never overwrite without a recovery point
