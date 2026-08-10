# Module: predictive-governor

- Status: approved
- Owner: ops-agent
- Risk: high
- Proposed: 2026-08-10

## Proposal

Activar el módulo `predictive-governor` (src/predictive-governor.ts) bajo el workflow de activación
de módulos experimentales (Fase 1 de madurez). Gobernador predictivo de recursos: anticipa carga
basándose en patrones de uso, precalienta recursos y ajusta presupuestos de tokens.

- Scope: planificación anticipada de recursos (CPU/tokens/budgets) para la pipeline de sesión.
- Impact: mejora la eficiencia de costos; no toca el core de sesión.
- Risk: alto (ajusta presupuestos de tokens de forma autónoma — requiere dry-run primero).
- Success criteria: CLI ejecutable con --analyze/--prewarm/--adjust, typecheck/lint/tests verdes,
  watchtower sigue 89/89.

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
  `src/module-maturity.ts --validate predictive-governor --run-checks`. Ya es step lazy en
  session-autostart (enabled: true).
