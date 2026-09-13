---
created: 2026-07-08 05:33:40
tags: [engram, architecture]
engram_id: 1500
type: architecture
---

# Migrated health-check.ps1 to TypeScript

**What**: Created src/health-check.ts as a TypeScript migration of scripts/health-check/health-check.ps1

**Why**: To have a TypeScript-native health check CLI that doesn't depend on PowerShell

**Where**: src/health-check.ts (332 lines), package.json (added "health:check:ts" script)

**Learned**:
- All 14 checks (mcp, team, session, factory, sdd, pnpm, lefthook, optimization, gateguard, costtracking, ml, rag, dashboard, mcpbridge) ported
- TCP port check requires async (net.Socket is callback-based), so checkDashboardV3 and checkEngramRag are async; main() uses instanceOf Promise to handle both sync and async checks
- PS1-style pipeline (`2>&1`, `|`) replaced with spawnSync/execSync and manual output parsing
- Uses only Node built-ins (fs, path, net, child_process) — no external deps
- Exit code = number of failed checks (same as PS1)

---
*Imported from Engram on 2026-09-06*
