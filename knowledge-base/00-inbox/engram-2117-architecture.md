---
created: 2026-07-28 00:38:53
tags: [engram, architecture]
engram_id: 2117
type: architecture
---

# Full stack evolution session: 9 fixes applied, 100% green

**What**: Complete stack evolution session. Fixed 9 issues across Engram, CodeGraph, Health Check, TypeScript compilation, timeouts, and Windows compatibility. All components now report 100% PASS.

**Why**: User requested full stack verification with zero warnings, failures, or false positives. All components must be active, automated, and properly integrated.

**Where**:
- `src/token-budget-guard.ts` — Fixed `which`→`where` for Windows
- `src/codegraph-mcp-server-start.ts` — NEW: auto-starts CodeGraph MCP server
- `config/session-autostart.config.json` — Added codegraph-mcp-server-start step
- `config/timeout-config.json` — health_check_ms 15000→60000
- `src/core/health-check.ts` — Fixed 4 issues: maxBuffer, npx tsc, cmd.exe spawn, engram JSON space parsing
- `src/core/health-check.ts` — Removed unused imports

**Fixes applied**:
1. Engram "not found" false positive — `which` doesn't exist on Windows
2. CodeGraph MCP server not auto-starting — created startup script + autostart step
3. TypeScript unused vars — cleaned codegraph-mcp-server-start.ts
4. Health check timeout too short (15s) — increased to 60s
5. spawnPortable without maxBuffer — processes with >200KB output died silently
6. MCP TS compile check used wrong tsc path — changed to npx tsc
7. Engram doctor spawn failed on Windows — added cmd.exe /c wrapper
8. Engram doctor JSON parsing — space after colon in "status": "ok"
9. Removed unused execSync import

**Current state**:
- Health Check: ALL PASS (14/14 components)
- Watchtower: 82/82 PASS (16/16 components)
- Nexus DB: HEALTHY (14 tables, 5 migrations)
- TypeScript: Clean compilation
- Engram: v1.20.0, Doctor 4/4 OK, 1475+ observations
- CodeGraph: v0.8.0, 513 files, 7694 nodes, MCP server auto-starts
- Graphify: 35788 nodes, 31MB graph
- Dashboard WS: Running (PID 4184, port 8080)

---
*Imported from Engram on 2026-09-06*
