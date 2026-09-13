---
created: 2026-06-01 13:30:59
tags: [engram, bugfix]
engram_id: 1275
type: bugfix
---

# Fixed skill-scan pre-commit hook - -Command + wrapper

**What**: Fixed skill-scan pre-commit hook that failed when multiple SKILL.md files were staged. Root cause: lefthook's PowerShell shell expanded `$f` before passing to inner pwsh -Command, and `"` quotes with -File didn't protect space-separated file lists.

**Why**: Pre-commit hook broke with staged_files array → Format ValidateSet error, then $f expansion error.

**Where**: .lefthook.yml (line 44), scripts/security/scan-skill-hook.ps1 (new), scripts/security/scan-skill.ps1

**Learned**:
- `pwsh -File "script.ps1" -Param "{staged_files}"` — quotes don't survive lefthook's shell (PowerShell) on Windows
- `pwsh -Command "& 'script.ps1' -Param '{staged_files}'"` — single quotes inside -Command protect spaces AND don't expand variables
- Wrapper script avoids `$PSScriptRoot` (not available in -Command mode), uses relative paths
- Final solution: wrapper script + `-Command "& 'wrapper.ps1' -Files '{staged_files}'"`

---
*Imported from Engram on 2026-09-06*
