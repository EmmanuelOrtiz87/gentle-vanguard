# Backlog de Desarrollo

> **Nota:** Este archivo es generado automáticamente a partir de `items.json`.

## Resumen

| Estado      | Cantidad |
| ----------- | -------- |
| Completado  | 12       |
| Deferred    | 1        |
| Pendiente   | 0        |

## Lista Detallada

| ID     | Título                     | Prioridad | Estado  | Owner        | Resuelto por                                                          |
| ------ | -------------------------- | --------- | ------- | ------------ | --------------------------------------------------------------------- |
| FF-001 | SDD CI Hardening           | high      | ✅ done | orchestrator | `scripts/hooks/check-sdd-gate.ps1` + `.github/workflows/sdd-gate.yml` |
| FF-002 | Process Metrics            | high      | ✅ done | orchestrator | `scripts/utilities/TELEMETRY-METRICS/sdd-process-metrics.ps1`         |
| FF-003 | Check Noise Reduction      | medium    | ✅ done | orchestrator | `scripts/hooks/hook-advisory-classifier.ps1`                          |
| FF-004 | Sync Drift Prevention      | medium    | ✅ done | orchestrator | `scripts/utilities/sync-drift-report.ps1`                             |
| FF-005 | PR Template Quality        | medium    | ✅ done | orchestrator | `.github/PULL_REQUEST_TEMPLATE.md`                                    |
| FF-006 | Local Workflow Performance | medium    | ✅ done | orchestrator | `scripts/utilities/gv-benchmark.ps1`                                  |
| FF-013 | Runtime Router Gating      | high      | ✅ done | AGENT-GOV    | `scripts/utilities/WORKFLOW-ORCHESTRATION/runtime-router.ps1`         |
| FF-007 | Agent Result Schema         | high      | ✅ done | framework-core | `config/agent-result-schema.json`                                    |
| FF-008 | Skills Auto-Discovery       | high      | ✅ done | framework-core | `scripts/utilities/SKILLS-TOOLS/skills-discovery.ps1`                |
| FF-017 | Auto-Actualización Skills   | medium    | ✅ done | framework-core | `scripts/utilities/SKILLS-TOOLS/auto-update-skills.ps1`              |
| FF-011 | Plugin Architecture         | medium    | ✅ done | framework-core | `config/plugin-manifest-schema.json`, `plugins-discovery.ps1`, `plugin-loader.ps1` |
| FF-016 | Token Efficiency / RTK      | low  | ⏸️ deferred | orchestrator  | Current stack sufficient (30-40% compression, ~32% max budget). See evaluation. |
| FF-018 | TUI Installer               | low       | ✅ done | orchestrator  | `scripts/utilities/gentle-vanguard-installer-tui.ps1`                    |

---

_Generado: 2026-05-10 — sincronizado con items.json_  
_Total: 11 done, 2 pending — única fuente de verdad: `docs/backlog/items.json`_

