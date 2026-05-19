---
name: cloud-agent-connector
description: >
  Standards and utilities for connecting to external cloud AI agents (Difi, Azure, OpenAI,
  Anthropic, Gemini, Ollama, and Bedrock via signed proxy). Supports command, script, interactive,
  and agent modes with secure secret management. Trigger: "cloud agent", "bedrock", "difi",
  "external model", "api connection", "invoke cloud"
---

## Purpose

Enable Gentle-Vanguard to delegate tasks to high-performance cloud models while maintaining
security, traceability, and strict tool-use protocols.

## Execution Modes

### 1. Command Mode (Single task)

```powershell
.\scripts\utilities\invoke-cloud-agent.ps1 -Provider openai -Command "Explain REST pagination"
```

### 2. Script Mode (Execute file)

```powershell
.\scripts\utilities\invoke-cloud-agent.ps1 -Provider openai -Script ".\tasks\analyze.ps1"
```

### 3. Interactive Mode (Manual)

```powershell
.\scripts\utilities\invoke-cloud-agent.ps1 -Interactive
```

### 4. Agent Mode (Delegated task)

```powershell
.\scripts\utilities\invoke-cloud-agent.ps1 -Provider anthropic -Agent "Refactor auth module"
```

### 5. Strict JSON Mode (Automation)

```powershell
.\scripts\utilities\invoke-cloud-agent.ps1 -Provider openai -StrictJson -Command "Return JSON"
```

## Supported Providers

| Provider            | Env Variable                                           | Use Case                       |
| ------------------- | ------------------------------------------------------ | ------------------------------ |
| AWS Bedrock (proxy) | Proxy-specific credentials (`auth_type: proxy_signed`) | Claude on AWS via signed proxy |
| OpenAI              | OPENAI_API_KEY                                         | GPT models                     |
| Anthropic           | ANTHROPIC_API_KEY                                      | Direct Claude                  |
| Azure               | AZURE_OPENAI_KEY                                       | GPT on Azure                   |
| Difi                | DIFI_API_KEY                                           | Custom platform                |
| Ollama              | None (local)                                           | Local models                   |

## Security Model

### Secret Management Hierarchy

1. **Environment variables** (highest security) - For production
2. **cloud-agents.local.json** (gitignored) - For provider metadata only (no secrets)
3. **config/cloud-agents.json** (committed) - Template only

### Configuration Files

```
config/
 cloud-agents.json          # SHARED template (no secrets)
 cloud-agents.local.json    # LOCAL provider metadata (GITIGNORED)
```

## Protocol: Preventing "Narration Errors"

Always use `-StrictJson` flag for automation:

```powershell
.\scripts\utilities\invoke-cloud-agent.ps1 -Provider openai -StrictJson -Command "..."
```

This injects:

> "STRICT MODE: You are an execution engine. Return ONLY valid JSON tool calls. No narration."

## Workflow

1. **Load Config:** Read from `cloud-agents.local.json` or `config/cloud-agents.json`
2. **Auth:** Inject API keys from environment
3. **Dispatch:** Send with default `temperature=0.1` (configurable) and optional strict JSON mode
4. **Validate:** Prefer strict JSON mode (`-StrictJson`) and validate responses in caller workflows
5. **Log:** Record runtime telemetry to `.runtime/telemetry/cloud-agent-telemetry.csv`

## Quick Commands

```powershell
invoke-cloud-agent.ps1 -ListProviders    # Show all providers
invoke-cloud-agent.ps1 -TestConnection    # Test current provider
invoke-cloud-agent.ps1 -Config           # Interactive config
```
