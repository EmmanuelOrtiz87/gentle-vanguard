# Module: cross-workspace-mesh

- Status: approved
- Owner: ops-agent
- Risk: high
- Proposed: 2026-08-10

## Proposal

Activar el módulo `cross-workspace-mesh` (src/cross-workspace-validator.ts) bajo el workflow de
activación de módulos experimentales (Fase 1 de madurez). Validador del mesh multi-workspace:
verifica la consistencia de referencias entre workspaces y ofrece auto-fix (--fix).

- Scope: integridad del cross-workspace mesh (referencias, configs, agentes entre workspaces).
- Impact: detecta referencias rotas entre workspaces; no toca el core de sesión.
- Risk: alto (auto-fix de referencias cruzadas puede romper configs — requiere --detailed primero).
- Success criteria: CLI ejecutable con --detailed/--fix, typecheck/lint/tests verdes, watchtower
  89/89.

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
  `src/module-maturity.ts --validate cross-workspace-mesh --run-checks`.
