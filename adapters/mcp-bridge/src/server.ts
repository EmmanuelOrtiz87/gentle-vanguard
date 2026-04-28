#!/usr/bin/env node

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import { registerReviewTool } from './tools/review.js';
import { registerAuditTool } from './tools/audit.js';
import { registerDelegateTool } from './tools/delegate.js';
import { registerHealthTool } from './tools/health.js';
import { registerSessionTools } from './tools/session.js';
import { registerSkillTools } from './tools/skills.js';

// Initialize MCP server
const server: any = new McpServer({
  name: 'foundation-mcp-bridge',
  version: '1.0.0',
});

// Get Foundation root from environment
const FOUNDATION_ROOT = process.env.FOUNDATION_ROOT || process.cwd();

// Register all Foundation tools
registerReviewTool(server, FOUNDATION_ROOT);
registerAuditTool(server, FOUNDATION_ROOT);
registerDelegateTool(server, FOUNDATION_ROOT);
registerHealthTool(server, FOUNDATION_ROOT);
registerSessionTools(server, FOUNDATION_ROOT);
registerSkillTools(server, FOUNDATION_ROOT);

// Error handling
process.on('unhandledRejection', (error) => {
  console.error('Unhandled rejection:', error);
});

process.on('SIGINT', async () => {
  console.error('Shutting down MCP bridge...');
  process.exit(0);
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error(`Foundation MCP Bridge running on stdio (root: ${FOUNDATION_ROOT})`);
}

main().catch((error) => {
  console.error('Failed to start MCP bridge:', error);
  process.exit(1);
});
