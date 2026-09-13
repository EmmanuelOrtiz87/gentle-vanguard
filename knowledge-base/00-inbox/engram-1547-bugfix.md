---
created: 2026-07-11 01:36:05
tags: [engram, bugfix]
engram_id: 1547
type: bugfix
---

# Fixed 11 broken PS1 refs to migrated TS scripts

**What**: Fixed 11 broken PS1 references to migrated TS scripts and created missing adaptive-common.ps1 module
**Why**: Session-autostart was failing because PS1 scripts referenced deleted TS-migrated files (engram-integrity-check.ps1, session-cleanup-start.ps1, adaptive-common.ps1)
**Where**:
- Created scripts/utilities/profile/PROFILE-ADAPTIVE/adaptive-common.ps1 (shared helpers)
- Fixed scripts/utilities/memory/ENGRAM/engram-auto-sync.ps1 (engram-integrity-check ref)
- Fixed scripts/utilities/ops/BACKUP-RESTORE/backup-engram.ps1 (engram-integrity-check ref)
- Fixed scripts/adaptive/correction-rules-engine.ps1 (engram-integrity-check ref)
- Fixed scripts/utilities/session-manager.ps1 (session-cleanup-start ref)
- Fixed tests/integration/phase-13-2-3/phase-integration.tests.ps1 (session-cleanup-start ref)
**Learned**: When migrating PS1 to TS, must update ALL callers including:
1. Other PS1 scripts that call the migrated script
2. Integration tests that check file content
3. Shared modules that provide helper functions
Pattern: Check for .ts version first, fall back to .ps1, use 'npx tsx' for TS invocation from PS1

---
*Imported from Engram on 2026-09-06*
