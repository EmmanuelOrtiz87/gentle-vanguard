---
created: 2026-06-10 03:49:34
tags: [engram, bugfix]
engram_id: 1377
type: bugfix
---

# Fixed corrupted PowerShell files - dedup + catch fix

**What**: Repaired 5 PowerShell files that had duplicated function definitions and corrupted catch blocks. Files were 1,300-5,612 lines with duplicate content; reduced to 6-280 lines of clean, parseable PowerShell.

**Why**: Files had a corruption pattern where `catch { Write-Debug "Exception caught: ...` contained the entire file content as a string literal, causing duplication and broken parsing.

**Where**:
- scripts/utilities/workflow/WORKFLOW-ORCHESTRATION/start-session.ps1 (5612→36 lines)
- scripts/utilities/session/get-session-id.ps1 (6→6 lines)
- scripts/utilities/agents/AUTO-DELEGATION/skill-recommender.ps1 (2331→32 lines)
- scripts/utilities/token/token-consumption-report.ps1 (6→6 lines)
- scripts/utilities/setup/INSTALL/install-prerequisites.ps1 (1300→280 lines)

**Learned**:
1. PowerShell backtick escape in double-quoted strings (`"$var`text"`) gets consumed by variable name parsing — use`+` concatenation instead
2. Corrupted catch regex must handle both `catch { Write-Debug...` and `} catch { Write-Debug...` patterns
3. Brace depth counting after corrupted catch fix determines how many `}` to append for closure
4. Git files not in HEAD need disk-read fallback
5. `-ErrorAction Stop` on native commands (git) is passed as argument, not consumed by PowerShell — must use `$ErrorActionPreference` or check `$LASTEXITCODE`

---
*Imported from Engram on 2026-09-06*
