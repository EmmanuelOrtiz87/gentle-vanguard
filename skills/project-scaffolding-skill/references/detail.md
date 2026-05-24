
### 6. Post-Creation Checklist

After scaffolding, always verify:

- [ ] `README.md` updated with project name and description
- [ ] `docs/project-context.md` contains project metadata
- [ ] `.env.example` created (no real secrets)
- [ ] `package.json` or `go.mod` has correct name/versión
- [ ] Git initialized: `git init`
- [ ] Initial commit: `git add . && git commit -m "Initial commit"`
- [ ] Run validation: `scripts/gentle-vanguard/gv.ps1 validate`

## Project Type Selection Guide

| Type            | When to Use                       | Default Stack     |
| --------------- | --------------------------------- | ----------------- |
| `service`       | REST APIs, gRPC, workers, daemons | Node.js/Express   |
| `cli`           | Tools, scripts, utilities         | Go                |
| `library`       | Reusable packages, SDKs           | TypeScript        |
| `frontend`      | Web apps (SPA/SSR)                | React/Vue/Angular |
| `fullstack`     | Frontend + Backend in monorepo    | Nx                |
| `microservices` | Distributed systems               | Multi-service     |

## Architecture Patterns

| Pattern         | Use When                     | Structure                     |
| --------------- | ---------------------------- | ----------------------------- |
| `layered`       | Traditional, simple projects | controller/service/repository |
| `clean`         | Complex business logic       | domain/adapters/ports         |
| `modular`       | Large monoliths to split     | bounded contexts              |
| `microservices` | Distributed teams/systems    | service-per-feature           |

## Validation Commands

Always run validation after project creation:

```powershell
# Workspace validation
.\scripts\gentle-vanguard\gv.ps1 validate

# Project validation
.\scripts\validation\validate-project.ps1 -ProjectPath "projects/my-project"

# Full validation with details
.\scripts\gentle-vanguard\gv.ps1 validate --project my-project --full
```

## Anti-Patterns to Avoid

1. **Don't hardcode values** - Use config files and env vars
2. **Don't skip validation** - Always verify after scaffolding
3. **Don't duplicate tools** - Use workspace tools, not vendored copies
4. **Don't skip .env.example** - Document required environment variables
5. **Don't forget docs** - Update README and project-context.md

## Quick Reference

```powershell
# Complete project creation flow
.\scripts\gentle-vanguard\gv.ps1 new --name my-api --kind service --architecture clean
cd projects\my-api
.\scripts\gentle-vanguard\gv.ps1 validate --project my-api
git add . && git commit -m "Initial commit"
```

## Skill Files

- `scripts/gentle-vanguard/gv.ps1` - Gentle-Vanguard scaffolding CLI
- `config/workspace.config.json` - Workspace configuration
- `templates/project-root/` - Base template
- `templates/project-types/*/` - Type-specific templates
- `skills/documentation-governance/` - Doc standards
- `skills/architecture-governance/` - Architecture standards