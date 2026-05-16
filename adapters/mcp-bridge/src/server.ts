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
  name: 'gentle-vanguard-mcp-bridge',
  version: '1.0.0',
});

// Get Gentle-Vanguard root from environment
const GENTLE_VANGUARD_ROOT = process.env.GENTLE_VANGUARD_ROOT || process.cwd();

// Register all Gentle-Vanguard tools
registerReviewTool(server, GENTLE_VANGUARD_ROOT);
registerAuditTool(server, GENTLE_VANGUARD_ROOT);
registerDelegateTool(server, GENTLE_VANGUARD_ROOT);
registerHealthTool(server, GENTLE_VANGUARD_ROOT);
registerSessionTools(server, GENTLE_VANGUARD_ROOT);
registerSkillTools(server, GENTLE_VANGUARD_ROOT);

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
  console.error(`Gentle-Vanguard MCP Bridge running on stdio (root: ${GENTLE_VANGUARD_ROOT})`);
}

main().catch((error) => {
  console.error('Failed to start MCP bridge:', error);
  process.exit(1);
});

