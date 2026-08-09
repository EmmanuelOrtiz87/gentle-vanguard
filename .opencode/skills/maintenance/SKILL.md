---
name: maintenance
description: Maintenance Skill — Gentle-Vanguard
triggers:
  - maintenance
---

# Maintenance Skill — Gentle-Vanguard

Auto-maintenance: prune checkpoints, compact event store, clean graphify snapshots, optimize session
state.

## Trigger

"mantenimiento", "limpiar", "prune", "optimizar", "compactar", "maintenance", "cleanup", "optimize",
"compact"

## Workflow

### 1. Prune old checkpoints

```
C:/Workspace_local/gentle-vanguard/src/checkpoint-manager.ts -Action list -Quiet
```

Keep only last 2 checkpoints (newest 2). Remove the rest using `Remove-Item -Recurse`.

### 2. Compact event store

```
C:/Workspace_local/gentle-vanguard/src/event-sourcing.ts -Action snapshot -AggregateId all -Quiet
C:/Workspace_local/gentle-vanguard/src/event-sourcing.ts -Action prune -RetentionDays 30 -Quiet
```

### 3. Clean graphify snapshots

Keep only last 3 daily snapshots in `graphify-out/`. Remove older date-named directories.

### 4. Compact engram (if >90 days)

```
C:/Workspace_local/gentle-vanguard/src/engram-auto-compact.ts -Quiet -RetentionDays 90
```

### 5. Report

Output: `{ pruned: N, compacted: N, cleaned: N, freed_mb: N }`

## Resources

- `C:/Workspace_local/gentle-vanguard/src/checkpoint-manager.ts`
- `C:/Workspace_local/gentle-vanguard/src/event-sourcing.ts`
- `C:/Workspace_local/gentle-vanguard/src/engram-auto-compact.ts`
- `config/session-autostart.config.json` — step `maintenance-auto-prune`
