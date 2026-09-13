---
created: 2026-06-01 16:18:49
tags: [engram, architecture]
engram_id: 1278
type: architecture
---

# CI/CD Expansion, Normativas, Go Workspace, Multi-Language Testing

**What**: Complete CI/CD & testing overhaul across 3 sessions. Added 8 GitHub Actions workflows, 4 normativas, devcontainer, Go workspace, and multi-language tests (Go 15, JS 7, Python 3).

**Why**: Required hardening of CI/CD pipeline, code quality enforcement, cross-module Go support, and comprehensive test coverage.

**Where**:
- `.github/workflows/` — 8 new workflows (js-ts-quality, python-quality, coverage, commitlint, markdown-lint, npm-audit, stale, labeler, openapi-validate)
- `rules/` — 4 new normativas (AI-SAFETY, COST-OPTIMIZATION, DISASTER-RECOVERY, INCIDENT-MANAGEMENT)
- `go.work` — workspace reconciling root + model-router-tui modules
- `scripts/utilities/model-router-tui/config_test.go` — 15 Go tests
- `tests/unit/dashboard.spec.js` — 7 JS tests
- `tests/unit/test_generate_from_template.py` — 3 Python tests (static analysis)
- `pyproject.toml` — removed --cov=src, added pythonpath
- `package.json` — added eslint, @typescript-eslint, c8 devDeps; lint/typecheck/coverage scripts
- `.devcontainer/devcontainer.json` — multi-language dev container
- `commitlint.config.js` — conventional commit enforcement

**Learned**:
- Go modules with `package main` at root don't support sub-packages in same module. Solution: `go.work` + separate `go.mod` in subdirectory.
- ESLint 8.x flat config incompatible with `.eslintrc.json` — pinned to 8.57.
- `generate-from-template.py` has Python 3.14 dataclass incompatibility (KW_ONLY in non-module context). Tests use static file analysis instead of import.
- Subagent tasks capped at 25 tool calls — large CI/test batches need parallelization.

---
*Imported from Engram on 2026-09-06*
