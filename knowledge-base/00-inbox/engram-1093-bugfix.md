---
created: 2026-05-24 02:22:10
tags: [engram, bugfix]
engram_id: 1093
type: bugfix
---

# Fixed privacy-sanitizer: null ref + exit code

**What**: Fixed 6 failing Pester tests in privacy-sanitizer.ps1
**Why**: $env:HOME is null on Windows; PowerShell evaluates $null -ne '' as $true, causing [regex]::Escape($null) to crash. Also, .ps1 scripts without exit don't set $LASTEXITCODE.
**Where**: scripts/security/privacy-sanitizer.ps1:86,187,191
**Learned**:
1. $null -ne '' is $true in PowerShell — use if ($_) to filter both null and empty
2. .ps1 scripts called with & don't set $LASTEXITCODE — always use explicit exit 0/1 if callers check exit codes
3. All 87 security tests now pass

---
*Imported from Engram on 2026-09-06*
