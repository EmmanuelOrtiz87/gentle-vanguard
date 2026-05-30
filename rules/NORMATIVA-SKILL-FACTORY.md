# NORMATIVA: Skill Factory

**Versión:** 1.0.0 | **Vigencia:** Inmediata | **Stack:** Gentle-Vanguard

## Propósito

Estandarizar la creación de nuevos skills mediante el Skill Factory, asegurando
que todos los skills tengan frontmatter YAML válido, registro en MCP, y
referencias completas.

## Reglas Obligatorias

| # | Regla | Sanción |
|---|-------|---------|
| 1 | **Frontmatter YAML completo** — Todo SKILL.md debe tener name, description, agent, triggers válidos | CI/CD reject |
| 2 | **Triggers descriptivos** — Mínimo 3 triggers que describan casos de uso reales | Code review |
| 3 | **Registro en MCP** — `-Register` debe usarse en la creación para que el skill sea descubrible | Best practice |
| 4 | **Rebuild post-creación** — El factory ejecuta `pnpm build:mcp` automáticamente | Auto-enforced |
| 5 | **Referencias completas** — Todo skill debe tener `references/detail.md` con ejemplos de uso | Pre-commit verify |

## Commands

| Operación | Comando |
|-----------|---------|
| Crear skill | `pwsh scripts/utilities/SKILL-FACTORY/skill-factory.ps1 -Name "<name>" -Description "<desc>" -Agent "<agent>" -Triggers "t1,t2,t3"` |
| Con registro | `pwsh scripts/utilities/SKILL-FACTORY/skill-factory.ps1 -Name "<name>" -Description "<desc>" -Agent "<agent>" -Triggers "t1,t2,t3" -Register` |
| Health check | `pwsh scripts/health-check/health-check.ps1 -Component factory` |

## Skill Structure

```
skills/<name>/
  SKILL.md              → Frontmatter YAML + description del skill
  references/
    detail.md           → Ejemplos de uso, parámetros, outputs
```

## SKILL.md Frontmatter Template

```yaml
---
name: <skill-name>
description: >
  <descripción del skill>
agent: <BA - Analysis | SAD - Design | DEV - Code | QA - Verify | ...>
triggers:
  - <trigger1>
  - <trigger2>
  - <trigger3>
---
```

## Post-Creation Checklist

- [ ] Skill visible en MCP: `search_skills(query:"<name>")`
- [ ] Registry actualizado: `.atl/skill-registry.md`
- [ ] MCP compila: `pnpm build:mcp` (0 errors)
- [ ] Frontmatter YAML válido
- [ ] `references/detail.md` con ejemplos

## Referencias

- `scripts/utilities/SKILL-FACTORY/skill-factory.ps1` — implementación
- `skills/<name>/SKILL.md` — skill creado
- `.atl/skill-registry.md` — registro maestro
- `scripts/mcp/skill-server.ts` — MCP server
