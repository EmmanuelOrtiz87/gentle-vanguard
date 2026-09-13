---
created: 2026-06-18 03:11:26
tags: [engram, bugfix]
engram_id: 1433
type: bugfix
---

# Pre-process pipeline debug and validate-stack

**What**: Debugged empty output from pre-process-input.ps1 and completed validate-stack

**Why**: The pipeline returned empty output on "inicia sesion" — blocked session-init workflow

**Where**:
- scripts/utilities/utils/pre-process-input.ps1 — 3 bugs fixed
- reports/dashboard-v2/server.js — /api/trace/health endpoint added
- reports/dashboard-v2/app.js — 3 trace health cards added
- reports/dashboard-v2/index.html — health grid expanded to 9 cards

**Learned**:
- Bug 1: `GetHashCode().ToString("x").Substring(0,16)` crashes because .NET int hash hex is ≤8 chars. Fixed with MD5 dual-hash.
- Bug 2: `[System.IO.Hashing.Crc32]` not available in PowerShell 7 without loading assembly. Fixed with `[System.Security.Cryptography.MD5]`.
- Bug 3: `Safe-Invoke` passed scriptblocks with `param($u)` and `$using:repoRoot` but `Start-Job` received no `-ArgumentList`, leaving `$u=$null`. Plus `$using:repoRoot` inside param-passed blocks may not resolve in job scope. Fixed by adding `-ArgumentList` to all 4 callers.
- validate-stack: all 6 steps pass (hashline 500 files, SESSION routing, 5 hashline actions, session autostart, AST parse 0 errors, git dirty expected)

---
*Imported from Engram on 2026-09-06*
