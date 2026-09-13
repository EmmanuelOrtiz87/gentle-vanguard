---
created: 2026-07-27 21:45:00
tags: [engram, bugfix]
engram_id: 2116
type: bugfix
---

# Fixed false positive engram not found

**What**: Fixed the false positive `[WARN] Engram is required by policy and was not found` in token-budget-guard.ts

**Why**: The script was using `which engram` command which doesn't exist on Windows. This caused all Windows environments to report engram as missing even when it was properly installed and functional.

**Where**: `src/token-budget-guard.ts`, lines 175-183 (checkEngram function)

**Learned**:
- Windows uses `where` instead of `which` for locating executables
- Added fallback to directly run `engram --version` if path lookup fails
- Platform detection with `process.platform === 'win32'`
- Similar issue exists in `src/core/tool-detector-enhanced.ts` line 92 which uses `which || where` syntax that may not work in all Windows shells

**Verification**: After fix, `npm run health:check` shows `[PASS] engram doctor` and token budget guard shows `Status: PASS` with no engram warnings.

---
*Imported from Engram on 2026-09-06*
