---
name: cloud-agent-connector-skill
description: >
  Standards for connecting to external cloud AI agents (AWS Bedrock, Difi, Azure).
  Trigger: "cloud agent", "bedrock", "difi", "external model", "api connection"
---

## Purpose
Enable Foundation to delegate tasks to high-performance cloud models while maintaining security, traceability, and strict tool-use protocols.

## Security & Configuration

### 1. Secrets Management (NEVER commit secrets)
Store credentials in `.env.local` (gitignored) or system environment variables:
```powershell
# .env.local (Example)
BEDROCK_API_KEY=your_key_here
DIFI_ENDPOINT=https://api.difi.ai/v1
```

### 2. Connection Script (`invoke-cloud-agent.ps1`)
- Reads secrets from environment.
- Enforces `JSON-only` response mode to prevent "narration errors".
- Logs metadata (tokens, latency) to `telemetry-master.csv`.

## Protocol: Preventing "Narration Errors"
When calling cloud APIs, always inject this system instruction:
> "STRICT MODE: You are an execution engine. Do not provide conversational filler. Return ONLY valid JSON tool calls or the requested data structure. If you cannot execute, return an error code."

## Workflow
1. **Load Config:** Read target endpoint from `config/cloud-agents.json`.
2. **Auth:** Inject API keys securely.
3. **Dispatch:** Send task with `temperature=0` (for determinism) and `json_mode=true`.
4. **Validate:** Ensure response is a valid tool call or data payload.
5. **Log:** Record success/failure in telemetry.
