# Module: skill-evolution-engine

- Status: approved
- Owner: orchestrator
- Risk: medium
- Proposed: 2026-08-10

## Proposal

Activar el módulo `skill-evolution-engine` (src/skills/skill-evolution-engine.ts) bajo el workflow
de activación de módulos experimentales (Fase 1 de madurez). Motor de evolución de skills y agentes:
analiza uso de skills, detecta gaps, sugiere refinamientos y depreca skills no usadas.

- Scope: mejora continua de los 175 skills y agentes del stack.
- Impact: mantiene el ecosistema de skills saludable; no toca el core de sesión.
- Risk: medio (deprecación de skills no usadas requiere revisión manual antes de aplicar).
- Success criteria: CLI ejecutable con --analyze, typecheck/lint/tests verdes, watchtower 89/89.

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
  `src/module-maturity.ts --validate skill-evolution-engine --run-checks`. Ya es step lazy en
  session-autostart (enabled: true).
