# MCP Bridge - Gentle-Vanguard

Exposes Gentle-Vanguard capabilities as an **MCP (Model Context Protocol)** server, enabling any
MCP-compatible tool to use Gentle-Vanguard's features.

---

## What is MCP?

Model Context Protocol (MCP) is a standard for AI tools to:

- **Expose tools** (executable actions)
- **Share resources** (readable data)
- **Use prompts** (predefined templates)

Any tool that supports MCP can connect to this server and access Gentle-Vanguard's capabilities.

---

## Quick Start

### Install Dependencies

```bash
cd adapters/mcp-bridge
npm install
```

### Build

```bash
npm run build
```

### Run Server

```bash
npm start
# Or for development with auto-reload:
npm run dev
```

---

## Exposed Tools

Gentle-Vanguard exposes these tools via MCP:

| Tool Name                  | Description              | Input Schema                             |
| -------------------------- | ------------------------ | ---------------------------------------- |
| `gentle-vanguard_review`        | Run 7D code review       | `{ path: string, dimensions: string[] }` |
| `gentle-vanguard_audit`         | Run workspace audit      | `{ mode: 'quick' \| 'full' }`            |
| `gentle-vanguard_delegate`      | Delegate to subagent     | `{ agent: string, prompt: string }`      |
| `gentle-vanguard_health`        | Check workspace health   | `{}`                                     |
| `gentle-vanguard_session_start` | Start new session        | `{ project: string }`                    |
| `gentle-vanguard_session_end`   | End session with summary | `{ sessionId: string }`                  |
| `gentle-vanguard_skill_list`    | List available skills    | `{}`                                     |
| `gentle-vanguard_skill_load`    | Load specific skill      | `{ skillName: string }`                  |

---

## Configuration for MCP Clients

### Windsurf (`~/.windsurf/mcp.json`)

```json
{
  "mcpServers": {
    "gentle-vanguard": {
      "command": "node",
      "args": ["/absolute/path/to/adapters/mcp-bridge/dist/server.js"],
      "env": {
        "GENTLE_VANGUARD_ROOT": "/path/to/gentle-vanguard"
      }
    }
  }
}
```

### OpenCode (`~/.config/opencode/mcp.json`)

```json
{
  "mcpServers": {
    "gentle-vanguard": {
      "command": "node",
      "args": ["/absolute/path/to/adapters/mcp-bridge/dist/server.js"]
    }
  }
}
```

### Claude Desktop (`~/.claude/mcp.json`)

```json
{
  "mcpServers": {
    "gentle-vanguard": {
      "command": "node",
      "args": ["/absolute/path/to/adapters/mcp-bridge/dist/server.js"]
    }
  }
}
```

### Cursor (`~/.cursor/mcp.json`)

```json
{
  "mcpServers": {
    "gentle-vanguard": {
      "command": "node",
      "args": ["/absolute/path/to/adapters/mcp-bridge/dist/server.js"]
    }
  }
}
```

---

## Tool Examples

### Run 7D Code Review

```typescript
// MCP client call
const result = await mcpClient.callTool({
  name: 'gentle-vanguard_review',
  arguments: {
    path: 'src/components/App.tsx',
    dimensions: ['security', 'quality', 'architecture'],
  },
});
// Returns: { content: [{ type: 'text', text: '...review results...' }] }
```

### Delegate to Subagent

```typescript
const result = await mcpClient.callTool({
  name: 'gentle-vanguard_delegate',
  arguments: {
    agent: 'sdd-apply',
    prompt: 'Implement the authentication feature from task #123',
  },
});
// Returns: { content: [{ type: 'text', text: '...delegation result...' }] }
```

---

## Architecture

```

   MCP Client      MCP Bridge       Gentle-Vanguard
 (Windsurf,                (this server)             Core
  Codex, etc.)


          MCP Protocol               Translates                  Calls
          (standard)                 to Gentle-Vanguard               Gentle-Vanguard
                                     CLI/Scripts                scripts
```

---

## Development

### Project Structure

```
mcp-bridge/
 package.json              # Dependencies (MCP SDK)
 tsconfig.json             # TypeScript config
 src/
    server.ts            # Main MCP server
    scripts/utilities/               # Tool implementations
       review.ts       # gentle-vanguard_review
       audit.ts        # gentle-vanguard_audit
       delegate.ts     # gentle-vanguard_delegate
       health.ts       # gentle-vanguard_health
       session.ts      # gentle-vanguard_session_*
    resources/          # MCP resources
    utils/              # Shared utilities
 dist/                   # Compiled JavaScript (gitignored)
```

---

## Error Handling

All tools return standardized error responses:

```typescript
// Success
{ content: [{ type: 'text', text: '...' }], isError: false }

// Error
{ content: [{ type: 'text', text: 'Error description' }], isError: true }
```

---

## Token Efficiency

The MCP Bridge maintains Gentle-Vanguard's token efficiency:

- Only sends necessary context
- Uses Gentle-Vanguard's compression strategies
- Respects memory tiering (hot/warm/cold)
- Logs token usage for monitoring

---

**Status**: Implementation Pending  
**Priority**: HIGH (covers 80% of non-standard tools)  
**Next**: Implement `server.ts` and `tools.ts`

