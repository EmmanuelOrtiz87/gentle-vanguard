# Architecture Standards

## Overview

Default decisión shapes, common areas, and repository targets for architecture governance.

## decisión Shape

All architecture decisións follow this structure:

```markdown
## Context

[What is the situation? What problem are we solving?]

## decisión

[What did we decide? Be specific about the choice.]

## Rationale

[Why this option over alternatives? Tradeoffs considered.]

## Consequences

[What becomes easier? What becomes harder? Side effects?]

## Status

[Proposed | Accepted | Deprecated | Superseded]

## Follow-up

[Action items, tickets, or next steps]
```

## Common decisión Areas

| Area                     | Scope                                | Examples                                          |
| ------------------------ | ------------------------------------ | ------------------------------------------------- |
| **Project Structure**    | Directory layout, naming conventions | Monorepo vs polyrepo, file naming patterns        |
| **Technology Stack**     | Language, framework, library choices | React vs Vue, PostgreSQL vs MySQL                 |
| **Architecture Pattern** | High-level design approach           | Microservices, layered architecture, event-driven |
| **Integration**          | How components communicate           | REST APIs, GraphQL, message queues                |
| **Persistence**          | Data storage decisións               | SQL vs NoSQL, ORM choices                         |
| **Security**             | Auth, authorization, secrets         | JWT vs sessions, OAuth providers                  |
| **Deployment**           | How code reaches production          | CI/CD pipelines, containerization                 |
| **Observability**        | Monitoring, logging, tracing         | Structured logging, metrics, distributed tracing  |

## Repository Targets

decisións are stored in:

1. **Local decisións**: `.decisións/` in the project root
   - Format: `decisión-YYYYMMDD-XXX.md`
   - For project-specific decisións

2. **Gentle-Vanguard decisións**: `decisións/` in gentle-vanguard
   - Format: `decisión-YYYYMMDD-XXX.md`
   - For cross-project patterns and standards

3. **Engram memory**: For session-persistent decisións
   - Use `mem_save` with type `decisión` or `architecture`
   - Survives across sessions and compactions

## Governance Rules

1. **Default to existing patterns** - Check SKILL_INDEX and existing code before introducing new
   patterns
2. **Document tradeoffs** - Every decisión must list alternatives considered
3. **Review before implementation** - Major decisións should be reviewed (use judgment-day)
4. **Update SKILL_INDEX** - If a decisión affects skill loading or triggers, update the index
5. **Cross-workspace sync** - Gentle-Vanguard decisións apply to all consumer repositories

## File Naming Standards

### ❌ Anti-Patterns (No usar)

| ❌ Incorrecto             | ✅ Correcto            | Razón                |
| ------------------------- | ---------------------- | -------------------- |
| `ARCHITECTURE-v2.md`      | `ARCHITECTURE.md`      | Versionado en nombre |
| `metrics-collector-v2.ts` | `metrics-collector.ts` | Versionado en nombre |
| `v264-scripts.test.ts`    | `scripts.test.ts`      | Versionado en nombre |
| `config-v1.json`          | `config.json`          | Versionado en nombre |

### ✅ Patrones Correctos

1. **Sin versionado en nombres**: Usar Git para historial de versiones
2. **Nombres descriptivos**: `scripts-integration.test.ts` > `v284-scripts.test.ts`
3. **Consistencia**: Kebab-case para archivos, camelCase para funciones
4. **Extensión explícita**: `.test.ts` para tests, `.config.json` para configs

### Versionado

El versionado se maneja mediante:

- **Git**: Historial completo de cambios (`git log`, `git diff`)
- **Base de datos**: Metadatos y referencias históricas
- **CHANGELOG.md**: Resumen de cambios por versión

```bash
# Ver historial de un archivo
git log --follow docs/architecture/ARCHITECTURE.md

# Ver diferencias entre versiones
git diff v1.0.0..v2.0.0 -- docs/architecture/ARCHITECTURE.md

# Restaurar versión anterior
git checkout v1.0.0 -- docs/architecture/ARCHITECTURE.md
```

## Quick Reference

```TypeScript
# List recent decisións
Get-ChildItem .decisións/ -Filter "decisión-*.md" | Sort-Object Name -Descending | Select-Object -First 10

# Search decisións
Select-String -Path .decisións/*.md -Pattern "pattern" -Context 2,2

# Save decisión to Engram
mem_save -title "decisión: chose X over Y" -type decisión -content "**What**: ...**Why**: ...**Where**: ..."
```

## Navigation

- **Topology**: [layer-topology.md](layer-topology.md)
- **Workflows**: [role-workflows.md](role-workflows.md)
- **This file**: Architecture standards and decisión templates
