---
created: 2026-08-06 05:16:05
tags: [engram, pattern]
engram_id: 2566
type: pattern
---

# Batch 2: validation scripts converted to runSyncShell

**What**: Converted 5 files in scripts/validation/ from child_process sync calls (execSync/spawnSync) to the centralized runSyncShell wrapper from '../../src/core/run-command.js'.
**Why**: Part of the stack-wide migration to centralized command execution (windowsHide, consistent timeouts/stdio).
**Where**: scripts/validation/test-optimizations.ts, test-simple.ts, test-token-capture.ts, validate-complete-system.ts, validate-token-system.ts
**Learned**:
- Import path must be '../../src/core/run-command.js' (relative from scripts/validation/).
- For execSync call sites that consumed a string (`.trim()`), append `.stdout` to the runSyncShell call — otherwise you get a RunSyncResult object.
- For spawnSync call sites that checked `result.status`/`result.stderr`, keep the full result object (RunSyncResult has status/stderr/stdout fields).
- Replace spawnSync('npx', ['tsx', 'src/token-budget-guard.ts', ...]) with a single shell string: runSyncShell('npx tsx src/token-budget-guard.ts ...', { cwd: ROOT }).
- Prettier fails on ALL these validation/db scripts (4-space indent, no trailing commas) — pre-existing debt, not introduced by conversion; don't --write reformat whole files.
- Remaining un-converted: practical-optimization-demo.ts, full-stack-verification.ts, final-validation.ts, real-world-simulation.ts (out of scope for batch 2).

---
*Imported from Engram on 2026-09-06*
