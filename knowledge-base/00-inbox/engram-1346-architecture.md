---
created: 2026-06-06 06:06:22
tags: [engram, architecture]
engram_id: 1346
type: architecture
---

# Full project audit completed

**What**: Complete audit and remediation of Gentle-Vanguard project — 92 files analyzed, 42 script directories, 386 skills, 18 test files reviewed

**Why**: User requested full audit of the entire codebase followed by execution of all identified fixes

**Where**: metrics-server.ps1, skill-server.ts, ft-evaluator.ps1, real-data.ts, InteractiveDocs.tsx, .lefthook.yml, scripts/utilities/ (79 files reorganized), deprecated/ (21 files deleted), tests/ (10 files path-fixed), config/lefthook.yml (merged), ESLint config

**Learned**:
- Two files had severe copy-paste corruption: metrics-server.ps1 (~2000 lines, 4 copies) and ft-evaluator.ps1 (427 lines, 8 copies) — both needed full deduplication rewrites
- Write-Host uses Information stream (stream 6) in PS7, not stdout — tests capturing Write-Host output need *>&1 with .MessageData property on InformationRecord
- Custom Orchestrator/Foundation tool uses Invoke-PesterRun which only outputs final summary, not per-test progress — older Pester API
- 48 main-suite tests + 42 extra tests + 7 node tests all pass (90 verified, 0 failures)
- Dashboard prod build (tsc + vite build) now succeeds

---
*Imported from Engram on 2026-09-06*
