---
created: 2026-06-10 04:12:33
tags: [engram, bugfix]
engram_id: 1378
type: bugfix
---

# Repaired two corrupted PowerShell files

**What**: Repaired two PowerShell files with template corruption (duplicated code 20-30×, `$_` replaced with file content in catch blocks)
**Why**: Both files had already been committed to git HEAD with the corruption, so git couldn't help. Files were unusable (hundreds of parse errors).
**Where**:
- `scripts/utilities/workflow/WORKFLOW-ORCHESTRATION/judgment-day.ps1` — reconstructed from HEAD sections [0..371] + [1590..1659] + [1660..1940] → 723 lines, 0 errors
- `scripts/utilities/telemetry/TELEMETRY-METRICS/sdd-process-metrics.ps1` — reconstructed from HEAD sections [0..27] + [112..225] → 143 lines, 0 errors
**Learned**: Template corruption pattern: template tool injected the full file content into `$_` inside catch blocks, then duplicated the entire file ~20-30×. The corruption was already in git HEAD. Fix strategy: analyze HEAD line-by-line to find the clean sections (before template duplication started) and stitch them together. PowerShell Parser.ParseInput gives precise error counts.

---
*Imported from Engram on 2026-09-06*
