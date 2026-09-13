---
created: 2026-05-22 19:32:34
tags: [engram, bugfix]
engram_id: 1038
type: bugfix
---

# Stack repair - session cleanup and config fixes

**What**: Repaired broken stack with multiple issues: 12 orphaned sessions, config inconsistencies, and engram-safe module detection bug
**Why**: User reported stack was broken, not respecting norms/roles. Root causes: sessions never closed, $repoRoot used before defined, Export-ModuleMember error in script mode
**Where**:
- session/ (12 session files status changed from active to orphaned)
- .clinerules (name fixed: foundation-orchestrator -> gentle-vanguard-orchestrator)
- .windsurf/config.json (version bumped 1.1.0 -> 1.3.0)
- scripts/utilities/session-manager.ps1 (moved $repoRoot definition before SkipEngramSafe check)
- scripts/utilities/engram-safe.ps1 (fixed module vs script detection)
**Learned**:
- PowerShell $MyInvocation.MyCommand.CommandType alone doesn't reliably detect dot-sourcing; need to also check $ExecutionContext.SessionState.Module
- Session files accumulate quickly if not properly closed - need orphan cleanup automation
- 86 skills legitimately exceed size limits (orchestrators/frameworks) - this is expected, not an error

---
*Imported from Engram on 2026-09-06*
