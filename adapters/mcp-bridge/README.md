# MCP Bridge - Foundation

Exposes Foundation capabilities as an **MCP (Model Context Protocol)** server, enabling any
MCP-compatible tool to use Foundation's features.

---

## What is MCP?

Model Context Protocol (MCP) is a standard for AI tools to:

- **Expose tools** (executable actions)
- **Share resources** (readable data)
- **Use prompts** (predefined templates)

Any tool that supports MCP can connect to this server and access Foundation's capabilities.

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

Foundation exposes these tools via MCP:

| Tool Name                  | Description              | Input Schema                             |
| -------------------------- | ------------------------ | ---------------------------------------- |
| `foundation_review`        | Run 7D code review       | `{ path: string, dimensions: string[] }` |
| `foundation_audit`         | Run workspace audit      | `{ mode: 'quick' \| 'full' }`            |
| `foundation_delegate`      | Delegate to subagent     | `{ agent: string, prompt: string }`      |
| `foundation_health`        | Check workspace health   | `{}`                                     |
| `foundation_session_start` | Start new session        | `{ project: string }`                    |
| `foundation_session_end`   | End session with summary | `{ sessionId: string }`                  |
| `foundation_skill_list`    | List available skills    | `{}`                                     |
| `foundation_skill_load`    | Load specific skill      | `{ skillName: string }`                  |

---

## Configuration for MCP Clients

### Windsurf (`~/.windsurf/mcp.json`)

```json
{
  "mcpServers": {
    "foundation": {
      "command": "node",
      "args": ["/absolute/path/to/adapters/mcp-bridge/dist/server.js"],
      "env": {
        "FOUNDATION_ROOT": "/path/to/foundation"
      }
    }
  }
}
```

### OpenCode (`~/.config/opencode/mcp.json`)

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

### Claude Desktop (`~/.claude/mcp.json`)

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

### Cursor (`~/.cursor/mcp.json`)

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

---

## Tool Examples

### Run 7D Code Review

```typescript
// MCP client call
const result = await mcpClient.callTool({
  name: 'foundation_review',
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
  name: 'foundation_delegate',
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

   MCP Client      MCP Bridge       Foundation
 (Windsurf,                (this server)             Core
  Codex, etc.)


          MCP Protocol               Translates                  Calls
          (standard)                 to Foundation               Foundation
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
       review.ts       # foundation_review
       audit.ts        # foundation_audit
       delegate.ts     # foundation_delegate
       health.ts       # foundation_health
       session.ts      # foundation_session_*
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

The MCP Bridge maintains Foundation's token efficiency:

- Only sends necessary context
- Uses Foundation's compression strategies
- Respects memory tiering (hot/warm/cold)
- Logs token usage for monitoring

---

**Status**: Implementation Pending  
**Priority**: HIGH (covers 80% of non-standard tools)  
**Next**: Implement `server.ts` and `tools.ts`
