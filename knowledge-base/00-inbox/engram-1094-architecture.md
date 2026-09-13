---
created: 2026-05-24 02:50:52
tags: [engram, architecture]
engram_id: 1094
type: architecture
---

# Security stack hardening: 13 fixes applied

**What**: Applied 13 security fixes across 8 scripts — closed CRITICAL null-regex corruption, HIGH plaintext fallback/typo/CSPRNG issues, and MEDIUM hardening gaps
**Why**: Audit found 41 issues. Fixed all CRITICAL (4), HIGH (6), and key MEDIUM (3). All 87 Pester tests pass.
**Where**: scripts/security/privacy-gateway.ps1, privacy-sanitizer.ps1, encryption-manager.ps1, secrets-manager.ps1, secure-auth.ps1, setup-secure.ps1, input-validator.ps1, secret-vault.ps1
**Learned**:
1. PowerShell $null -ne '' is $true — always use Where-Object { $_ } to filter nulls before regex
2. [regex]::Escape($null) returns "" causing -replace "" to insert text between every character (global text corruption)
3. .ps1 scripts without exit don't set $LASTEXITCODE — always use explicit exit 0/1
4. $ErrorActionPreference 'Stop' + Write-Error in catch can cause cascading errors; prefer explicit exit codes
5. $HOME can be null on constrained Windows environments — always provide fallback
6. secrets-manager now throws on missing vault instead of silently falling back to unencrypted env vars

---
*Imported from Engram on 2026-09-06*
