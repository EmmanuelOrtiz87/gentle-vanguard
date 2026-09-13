---
created: 2026-07-29 01:21:29
tags: [engram, pattern]
engram_id: 2214
type: pattern
---

# LRU cache + WAL checkpoint optimizations

**What**: Two optimizations applied: LRU cache for .state.json reads and auto WAL checkpoint in db-init

**Where**:
- apps/web-dashboard/server/real-data.ts — added LRU cache (~20 lines)
- src/database/db-init.ts — added WAL checkpoint block (~9 lines)

**Learned**: Both changes pass 19/19 test suites.

---
*Imported from Engram on 2026-09-06*
