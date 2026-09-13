---
created: 2026-07-17 15:12:13
tags: [engram, architecture]
engram_id: 1730
type: architecture
---

# Fixed 2 config entries + killed zombie watchdog (Wave 7 completion)

**What**: Completed Wave 7 PS1→TS migration cleanup by fixing 2 config entries and killing zombie watchdog
**Why**: adaptive-opencode-profile and validate-tool-configs TS files existed but config still pointed to PS1. Zombie watchdog PS1 (PID 21928) had been running since July 12, spawning phantom CMD windows every 5s.
**Where**:
- config/session-autostart.config.json — 2 steps updated: adaptive-opencode-profile → src/adaptive-opencode-profile.ts, validate-tool-configs → src/validate-tool-configs.ts
- PID 21928 killed (dashboard-ws-autostart.ps1 watchdog, running 5 days)
- PID 2028 killed (powershell.exe -Command npx.cmd tsx server/websocket-server.ts)
**Learned**:
- 509 PS1 files remain in repo, 29 still in pipeline config
- Previously migrated TS files (adaptive-opencode-profile, validate-tool-configs) were not referenced in pipeline config — always update config when creating TS replacement
- session-autostart.ts already uses windowsHide: true (line 51) so pipeline spawns are hidden
- Old watchdog processes can persist across sessions for days — always kill old PS1 processes when migrating
- Next priority: migrate remaining PS1 pipeline steps starting with session-manager (required: true)

Key metrics:
- Typecheck: 0 errors | Lint: 0 errors | Tests: 23/23 pass
- Dashboard build: OK
- Pipeline: 32 TS steps + 29 PS1 steps = 61 total
- Migrations completed: 12 PS1→TS across 7 waves

---
*Imported from Engram on 2026-09-06*
