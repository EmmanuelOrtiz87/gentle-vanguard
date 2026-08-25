# WORKFLOW — Consolidated Normatives

**Source files:** GIT, RELEASE, ENGRAIN-BACKUP, SDD-PIPELINE, SESSION, CONFIG, DOCS, SKILL-FACTORY

## Git Workflow (Source: NORMATIVAS-GIT.md)

- Branching: `main` (protected, tagged) ← `develop` (integration) ← `feature/ISSUE-123-desc`
- Commit messages: `type(scope): description` — types: feat, fix, refactor, docs, chore, test
- No direct pushes to main; PR + CI pass + review required
- `.gitignore` enforced; no large files (>10MB), no secrets, no local artifacts

## Release Process (Source: NORMATIVAS-RELEASE.md)

- MUST use `release-automation.ps1` — manual tagging prohibited
- Pipeline: validate VERSION/badges/CHANGELOG → build/create-installer.ps1 → sync-to-public
- Output: `dist/Gentle-Vanguard.exe` (NSIS installer, AES-256 encrypted)
- Deprecated: `create-release.ps1` — DO NOT USE

## Engram Backup (Source: NORMATIVA-ENGRAIN-BACKUP.md)

- Auto post-session: `backup-engram.ps1` via session-manager
- Format: NDJSON (observations, relations, sessions) + SHA256 manifest
- Git-based rollback in `.engram-data/`; integrity check weekly
- Retention: 30d uncompressed, 90d gzip compressed

## SDD Pipeline (Source: NORMATIVA-SDD-PIPELINE.md)

- Phases: INIT → EXPLORE → PROPOSE → SPEC → TASKS → DESIGN → APPLY → VERIFY → ARCHIVE
- Feature name required (`-Feature <name>`, alphanumeric, no spaces)
- Gates between phases: each produces `gate-<phase>.json` with PASS/FAIL status
- DryRun before real execution; `.sdd/` in `.gitignore` (no commit of artifacts)

## Session Lifecycle (Source: NORMATIVAS-SESSION.md)

- Session artifacts LOCAL-ONLY: closure reports, delivery checklists, context packs →
  `.local/session-artifacts/`
- Session start: `session-start.ps1` — loads config, validates health, opens session in engram
- Session close: `session-close.ps1` — calculates metrics, runs feedback analyzer, backs up engram
- Session lifecycle authority: `.session/session-current.json`.
- `.session/.active-session.json` is a historical/compatibility persistence marker, not the lifecycle
  authority.
- Token aggregates and transactions are authoritative in Nexus (`.runtime/gentle-vanguard.db`); tool
  JSONL rollouts are the raw usage authority for JSONL-producing tools, while generated JSON snapshots
  are derived reports.

## Configuration (Source: NORMATIVAS-CONFIG.md)

- All configs validated at startup against schema; defaults applied; locked after init
- Environment overrides supported; immutable after initialization
- Config files: `config/*.json` with `$schema` reference; changes tracked in git

## Documentation (Source: NORMATIVAS-DOCS.md)

- Levels: README (overview) → Getting Started (install) → User Guide (features) → API Reference →
  Architecture
- Doc format: Markdown with `<!-- METADATA -->` frontmatter (version, status, owner)
- API docs: OpenAPI 3.1 in `docs/api/`; internal: ADRs in `docs/adr/`
- Changes to rules/ → update AGENTS.md; `docs/` auto-synced on release

## Skill Factory (Source: NORMATIVA-SKILL-FACTORY.md)

- Frontmatter YAML required: name, description, agent, triggers (≥3)
- `-Register` flag for MCP discoverability; `pnpm build:mcp` auto-runs post-creation
- Every skill needs `references/detail.md` with usage examples
- Command:
  `skill-factory.ps1 -Name <name> -Description <desc> -Agent <agent> -Triggers "t1,t2,t3" [-Register]`
