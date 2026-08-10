# Module: convergence-monitor

- Status: approved
- Owner: orchestrator
- Risk: medium
- Proposed: 2026-08-09

## Proposal

Activar el módulo `convergence-monitor` (src/convergence-monitor.ts) — monitorea la convergencia del
stack (que las métricas/estados tiendan a valores esperados) y alerta de divergencias.

- Scope: monitoreo de convergencia en la pipeline de sesión.
- Impact: visibilidad de drift del stack; no modifica comportamiento core.
- Risk: medio (lectura de métricas; sin escritura destructiva).
- Success criteria: CLI ejecutable, typecheck/lint/tests verdes, watchtower 89/89.

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
- Notes: activado bajo el workflow MODULE-ACTIVATION-WORKFLOW.md.
