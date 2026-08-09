# Module: fine-tuning-collector

- Status: approved
- Owner: ops-agent
- Risk: high
- Proposed: 2026-08-09

## Proposal

Activar el módulo `fine-tuning-collector` (src/fine-tuning-data-collector.ts) — recolecta datos de
conversación/sesión para fine-tuning futuro. Local-first: escribe a disco local (`.session/`),
sin envío a cloud.

- Scope: recolección de datos de sesión para entrenamiento.
- Impact: genera datasets locales; no afecta la ejecución de sesiones.
- Risk: high (maneja datos de prompts) — mitigado por almacenamiento local y sin exfiltración.
- Success criteria: CLI ejecutable, datos en `.session/`, gates verdes.

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
- Notes: activado con almacenamiento local-only (principio local-first).
