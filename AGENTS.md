# Gentleman Foundation - Agent Guidelines

This is the **Gentleman Foundation** project - the global development platform for enterprise teams.

## Foundation Architecture

```
~/.gentleman/                    # Global installation
├── skills/                     # 28 development skills
├── tools/                      # CLI tools
├── hooks/                      # Git hooks
├── bin/                        # CLI wrappers (gf)
├── config/                     # Configuration
└── templates/                  # Project templates
```

## Quick Start

### Install Foundation
```powershell
# One-time machine setup
.\scripts\bootstrap-machine.ps1

# Verify installation
gf validate
```

### Update Skills
```powershell
gf update
```

### List Available Skills
```powershell
gf list
```

## Available Skills (28)

| Category | Skills |
|----------|--------|
| Orchestrator | project-orchestrator, skill-creator |
| Frontend | angular-spa, react-19, nextjs-15, tailwind-4 |
| State | zustand-5 |
| Validation | zod-4 |
| Backend | golang-api, api-design, django-drf |
| Database | database-relational, database-nosql |
| DevOps | docker-devops |
| Testing | testing-strategy, testing-skill |
| AI | ai-sdk-5, mcp-skill |
| Workflow | github-pr, jira-task, jira-epic |
| Quality | typescript, code-review, security |
| Governance | project-scaffolding, architecture, documentation, git-workflow, script-governance |

## Scripts

| Script | Purpose |
|--------|---------|
| `bootstrap-machine.ps1` | Install foundation globally |
| `sync-skills.ps1` | Sync skills to global |
| `setup-project.ps1` | Setup project with foundation |
| `orchestrator-next-steps.ps1` | Ask the orchestrator for next development actions |
| `validate-project.ps1` | Validate project |

## Developer Communication Policy

Default interaction mode for agent responses:

1. Executive mode by default: short, precise, action-oriented responses.
2. `simple` mode available for minimum-token output when developer requests concise closure-only responses.
3. Extended details only on explicit request from developer:
	- `EXTENDER`
	- `DETALLE`
	- `SIMPLE`
	- `RESUMEN`
4. In `simple` mode, response contract is:
	- `OK: cerrado` (or `OK: <resultado mínimo>`)
	- `ERROR: <causa breve> | ACCION: <siguiente paso mínimo>`
5. Suggestions, optional improvements, and adjustment proposals only when explicitly authorized by developer.
6. If requirements are ambiguous, ask one concise clarification question before proceeding.
7. For critical risk (security/data loss), agent must warn immediately even in simple/executive mode.
8. The orchestrator can request temporary escalation to standard/deep based on detected risk and must ask developer authorization to keep that level.
9. Document optimization is selective: optimize operational artifacts (review/audit/handoff), keep architecture/design/technical/business docs complete.

Policy reference: `docs/guides/DEVELOPER-COMMUNICATION-POLICY.md`

## Code Standards

### PowerShell Scripts
- `$ErrorActionPreference = 'Stop'` for critical scripts
- `param()` with proper attributes
- `Write-Host -ForegroundColor` for status
- Verb-Noun naming convention

### Shell Scripts
- `set -e` for error propagation
- `#!/usr/bin/env bash` shebang

### Git Workflow
- Conventional commits: `feat(scope): description`
- Run validation before commit
- Atomic commits

## Testing
- Write tests for critical functionality
- Table-driven tests preferred
- Coverage target: 70%+

## Security
- Never commit secrets
- Use environment variables
- Validate inputs
- Run security hooks pre-commit

## See Also
- `skills/SKILL_INDEX.md` - Complete skill reference
- `docs/ARCHITECTURE.md` - Foundation architecture
- `docs/guides/DEVELOPER-COMMUNICATION-POLICY.md` - Response mode and authorization rules
