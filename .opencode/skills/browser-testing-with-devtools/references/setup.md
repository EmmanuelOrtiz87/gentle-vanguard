# Setup — Chrome DevTools MCP

## Installation

Add to your project's `.mcp.json` or equivalent MCP server config:

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": ["-y", "chrome-devtools-mcp@latest", "--isolated"]
    }
  }
}
```

### Flags

| Flag | Behaviour |
|------|-----------|
| *(none)* | Launches Chrome with a dedicated profile at `~/.cache/chrome-devtools-mcp/`, separate from your personal browser. |
| `--isolated` | Uses a **temporary** profile that is wiped when the browser closes. Recommended for most testing. |
| `--autoConnect` | (Chrome 144+) Attaches to your **running** Chrome instead. Requires enabling remote debugging via `chrome://inspect/#remote-debugging`. Only use when the test genuinely needs your logged-in state — see `references/security.md` first. |

## Available Tools

| Tool | What It Does | When to Use |
|------|-------------|-------------|
| **Screenshot** | Captures the current page state | Visual verification, before/after comparisons |
| **DOM Inspection** | Reads the live DOM tree | Verify component rendering, check structure |
| **Console Logs** | Retrieves console output (log, warn, error) | Diagnose errors, verify logging |
| **Network Monitor** | Captures network requests and responses | Verify API calls, check payloads |
| **Performance Trace** | Records performance timing data | Profile load time, identify bottlenecks |
| **Element Styles** | Reads computed styles for elements | Debug CSS issues, verify styling |
| **Accessibility Tree** | Reads the accessibility tree | Verify screen reader experience |
| **JavaScript Execution** | Runs JavaScript in the page context | Read-only state inspection and debugging (see Security Boundaries) |
