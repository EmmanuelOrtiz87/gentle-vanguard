---
created: 2026-06-18 14:31:36
tags: [engram, architecture]
engram_id: 1439
type: architecture
---

# Dynamic port allocation + watchdog fixes + doc updates

**What**: Implemented dynamic port allocation for the LLM observability dashboard. Created dashboard-common.ps1 with Get-FreePort (scans +100 ports), Save/Read/Clear-DashboardPorts, Get-ProcessIdByPort. Fixed 3 root-cause bugs in dashboard-ws-autostart.ps1: (1) Write-Warn is not a valid cmdlet (should be Write-Warning) — script crashed silently, (2) $repoRoot path calculation was 3 levels deep but scripts are 4 levels from root at scripts/utilities/dashboard/, (3) watchdog Start-Process used conflicting -NoNewWindow + -WindowStyle Hidden; changed to cmd /c set WS_PORT=... && npx.cmd tsx ... for reliable Windows batch execution. Also fixed dashboard-stop.ps1: Get-Process.CommandLine can hang on zombie processes; replaced with try/catch per-process iteration. Watchdog stores own PID in .runtime/dashboard-ws-watchdog.pid and stop script kills watchdog FIRST to prevent restart loops. Ports persisted to .runtime/dashboard-ports.json. Updated vite.config.ts to read WS_PORT and VITE_DEV_PORT from env vars. All verified: WS starts on 8080 (HTTP 200), auto-fallback to 8081 when occupied, stop script closes ports AND cleans all state files. 0 build errors.

**Why**: The dashboard needed to handle port conflicts gracefully instead of crashing. Multiple sessions or stale processes could leave port 8080 occupied. The dynamic allocation ensures the dashboard always finds a free port and all components (WS server, Vite proxy, frontend) stay consistent.

**Where**: scripts/utilities/dashboard/dashboard-{common,ws-autostart,start,stop}.ps1, apps/web-dashboard/vite.config.ts, .opencode/skills/dashboard/SKILL.md, AGENTS.md

**Learned**:
- Get-NetTCPConnection with -ErrorAction SilentlyContinue is fast and reliable for port detection on Windows; fallback to TcpListener test bind for edge cases
- $pid is a reserved PowerShell automatic variable (cannot be reassigned); always use $procId instead
- Start-Process with npx.cmd (batch file) works reliably via cmd /c "set VAR=val && npx.cmd args" pattern on Windows
- Get-Process -Name node | Where-Object { $_.CommandLine -match 'pattern' } can hang on zombie processes; wrap in try/catch
- Stopping watchdog BEFORE killing the WS process prevents restart-loop race conditions

---
*Imported from Engram on 2026-09-06*
