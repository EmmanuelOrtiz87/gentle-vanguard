# Cloud Agent Security Guide

## Overview
Foundation's Cloud Agent Connector supports secure connections to external AI providers (AWS Bedrock, Difi, Azure, OpenAI, Anthropic, Gemini, Ollama).

**For complete setup and usage guide, see:** [CLOUD-AGENT-CONNECTOR.md](CLOUD-AGENT-CONNECTOR.md)

## Quick Security Rules

1. **Never commit secrets** - `cloud-agents.local.json` is gitignored
2. **Use environment variables** for production credentials
3. **Least privilege** - Minimum required IAM permissions
4. **Rotate keys** - Every 90 days
5. **Audit logs** - All requests logged to `telemetry-master.csv`

## Secret Management Hierarchy

| Level | Method | Security |
|-------|--------|----------|
| 1 | Environment variables | Highest |
| 2 | `cloud-agents.local.json` | High (gitignored) |
| 3 | `config/cloud-agents.json` | Template only (no secrets) |

## Quick Setup

```powershell
# 1. Create local configuration
.\scripts\utilities\invoke-cloud-agent.ps1 -Config
# Select option 2

# 2. Add your API keys as environment variables
$env:OPENAI_API_KEY = "sk-..."

# 3. Enable provider in cloud-agents.local.json
# Set "enabled": true for your provider

# 4. Test connection
.\scripts\utilities\invoke-cloud-agent.ps1 -Provider openai -TestConnection
```

## Common Issues

| Error | Cause | Solution |
|-------|-------|----------|
| "Auth Failed" | Missing API key | Check `$env:YOUR_API_KEY` is set |
| "Narration error" | Model talked instead of acting | Use `-StrictJson` flag |
| "Connection timeout" | Network issue | Check firewall/proxy |

## Provider-Specific Notes

### AWS Bedrock
- Use IAM credentials with `bedrock:InvokeModel` only
- Consider VPC endpoints for production

### OpenAI/Azure
- Set API key in environment: `$env:OPENAI_API_KEY`
- Rate limits apply per API key

### Ollama (Local)
- No API key needed
- Ensure service running: `ollama serve`

## Files

| File | Git | Purpose |
|------|-----|---------|
| `invoke-cloud-agent.ps1` | Yes | Main script |
| `config/cloud-agents.json` | Yes | Template (no secrets) |
| `config/cloud-agents.local.json` | **NO** | Your secrets |
| `telemetry-master.csv` | No | Audit log |
