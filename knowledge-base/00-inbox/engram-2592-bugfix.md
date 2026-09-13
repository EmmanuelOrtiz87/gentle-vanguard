---
created: 2026-08-06 13:31:47
tags: [engram, bugfix]
engram_id: 2592
type: bugfix
---

# Fix: db-health.ts cmd.exe quote mangling + MCP health-check input missing

**What**: Fixed two validation bugs in the Gentle-Vanguard stack.
1. `scripts/database/db-health.ts` reported "Integrity FAILED" and "0 tables" even though the DB was healthy. Root cause: it used `runSyncShell` which on Windows invokes `cmd.exe /d /s /c` — this mangles nested quotes, so `sqlite3 "C:\...\db" "PRAGMA integrity_check;"` reached sqlite3 as `\ C:\...` and failed. Fixed by rewriting the script to use `better-sqlite3` directly (no external CLI dependency). Result: HEALTHY — 21 tables, 1331 rows, 7 migrations.
2) `src/core/health-check.ts` MCP check built the JSON-RPC input (initialize + tools/list) but never passed it to the spawned process (`runSync('node', [mcpJs], {...})` lacked the `input` option). The MCP server reads stdin via StdioServerTransport, got EOF, returned 0 tools. Fixed by adding `input` to the runSync options. Result: 5 tools respond.

**Why**: User demanded exhaustive stack validation (100% operational). Health check had 1 FAIL, watchtower had 1 FAIL.

**Where**: scripts/database/db-health.ts, src/core/health-check.ts

**Learned**:
- On Windows, NEVER use `runSyncShell`/`cmd.exe /d /s /c` with nested quotes for sqlite3 or similar CLIs — use `runSync` with direct argv arrays, or better, use better-sqlite3 directly.
- `runSync`/`runSyncShell` from src/core/run-command.ts support the `input` option (SpawnSyncOptions) for passing stdin to child processes.
- The watchtower (maintenance-watchtower.ts) already used the correct direct-argv pattern for sqlite3.
- CodeGraph MCP server runs as stdio MCP (not TCP) — port 3000 closed is expected; watchtower detects it via PID file/process table.

---
*Imported from Engram on 2026-09-06*
