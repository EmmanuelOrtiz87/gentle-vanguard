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

| ID     | Date       | Theme                      | Description                                                                     | Priority | Status  | Owner        | Trigger to Revisit                                         |
| ------ | ---------- | -------------------------- | ------------------------------------------------------------------------------- | -------- | ------- | ------------ | ---------------------------------------------------------- |
| FF-001 | 2026-04-13 | SDD CI Hardening           | Tighten SDD gate to require `validated`/`done` on PRs to protected branches.    | high     | pending | orchestrator | When current SDD baseline is stable for one full sprint.   |
| FF-002 | 2026-04-13 | Process Metrics            | Add SDD process KPIs (spec coverage, lead time impact, rework ratio).           | high     | pending | orchestrator | When at least 10 PRs have passed through current SDD gate. |
| FF-003 | 2026-04-13 | Check Noise Reduction      | Reduce non-actionable CI warnings and improve blocking/advisory classification. | medium   | pending | orchestrator | When warning volume affects merge throughput.              |
| FF-004 | 2026-04-13 | Sync Drift Prevention      | Add periodic drift report for Gentle-Vanguard vs consumers manifests/skills.    | medium   | pending | orchestrator | When multi-repo sync cadence increases.                    |
| FF-005 | 2026-04-13 | PR Template Quality        | Standardize PR templates to include spec traceability and validation evidence.  | medium   | pending | orchestrator | When next workflow template update is scheduled.           |
| FF-006 | 2026-04-13 | Local Workflow Performance | Profile and optimize `gv health/verify` runtime for faster local loops.         | medium   | pending | orchestrator | When local validation runtime exceeds agreed SLO.          |

## Notes

1. This backlog is reference-first and should stay concise.
2. Move completed items to `done` and keep rationale in-place for historical traceability.
3. Do not duplicate items; update existing rows when scope evolves.
