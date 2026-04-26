# Workspace Agent Bootstrap (Agnostic)

This file defines agent-agnostic startup behavior for this workspace.

## Startup Rule

Before substantial work in a new conversation, run:

1. `tools/session-autostart.cmd` on Windows, or
2. `bash ./tools/session-autostart.sh` on Linux/macOS/WSL.

Default behavior is controlled by `tools/session-autostart.config.json`.

## Session Tracking Rule

When session tracking capability exists, initialize a session early using:

1. `project = workspace_local`
2. `directory = c:\Workspace_local`
3. session id pattern `session-YYYY-MM-DD-XX`

## Reliability Rule

1. Treat `READY` as pass.
2. Treat `PARTIAL` as actionable and resolve before deep implementation.
3. Use `full` mode before release-critical work.

## Context Optimization (Token Efficiency)

### Memory Tiering
- **Hot**: Active session, no compression
- **Warm**: Recent (1 day), 90% retention
- **Cold**: Archive (7 days), 70% retention

### Handoff Compression Mode
For agent-to-agent transfers, use `tools/handoff-compress.ps1`:
- Preserves: decisions, results, FIXMEs, status flags
- Truncates: verbose outputs, repeated patterns
- Output: state-only handoff (~30% size reduction)

### Pre-Compact Hook
Before context compaction (every ~25k tokens), run:
```powershell
.\tools\pre-compact-hook.ps1 -ProjectName "workspace_local" -CompressionRatio 0.90
```
Preserves anchored content (FIXME, TODO, BUG, DECISION, RESULT).

### Adaptive Skill Loading
Skills auto-load based on project context:
| Signal | Skill |
|--------|-------|
| Angular component | angular-core, angular-spa |
| React TSX | react-19 |
| Go files | golang-api |
| Docker files | docker-devops |
| PowerShell scripts | workspace-automation |
| Session management | session-lifecycle |

See: `rules/adaptive/` for dynamic rule configuration.

## Auto-Delegation Rule (MANDATORY)

Before processing ANY user request, you MUST:

1. **Route task automatically** to determine which subagent(s) are needed:
```powershell
# Quick test - detect intent and agent
.\scripts\utilities\auto-delegation-wrapper.ps1 "<user-request>"
# Or use skill-router for restricted operations:
.\scripts\utilities\skill-router.ps1 -Query "<what-user-wants>"
```

2. **If the task involves security, orchestrator, skills, or restricted operations**, validate access:
```powershell
.\scripts\utilities\skill-router.ps1 -Query "<what-user-wants>"
# BLOCKED if requires auth → authenticate first
.\scripts\utilities\auth-session.ps1 -ApiKey "fnd_local_2026_Emmanuel_"
```

3. **Proceed** after routing decision is made with appropriate agent/skill.

**Never process any user request without first routing it.**

## Workspace-Specific Skills

### Automation Skills

| Skill | Trigger | Path |
|-------|---------|------|
| `workspace-automation` | When creating PowerShell scripts, configuring scheduled tasks, or automating workspace tasks | [`skills/workspace-automation/SKILL.md`](skills/workspace-automation/SKILL.md) |
| `session-lifecycle` | When managing session start/end, implementing session hooks, or tracking session state | [`skills/session-lifecycle/SKILL.md`](skills/session-lifecycle/SKILL.md) |

**Usage**: These skills are automatically loaded when working with workspace automation. Load manually with:
```
Read skills/workspace-automation/SKILL.md before creating automation scripts
Read skills/session-lifecycle/SKILL.md before modifying session management

## Required Tools

The following tools should be installed for complete Foundation functionality:

### Core Tools
| Tool | Purpose | Installation |
|------|---------|--------------|
| `lefthook` | Git hooks management | `npm install -g lefthook` |
| `prettier` | Code formatting | `npm install -D prettier` |
| `commitlint` | Commit validation | `npm install -D @commitlint/cli` |

### Security Tools
| Tool | Purpose | Installation |
|------|---------|--------------|
| `trufflehog` | Secrets detection | `choco install trufflehog` |
| `git-secrets` | AWS secrets prevention | git clone + make |

### MCP Servers (Model Context Protocol)
| Server | Purpose |
|--------|----------|
| `@modelcontextprotocol/server-filesystem` | File system access |
| `@modelcontextprotocol/server-git` | Git operations |
| `@modelcontextprotocol/server-sqlite` | Database queries |

## Security Rules

### Secrets Detection
NEVER commit secrets, API keys, or credentials. Always:
1. Use `.env` files (never commit `.env`)
2. Add secrets to `.gitignore`
3. Use `trufflehog` before committing:
   ```powershell
   trufflehog filesystem .
   ```

### Git Hooks
The following hooks are configured:
- `pre-commit`: Lint, format, secrets scan
- `pre-push`: Tests, judgment day
- `commit-msg`: Conventional commits validation

### Vulnerability Scanning
Run dependency audit regularly:
```powershell
npm audit
# or
pip audit
```

## Monitoring & Observability

### Metrics Endpoints
| Endpoint | Description |
|----------|-------------|
| `/api/v1/metrics` | Session and token metrics |
| `/api/v1/health` | System health check |

### Telemetry
- Distributed tracing: `.telemetry/`
- Session metrics: `.session/metrics/`
- Telemetry master: `docs/management/telemetry-master.csv`

## MCP Integration

MCP servers provide tool integration to LLMs:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/root"]
    },
    "git": {
      "command": "npx", 
      "args": ["-y", "@modelcontextprotocol/server-git"]
    }
  }
}
```

## Plugin System

Foundation supports plugins in `plugins/` directory:

```
plugins/
├── my-plugin/
│   ├── SKILL.md
│   ├── hooks/
│   └── scripts/
```

**Usage**:
```powershell
wf plugins list
wf plugins install <name>
wf plugins uninstall <name>
```
```
