---
created: 2026-07-10 05:49:35
tags: [engram, architecture]
engram_id: 1536
type: architecture
---

# Phase 2+3 cleanup: 5 TS migrations + 17 config fixes

**What**: Migrated 5 core PS1 scripts to TypeScript (Wave 2) and fixed 17 broken config references across the Gentle-Vanguard stack.

**Why**: PS1 scripts had runtime bugs (session-scoring null access, session-cleanup -and parameter), broken paths in 5 config files, and 5 TS-migrated PS1 originals still on disk despite being documented as eliminated.

**Where**:
- New TS files: src/session-scoring.ts, src/token-budget-guard.ts, src/audit-pipeline.ts, src/session-cleanup-start.ts, src/correction-rules-engine.ts
- Config fixes: .lefthook.yml, session-autostart.config.json, orchestrator.json, health-check.ts, maintenance-watchtower.ts
- Removed: 5 TS-migrated PS1 originals, 8 unreferenced PS1 scripts, 5 unreferenced hooks
- Updated: ps1-ts-migration.json to v3.0.0

**Learned**:
- auto-code-review.ps1 hook scans scripts/utilities/ and fails on missing files (pre-existing, non-blocking)
- Watchtower health checks reference PS1 paths directly — must update when migrating to TS
- format-check hook requires prettier on all new TS files before commit
- Session-autostart spawns TS via `npx tsx` and PS1 via `pwsh -NoProfile -File` — TS eliminates ~300-500ms pwsh startup per invocation
- 11 TS files now in src/ covering the full pipeline core

---
*Imported from Engram on 2026-09-06*
