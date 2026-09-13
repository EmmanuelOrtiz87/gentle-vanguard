---
created: 2026-05-21 22:34:25
tags: [engram, architecture]
engram_id: 988
type: architecture
---

# Session lifecycle optimization: orphan cleanup + lighter protocol

**What**: Optimized session start/close lifecycle — fixed orphan session accumulation, made close protocol lighter (10 manual steps → 3), fixed pre-close-validator auto-commit danger, fixed tool-detection exit code, fixed session-autostart Invoke-Expression bug.

**Why**: 57 orphaned sessions were accumulating because Clear-OrphanedSessions only looked for "active" status. Close protocol had 10 manual steps creating friction (most sessions never closed properly). Pre-close-validator auto-committed/pushed without consent.

**Where**: scripts/utilities/session-manager.ps1 (Clear-OrphanedSessions), config/session-autostart.config.json (statusesToClean), scripts/utilities/detect-tool.ps1 (return→exit 0), scripts/utilities/session-autostart.ps1 (Invoke-Expression→&), scripts/utilities/pre-close-validator.ps1 (auto-commit requires -AutoResolve -Force now), rules/NORMATIVAS-SESSION.md (optimized protocols), CLAUDE.md (Phase A/B consolidated)

**Learned**:
1. Clear-OrphanedSessions only targeted "active" status — orphaned sessions were invisible to cleanup. Fix: also handle "orphaned" and "ended" statuses by deleting files >24h old.
2. Invoke-Expression doesn't propagate $LASTEXITCODE reliably. Fix: use & directly.
3. Script-level `return` in PowerShell doesn't set $LASTEXITCODE. Fix: use `exit 0`.
4. Reduce protocol friction = more compliance. 10 close steps → 3 manual + pipeline automation.

---
*Imported from Engram on 2026-09-06*
