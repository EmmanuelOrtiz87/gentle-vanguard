---
created: 2026-07-05 06:24:24
tags: [engram, bugfix]
engram_id: 1477
type: bugfix
---

# PowerShell Join-Path 3-arg PS7 fix across codebase

**What**: Fixed 21 PowerShell scripts with 3-arg Join-Path calls that fail in PS7

**Why**: PowerShell 7 Join-Path only accepts 2 positional args. Scripts written for PS5 used 3-arg syntax which causes parse errors in PS7.

**Where**: maintenance-watchtower.ps1, correction-capture.ps1, session-scoring.ps1, skill-auto-patch.ps1, usage-tracker.ps1, skill-factory.ps1, sdd-pipeline.ps1, ft-dataset-builder.ps1, ft-data-collector.ps1, ft-trainer.ps1, ft-inference.ps1, ft-evaluator.ps1, ft-registry.ps1, ft-status.ps1, sync-skill-registry.ps1, build-skill-registry.ps1, ft-data-collector.tests.ps1

**Learned**:
1. Always use nested Join-Path: `Join-Path (Join-Path $a $b) $c`
2. For cross-function variable sharing, define at script scope (before `function` keyword)
3. Unicode box-drawing chars cause PowerShell parse errors — use ASCII
4. Run Prettier before commit when HTML files modified

---
*Imported from Engram on 2026-09-06*
