---
created: 2026-08-14
tags: [#capabilities, #dashboard, #fase1, #fase2, #mcp, #decision]
status: accepted|proposed|rejected|deprecated
---

# ADR: Stack Capabilities Fase 1-2 Dashboard Integration

**Status:** {{status}} **Date:** 2026-08-14 **Owner:**

## Summary

Stack Capabilities Fase 1/2 - Integracion Dashboard. Capacidades: predictive-anomaly-detector (anomaly-state.json + anomaly-alerts.json), token-spike-guard, performance-metrics-collector, sequential-thinking MCP (5 tools: think_sequential, get_thought_chain, get_thought_summary, list_thought_chains, delete_thought_chain), multi-channel-alert, compare-tokens-sessions (npm run token:compare), self-healing-db (db-healing/state.json), circuit-breaker-v2 (circuit-breaker-v2/state.json). Integracion dashboard commit 46b86bcd: getStackCapabilities() en real-data.ts lee los 3 archivos de estado, StackCapabilitiesPanel.tsx, campo stackCapabilities en DashboardData, verificado en /api/metrics end-to-end. MCP fetch server commit 580ac825 con self-test --test (PASS 2 results), job mcp-servers en CI commit dfbe3f03. Aprendizajes: list_thought_chains usa campo id (no chainId); en Windows lanzar MCP con node --import tsx (spawn npx.cmd falla EINVAL en Node 24); token_transactions usa created_at (no timestamp); WS server requiere reinicio manual para cargar codigo nuevo.

## Context

## Decision

## Consequences

### Positive

-

### Negative

-

## Alternatives Considered

-

## Related Decisions

- [[]] -

## Notes

## Metadata

```json
{
  "adr_id": "Stack Capabilities Fase 1-2 Dashboard Integration",
  "title": "Stack Capabilities Fase 1-2 Dashboard Integration",
  "status": "{{status}}",
  "created": "2026-08-14"
}
```
