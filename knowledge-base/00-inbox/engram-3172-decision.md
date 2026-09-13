---
created: 2026-08-26 14:09:39
tags: [engram, decision]
engram_id: 3172
type: decision
---

# opencode.json model fix: 21 agents migrated to big-pickle

**What**: Updated all 21 agent definitions in opencode.json from opencode-go/gpt-5.6-luna to opencode/big-pickle because gpt-5.6-luna has no credits available.

**Why**: Subagent tasks were being cancelled/failing because the platform tried to use gpt-5.6-luna which has no available tokens. User confirmed big-pickle is the working model.

**Where**: opencode.json — all agent model fields changed

**Learned**:
1. The opencode.json model config may not be respected by the task tool — the platform has its own model resolution
2. For guaranteed execution, the orchestrator should run verification commands directly rather than delegating
3. All 21 agents now reference opencode/big-pickle (verified: 21 occurrences, 0 of old model)

---
*Imported from Engram on 2026-09-06*
