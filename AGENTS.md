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
| Governance | project-scaffolding, architecture, documentation, git-workflow |

## Scripts

| Script | Purpose |
|--------|---------|
| `bootstrap-machine.ps1` | Install foundation globally |
| `sync-skills.ps1` | Sync skills to global |
| `setup-project.ps1` | Setup project with foundation |
| `validate-project.ps1` | Validate project |

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
