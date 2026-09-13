---
created: 2026-06-09 13:32:10
tags: [engram, bugfix]
engram_id: 1376
type: bugfix
---

# Fixed gv.ps1 template corruption

**What**: Repaired template corruption in gv.ps1 (scripts/utilities/workflow/WORKFLOW-ORCHESTRATION/gv.ps1) that had 4x duplicated copies (7751→1937 lines), 3 corrupted catch blocks containing full file as Write-Debug message, and nested overlapping copies creating 145 switch cases.

**Why**: File was unusable due to template duplication and corrupted catch blocks causing 87+ parse errors.

**Where**: scripts/utilities/workflow/WORKFLOW-ORCHESTRATION/gv.ps1

**Learned**:
- Repair approach: extracted git HEAD header (lines 1-43 param/init/dot-sourcing) + last copy (lines 4181-7747 functions/switch/exit 0), then truncated at first exit 0 to remove nested duplicate content
- The corrupted catch pattern was: `catch { Write-Debug "Exception caught: # gv.ps1 - Workflow CLI ... [full file content as string] }`
- Fixed 3 corrupted catches by replacing with `catch { }`
- Confirmed 0 parse errors via System.Management.Automation.Language.Parser::ParseFile

---
*Imported from Engram on 2026-09-06*
