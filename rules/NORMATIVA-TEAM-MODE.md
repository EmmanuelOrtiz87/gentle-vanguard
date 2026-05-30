# NORMATIVA: Team Mode

**Versión:** 1.0.0 | **Vigencia:** Inmediata | **Stack:** Gentle-Vanguard

## Propósito

Regular el uso del orquestador multi-agente paralelo para garantizar ejecución
eficiente, resultados sintetizados, y prevención de fugas de recursos.

## Reglas Obligatorias

| # | Regla | Sanción |
|---|-------|---------|
| 1 | **MaxParallel limitado** — `-MaxParallel` no debe exceder el número de cores de CPU disponibles | Script enforce |
| 2 | **Timeout obligatorio** — `-TimeoutSeconds` debe especificarse para evitar jobs huérfanos | Script reject |
| 3 | **Sintetizar resultados** — Usar `-Synthesize` para unificar resultados de sub-agentes en un output cohesivo | Best practice |
| 4 | **Logs en .session/** — Team Mode escribe logs en `.session/team-mode/`; no committear | Pre-commit reject |
| 5 | **Skills validados** — Los skills asignados deben existir en `.atl/skill-registry.md` y ser respondidos por MCP | Pre-flight check |

## Commands

| Operación | Comando |
|-----------|---------|
| Ejecutar | `pwsh scripts/team-mode/team-orchestrator.ps1 -Task "<task>" -MaxParallel 2 -TimeoutSeconds 120` |
| Con skills | `pwsh scripts/team-mode/team-orchestrator.ps1 -Task "<task>" -Skills "dev,qa,ops"` |
| Health check | `pwsh scripts/health-check/health-check.ps1 -Component team` |

## Resource Limits

| Recurso | Límite | Comportamiento |
|---------|--------|----------------|
| MaxParallel | ≤ CPU cores | Default: 2 |
| TimeoutSeconds | 30-600 | Default: 120 |
| Jobs simultáneos | ≤ MaxParallel | Cola FIFO |
| Log size | ≤ 10MB | Auto-rotate en `.session/team-mode/` |

## Error Recovery

Si Team Mode falla:
1. Revisar `.session/team-mode/*.log` para errores de sub-agentes
2. Verificar MCP server responde (`health-check.ps1 -Component mcp`)
3. Reducir `-MaxParallel` a 1
4. Aumentar `-TimeoutSeconds`

## Referencias

- `scripts/team-mode/team-orchestrator.ps1` — implementación
- `scripts/mcp/skill-server.ts` — MCP server para routing de skills
- `.session/team-mode/` — logs de ejecución
