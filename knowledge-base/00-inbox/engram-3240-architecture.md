---
created: 2026-08-29 08:29:46
tags: [engram, architecture]
engram_id: 3240
type: architecture
---

# F2.5 adaptive-router split into per-domain modules

**What**: Split `src/orchestration/adaptive-router.ts` (~997 lines) into a thin entry + per-domain modules under `src/orchestration/adaptive-router/`. Entry file is now 26 lines: keeps top doc comment, imports `main` from `./adaptive-router/index.js`, keeps CLI entry guard (`import.meta.url === pathToFileURL(process.argv[1]).href`) + `main()` verbatim.

**Why**: Mechanical refactor (F2.5) to reduce a 901-line monolith into per-domain modules. ZERO behavior changes required.

**Where**:
- `src/orchestration/adaptive-router.ts` (entry, 26 lines)
- `adaptive-router/types.ts` (interfaces: RouterArgs, AgentPerformance, DomainEntry, RoutingOverride, RoutingTable, SkillMetric, DelegationRecord, CorrectionEntry)
- `adaptive-router/config.ts` (paths, DEFAULT_CONFIG, loadJson, loadJsonLines, Logger, getLogger, ensureDir, now, daysAgo)
- `adaptive-router/seed.ts` (SEED_DOMAINS, SEED_OVERRIDES, buildSeedDomains, buildSeedOverrides)
- `adaptive-router/collect.ts` (collectSkillUsage, collectDelegations, collectCorrections, collectReflections, collectKnowledgeConcepts, collectStaticRouterSkills)
- `adaptive-router/table.ts` (computeAgentPerformance, buildOverrides, buildRoutingTable, formatStatus)
- `adaptive-router/index.ts` (getDb, parseArgs, main)

**Learned**:
- GOTCHA: the original `getDb()` used `_require('../apps/web-dashboard/server/database/manager')` from `src/orchestration/adaptive-router.ts`, which resolves to `src/apps/...` — a BROKEN path that doesn't exist. So `getDb()` always returned null (require threw, caught silently). To preserve ZERO behavior change, the new index.ts at `src/orchestration/adaptive-router/` must use `_require('../../apps/...')` (also resolves to broken `src/apps/...`), NOT `'../../../apps/...'` (which would resolve to the real `apps/...` and enable SQLite dual-write — a behavior change).
- Use `.js` extension specifiers in imports (TS5097-safe).
- `--suggest` is NOT a recognized flag in parseArgs — it defaults to build mode. This is original behavior, unchanged.
- All verification passed: tsc --noEmit (0), eslint --max-warnings 0 (0), prettier (0), runtime probe (ok: function), CLI dry-run (exit 0).

---
*Imported from Engram on 2026-09-06*
