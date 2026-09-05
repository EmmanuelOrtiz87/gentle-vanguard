# ADR-0029 — OWASP Agentic AI Top 10 compliance mapping

## Status

accepted

- **Date**: 2026-09-03
- **Author**: mavis (root) — sesión del usuario
- **Relacionado**: ADR-0027 (Policy Engine), ADR-0028 (MCP Security Gateway),
  `src/rdd/rdd-kill-switch.ts`, `src/tools/event-sourcing.ts`, `src/resilience/`,
  `config/token-budget-guard.json`, ADR-0017 (local-first)

---

## Context

El stack gentle-vanguard tiene numerosos controles de seguridad distribuidos (guardrails, kill
switch, event sourcing hash-chained, saga/circuit/chaos, token budget, secret scanner, etc.), pero
**no hay un mapeo formal** de esos controles contra el **OWASP Agentic AI Top 10 (2025)**. Al
analizar el Microsoft Agent Governance Toolkit (que mapea su arquitectura a OWASP), el gap real es:
**no hay visibilidad de qué categorías de riesgo OWASP están cubiertas y cuáles no**, ni un reporte
de cobertura accionable para CI.

## Decision

Crear un **mapeo OWASP Agentic AI Top 10** (`src/security/owasp/`) que:

1. **Define las 10 categorías** OWASP Agentic AI (LLM01:2025 a LLM10:2025).
2. **Mapea cada categoría** a los componentes GV específicos que proveen el control, con evidencia
   (paths de archivos).
3. **Scoring de cobertura**: `full` / `partial` / `none` por categoría + cobertura global.
4. **Modo `--strict`** para CI: falla si la cobertura global < 80% o hay categorías `none`.
5. **API programática** `buildOwaspMapping()` + `generateReport(strict)` + CLI (`report`, `verify`).
6. **Tests unitarios** `tests/unit/owasp-agentic-top10.test.ts` (6 tests).

## Razones

- **Visibilidad de riesgo**: saber qué categorías OWASP están cubiertas y cuáles no.
- **CI gate**: el modo `--strict` impide regresiones de cobertura.
- **Evidencia trazable**: cada categoría apunta a los archivos que implementan el control.
- **Alineado con AGT**: el toolkit de Microsoft mapea su arquitectura a OWASP; replicamos ese
  patrón de forma nativa.

## Consecuencias

### Positivas

- Reporte de cobertura accionable (actualmente 75%: 5 full / 5 partial / 0 none).
- Base para priorizar la elevación de categorías `partial` a `full`.
- Base para el facade de integración (`agent-governance-integration.ts`).

### Negativas / Trade-offs

- El mapeo requiere mantenimiento (nuevos controles deben reflejarse).
- La cobertura es una estimación cualitativa, no una certificación.

## Alternativas consideradas

1. **No hacer nada** — sin visibilidad de cobertura OWASP. ❌ Rejected: no hay forma de medir el
   riesgo agentic.
2. **Usar el mapeo de AGT directamente** (externo). ❌ Rejected: no refleja los controles reales del
   stack GV.

## Métricas de éxito

- `npm run owasp:top10:test` → 6/6 pass.
- `npx tsx src/security/owasp/owasp-agentic-top10.ts report` → 75% cobertura, reporte en
  `.runtime/owasp-agentic-top10.json`.
- `tsc --noEmit` y `eslint` limpios.

## Referencias

- OWASP Agentic AI Top 10 (2025)
- Microsoft Agent Governance Toolkit — OWASP Agentic Top 10 architecture mapping
- `src/rdd/rdd-kill-switch.ts` (LLM06 excessive agency)
- `src/tools/event-sourcing.ts` (LLM08/LLM09 audit)
- `src/resilience/` (LLM10)
- `config/token-budget-guard.json` (LLM10 resource exhaustion)
- ADR-0027, ADR-0028
- ADR-0017 (local-first)
