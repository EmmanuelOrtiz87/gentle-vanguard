# Module: proactive-intelligence

- Status: approved
- Owner: orchestrator
- Risk: high
- Proposed: 2026-08-10

## Proposal

Activar el módulo `proactive-intelligence` (src/ml/proactive-intelligence-engine.ts) bajo el workflow
de activación de módulos experimentales (Fase 1 de madurez). Motor de inteligencia proactiva:
anticipa necesidades del usuario basándose en patrones de uso y contexto de sesión.

- Scope: sugerencias proactivas y anticipación de acciones para el orquestador.
- Impact: mejora la experiencia del usuario; no toca el core de sesión.
- Risk: alto (analiza patrones de uso — privacidad de datos de sesión).
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
  `src/module-maturity.ts --validate proactive-intelligence --run-checks`. Ya es step lazy en
  session-autostart (enabled: true).
