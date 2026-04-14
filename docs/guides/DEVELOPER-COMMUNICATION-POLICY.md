# Developer Communication Policy

## Purpose

Standardize agent-to-developer communication to reduce ambiguity, token waste, and unnecessary back-and-forth.

## Default Mode

1. Default mode is `executive`.
2. Responses must be short, clear, and action-focused.
3. Use plain language and avoid unnecessary narrative.

## Minimal Mode (`simple`)

Use `simple` mode when the developer wants the lowest possible token usage and closure-first output.

Activation triggers:

- `SIMPLE`
- `RESUMEN`
- Equivalent explicit request in natural language (for example: "solo cierre", "respuesta mínima").

`simple` response contract:

1. Success: `OK: cerrado` (or `OK: <resultado mínimo verificable>`).
2. Failure: `ERROR: <causa breve> | ACCION: <paso mínimo requerido>`.
3. Do not include optional suggestions unless explicitly authorized.
4. Keep warnings only for critical risk (security/data-loss/regression).

## Detail Escalation

Use extended detail only when the developer explicitly requests it.

Approved triggers:

- `EXTENDER`
- `DETALLE`
- Explicit equivalent request in natural language.

Without one of those triggers, keep executive mode.

## Risk-Based Escalation (Orchestrator)

The orchestrator may request a temporary response-level escalation when risk is high.

Escalation model:

1. Minimal on request: `simple`.
2. Default: `executive`.
3. Escalate to `standard` for medium risk:
	- ambiguous requirement with implementation impact
	- non-trivial integration or migration risk
4. Escalate to `deep` for high risk:
	- security, data-loss, compliance, or critical regression risk
	- architecture decisions with broad blast radius

When escalation is applied, the agent must:

1. State why escalation is needed in one short line.
2. Ask for developer authorization before keeping the higher level for subsequent responses.

## Authorization Gate for Suggestions

The agent must not proactively push optional improvements, refactors, or scope expansions unless the developer authorizes suggestions.

Approved trigger examples:

- `AUTORIZO SUGERENCIAS`
- `PROPON MEJORAS`

If no authorization is given, deliver only what was requested.

## Critical Exceptions

Even in executive mode, the agent must immediately warn about:

1. Security risks.
2. Potential data loss or destructive operations.
3. High-confidence behavioral regressions.

Warnings must remain concise and actionable.

## Stable Response Contract

For normal operational responses:

1. Decision.
2. Action taken.
3. Result.
4. Next step only if needed.

## Documentation Scope Optimization

Optimization applies selectively, not globally.

Optimize for concise output (executive-first + optional details) in:

1. Review reports.
2. Audit/session closure outputs.
3. Operational status and handoff notes.

Do not compress core knowledge documents that require full traceability and technical depth:

1. Architecture and design documentation.
2. Implementation and technical guides.
3. Business and product documentation.

Rule: keep foundational/technical/business documents complete; optimize only operational/transient artifacts.

## Governance

This policy is enforced as a required governance artifact by:

- `scripts/diagnostics/validate-script-governance.ps1`

Any removal or relocation must be approved by the developer and updated in governance rules.
