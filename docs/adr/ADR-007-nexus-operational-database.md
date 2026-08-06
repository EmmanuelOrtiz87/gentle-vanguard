# ADR-007: Nexus Operational Database

## Status

Accepted

## Date

2026-07-26

## Context

The Gentle-Vanguard stack originally persisted operational data (metrics, sessions, traces, events,
alerts, feedback) across multiple fragmented JSON files in `.session/context-log/` and similar
directories. This approach had several problems:

1. **No ACID guarantees** — concurrent writes could corrupt data
2. **No schema enforcement** — each writer used its own format
3. **No query capability** — aggregating data required reading and parsing multiple JSON files
4. **No relationship tracking** — sessions, traces, and events were stored in isolation
5. **No data lifecycle** — old data accumulated indefinitely without pruning

Separately, new components needed persistence: response cache (Wave 35), contract results (Wave 36),
skill usage tracking, token accounting, routing rules, and session scoring (Wave 37). Each would
have required its own JSON file without a unified solution.

Additionally, the database lacked a formal identity — it was referred to simply as
`gentle-vanguard.db` without the architectural presence that components like Engram, CodeGraph, and
Graphify have.

## Decision

### Phase 1: SQLite Foundation (Wave 34)

Replace all JSON file persistence with a single SQLite database (`gentle-vanguard.db`) in WAL mode:

- **DatabaseManager singleton** in `apps/web-dashboard/server/database/manager.ts`
- **Migration system** with idempotent `_migrations` tracking table
- **Migration 001** — Core operational tables: `metric_snapshots`, `sessions`, `traces`, `events`,
  `alerts`, `feedback`
- **WAL mode** for concurrent read/write without locks
- **Foreign keys ON** for referential integrity
- Autostart pipeline integration via `db-init` lazy step

### Phase 2: Stack Tables (Wave 35-36)

Migration 002 added operational tables:

- `response_cache` — SHA256 key → response with TTL and hit_count
- `contract_results` — SDD contract validation (pass/fail/error)
- `skill_usage` — Per-session skill usage with tokens and cost
- `token_usage` — Token accounting with generated `total_tokens` column
- `routing_rules` — Adaptive router persistence with hit_count

### Phase 3: Session Scoring (Wave 37)

Migration 003 added `session_scoring` table for quality metrics per session: delegations,
corrections, proactive hits, cloud calls, checkpoints, tracing spans, audit events.

### Phase 4: Identity (Wave 37.5)

The database was formally named **Nexus** — the central point where all operational data converges.
This included:

- `rules/NEXUS-NORMATIVA.md` — identity, lifecycle, guardrails, retention policy
- `skills/nexus-database/SKILL.md` — autonomous management skill
- `AGENTS.md` updated with Nexus identity section
- `skills/SKILL_INDEX.md` and `skill-router.ts` — Nexus registered as routable skill
- `rules/RECOVERY-NORMATIVA.md` — Nexus listed as critical component

## Consequences

### Positive

- **ACID transactions** for all operational data
- **Single backup/restore** point for the entire operational stack
- **Query capability** via SQL across all data domains
- **Migration system** enables schema evolution with version tracking
- **12 tables, 3 migrations** covering all operational needs
- **Auto-init, auto-prune, auto-backup** via lazy pipeline steps (53 steps total)
- **Watchtower monitoring** with 98 checks including DB-specific checks
- **Identity** as a first-class stack component (Nexus)

### Negative

- **SQLite dependency** — requires `better-sqlite3` and `sqlite3` CLI
- **Single-writer limitation** — though mitigated by WAL mode
- **Additional migration burden** — schema changes require versioned migrations
- **File size** — single file grows; mitigated by pruneAll() and housekeeping

## Alternatives Considered

### PostgreSQL

- Pros: Production-grade, concurrent, networked
- Cons: Heavy for a local development stack; requires server setup; violates local-first principle
- Rejected: Overkill for single-developer local stack

### Continue with JSON files

- Pros: No new dependencies, simple
- Cons: No ACID, no queries, no relationships, fragmentation
- Rejected: Does not scale to the stack's operational needs

### Multiple SQLite databases (one per domain)

- Pros: Independent lifecycle per domain
- Cons: No cross-domain queries, more complex backup/restore
- Rejected: Nexus is designed for cross-domain correlation (e.g., session → traces → scoring)
