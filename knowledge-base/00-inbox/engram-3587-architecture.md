---
created: 2026-09-01 19:13:57
tags: [engram, architecture]
engram_id: 3587
type: architecture
---

# Session Validation System - Intelligent Session Lifecycle

**What**: Implemented intelligent session validation system with inventory tracking for selective close
**Why**: Need to validate session state at start (active/nested/zombie), register resources, and close only what was started
**Where**: src/session/session-validator.ts, src/core/session-autostart.ts, src/session/session-close/phases.ts, src/session/session-cleanup-start.ts
**Learned**:
- Session validation detects active sessions via lock file (not blocking on Nexus query)
- Inventory tracks daemonsStarted, skillsActivated, lazyStepsLaunched, cachesInitialized, checkpointsCreated
- Selective close uses inventory instead of static whitelist
- Pre-start checkpoint created BEFORE pipeline for rollback capability
- New npm scripts: session:validate, session:validate:inventory, session:validate:close
- Stale-session-sweeper handles zombie Nexus sessions automatically

---
*Imported from Engram on 2026-09-06*
