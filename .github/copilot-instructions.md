# Workspace Chat Enforcement

This repository enforces a compact chat response contract in the agent layer.

## Active Baseline

1. Language: `es`
2. Detail level: `simple`
3. Compression profile: `ultra`

## Chat Levels

The chat layer supports explicit levels mapped to detail/profile bundles:

1. `chat-compact` => `simple + ultra`
2. `chat-balanced` => `executive + lleno`
3. `chat-detailed` => `expanded + lite`

Runtime activation (orchestrator CLI):

1. `./scripts/utilities/wf.ps1 response-mode chat:chat-compact`
2. `./scripts/utilities/wf.ps1 response-mode chat:chat-balanced`
3. `./scripts/utilities/wf.ps1 response-mode chat:chat-detailed`

## Mandatory Output Contract

When no explicit escalation is requested:

1. Success format: `OK: <minimum verifiable result>`
2. Failure format: `ERROR: <brief cause> | ACTION: <minimum required step>`
3. Keep responses action-focused and closure-first.
4. Do not include optional suggestions unless explicitly authorized.
5. Keep warnings only for critical risk (security, data-loss, or high-confidence regression).

## Escalation Rules

Escalate detail only when one of these conditions applies:

1. Developer explicitly asks for more detail (`DETALLE`, `EXTENDER`, equivalent natural-language request).
2. Critical risk requires additional explanation to avoid unsafe action.

When escalating:

1. State escalation reason in one short line.
2. Return to simple mode after resolving the escalation context.

## Scope

This file complements runtime orchestration config in `config/orchestrator.json`.
It exists to enforce style at the chat/agent layer, not only at script/config level.