---
created: 2026-07-14 20:07:15
tags: [engram, bugfix]
engram_id: 1672
type: bugfix
---

# ESM require() crash fixes + dead PS1 cleanup + doc updates

**What**: Fixed 3 runtime crash bugs (ESM require()), cleaned dead PS1 fallback paths, updated stale docs

**Why**: require('fs') in ESM modules crashes at runtime; package.json dashboard:server used node on .ts file; maintenance-auto-prune ran 'list' instead of 'prune'; ROADMAP.md claimed 8 completed migrations as "Pendiente"; PRODUCTION-RUNBOOK.md referenced deleted PS1 scripts

**Where**: src/post-autostart-summary.ts:63 (require→readdirSync), src/correction-rules-engine.ts (removed dead PS1 fallback + runPs1), src/engram-auto-sync.ts (removed dead PS1 fallback), tests/eval/health-check.test.ts:32 (require→readFileSync), package.json:52 (node→npx tsx), config/session-autostart.config.json:463 (list→prune), docs/ROADMAP.md, docs/operations/PRODUCTION-RUNBOOK.md

**Learned**:
- ESM projects cannot use require() — tsx allows it but it's wrong for the module system
- Dead PS1 fallback paths add complexity without value when TS version always exists
- format-check hook catches unformatted markdown files — always run prettier before commit
- Post-commit hooks (hashline-snapshot ~28s) need 180s timeout for git commit commands

---
*Imported from Engram on 2026-09-06*
