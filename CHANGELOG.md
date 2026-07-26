# Changelog — Gentle-Vanguard

## [3.3.3] — 2026-07-26

### Wave 37.5 — Nexus Identity & Optimization
- **Nexus DB Identity**: Named the operational database "Nexus" — identity manifest, normativa
  (`rules/NEXUS-NORMATIVA.md`), skill (`skills/nexus-database/SKILL.md`), registered in
  `AGENTS.md`, `skill-router.ts`, `SKILL_INDEX.md`, `RECOVERY-NORMATIVA.md`
- **Watchtower Fix**: False positive integrity check — three-state classifier (PASS/WARN/FAIL),
  transient lock detection, auto-checkpoint WAL when WAL > 5MB or WAL > 1.5x DB size
- **Engram Critical**: Marked Engram as CRITICAL (SI) in recovery normativa — persistent memory is
  the stack's historical north
- **WAL Optimization**: Auto-checkpoint reduced WAL from 3.93 MB to 0.61 MB
- **3 ADRs**: ADR-007 (Nexus), ADR-008 (Session Scoring), ADR-009 (Watchtower)
- **CLI Migration**: `src/cli/gv.ts` — TS replacement for `bin/gv.ps1` CLI with commands:
  check, validate, info, list, health, prune, backup, optimize
- **CLI Registration**: `npm run gv` and `npm run cli:gv` in package.json

### Wave 37 — Session Scoring & Stack Tables
- **Phase B**: 4 React panels for stack tables (response_cache, contract_results, skill_usage,
  token_usage) + hook `useStackTables` + i18n entries
- **Phase C**: 5 SQLite metrics + 3 alert rules in dashboard
- **Phase D**: `pruneAll()` in DatabaseManager + `db-prune.ts` + lazy pipeline step
- **Phase E**: Migration 003 `session_scoring` table — CRUD + dual-write in session-scoring.ts
- **Migration 003**: `session_scoring` (12th table) — quality scoring per session

### Wave 34-36 — SQLite Foundation
- **Wave 34**: Stack-wide SQLite database lifecycle — `DatabaseManager` singleton, WAL mode, FK ON
- **Wave 35**: SQLite-backed response cache (SHA256 + TTL + hit_count)
- **Wave 36**: SQLite dual-write for token-tracker, skill-usage-tracker, result-gatekeeper,
  adaptive-router, event-sourcing
- **Migration 001**: Core operational (metric_snapshots, sessions, traces, events, alerts, feedback)
- **Migration 002**: Stack tables (response_cache, contract_results, skill_usage, token_usage,
  routing_rules)
- **Dashboard data API**: SQLite-backed endpoints for all 11 tables

### Stack Infrastructure
- **214 TS files** in `src/` — full PS1→TS migration of all core scripts
- **112 skills** — comprehensive library
- **49 rules** — governance and normativas
- **88 pipeline steps**, 52 lazy (59%)
- **98 watchtower checks** across 11 components
- **21 CI/CD workflows** — lint, typecheck, security, docker, release
- **67 test files** — config, workflows, security, research

---

## [3.3.0] — 2026-07-20

### Dashboard Evolution
- Wave 29: LiveChart always renders mcpSkills+commits, 32-skill registry
- Wave 30: vitest unit tests for LiveChart, jsdom testing infra
- Wave 31: MetricsCard, InfoPopup, AlertPanel tests + engram session close
- Dashboard build: 3.13s, 22KB gzip main bundle

### Infrastructure
- Wave 28: src/ restructured into subdirectories (Core/ infrastructure/ skills/ database/ etc.)
- Wave 27: SessionActivityHeatmap, LiveTraceFeed with filters, ActivityTimeline 24h chart
- SkillHeatmap component — visual skill activity grid with intensity colors

---

## [3.2.0] — 2026-07-15

### Migration to TypeScript
- PS1→TS migration complete for all core scripts in `scripts/`
- `maintenance-watchtower.ts` (834 lines) replaced watchtower PS1
- `health-check.ts` (332 lines), `session-autostart.ts` (168 lines)
- All 21 research Python scripts consolidated into single search_datasets.py
- 108 PS1 scripts deleted after TS migration verified

### CI/CD
- 6 jobs: lint-typecheck, test, dashboard-build, docker-build, python-lint, go-test
- 3 security jobs: gitleaks, secretlint, trivy
- Config consolidation: model-router.json replaces model-routing.json

---

## [3.1.0] — 2026-07-10

### Autonomous Stack
- Session autostart pipeline with 88 steps (52 lazy)
- Maintenance watchtower with 98 checks across 11 components
- Auto-healing: process restart, DB health check, WAL checkpoint
- Auto-learn: auto-norm-learner, self-reflection-loop
- Auto-evolve: skill-evolution-engine, auto-update, auto-optimizer
- Convergence monitor + findings ledger + compact state
- 6 ADRs created (ADR-001 through ADR-006)

### Security
- Security orchestrator with dependency scanning
- Secretlint + trufflehog pre-commit hooks
- Governance pipeline with audit events
- Distributed tracing with OTLP export

---

## [3.0.0] — 2026-07-01

### Initial Foundation
- Project scaffolding with TypeScript strict mode
- PowerShell CLI (`bin/gv.ps1`, `bin/gf.ps1`)
- 112 skills across 20+ domains
- OpenCode + Claude + Copilot compatibility
- Local-first, tool-agnostic architecture

---

Earlier versions (v2.x) are not tracked in this changelog. See git tags for historical releases.
