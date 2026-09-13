---
created: 2026-07-12 07:05:07
tags: [engram, bugfix]
engram_id: 1600
type: bugfix
---

# Final hardening: 0 FAIL watchtower

**What**: Final codebase hardening — 0 FAIL watchtower, unhandled promises fixed, engram deadlock handling, broken PS1 refs

**Why**: Post-cleanup audit found 44 issues (3 HIGH, 5 MEDIUM, 36 LOW). Fixed all HIGH and MEDIUM.

**Where**:
- src/architecture/resilience/ResilienceManager.ts: setInterval async callbacks wrapped in try/catch
- src/maintenance-watchtower.ts: engram MCP server deadlock detection (skip doctor when MCP running), fire-and-forget loop() error handler, stale PID files fixed
- src/token-budget-guard.ts: `any` → `Record<string, unknown>`
- scripts/adaptive/correction-rules-engine.ps1: removed dead cache-warmer.ps1 reference
- scripts/monitoring/cross-workspace-validator.ps1: fixed wrong gv.ps1 path

**Learned**:
- `tasklist` with `shell: true` and `/FI` args produces empty output on Windows — use `tasklist` with no args and filter in JS
- Engram MCP server holds DB lock → `engram doctor` deadlocks when MCP active → detect via `tasklist` and skip gracefully
- `setInterval(async () => {...})` silently swallows rejections → always wrap in try/catch
- Stale `.runtime/dashboard-ports.json` and PID files cause false FAILs in watchtower

**Result**: Watchtower 76 PASS | 2 WARN | 0 FAIL (was 73 PASS | 2 WARN | 3 FAIL)

---
*Imported from Engram on 2026-09-06*
