---
name: mcp-skill
description: >
  Model Context Protocol: MCP servers, tools, resources, prompts. Trigger: "MCP", "Model Context
  Protocol", "MCP server", "MCP tool", "MCP resource".
---

## When to Use

- Setting up MCP servers
- Creating AI tools
- MCP client configuration
- Resource management
- Prompt templates

## MCP Architecture

```

   AI Agent   MCP Server
  (Client)
        - Tools
                       - Resources
                       - Prompts




                        External
                         System

```

## MCP Server Structure

```typescript
// server.ts
import { McpServer } from '@modelcontextprotocol/sdk/server';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio';
import { z } from 'zod';

const server = new McpServer({
  name: 'my-mcp-server',
  versión: '1.0.0',
});
```

## Tools

```typescript
// Define tools
server.tool(
  'get_weather',
  'Get current weather for a location',
  {
    location: z.string().describe('City name'),
    unit: z.enum(['celsius', 'fahrenheit']).optional(),
  },
  async ({ location, unit = 'celsius' }) => {
    const weather = await fetchWeather(location, unit);
    return {
      content: [{ type: 'text', text: JSON.stringify(weather) }],
    };
  },
);

server.tool(
  'create_task',
  'Create a new task',
  {
    title: z.string(),
    description: z.string().optional(),
    priority: z.enum(['low', 'medium', 'high']).default('medium'),
  },
  async ({ title, description, priority }) => {
    const task = await db.tasks.create({ title, description, priority });
    return {
      content: [{ type: 'text', text: JSON.stringify(task) }],
    };
  },
);
```

## Resources

```typescript
// Static resources
server.resource('docs', 'https://example.com/api/docs', async () => {
  const docs = await fetchDocs();
  return { contents: [{ uri: 'docs://full', text: docs }] };
});

// Dynamic resources
server.resource('user_profile', 'users://{userId}/profile', async ({ userId }) => {
  const profile = await db.users.findById(userId);
  return { contents: [{ uri: `users://${userId}/profile`, text: JSON.stringify(profile) }] };
});
```

## Prompts

```typescript
server.prompt(
  'code_review',
  'Generate a code review prompt',
  {

---

> **Referencia detallada**: [eferences/detail.md](references/detail.md)