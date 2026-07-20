# Migration Patterns

## Strangler Pattern

Run old and new systems in parallel. Route traffic incrementally from old to new.

```
Phase 1: New system handles 0%, old handles 100%
Phase 2: New system handles 10% (canary)
Phase 3: New system handles 50%
Phase 4: New system handles 100%, old system idle
Phase 5: Remove old system
```

## Adapter Pattern

Create an adapter that translates calls from the old interface to the new implementation. Consumers
keep using the old interface while you migrate the backend.

```typescript
class LegacyTaskService implements OldTaskAPI {
  constructor(private newService: NewTaskService) {}

  // Old method signature, delegates to new implementation
  getTask(id: number): OldTask {
    const task = this.newService.findById(String(id));
    return this.toOldFormat(task);
  }
}
```

## Feature Flag Migration

Use feature flags to switch consumers from old to new system one at a time:

```typescript
function getTaskService(userId: string): TaskService {
  if (featureFlags.isEnabled('new-task-service', { userId })) {
    return new NewTaskService();
  }
  return new LegacyTaskService();
}
```

## Database Schema Migrations (Expand/Contract)

**Never change a column in place.** Migrate in additive phases so old and new code are both valid at
every step.

```
EXPAND ──────────────→ MIGRATE ──────────────→ CONTRACT
add the new column,    backfill existing rows,  once no code reads the
nullable, alongside    dual-write old+new from  old column, drop it in
the old one            the app                  a later, separate deploy
```

**Worked example — renaming `name` to `full_name`:**

1. **Expand.** Add `full_name` as nullable. Deploy. (Old code ignores it; nothing breaks.)
2. **Dual-write.** App writes both `name` and `full_name` on every insert/update. Deploy.
3. **Backfill.** Copy `name → full_name` for existing rows, in batches.
4. **Switch reads.** Point the app at `full_name`, keep writing both. Deploy and bake.
5. **Contract.** Stop writing `name`, then — in a *separate, later* deploy — drop the column.

Each step is independently deployable and reversible: if step 4 misbehaves, roll the code back and
`full_name` is still being populated.

**Rules:**
- **Additive first, destructive last and alone.** Adds are safe in any deploy; drops get their own
  deploy after no code references the old shape.
- **Every migration has a tested down path.** Write and run the `down` before merging.
- **Backfill in batches, off the hot path.** Chunk and throttle large updates to avoid table locks.
- **Build large indexes without blocking writes** (e.g. Postgres `CREATE INDEX CONCURRENTLY`).
- **Decouple from code by feature flag** when the cutover is risky.
