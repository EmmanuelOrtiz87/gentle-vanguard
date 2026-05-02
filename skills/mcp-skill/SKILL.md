---
name: mcp-skill
description: >
  Model Context Protocol: MCP servers, tools, resources, prompts.
  Trigger: "MCP", "Model Context Protocol", "MCP server", "MCP tool", "MCP resource".
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
  }
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
  }
);
```

## Resources

```typescript
// Static resources
server.resource(
  'docs',
  'https://example.com/api/docs',
  async () => {
    const docs = await fetchDocs();
    return { contents: [{ uri: 'docs://full', text: docs }] };
  }
);

// Dynamic resources
server.resource(
  'user_profile',
  'users://{userId}/profile',
  async ({ userId }) => {
    const profile = await db.users.findById(userId);
    return { contents: [{ uri: `users://${userId}/profile`, text: JSON.stringify(profile) }] };
  }
);
```

## Prompts

```typescript
server.prompt(
  'code_review',
  'Generate a code review prompt',
  {
    language: z.string().optional(),
    focus: z.string().optional(),
  },
  ({ language, focus }) => ({
    messages: [{
      role: 'user',
      content: {
        type: 'text',
        text: `Review the following ${language || 'code'} focusing on: ${focus || 'general quality'}`,
      },
    }],
  })
);
```

## Server Implementation

```typescript
// main.ts
import { McpServer } from '@modelcontextprotocol/sdk/server';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio';
import { z } from 'zod';

async function main() {
  const transport = new StdioServerTransport();
  const server = new McpServer({
    name: 'filesystem-server',
    versión: '1.0.0',
  });

  // Register tools, resources, prompts...
  
  await server.connect(transport);
  console.error('MCP server running on stdio');
}

main().catch(console.error);
```

## Client Configuration

```json
// .mcp.json (OpenCode, Claude, etc.)
{
  "mcpServers": {
    "filesystem": {
      "command": "node",
      "args": ["/path/to/server/dist/main.js"],
      "env": {
        "ROOT_PATH": "/home/user/projects"
      }
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "database": {
      "command": "node",
      "args": ["/path/to/mcp-database-server/dist/main.js"],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}"
      }
    }
  }
}
```

## Tool Result Format

```typescript
// Success result
return {
  content: [
    { type: 'text', text: 'Result data' },
    { type: 'image', data: base64, mimeType: 'image/png' },
    { type: 'resource', resource: { uri: 'file://...', name: 'file.txt' } }
  ],
  isError: false,
};

// Error result
return {
  content: [{ type: 'text', text: 'Error description' }],
  isError: true,
};
```

## Best Practices

1. **Tool naming**: Use kebab-case `get_user_data`
2. **Descriptions**: Clear descriptions for AI understanding
3. **Zod validation**: Strong input validation
4. **Error handling**: Return proper error results
5. **Idempotency**: Tools should be safe to retry

## Example: Todo MCP Server

```typescript
import { McpServer } from '@modelcontextprotocol/sdk/server';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio';
import { z } from 'zod';

const server = new McpServer({
  name: 'todo-server',
  versión: '1.0.0',
});

const todos = new Map<string, Todo>();

server.tool(
  'create_todo',
  'Create a new todo item',
  {
    title: z.string().min(1),
    priority: z.enum(['low', 'medium', 'high']).default('medium'),
  },
  ({ title, priority }) => {
    const id = crypto.randomUUID();
    const todo = { id, title, priority, completed: false, createdAt: new Date() };
    todos.set(id, todo);
    return { content: [{ type: 'text', text: JSON.stringify(todo) }] };
  }
);

server.tool(
  'list_todos',
  'List all todos',
  z.object({}),
  () => {
    return { content: [{ type: 'text', text: JSON.stringify([...todos.values()]) }] };
  }
);

server.tool(
  'complete_todo',
  'Mark a todo as completed',
  { id: z.string() },
  ({ id }) => {
    const todo = todos.get(id);
    if (!todo) return { content: [{ type: 'text', text: 'Todo not found' }], isError: true };
    todo.completed = true;
    return { content: [{ type: 'text', text: JSON.stringify(todo) }] };
  }
);

const transport = new StdioServerTransport();
server.connect(transport);
```

## Quick Reference

| Component | Purpose |
|-----------|---------|
| Tool | Executable actions |
| Resource | Data to read |
| Prompt | Predefined prompts |
| Server | MCP server implementation |
| Transport | Communication (stdio, HTTP) |

