---
created: 2026-06-10 12:36:13
tags: [engram, bugfix]
engram_id: 1379
type: bugfix
---

# Fixed hyphenated variable parse errors in all .ps1 files

**What**: Fixed parse errors in 10 PowerShell .ps1 files caused by variable names containing hyphens (e.g. `$Gentle-VanguardRoot`) without `${}` wrapping

**Why**: PowerShell parser rejects variable names with hyphens unless wrapped in `${braces}`. These were all pre-existing parse errors preventing scripts from running.

**Where**:
- scripts/core/sync-stack.ps1 (`$gentle-vanguardInstall`)
- scripts/project/sync-docs.ps1 (`$gentle-vanguardRoot`)
- scripts/utilities/utils/UTILITIES/stack-on-demand.ps1 (`$gentle-vanguardRoot`)
- scripts/utilities/setup/INSTALL/install-gentle-vanguard-cli.ps1 (`$gentle-vanguardCode`)
- skills/parallel-execution-limits/activate.ps1 (`$global:Gentle-VanguardSkills`)
- scripts/core/bootstrap-machine.ps1 (`$Gentle-VanguardRoot`)
- scripts/gentle-vanguard/bootstrap-machine.ps1 (`$Gentle-VanguardRoot`)
- scripts/core/setup-multi-machine.ps1 (`$Gentle-VanguardRepo`, `$gentle-vanguardSlug`, `$gentle-vanguardPath`)
- scripts/gentle-vanguard/setup-multi-machine.ps1 (`$Gentle-VanguardRepo`, `$gentle-vanguardSlug`, `$gentle-vanguardPath`)
- scripts/utilities/utils/UTILITIES/gentle-vanguard-sync.ps1 (`$Gentle-VanguardPath`, `$gentle-vanguardRoot`, `$gentle-vanguardManifestPath`, `$currentGentle-VanguardVersion`)

**Learned**: Also had to fix property access patterns like `$manifest.gentle-vanguardPath` → `$manifest."gentle-vanguardPath"` for property names containing hyphens. Used `replaceAll` for consistent replacement. All files verified with `[System.Management.Automation.Language.Parser]::ParseFile` to confirm 0 remaining errors.

---
*Imported from Engram on 2026-09-06*
