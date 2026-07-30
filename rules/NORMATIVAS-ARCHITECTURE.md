# ARCHITECTURE — Consolidated Normatives

**Source files:** ARCHITECTURE, API-VERSIONING, CROSS-PLATFORM, MULTI-REPO, COST-OPTIMIZATION,
PERFORMANCE

## Architecture Principles (Source: NORMATIVAS-ARCHITECTURE.md)

- Layered: Presentation → Application → Domain → Infrastructure (strict dependency direction)
- Dependency injection: `config/orchestrator.json` for agent/skill wiring
- Orchestrator pattern: single entry point delegates to specialized agents via Team Mode
- Config-driven routing: `config/delegation-config.json` + confidence thresholds (0.0–1.0)

## API Versioning (Source: NORMATIVAS-API-VERSIONING.md)

- SemVer 2.0: MAJOR (breaking) → MINOR (new, backward-compat) → PATCH (bug fix)
- Breaking changes: 1 full version deprecation notice before removal; `Sunset` header
- Version in URL path (`/v1/`, `/v2/`); changelog per version in CHANGELOG.md

## Cross-Platform (Source: NORMATIVAS-CROSS-PLATFORM.md)

- Windows 10+/Ubuntu 22.04+/macOS 13+ — all scripts must run on all platforms
- **TypeScript-First**: All operational scripts MUST be TypeScript via `npx tsx`.
  See `rules/TYPESCRIPT-FIRST-POLICY.md` for full policy. TypeScript scripts are deprecated
  for stack operations; TypeScript remains available as a system shell only.
- Paths: use `Join-Path` not string concat; `[IO.Path]::DirectorySeparatorChar`
- Line endings: LF in repo; CRLF only for Windows-specific user-facing files

## Multi-Repo Strategy (Source: NORMATIVAS-MULTI-REPO.md)

- V3.0: monorepo recommended — `apps/`, `packages/`, `infrastructure/`, `docs/`, `scripts/`
- Polyrepo only when: separate teams, distinct release cadences, org-level boundaries
- Cross-repo: Git submodules (pinned) + sync scripts

## Cost Optimization (Source: NORMATIVAS-COST-OPTIMIZATION.md)

- Measure before optimize: all cost changes based on metrics
- Model routing: economic models for routine agents, premium for critical phases (SDD-design,
  verify)
- Token tracking: `token-usage.json` updated every turn; weekly cost reports
- Caching: SHA256 response cache (30min TTL); pre-task compression ≥25% ratio

## Performance SLOs (Source: NORMATIVAS-PERFORMANCE.md)

- Agent dispatch: <500ms target, >1000ms critical
- Skill load: <2s target, >5s critical
- Agent task completion: <30s target, >60s critical
- Pre-process-input: ~1.7s cache hit (SHA256, 30min TTL); cache pruning >1hr
- Circuit breaker: 100% uptime target, auto-reset after 30s cooldown
