# ADR-008: Session Scoring Quality Metrics

## Status

Accepted

## Date

2026-07-26

## Context

The Gentle-Vanguard stack needed a way to measure session quality objectively. Without quality
metrics, there was no way to:

1. **Detect degradation** — sessions becoming less effective over time
2. **Compare agent performance** — which sub-agents deliver better results
3. **Drive auto-correction** — trigger corrective actions when quality drops
4. **Evaluate the stack** — is each session more valuable than the last?

Existing data (token usage, tool calls, file changes) was available but fragmented across JSON files
and not correlated into a quality score.

## Decision

Implement Session Scoring as:

### Data Model (Migration 003)

```sql
CREATE TABLE session_scoring (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT NOT NULL,
  quality_score REAL DEFAULT 100,
  success_rate REAL DEFAULT 100,
  total_delegations INTEGER DEFAULT 0,
  total_corrections INTEGER DEFAULT 0,
  total_proactive INTEGER DEFAULT 0,
  proactive_hits INTEGER DEFAULT 0,
  total_cloud_calls INTEGER DEFAULT 0,
  total_checkpoints INTEGER DEFAULT 0,
  total_tracing_spans INTEGER DEFAULT 0,
  total_audit_events INTEGER DEFAULT 0,
  summary_json TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);
```

### Scoring Formula

```
quality_score = base(100) - corrections_weight + proactive_bonus + delegation_efficiency
```

Where:
- `base = 100` — perfect session starts at 100
- Each correction reduces the score
- Each proactive hit increases the score
- Delegation efficiency measures how well tasks are distributed

### Storage

- Stored in Nexus (`.runtime/gentle-vanguard.db`) via the DatabaseManager singleton
- Dual-write: JSON file + SQLite for backward compatibility during transition
- Upsert by session_id (one record per session)

### Integration

- **Session start**: `session-scoring-init` pipeline step records session start
- **Session events**: `session-scoring.ts` records delegations, corrections, proactive hits
- **Dashboard**: React panels show quality scores per session
- **Auto-correction**: `judgment-day-correction` step triggers when scores drop below threshold

## Consequences

### Positive

- **Objective quality measurement** — every session has a comparable score
- **Trend detection** — scores over time reveal stack health
- **Actionable** — low scores trigger automatic corrections
- **Dashboard visibility** — quality displayed alongside metrics
- **Dual-write** during transition (JSON + SQLite)

### Negative

- **Formula tuning needed** — initial weights may not reflect true quality
- **Gaming risk** — agents could optimize for score rather than outcome
- **Storage overhead** — one row per session (mitigated: only ~1KB per row)

## Alternatives Considered

### Score-only (no dimensions)

- Pros: Simple, single number
- Cons: No way to understand WHY a score is low
- Rejected: Need dimensional breakdown for corrective action

### External evaluation service

- Pros: Objective third-party evaluation
- Cons: Latency, cost, dependency
- Rejected: Local-first principle
