---
created: 2026-05-29 04:49:44
tags: [engram, architecture]
engram_id: 1212
type: architecture
---

# SDD Pipeline ejecutable

**What**: Created SDD Pipeline executable orchestrator at scripts/sdd-pipeline/sdd-pipeline.ps1. Executes full SDD lifecycle end-to-end: INIT → EXPLORE → PROPOSE → SPEC → TASKS → DESIGN → APPLY → VERIFY → ARCHIVE. Each phase produces gates (gate-<phase>.json) and artifacts in .sdd/<feature>/. Supports single-phase execution (-Phase flag) and dry-run mode (-DryRun). Path resolution fixed from 3 to 2 Parents ($PSScriptRoot → repo root).

**Why**: Automates the SDD lifecycle so features can be executed as a repeatable pipeline with quality gates between phases, replacing manual phase-by-phase execution.

**Where**: scripts/sdd-pipeline/sdd-pipeline.ps1, artifacts stored at .sdd/<feature>/

**Learned**:
- $PSScriptRoot already resolves to script directory, so going up 3 Parents goes one level above repo root
- All 9 phases passed in both dry-run and real execution modes

---
*Imported from Engram on 2026-09-06*
