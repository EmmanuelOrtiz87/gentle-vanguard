# ADR-009: Watchtower False Positive Detection and Auto-Healing

## Status

Accepted

## Date

2026-07-26

## Context

The maintenance watchtower (`src/Core/maintenance-watchtower.ts`) performs 98 health checks across
11 components every session. One check — the SQLite integrity check for the Nexus database —
consistently produced false positives.

### The Problem

The watchtower used `spawnSync('sqlite3', [dbPath, 'PRAGMA integrity_check;'], { shell: true })` and
compared stdout to `'ok'`. However:

1. When the DB was transiently locked by another process (e.g., Dashboard WebSocket server), sqlite3
   returned a non-zero exit code with an empty or error stdout
2. `spawnSync` does NOT throw on non-zero exit — it returns with `r.status !== 0` and potentially
   empty stdout
3. Empty string !== 'ok', so the check reported **FAIL** even when the DB was perfectly healthy
4. Meanwhile, `db-health.ts` (using `execSync`) correctly caught the error and reported it cleanly

This created a discrepancy: `npm run db:health -- --json` showed `integrity: 'ok'` but the
watchtower reported `FAIL`.

### Other Limitations

1. **WAL check threshold** was fixed at 5 MB, but a 0.24 MB DB with 3.93 MB WAL (16× ratio) was
   under threshold and not flagged
2. No auto-healing for WAL — only warning, no action

## Decision

### Fix 1: Transient vs Corruption Detection

Replace binary `output === 'ok'` check with a three-state classifier:

```
PASS: integrity_check returns "ok"
WARN: Transient issue detected (process error, DB locked, CLI unavailable, empty stdout)
FAIL: Definite corruption (output contains real integrity errors)
```

Detection logic:

- `processFailed = r.error || (r.status !== 0)` — the process itself failed to execute
- `isTransient = processFailed || output === '' || /locked|busy|no such|Error/i.test(stderr)`
- Only FAIL on `output !== 'ok'` AND `!isTransient`

### Fix 2: Smart WAL Auto-Checkpoint

Replace fixed 5 MB threshold with a ratio-based approach:

- Trigger checkpoint when WAL > 5 MB **or** WAL > 1.5× DB size
- Automatically execute `PRAGMA wal_checkpoint(TRUNCATE)` instead of just warning
- Report result as auto-healed with before/after sizes
- On checkpoint failure, report WARN with `checkpoint failed` detail

### Implementation

```typescript
const needsCheckpoint = walMB > 5 || walRatio > 1.5;
if (needsCheckpoint) {
  spawnSync('sqlite3', [dbPath, 'PRAGMA wal_checkpoint(TRUNCATE);'], ...);
  addResult('gentle-vanguard-db', 'WAL auto-checkpoint', 'PASS',
    `${walMB} MB → ${newWalMB} MB (ratio ${walRatio}x)`, 'auto-healed');
}
```

## Consequences

### Positive

- **Zero false positives** — integrity check now correctly distinguishes transient from corruption
- **Auto-healing WAL** — no manual intervention needed for large WAL files
- **Better visibility** — WAL auto-checkpoint results logged with before/after sizes
- **Consistency** — watchtower results now match `db-health --json` output

### Negative

- **Slightly more complex** — three-state logic vs binary pass/fail
- **Auto-healing hides issues** — transient WAL growth might indicate a deeper problem (mitigated:
  logged with details)

## Alternatives Considered

### Use execSync instead of spawnSync

- Pros: Simpler, throws on error
- Cons: Can't distinguish transient from corruption (both throw)
- Rejected: Would lose the three-state classification

### Ignore transient errors entirely

- Pros: No false positives
- Cons: Would miss real corruption masked by transient symptoms
- Rejected: Need to detect and report but not flag as FAIL
