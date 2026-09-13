---
created: 2026-06-01 15:17:21
tags: [engram, architecture]
engram_id: 1276
type: architecture
---

# Proyecto llevado al siguiente nivel: normativas + CI + tests + linting

**What**: Complete project hardening session — added 4 normativas, 2 CI workflows, ESLint infra, Go/JS tests, fixed all lint/type errors

**Why**: User requested to take project to next level with all optimizations, best practices, norms, rules — leave everything functional, configured, detailed, documented

**Where**:
- `rules/NORMATIVAS-AI-SAFETY.md` — OWASP LLM Top 10, hallucination guard, prompt injection, bias
- `rules/NORMATIVAS-COST-OPTIMIZATION.md` — API cost governance, provider routing, token budgets
- `rules/NORMATIVAS-DISASTER-RECOVERY.md` — RPO/RTO, backup tiers, recovery procedures, offline mode
- `rules/NORMATIVAS-INCIDENT-MANAGEMENT.md` — Severity matrix, incident lifecycle, post-mortem
- `.github/workflows/js-ts-quality.yml` — ESLint + TypeScript type check CI gate
- `.github/workflows/commitlint.yml` — Conventional commits validation on PRs
- `package.json` — ESLint 8, @typescript-eslint/*, c8 (coverage) added; scripts: lint, typecheck, coverage
- `commitlint.config.js` — conventional commit rules
- `go.mod` — initialized at root for Go tests
- `.eslintrc.json` — fixed parserOptions.project for type-aware rules
- `tsconfig.json` — include src/**/*.ts for full coverage
- `tests/unit/dashboard.spec.js` — 7 tests for dashboard data structure + i18n
- `model_router_test.go` — 5 Go tests for model config, cost calculation, failover
- `scripts/mcp/skill-server.ts` — fixed malformed regex, empty catch, strict-boolean-expressions, eqeqeq, missing return types
- `src/architecture/resilience/ResilienceManager.ts` — fixed unused config param, unused error var, console.log→console.warn, no-explicit-any, strict-boolean-expressions
- Updated: `rules/NORMATIVES.md` (v1.1.0), `docs/AGENTS.md`, `rules/DEVELOPMENT-STANDARDS.md`, `config/quality-gates.json`

**Learned**:
- ESLint strict-boolean-expressions is aggressive — every nullable in conditional must be explicitly handled
- ESLint 9 uses flat config incompatible with .eslintrc.json — had to pin to ESLint 8
- Dockerfile.go template confused Go module — added //go:build ignore
- Go tests need to be in root or properly initialized module directory
- Console.log is disallowed by ESLint but console.warn/error are allowed

---
*Imported from Engram on 2026-09-06*
