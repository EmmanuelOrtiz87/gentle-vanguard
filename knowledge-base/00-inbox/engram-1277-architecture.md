---
created: 2026-06-01 15:50:05
tags: [engram, architecture]
engram_id: 1277
type: architecture
---

# Segunda tanda: 8 CI workflows + devcontainer + Python lint

**What**: Second hardening wave — 8 new CI workflows, devcontainer, Python linting infra

**Why**: User requested to take project to next level with all optimizations, checks, and best practices

**Where**:
- `.github/workflows/python-quality.yml` — Ruff lint + pytest + coverage (Python)
- `.github/workflows/coverage.yml` — JS/TS coverage via c8
- `.github/workflows/stale.yml` — Weekly stale issue/PR cleanup
- `.github/workflows/markdown-lint.yml` — Markdown quality gate
- `.github/workflows/npm-audit.yml` — Weekly dependency vulnerability scan
- `.github/workflows/labeler.yml` — Auto-label PRs by changed paths
- `.github/workflows/openapi-validate.yml` — OpenAPI spec validation
- `.devcontainer/devcontainer.json` — Reproducible dev environment (Go, Python, Node, PS, VSCode)
- `config/quality-gates.json` — Added all new workflows to requiredWorkflows/requiredStatusChecks
- `docs/AGENTS.md` — Key References table updated with all new CI and devcontainer

**Learned**:
- GitHub labeler v6 uses `changed-files` with `any-glob-to-any-file` (different from v5)
- OpenAPI validation needs `@apidevtools/swagger-cli` globally installed
- Devcontainer `features` syntax supports multiple language runtimes in one container
- Stale action needs separate permissions `issues: write` and `pull-requests: write`

---
*Imported from Engram on 2026-09-06*
