# Module: root-cause-correlator

- Status: approved
- Owner: self-diag-agent
- Risk: medium
- Proposed: 2026-08-09

## Proposal

Activar el módulo `root-cause-correlator` (src/root-cause-correlator.ts) como primer caso real del
workflow de activación de módulos experimentales (Fase 1 de madurez). Correlaciona causas raíz de
incidentes usando los spans de tracing y los logs de la watchtower.

- Scope: correlación de incidentes para self-diag y watchtower.
- Impact: mejora la observabilidad y el diagnóstico; no toca el core de sesión.
- Risk: medio (lectura de datos de trazabilidad, sin escritura destructiva).
- Success criteria: CLI ejecutable, typecheck/lint/tests verdes, watchtower sigue 89/89.

## Gates

- [x] tests (npm run test)
- [x] typecheck (npm run typecheck)
- [x] lint (npm run lint)
- [x] security-scan (npm run secretlint)

## Approvals

| Role         | Verdict  | Date       | Signature           |
| ------------ | -------- | ---------- | ------------------- |
| gov-agent    | approved | 2026-08-09 | gentle-vanguard-bot |
| orchestrator | approved | 2026-08-09 | gentle-vanguard-bot |

## Rollout

- Activation date: 2026-08-09
- Notes: activado bajo el workflow MODULE-ACTIVATION-WORKFLOW.md; gates verificados con
  `src/module-maturity.ts --validate root-cause-correlator --run-checks`.
