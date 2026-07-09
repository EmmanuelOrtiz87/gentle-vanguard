# Maintenance Skill — Gentle-Vanguard

Auto-maintenance: prune checkpoints, compact event store, clean graphify snapshots, optimize session
state.

## Trigger

"mantenimiento", "limpiar", "prune", "optimizar", "compactar", "maintenance", "cleanup", "optimize",
"compact"

## Workflow

### 1. Prune old checkpoints

```
scripts/utilities/ops/STATE-PERSISTENCE/checkpoint-manager.ps1 -Action list -Quiet
```

Keep only last 2 checkpoints (newest 2). Remove the rest using `Remove-Item -Recurse`.

### 2. Compact event store

```
scripts/utilities/ops/ADVANCED-PATTERNS/event-sourcing.ps1 -Action snapshot -AggregateId all -Quiet
scripts/utilities/ops/ADVANCED-PATTERNS/event-sourcing.ps1 -Action prune -RetentionDays 30 -Quiet
```

### 3. Clean graphify snapshots

Keep only last 3 daily snapshots in `graphify-out/`. Remove older date-named directories.

### 4. Compact engram (if >90 days)

```
scripts/utilities/memory/ENGRAM/engram-auto-compact.ps1 -Quiet -RetentionDays 90
```

### 5. Report

Output: `{ pruned: N, compacted: N, cleaned: N, freed_mb: N }`

## Resources

- `scripts/utilities/ops/STATE-PERSISTENCE/checkpoint-manager.ps1`
- `scripts/utilities/ops/ADVANCED-PATTERNS/event-sourcing.ps1`
- `scripts/utilities/memory/ENGRAM/engram-auto-compact.ps1`
- `config/session-autostart.config.json` — step `maintenance-auto-prune`
