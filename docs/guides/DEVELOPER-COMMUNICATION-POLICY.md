# Developer Communication Policy

## Purpose

Standardize agent-to-developer communication to reduce ambiguity, token waste, and unnecessary back-and-forth.

## Default Mode

1. Default mode is `executive`.
2. Responses must be short, clear, and action-focused.
3. Use plain language and avoid unnecessary narrative.

## Detail Escalation

Use extended detail only when the developer explicitly requests it.

Approved triggers:

- `EXTENDER`
- `DETALLE`
- Explicit equivalent request in natural language.

Without one of those triggers, keep executive mode.

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

## Governance

This policy is enforced as a required governance artifact by:

- `scripts/diagnostics/validate-script-governance.ps1`

Any removal or relocation must be approved by the developer and updated in governance rules.
