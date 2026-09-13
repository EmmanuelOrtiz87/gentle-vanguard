---
created: 2026-07-05 06:05:54
tags: [engram, bugfix]
engram_id: 1476
type: bugfix
---

# PowerShell Join-Path 3-arg scoping bug in watchtower

**What**: Fixed maintenance-watchtower.ps1 — Join-Path with 3 positional args fails in PS7 + variable scoping bug

**Why**: PowerShell 7 Join-Path only accepts 2 positional args. Additionally, variables defined inside functions ($runtimeDir, $sessionDir) are not visible to other functions due to PowerShell scoping rules.

**Where**: scripts/maintenance/maintenance-watchtower.ps1

**Learned**:
1. Always use nested Join-Path: `Join-Path (Join-Path $a $b) $c` or string interpolation `"$a\$b\$c"`
2. For cross-function variable sharing, define at script scope (before any `function` keyword) not inside functions
3. Unicode box-drawing chars (━━) cause PowerShell parse errors — use ASCII (====) instead
4. Prettier must run before commit when HTML files are modified

---
*Imported from Engram on 2026-09-06*
