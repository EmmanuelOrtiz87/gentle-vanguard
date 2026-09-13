---
created: 2026-08-28 00:48:50
tags: [engram, architecture]
engram_id: 3199
type: architecture
---

# Expanded guardrail classification with real system error patterns

**What**: Expanded guardrail failure classification with real system error patterns (item 3 of guardrail plan). Added signatures to `src/guardrail-orchestrator.ts`:
- config: `/spawn .*enoent/i`, `/(command|script|binary|executable).*not found/i`
- security: `/eacces/i`
- resource: `/enospc/i`, `/no space left on device/i`, `/eadinuse/i`, `/port.*(in use|already in use|taken)/i`

Added test cases to `tests/unit/guardrail-orchestrator.test.ts` for each learning.

**Why**: User requested advancing all pending items. Real runtime error patterns from the stack (spawn ENOENT, ENOSPC, EADDRINUSE, EACCES) were falling into 'unknown' — these are common Node.js system errors the stack encounters.

**Where**: src/guardrail-orchestrator.ts, tests/unit/guardrail-orchestrator.test.ts

**Learned**:
- Commit `7e9fff04` pushed to origin/main (227883ad..7e9fff04). All pre-push hooks passed.
- Verified classifications: spawn ENOENT→config, ENOSPC→resource, EADDRINUSE→resource, EACCES→security.
- Evaluated other pipeline points (session-close, saga, rollback, team-orchestrator spawnWorker, orchestrate-auto-fix writeDelegate) — all already have their own failure-handling mechanisms. Forcing guardrail integration would be over-engineering.
- The delegation entry points (route-and-delegate, agent-delegator CLI, model-broker) are the correct guardrail integration points, already wired in commit 227883ad.

---
*Imported from Engram on 2026-09-06*
