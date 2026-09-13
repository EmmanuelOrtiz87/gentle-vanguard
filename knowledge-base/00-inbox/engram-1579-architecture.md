---
created: 2026-07-12 05:58:05
tags: [engram, architecture]
engram_id: 1579
type: architecture
---

# Session cleanup Phase 1 completion - all pipeline steps passing

**What**: Completed Phase 1 cleanup of Gentle-Vanguard stack — all 30 session-autostart steps now pass with 0 failures, watchtower at 76/78 PASS (2 freshness WARNs only)

**Why**: Multiple cascading corruption bugs in PS1 files (catch blocks embedding entire files as string literals), stack overflow in checkpoint-manager.ts, and invalid ValidateSet arguments in config

**Where**:
- checkpoint-manager.ts — added maxDepth=10 to collectSessionFiles()
- session-autostart.config.json — changed token-notification-init from '-Action status' to '-Action init'
- skill-recommender.ps1 — reconstructed from 2331→155 lines (82 param( duplications removed)
- digest-generator.ps1 — reconstructed from 15573→183 lines (same pattern)
- token-usage-notifier.ps1 — direct invocation instead of @args_ splatting
- invoke-document-analysis.ps1 — made DocumentPath optional
- gv.ps1 — deprecated (7751 lines, not called by pipeline)

**Learned**: The PowerShell cascading duplication pattern is: `catch { Write-Debug "Exception caught: <#` or `catch { Write-Debug "Exception caught: param(` — the unclosed string literal swallows the entire file, creating fractal duplication. Always use `Write-Debug "Exception caught: $_"` in catch blocks. Files with this corruption should be reconstructed from the clean sections (usually the last N hundred lines before the next corruption boundary).

**Remaining non-critical items**:
- token-usage-auto.ps1: Dead code with same corruption (1221 lines, 15 param() dups), not called by anything
- engram-rag-reindex.ps1: Broken refs to engram-vector-index.ps1, not in pipeline
- engram-backup: Integrity check fails due to ESM `require` in SQLite check (pre-existing)
- dashboard-ws: Timeout on start (pre-existing, auto-healed by watchdog)

---
*Imported from Engram on 2026-09-06*
