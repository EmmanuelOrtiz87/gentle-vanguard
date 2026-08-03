# GitHub Copilot Instructions for Gentle-Vanguard
# Auto-managed by maintenance-watchtower

## Project Context
Gentle-Vanguard is an AI-Powered Development Orchestrator platform. 
Language: TypeScript (strict mode, ES2022)
Package Manager: pnpm 11.15.1
Runtime: Node.js 20+
Shell: PowerShell 7+

## Architecture
- Core stack in `src/` (TypeScript)
- Pipeline scripts in `scripts/` 
- Dashboard in `apps/web-dashboard/` (React/TypeScript/Vite)
- Knowledge base in `.engram-data/` (persistent memory)
- Code graph in `.codegraph/` (symbol intelligence)
- Configuration in `config/` (JSON)

## Key Conventions
- All new code must pass: `npm run typecheck && npm run lint`
- Use `npx tsx` to run TypeScript files directly
- Database: SQLite via better-sqlite3 (Nexus operational DB)
- Follow SDD lifecycle for new features
- Save decisions to Engram memory after significant work
- Use maintenance-watchtower for stack verification

## Naming
- Files: kebab-case.ts (e.g., `session-autostart.ts`)
- Classes: PascalCase
- Functions/variables: camelCase
- Constants: UPPER_SNAKE_CASE
- Types/interfaces: PascalCase with Interface/Type suffix

## Testing
- Vitest for unit tests
- Playwright for E2E tests
- Coverage target: 80%+
- Run: `npm run test:config && npm run test:workflows`

## Critical Files
- `src/session-autostart.ts` — session initialization
- `src/core/maintenance-watchtower.ts` — health monitoring
- `src/cli/gv.ts` — CLI entry point
- `apps/web-dashboard/` — LLM observability dashboard
- `config/session-autostart.config.json` — 53-step pipeline

## Security
- No secrets in code, ever
- Pre-commit hooks: secretlint, trufflehog
- CI: gitleaks, trivy
- use `bin/gv.ps1 secret` for credential management
