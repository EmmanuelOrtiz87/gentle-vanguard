# Adapter Examples

Quick reference for using Foundation adapters with various tools.

---
## MCP Bridge Examples

### 1. Configure Windsurf to use Foundation

**File**: `~/.windsurf/mcp.json`

```json
{
  "mcpServers": {
    "foundation": {
      "command": "node",
      "args": ["/absolute/path/to/adapters/mcp-bridge/dist/server.js"],
      "env": {
        "FOUNDATION_ROOT": "/path/to/workspace-foundation"
      }
    }
  }
}
```

**Use in Windsurf**:
```
User: "Run a 7D review on src/components/App.tsx"
Windsurf calls: foundation_review({ path: "src/components/App.tsx" })
```

---
### 2. Configure Codex to use Foundation

**File**: `~/.codex/mcp.json` (if Codex supports MCP)

```json
{
  "mcpServers": {
    "foundation": {
      "command": "node",
      "args": ["/absolute/path/to/adapters/mcp-bridge/dist/server.js"]
    }
  }
}
```

**Alternative**: Use Codex Adapter (if no MCP support)

```bash
# Start proxy
node adapters/format-adapters/codex-adapter/proxy.js --port 8080

# Configure Codex
export OPENAI_API_BASE="http://localhost:8080/v1"
```

---
### 3. Call Foundation Tools via MCP

**Example: Run 7D Code Review**

```typescript
// Any MCP client can call:
const result = await mcpClient.callTool({
  name: 'foundation_review',
  arguments: {
    path: 'src/components/App.tsx',
    dimensions: ['security', 'quality', 'architecture'],
    mode: 'full'
  }
});

console.log(result.content[0].text); // Review output
```

**Example: Delegate to Subagent**

```typescript
const result = await mcpClient.callTool({
  name: 'foundation_delegate',
  arguments: {
    agent: 'sdd-apply',
    prompt: 'Implement the authentication feature from task #123'
  }
});
```

---
## Format Adapter Examples

### Windsurf Adapter (Planned)

```bash
# Convert Foundation skill to Windsurf format
node adapters/format-adapters/windsurf-adapter/adapter.js \
  --input skills/react-19-skill/SKILL.md \
  --output ~/.windsurf/skills/react-19.md

# Windsurf now has React 19 skill loaded
```

### Codex Adapter (Planned)

```bash
# Start OpenAI-compatible proxy
node adapters/format-adapters/codex-adapter/proxy.js --port 8080

# Codex configuration
export OPENAI_API_BASE="http://localhost:8080/v1"
export OPENAI_API_KEY="dummy"  # Not needed for local

# Codex now uses Foundation via OpenAI API
```

---
## Enhanced Detection Examples

### Run Detection

```powershell
# Basic detection
.\adapters\detection\enhanced-detect.ps1

# Output:
# === Foundation Enhanced Detection ===
# Tool: windsurf (Windsurf)
# Confidence: medium (source: env/process)
# Detection: WINDSURF_ env or process name
#
# Capabilities: ai_chat, code_generation
# Supports MCP: False
# Supports Skills: False
#
# === Adapter Status ===
# MCP Bridge: True
# Format Adapter: False
#
# === Recommendation ===
# Use MCP Bridge at adapters/mcp-bridge
```

### JSON Output (for automation)

```powershell
$detection = .\adapters\detection\enhanced-detect.ps1 -AsJson | ConvertFrom-Json

if (-not $detection.supportsMcp) {
  Write-Host "Tool doesn't support MCP. Use format adapter."
  if ($detection.adapterStatus.formatAdapter.available) {
    Write-Host "Adapter found at: $($detection.adapterStatus.formatAdapter.path)"
  }
}
```

---
## End-to-End Flow Examples

### Scenario 1: Windsurf User Wants 7D Review

```
1. User: "Review my code for security issues"
2. Windsurf detects: doesn't have native 7D review
3. Enhanced Detection: tool=windsurf, supportsMcp=false
4. Recommendation: Use MCP Bridge
5. Windsurf (if MCP configured):
   - Calls foundation_review via MCP
   - Gets review results
   - Displays to user
```

### Scenario 2: Codex User Wants to Delegate Task

```
1. User: "Implement the login feature using SDD"
2. Codex detects: can use OpenAI functions
3. Codex Adapter (proxy):
   - Receives OpenAI function call
   - Translates to foundation_delegate
   - Executes via Foundation CLI
   - Returns result in OpenAI format
4. Codex displays result to user
```

---
## Troubleshooting

### MCP Bridge not connecting

```bash
# Check if server starts
node adapters/mcp-bridge/dist/server.js
# Should output: "Foundation MCP Bridge running on stdio"

# Check FOUNDATION_ROOT
echo $env:FOUNDATION_ROOT
# Should point to workspace-foundation directory
```

### Detection showing "unknown"

```powershell
# Check environment variables
Get-ChildItem env: | Where-Object { $_.Name -like "*WINDSURF*" }

# Check parent processes
.\adapters\detection\enhanced-detect.ps1 -Verbose
```

---
**Status**:  Work in Progress  
**Last Updated**: 2026-04-28
