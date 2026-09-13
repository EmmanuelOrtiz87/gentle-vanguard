---
created: 2026-05-22 16:19:32
tags: [engram, architecture]
engram_id: 1015
type: architecture
---

# Script Path Resolution Fixes - 63% Complete

**What**: Fixed 39 of 62 PowerShell scripts with $PSScriptRoot null/empty issues. Applied robust path resolution pattern across critical scripts.

**Why**: Scripts were failing when executed in certain contexts (jobs, invoked expressions) where $PSScriptRoot is null, causing "Path is null" errors in session-autostart pipeline.

**Where**:
- scripts/utilities/* (18 scripts fixed)
- scripts/adaptive/* (8 scripts fixed)
- scripts/core/* (3 scripts fixed)
- scripts/skills/* (3 scripts fixed)
- scripts/metrics/* (2 scripts fixed)
- scripts/security/* (2 scripts fixed)
- scripts/validation/* (2 scripts fixed)

**Learned**: Pattern for robust path resolution:

```powershell
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { 
    Split-Path -Parent $MyInvocation.MyCommand.Path 
} else { 
    Get-Location 
}
```

**Pending**: 23 scripts remaining to fix. Next priority:
1. Scripts in scripts/utilities/ (remaining)
2. Scripts in scripts/testing/
3. Scripts in hooks/
4. Scripts in skills/ (remaining)

**Session Context**: session-2026-05-22_1225, 24/24 pipeline steps passing after fixes.

---
*Imported from Engram on 2026-09-06*
