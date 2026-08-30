# ADR-0023: Response Cache — Capability Without Current Integration Point

**Status**: Accepted  
**Date**: August 30, 2026  
**Scope**: Gentle-Vanguard LLM call path

## Context

The integration audit (2026-08-30) revealed that the response cache subsystem is **initialized but
not connected to the real LLM call path**. The following components exist and are functional:

- `src/resilience/response-cache.ts` — the `ResponseCache` class (get/set, TTL, stats).
- `src/core/session-cache-auto.ts` — auto-initializes a `ResponseCache` instance at session start
  (imported by `session-autostart.ts:16`, auto-init block at lines 266-278).
- `src/ml/llm-call-wrapper.ts` — `wrapLLMCall` (line 210).
- `src/core/orchestrator-cache-wrapper.ts` — `orchestratorWithCache` (line 130).
- `src/core/orchestrator-cache-plugin.ts` — plugin-style interceptor.
- `src/resilience/response-cache-orchestrator.ts` — auxiliary CLI (`--before`/`--after`).

The audit found that `wrapLLMCall`, `orchestratorWithCache`, and `orchestrator-cache-plugin` have
**zero importers** in `src/` — they are dead code from the runtime's perspective. The cache is
initialized at session start but never consulted to serve or route actual LLM/orchestrator traffic.

## Root Cause

The actual LLM calls in this stack happen inside the **external opencode runtime**, not in this
codebase. The cache wrappers were designed to intercept calls that never route through this code:

- The stack's own orchestrator does not make LLM calls through `wrapLLMCall`.
- The external runtime does not import or invoke any of these modules.
- `response-cache-orchestrator.ts` itself documents (header lines 12-15) that "the real integration
  should be done in session-autostart.ts" and "each orchestrator response should use ResponseCache
  class" — but no such wiring was ever completed.

## Decision

**Do not force a connection.** The cache is a real, working component, but its intended integration
point does not exist in the current architecture. Forcing a connection would be "baling wire" —
exactly the anti-pattern this stack rejects.

Instead:

1. **Keep the cache initialized** at session start (`session-cache-auto.ts`) — it is harmless,
   provides stats, and is ready for future use.
2. **Document this ADR** as the authoritative record of the decision.
3. **Do NOT** add fake call sites, mock integrations, or "presence without integration" wiring.
4. **Future integration path** (when/if the stack gains its own LLM call path, e.g., an MCP server
   or a local model gateway): connect `wrapLLMCall`/`orchestratorWithCache` at that point, with real
   traffic flowing through them and measurable cache-hit savings.

## Consequences

- **Positive**: Honest architecture. No dead-weight glue. The cache remains available and
  initialized for when a real integration point exists.
- **Negative**: The cache currently delivers no token savings. This is acknowledged and accepted
  rather than faked.
- **Monitoring**: `response-cache.ts stats` and `session-cache-auto --stats` remain available to
  confirm the cache is healthy and ready.

## Alternatives Considered

- **Force-connect via MCP server**: Would require building an MCP server that intercepts the
  external runtime's calls. Large architectural change with unclear benefit while the external
  runtime manages its own caching. Rejected for now.
- **Remove the cache entirely**: Would lose a working, tested component. Rejected — the cache is
  sound and the integration point may materialize.
- **Fake call sites**: Adding imports/calls that don't route real traffic. Rejected — this is the
  "presence without integration" anti-pattern.
