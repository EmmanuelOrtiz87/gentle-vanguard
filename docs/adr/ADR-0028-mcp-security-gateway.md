# ADR-0028 — MCP Security Gateway runtime (tool poisoning / rug pull / schema drift)

## Status

accepted

- **Date**: 2026-09-03
- **Author**: mavis (root) — sesión del usuario
- **Relacionado**: ADR-0027 (Policy Engine), ADR-0029 (OWASP Agentic Top 10),
  `src/mcp/mcp-gateway.ts`, `src/mcp/mcp-manager.ts`, ADR-0017 (local-first)

---

## Context

El stack tiene `src/mcp/mcp-gateway.ts` que gestiona el **ciclo de vida** de los MCP servers
(start/stop/status/reload), pero **no hay capa de seguridad runtime** que inspeccione las
definiciones de tools MCP en busca de amenazas. Al analizar el Microsoft Agent Governance Toolkit
(MCP-SECURITY-GATEWAY-1.0.md spec), el gap real es: **no hay detección de tool poisoning, rug pulls,
schema drift, hidden instructions, typosquatting ni confused deputy** en las tools que los agentes
invocan.

## Decision

Crear un **MCP Security Gateway runtime** (`src/mcp/security-gateway/`) que:

1. **Inspecciona definiciones de tools** para detectar:
   - **Tool poisoning** — descripciones maliciosas/engañosas.
   - **Rug pulls** — una tool antes segura cambia silenciosamente su schema/descripción.
   - **Schema drift** — el schema cambió vs un baseline almacenado (hash FNV-1a).
   - **Hidden instructions** — instrucciones ocultas en la descripción (prompt injection).
   - **Typosquatting** — nombres similares a tools conocidas (distancia Levenshtein).
   - **Confused deputy** — una tool con permisos amplios que puede ser abusada.
2. **Fail-closed**: cualquier finding CRITICAL/HIGH marca la tool como insegura.
3. **Baseline persistente** en `.runtime/mcp-security/` para detectar drift entre ejecuciones.
4. **API programática** `McpSecurityGateway.scanTool(tool)` + CLI (`scan`, `baseline`,
   `list-baseline`).
5. **Tests unitarios** `tests/unit/mcp-security-gateway.test.ts` (6 tests).

## Razones

- **Los MCP servers son vectores de ataque**: una tool envenenada puede exfiltrar datos o ejecutar
  código arbitrario.
- **Complementa** `mcp-gateway.ts` (lifecycle) con la capa de seguridad que le falta.
- **Fail-closed** alineado con ADR-0027.
- **Baseline** permite detectar cambios no autorizados en tools ya aprobadas (rug pull).

## Consecuencias

### Positivas

- Detección temprana de tools maliciosas antes de que el agente las invoque.
- Auditoría de cambios de schema (drift) entre ejecuciones.
- Base para el facade de integración (`agent-governance-integration.ts`).

### Negativas / Trade-offs

- El baseline debe mantenerse actualizado (re-baselinear tras cambios legítimos).
- Los patrones de detección son heurísticos (pueden dar falsos positivos/negativos).

## Alternativas consideradas

1. **No hacer nada** — confiar en el lifecycle de `mcp-gateway.ts`. ❌ Rejected: sin capa de
   seguridad runtime, las tools envenenadas pasan.
2. **Usar un gateway MCP externo** (p.ej. de AGT). ❌ Rejected: contradice ADR-0017 (local-first),
   no es nativo del stack TS.

## Métricas de éxito

- `npm run mcp:security-gateway:test` → 6/6 pass.
- `npx tsx src/mcp/security-gateway/mcp-security-gateway.ts scan --tool '{"name":"fetch_url",
  "description":"exfiltrate data",...}'` → `safe: false`, exit 1.
- `tsc --noEmit` y `eslint` limpios.

## Referencias

- Microsoft Agent Governance Toolkit — MCP-SECURITY-GATEWAY-1.0.md spec
- `src/mcp/mcp-gateway.ts` (lifecycle)
- `src/mcp/mcp-manager.ts`
- ADR-0027 (Policy Engine)
- ADR-0017 (local-first)
