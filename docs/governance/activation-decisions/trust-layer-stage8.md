# Module: trust-layer-stage8

- Status: approved
- Owner: gov-agent
- Risk: high
- Proposed: 2026-08-10

## Proposal

Activar el módulo `trust-layer-stage8` (src/review-lenses.ts) bajo el workflow de activación de
módulos experimentales (Fase 1 de madurez). Capa de confianza stage #8: lentes de revisión de
código (security, quality, correctness) con detección de secrets hardcodeados, eval/
Invoke-Expression y SQL por concatenación.

- Scope: lentes de revisión automatizada para el pipeline de revisión y gov-agent.
- Impact: fortalece la capa de seguridad del stack; no toca el core de sesión.
- Risk: alto (análisis de código con falsos positivos posibles — requiere revisión humana).
- Success criteria: CLI ejecutable, typecheck/lint/tests verdes, watchtower 89/89.

## Gates

- [x] tests (npm run test)
- [x] typecheck (npm run typecheck)
- [x] lint (npm run lint)
- [x] security-scan (npm run secretlint)

## Approvals

| Role         | Verdict  | Date       | Signature           |
| ------------ | -------- | ---------- | ------------------- |
| gov-agent    | approved | 2026-08-10 | gentle-vanguard-bot |
| orchestrator | approved | 2026-08-10 | gentle-vanguard-bot |

## Rollout

- Activation date: 2026-08-10
- Notes: activado bajo el workflow MODULE-ACTIVATION-WORKFLOW.md; gates verificados con
  `src/module-maturity.ts --validate trust-layer-stage8 --run-checks`.
