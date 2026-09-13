---
created: 2026-08-31 05:28:32
tags: [engram, decision]
engram_id: 3462
type: decision
---

# F2.3 batch 1: 22 library modules migrated to structured logger

**What**: Migrated 22 library modules from console.*to the structured logger (src/utils/logger.ts) in branch feat/f24-eradicate-any. Commits 3b839d64 (code) + 16dee4ba (docs). PR #173 created toward main.
**Why**: F2.3 of STACK-EVOLUTION-PLAN-2026 — consistent, level-aware, correlatable logging in library modules.
**Where**: src/architecture/resilience/ResilienceManager.ts, src/core/session-context-log.ts, src/core/session-metrics-tracker.ts, src/core/watchtower/* (config/dashboard/data/infra/security/context/rebuild), src/mcp/mcp-lsp-server/language-service.ts, src/ml/knowledge-synthesizer/config.ts, src/ml/model-error-interceptor.ts, src/orchestration/adaptive-router/config.ts, src/orchestration/smart-task-wrapper.ts, src/research/research-trends/fetch.ts, src/resilience/response-cache/{cache,sqlite}.ts, src/session/session-close/phases.ts, src/tokens/token-ingest/nexus.ts, src/tools/event-sourcing-api.ts. Plus scripts/codemod-console-to-logger.ts and tsconfig.json (scripts/*.ts added).
**Learned**:
- The codemod scripts/codemod-console-to-logger.ts had bugs: it inserted logger import/instance INSIDE multi-line import blocks (breaking syntax), and created duplicate log/logger identifiers in files that already had them. Fixed findLastImportIdx to skip continuation lines.
- Name collision pattern: modules with a local `log` function (from helpers) need `import { log as createLogger }` alias to avoid TS2300 duplicate identifier.
- CLI sections (main()/cli() direct execution) MUST keep console.* per F2.3 design because their stdout is parsed (JSON/status output). Reverted migrations in: version-sync, setup-branch-protection, complete-stack-fix, rescue-database, zcode-sync, post-edit-graphify, delivery/gate, adaptive-router/index, static-gates, deployment-prerequisites, credentials-inventory, knowledge-synthesizer/index.
- Branch feat/f24-eradicate-any is protected by ruleset 'gentle-vanguard' (id 21824110) applying to ~ALL branches: requires verified signatures, Production Gate status check, PR with 1 approval, CodeQL+Gitleaks. current_user_can_bypass=always (admin). Push succeeded via admin bypass; PR #173 created.
- Typecheck + lint + 6/6 test suites pass.

---
*Imported from Engram on 2026-09-06*
