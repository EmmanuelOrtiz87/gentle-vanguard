---
created: 2026-06-09 13:20:29
tags: [engram, bugfix]
engram_id: 1375
type: bugfix
---

# Fixed template corruption in git.ps1

**What**: Fixed severe template corruption in git.ps1 (6861→454 lines, 769→0 parse errors) by extracting first copy and fixing 14 corrupted catch blocks

**Why**: File had 14 catch blocks corrupted by injected Get-GitInfo function body (pattern: `catch { Write-Debug "Exception caught: function Get-GitInfo {`) due to script duplication tool error. The file had ~85x duplication making it unusable.

**Where**: scripts/utilities/workflow/WORKFLOW-ORCHESTRATION/commands/git.ps1

**Learned**:
- The corruption pattern: `catch { Write-Debug "Exception caught: function Get-GitInfo {` followed by full Get-GitInfo function body (12 lines, ending with `@{ Branch = ... }`)
- Best fix method: extract the first copy of each unique function (L1-L70 fix, + L234-L633), removing duplicate blocks (L71-L233), then fix the 2 corrupted catches within the first copy
- Use `[System.Management.Automation.Language.Parser]::ParseFile()` to verify parse errors
- Bracket/brace-depth counting doesn't work for corrupted PowerShell because injected strings contain unclosed quotes that span hundreds of lines

---
*Imported from Engram on 2026-09-06*
