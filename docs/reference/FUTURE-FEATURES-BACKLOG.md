# DEPRECATED: El backlog oficial ahora vive en docs/backlog/items.json (JSON fuente) y docs/backlog/README.md (resumen generado). Este archivo queda solo como referencia histrica. Actualiza y consulta el backlog nicamente en docs/backlog/.

# Future Features Backlog

This file is the single source of truth for deferred improvements, optimizations, and future
features.

## Purpose

1. Keep pending items visible and queryable.
2. Avoid losing improvement ideas between sessions.
3. Normalize how deferred work is captured and revisited.

## Intake Rules

When a user decides to defer work, register one new item here with:

1. Date.
2. Scope.
3. Why deferred now.
4. Expected value.
5. Next review trigger.

## Confirmation Rules

Before adding an item, the orchestrator must request user confirmation if either condition is true:

1. The request is ambiguous (scope/outcome unclear).
2. The request appears redundant with an existing backlog item.

If the user confirms, append the item. If not confirmed, do not register it.

## Status Values

1. `pending`
2. `scheduled`
3. `in-progress`
4. `done`
5. `discarded`

## Backlog Items

| ID     | Date       | Theme                          | Description                                                                                                                                   | Priority | Status  | Owner          | Trigger to Revisit                                                                                         |
| ------ | ---------- | ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------- | -------------- | ---------------------------------------------------------------------------------------------------------- |
| FF-001 | 2026-04-13 | SDD CI Hardening               | Tighten SDD gate to require `validated`/`done` on PRs to protected branches.                                                                  | high     | done    | orchestrator   | Resuelto: `scripts/hooks/check-sdd-gate.ps1` + `.github/workflows/sdd-gate.yml`                            |
| FF-002 | 2026-04-13 | Process Metrics                | Add SDD process KPIs (spec coverage, lead time impact, rework ratio).                                                                         | high     | done    | orchestrator   | Resuelto: `scripts/utilities/TELEMETRY-METRICS/sdd-process-metrics.ps1`                                    |
| FF-003 | 2026-04-13 | Check Noise Reduction          | Reduce non-actionable CI warnings and improve blocking/advisory classification.                                                               | medium   | done    | orchestrator   | Resuelto: `scripts/hooks/hook-advisory-classifier.ps1`                                                     |
| FF-004 | 2026-04-13 | Sync Drift Prevention          | Add periodic drift report for Gentle-Vanguard vs consumers manifests/skills.                                                                       | medium   | done    | orchestrator   | Resuelto: `scripts/utilities/sync-drift-report.ps1` + `gv sync-drift`                                      |
| FF-005 | 2026-04-13 | PR Template Quality            | Standardize PR templates to include spec traceability and validation evidence.                                                                | medium   | done    | orchestrator   | Resuelto: `.github/PULL_REQUEST_TEMPLATE.md` con SDD ref + spec status + validation evidence               |
| FF-006 | 2026-04-13 | Local Workflow Performance     | Profile and optimize `gv health/verify` runtime for faster local loops.                                                                       | medium   | done    | orchestrator   | Resuelto: `scripts/utilities/gv-benchmark.ps1` — PASS en SLOs (status 1.8s, health 2.1s)                   |
| FF-007 | 2026-04-15 | Agent Result Schema            | Structured JSON output schema for sub-agent results to enable merge/consolidation.                                                            | high     | pending | agent-router   | When parallel execution is implemented.                                                                    |
| FF-008 | 2026-04-15 | Skills Auto-Discovery          | Script to auto-detect available skills in skills/ directory and generate mapping.                                                             | high     | pending | agent-router   | When new skills are added frequently.                                                                      |
| FF-009 | 2026-04-15 | Parallel Agent Dispatch        | Support `-Parallel` flag in agent-router for concurrent sub-agent execution.                                                                  | high     | done    | agent-router   | When agent result schema is stable.                                                                        |
| FF-010 | 2026-04-15 | Event Bus System               | Basic pub/sub event system for script hooks and automation triggers.                                                                          | medium   | done    | framework-core | When orchestration complexity increases.                                                                   |
| FF-011 | 2026-04-15 | Plugin Architecture            | Extensibility contract for third-party plugins with standardized interface.                                                                   | medium   | pending | framework-core | When community adoption grows.                                                                             |
| FF-012 | 2026-04-15 | Unified Metrics Dashboard      | Centralized metrics collection with HTML dashboard (Grafana postergado).                                                                      | medium   | done    | framework-core | Resuelto: `scripts/utilities/TELEMETRY-METRICS/generate-dashboard.ps1` — HTML + PDF/PNG export             |
| FF-013 | 2026-04-15 | SDD Governance Enforcement     | Mandatory SDD gate pre-merge with validated/done status.                                                                                      | high     | done    | AGENT-GOV      | Resuelto: `scripts/hooks/check-sdd-gate.ps1` + `.github/workflows/sdd-gate.yml`                            |
| FF-014 | 2026-04-17 | Legacy Toolchain Cleanup       | Complete removal of legacy optional integrations references and finalize native-only documentation/flows.                                     | high     | done    | AGENT-GOV      | Completed in current release.                                                                              |
| FF-015 | 2026-04-19 | Git Hooks Robustness           | Automatizar la verificación e instalación de hooks en setup/bootstrap de Gentle-Vanguard.                                                          | high     | done    | orchestrator   | Resuelto: `scripts/utilities/install-hooks.ps1` — auto-instala todos los hooks con logging                 |
| FF-016 | 2026-04-19 | Token Efficiency               | Evaluar integracin de RTK (Rust Token Killer) solo si los hooks/skills actuales no logran reducir el consumo de tokens en casos reales.       | low      | pending | orchestrator   | Cuando se detecte un cuello de botella real de consumo de tokens no mitigable por los mecanismos actuales. |
| FF-017 | 2026-04-19 | Auto-Actualizacin Skills/Tools | Implementar mecanismo de auto-actualizacin para skills y herramientas nativas para reducir mantenimiento manual y asegurar mejoras continuas. | medium   | pending | orchestrator   | Prxima release o cuando se detecten skills/herramientas desactualizadas.                                   |
| FF-018 | 2026-04-19 | Instalador Interactivo (TUI)   | Desarrollar instalador y configurador interactivo tipo TUI para facilitar onboarding y setup nativo de Gentle-Vanguard.                            | low      | pending | orchestrator   | Prxima release o cuando se priorice experiencia de onboarding.                                             |

## Notes

1. This backlog is reference-first and should stay concise.
2. Move completed items to `done` and keep rationale in-place for historical traceability.
3. Do not duplicate items; update existing rows when scope evolves.

