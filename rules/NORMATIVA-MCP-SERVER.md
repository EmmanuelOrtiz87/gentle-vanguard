# NORMATIVA: MCP Skill Server

**Versión:** 1.0.0 | **Vigencia:** Inmediata | **Stack:** Gentle-Vanguard

## Propósito

Garantizar que el servidor MCP de Skills funcione correctamente, se compile siempre
después de cambios, y que los skills registrados sean descubribles y utilizables
por todas las herramientas compatibles.

## Reglas Obligatorias

| # | Regla | Sanción |
|---|-------|---------|
| 1 | **Compilar siempre** — `pnpm build:mcp` debe ejecutarse tras cualquier cambio en `scripts/mcp/skill-server.ts`, `skills/*/SKILL.md`, o `.atl/skill-registry.md` | Pre-commit hook lo verifica |
| 2 | **Registry actualizado** — Todo skill nuevo debe registrarse en `.atl/skill-registry.md` con agente y triggers | CI/CD reject si falta |
| 3 | **Tests de integración** — `scripts/health-check/health-check.ps1 -Component mcp` debe pasar antes de merge a main | CI/CD gate |
| 4 | **Sin errores de compilación** — `pnpm tsc` debe producir 0 errores, 0 warnings | Pre-commit reject |
| 5 | **Compatibilidad backward** — No eliminar tools del MCP sin deprecación de 1 versión | Code review mandatory |

## Commands

| Operación | Comando |
|-----------|---------|
| Compilar MCP | `pnpm build:mcp` |
| Health check | `pwsh scripts/health-check/health-check.ps1 -Component mcp` |
| Listar skills | JSON-RPC: `{"method":"tools/call","params":{"name":"list_skills"}}` |
| Buscar skill | JSON-RPC: `{"method":"tools/call","params":{"name":"search_skills","arguments":{"query":"..."}}}` |

## Estructura

```
scripts/mcp/skill-server.ts     → Código fuente TypeScript
dist/scripts/mcp/skill-server.js → Compilado (generado por pnpm tsc)
.atl/skill-registry.md           → Registro maestro de skills
skills/<name>/SKILL.md          → Skill individual con frontmatter YAML
opencode.json#mcp.skill-server  → Registro en tool config
```

## Failure Recovery

Si el MCP server no responde:
1. Verificar `Test-Path dist/scripts/mcp/skill-server.js`
2. Ejecutar `pnpm build:mcp`
3. Si persiste: `node dist/scripts/mcp/skill-server.js` y verificar stderr
4. Revisar `opencode.json` que la ruta coincida con el compilado

## Referencias

- `scripts/mcp/skill-server.ts` — implementación
- `scripts/health-check/health-check.ps1` — health check cross-component
- `config/lefthook.yml` — pre-commit hook `build-mcp-server`
- `package.json#scripts.build:mcp` — compilación
