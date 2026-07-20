# The Migration Process

### Step 1: Build the Replacement

Don't deprecate without a working alternative. The replacement must:
- Cover all critical use cases of the old system
- Have documentation and migration guides
- Be proven in production (not just "theoretically better")

### Step 2: Announce and Document

```markdown
## Deprecation Notice: OldService

**Status:** Deprecated as of 2025-03-01 **Replacement:** NewService (see migration guide below)
**Removal date:** Advisory — no hard deadline yet **Reason:** OldService requires manual scaling and
lacks observability. NewService handles both automatically.

### Migration Guide

1. Replace `import { client } from 'old-service'` with `import { client } from 'new-service'`
2. Update configuration (see examples below)
3. Run the migration verification script: `npx migrate-check`
```

### Step 3: Migrate Incrementally

For each consumer:
```
1. Identify all touchpoints with the deprecated system
2. Update to use the replacement
3. Verify behavior matches (tests, integration checks)
4. Remove references to the old system
5. Confirm no regressions
```

**The Churn Rule:** If you own the infrastructure being deprecated, you are responsible for migrating
your users — or providing backward-compatible updates that require no migration. Don't announce
deprecation and leave users to figure it out.

### Step 4: Remove the Old System

Only after all consumers have migrated:
```
1. Verify zero active usage (metrics, logs, dependency analysis)
2. Remove the code
3. Remove associated tests, documentation, and configuration
4. Remove the deprecation notices
5. Celebrate — removing code is an achievement
```
