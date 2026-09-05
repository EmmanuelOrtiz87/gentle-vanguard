# ADR-0027 — Policy Engine determinista fail-closed para acciones de agentes

## Status

accepted

- **Date**: 2026-09-03
- **Author**: mavis (root) — sesión del usuario
- **Relacionado**: ADR-0028 (MCP Security Gateway), ADR-0029 (OWASP Agentic Top 10),
  ADR-0017 (local-first), `src/security/guardrail-orchestrator.ts`,
  `src/security/guardrails/input-moderation.ts`

---

## Context

El stack gentle-vanguard tiene guardrails **reactivos y heurísticos**: `input-moderation.ts`
(12 patrones stub, `failOpen`) y `guardrail-orchestrator.ts` (clasifica fallos *después* de que
ocurren). Ninguno evalúa una acción **antes** de ejecutarse contra un conjunto de políticas
declarativas, y ninguno es **fail-closed** (por defecto permiten si no hay match).

Al analizar el Microsoft Agent Governance Toolkit (AGT v4.1.0) y Gentle-AI (v2.5.0), el gap real
identificado (memoria Engram #3641) es: **no existe un policy engine determinista que decida
`allow`/`deny`/`require_approval` antes de ejecutar una acción de agente** (filesystem, MCP tool,
send, etc).

## Decision

Crear un **Policy Engine determinista fail-closed** (`src/security/policy-engine/`):

1. **Config declarativa** en `config/policy-engine.json` (v1.0.0) + `config/policy-engine.schema.json`
   (JsonSchema draft-07). Dos políticas iniciales: `gv-core-tool-safety` (4 reglas) y
   `gv-mcp-tool-policy` (1 regla allowlist).
2. **Lenguaje de condiciones restringido** — SIN `eval()`: `in`, `not in`, `==`, `!=`, `matches`
   (regex), `and`, `or`, agrupación con paréntesis. Parser determinista en
   `evaluateCondition()`.
3. **Fail-closed**: si ninguna política permite explícitamente una acción, se DENIEGA. `defaultAction:
   deny`, `failClosed: true`.
4. **Tres veredictos**: `allow`, `deny`, `require_approval` (acciones de alto riesgo requieren
   aprobación humana).
5. **API programática** `PolicyEngine.evaluate(action, policyId?)` + CLI (`evaluate`, `list`).
6. **Tests unitarios** `tests/unit/policy-engine.test.ts` (13 tests).

## Razones

- **Fail-closed es el estándar de seguridad** (AGT/Gentle-AI lo usan): lo desconocido se niega, no
  se permite silenciosamente.
- **Determinista y sin `eval()`**: auditable, testeable, sin riesgo de inyección de código en las
  condiciones.
- **Complementa** los guardrails reactivos existentes: el policy engine decide ANTES, los guardrails
  reaccionan DESPUÉS.
- **Config declarativa**: los operadores pueden cambiar políticas sin tocar código.

## Consecuencias

### Positivas

- Las acciones destructivas (delete/truncate/drop) se deniegan por defecto.
- El acceso a credenciales (`.env`) se bloquea.
- Los envíos externos (send_email) requieren aprobación.
- Los MCP tools no allowlistados se deniegan.
- Base para el facade de integración (ADR-0027+0028+0029 → `agent-governance-integration.ts`).

### Negativas / Trade-offs

- Requiere mantener el config de políticas al día (nuevas acciones/tools deben añadirse a la
  allowlist).
- El lenguaje de condiciones es un subconjunto (no soporta funciones arbitrarias).

## Alternativas consideradas

1. **No hacer nada** — mantener guardrails reactivos. ❌ Rejected: no hay gate preventivo fail-closed.
2. **Usar OPA/Cedar (externo)** — motor de políticas completo. ❌ Rejected: contradice ADR-0017
   (local-first, cero deps externas), overkill para el subconjunto necesario.
3. **Usar `eval()` para condiciones** — simple pero inseguro. ❌ Rejected: riesgo de inyección.

## Métricas de éxito

- `npm run policy:engine:test` → 13/13 pass.
- `npx tsx src/security/policy-engine/policy-engine.ts evaluate --action '{"type":"delete",...}'`
  → `denied: true`, exit 1.
- `tsc --noEmit` y `eslint` limpios.

## Referencias

- Microsoft Agent Governance Toolkit v4.1.0 (Agent Control Specification)
- Gentle-AI v2.5.0
- Memoria Engram #3641 (gap analysis)
- `src/security/guardrail-orchestrator.ts`
- `src/security/guardrails/input-moderation.ts`
- ADR-0017 (local-first)
