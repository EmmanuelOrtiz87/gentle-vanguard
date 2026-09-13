---
created: 2026-05-18 23:08:41
tags: [engram, architecture]
engram_id: 948
type: architecture
---

# CodeGraph full stack integration

**What**: Integrated CodeGraph MCP server into the entire Gentle-Vanguard stack — from passive/on-demand to proactive/orchestrated mode.

**Why**: CodeGraph was configured but only invoked manually by agents. 8 integration gaps were identified and resolved to maximize its value (92% fewer tool calls, 71% faster exploration).

**Where**:
- `config/session-autostart.config.json` — added step 16: codegraph-sync (freshness check + auto-sync)
- `config/auto-delegation.json` — added CODEGRAPH agent profile, keyword mappings (40+ triggers EN/ES), skillToAgentProfile, agentCodeToSkill
- `scripts/utilities/pre-process-input.ps1` — added CODEGRAPH_CONTEXT_RECOMMENDED detection for modification/dependency tasks
- `scripts/utilities/codegraph-sync-autostart.ps1` — NEW: autostart pipeline step (30min staleness threshold)
- `scripts/utilities/codegraph-post-modification-sync.ps1` — NEW: post-modification hook (3-file threshold, triggers: manual/post-commit/branch-switch)
- `scripts/utilities/codegraph-metrics-tracker.ps1` — NEW: usage metrics (record/summary/reset per tool)
- `scripts/utilities/codegraph-ci-validate.ps1` — NEW: CI validation with codegraph affected
- `.codegraph/config.json` — added *.ps1,*.md, *.yaml,*.yml, *.toml to include patterns
- `.atl/skill-registry.md` — reassigned codegraph-skill from (unassigned) to CODEGRAPH - Code Intelligence
- `CLAUDE.md` — added Core Rule #12 (CodeGraph integration) and 5 Key References for CodeGraph scripts

**Learned**:
- CodeGraph operates as MCP server (local SQLite, better-sqlite3 backend) — not a CLI tool for most operations
- The file watcher auto-syncs every 2 seconds, but autostart freshness check catches stale indexes at session start
- CODEGRAPH_CONTEXT_RECOMMENDED flag in pre-process-input enables proactive context gathering before code modifications
- Agent profile CODEGRAPH uses temperature 0.1 + hallucinationGuard critical — code intelligence must be deterministic

---
*Imported from Engram on 2026-09-06*
