# Stack Reset Report - 2026-08-08

## Summary

Complete stack reset and Bedrock compatibility fixes applied.

## Changes Applied

### 1. Token Budget Reset ✅

- Reset metrics.json to 0 tokens
- Daily budget: 5,000,000 tokens
- Session budget: 3,000,000 tokens

### 2. opencode.json Fixes ✅

Added `litellm_settings.drop_params: true` to 15 agents:
- ops-agent
- gov-agent
- session-agent
- premortem-agent
- maintenance-agent
- gitflow-agent
- self-diag-agent
- knowledge-agent
- mkt-agent
- sales-agent
- finance-agent
- hr-agent
- legal-agent
- bus-tele-agent
- sia-agent

### 3. Database Status

- Nexus DB: 23 tables, 29,546 rows
- Integrity: OK
- 7 migrations applied

## Pre-flight Checklist

- [ ] Run `npm run health:check`
- [ ] Run `npm run watchtower:health`
- [ ] Verify MCP servers: `npm run mcp:status`
- [ ] Test agent delegation: `npm run test:agent`

## Bedrock Compatibility

The `drop_params: true` setting ensures that unsupported parameters like `reasoning_effort` are automatically dropped when calling Bedrock models.
