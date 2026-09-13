---
created: 2026-08-03 01:46:57
tags: [engram, bugfix]
engram_id: 2473
type: bugfix
---

# Fixed src/ dir case mismatch breaking Linux CI

**What**: Renamed src subdirectories in git from uppercase to lowercase to match the local disk (source of truth): src/Core→src/core (18 files), src/MCP→src/mcp (5), src/Skills→src/skills (9), src/Security→src/security (6). Also fixed 2 refs in src/cli/gv.ts and update-health-check.cjs that pointed to src/Core/maintenance-watchtower.ts.

**Why**: GitHub Actions on Linux (case-sensitive FS) checked out src/Core/ (uppercase, what git had) but ALL imports used './core/', package.json scripts used 'src/core/', and configs used 'src/core/'. Result: TS2307 "Cannot find module './core/timeout-config'" in postinstall typecheck → Tests check FAILED on PR #149. Local Windows dev worked because core.ignorecase=true and NTFS is case-insensitive.

**Where**: src/core/, src/mcp/, src/skills/, src/security/ (38 renames, 100% pure = no content change), src/cli/gv.ts:150, update-health-check.cjs. Commit a0295512 on release/v3.5.0.

**Learned**:
1. git config core.ignorecase=true HIDES case mismatches between git index and working tree on Windows — always verify with `git ls-files` + .NET Directory.GetDirectories (case-sensitive) or `git ls-tree`.
2. The LOCAL disk is the source of truth (src/core lowercase); git had uppercase from an old commit. Do NOT normalize imports — align git to disk.
3. Verify remote availability with `gh api repos/OWNER/REPO/contents/<path>?ref=<branch>` — returned 404 before fix, works after.
4. PowerShell -match is case-insensitive; use Select-String -CaseSensitive for case checks.

---
*Imported from Engram on 2026-09-06*
