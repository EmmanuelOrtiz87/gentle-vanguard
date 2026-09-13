---
created: 2026-05-23 17:57:36
tags: [engram, bugfix]
engram_id: 1056
type: bugfix
---

# Session-start fixes: InvariantCulture + orphan cleanup

**What**: Fixed `[DateTime]::Parse()` without InvariantCulture in session-manager.ps1 causing "Bad startTime" warnings. Closed 5 orphaned active sessions from previous runs. Built skill registry. Validated autostart pipeline runs clean 25/25.

**Why**: System locale `es-AR` (dd/MM/yyyy) caused DateTime parsing failures for session dates in MM/dd/yyyy format. The `[DateTime]::Parse()` is culture-sensitive and failed when month > 12.

**Where**:
- `scripts/utilities/session-manager.ps1` — line 198 and 225: added `[cultureinfo]::InvariantCulture`
- `session/` — closed 5 orphaned sessions (1735, 1736, 1737, 2226, 0131)
- `.atl/skill-registry.md` — rebuilt with 133 skills, 132 assigned
- `scripts/utilities/build-skill-registry.ps1` — confirmed working

**Learned**:
- Always use `[cultureinfo]::InvariantCulture` for `[DateTime]::Parse()` in cross-locale PowerShell scripts
- Session cleanup `Clear-OrphanedSessions` cannot clean sessions < 24h old; manual close needed for recent orphans
- Engram memory (PowerShell-based) reports "not available" but CLI binary works — pre-existing gap not related to this change
- Autostart pipeline 25/25 steps passes cleanly after fixes

---
*Imported from Engram on 2026-09-06*
