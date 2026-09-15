#!/usr/bin/env node
/**
 * Gentle-Vanguard Design System v2 — MCP Server.
 *
 * Exposes the design system to any MCP-compatible client (opencode, codex, copilot, etc).
 * Tools:
 *   - list_tokens: query design tokens by category
 *   - get_component: get the API for a React component
 *   - audit_design: run impeccable detect on a path/URL
 *   - sync_design: regenerate tokens in all consuming apps
 *   - get_design_md: return the canonical DESIGN.md
 *
 * Transport: stdio. Launch with `npx tsx packages/gv-design-system/src/mcp/server.ts`.
 *
 * Registration: add to `config/mcp-registry.json`:
 *   {
 *     "name": "gv-design-system",
 *     "type": "user",
 *     "transport": "stdio",
 *     "command": "npx tsx packages/gv-design-system/src/mcp/server.ts",
 *     "description": "Gentle-Vanguard design system v2: tokens, components, audit"
 *   }
 */
export {};
//# sourceMappingURL=server.d.ts.map