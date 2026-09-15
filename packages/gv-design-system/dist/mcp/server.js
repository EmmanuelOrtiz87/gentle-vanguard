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
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';
import { execSync } from 'node:child_process';
import { readFileSync, existsSync } from 'node:fs';
import { resolve, join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { z } from 'zod';
import { tokens, BRAND_WAIVERS } from '../tokens/tokens.js';
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
// src/mcp/server.ts -> packages/gv-design-system/
const DS_ROOT = join(__dirname, '..', '..');
// packages/gv-design-system/ -> repo root
const REPO_ROOT = resolve(DS_ROOT, '..', '..');
const DESIGN_MD_PATH = join(DS_ROOT, 'DESIGN.md');
// === Tool schemas ===
const ListTokensInput = z.object({
    category: z
        .enum(['color', 'typography', 'spacing', 'radius', 'elevation', 'motion', 'zIndex', 'all'])
        .optional()
        .default('all'),
    theme: z.enum(['dark', 'light', 'all']).optional().default('all'),
});
const GetComponentInput = z.object({
    name: z.enum(['Button', 'Card', 'Input', 'Stack', 'Text', 'Tag', 'IconButton']),
    variant: z.string().optional(),
});
const AuditDesignInput = z.object({
    target: z.string().describe('Path or URL to audit'),
    json: z.boolean().optional().default(false),
    scope: z.enum(['all', 'type', 'layout', 'color', 'motion']).optional(),
});
const SyncDesignInput = z.object({
    app: z.string().optional().describe('Specific app to sync (default: all)'),
    dryRun: z.boolean().optional().default(false),
});
// === Server setup ===
const server = new Server({
    name: 'gv-design-system',
    version: '2.0.0',
}, {
    capabilities: {
        tools: {},
    },
});
// === Tool definitions ===
server.setRequestHandler(ListToolsRequestSchema, async () => ({
    tools: [
        {
            name: 'list_tokens',
            description: 'List Gentle-Vanguard design tokens (colors, typography, spacing, radius, elevation, motion, zIndex). Filter by category and theme.',
            inputSchema: {
                type: 'object',
                properties: {
                    category: {
                        type: 'string',
                        enum: [
                            'color',
                            'typography',
                            'spacing',
                            'radius',
                            'elevation',
                            'motion',
                            'zIndex',
                            'all',
                        ],
                        description: 'Token category to return',
                        default: 'all',
                    },
                    theme: {
                        type: 'string',
                        enum: ['dark', 'light', 'all'],
                        description: 'Theme variant (dark is default)',
                        default: 'all',
                    },
                },
            },
        },
        {
            name: 'get_component',
            description: 'Get the API (props + variants) of a Gentle-Vanguard React component. Returns TypeScript interface and usage examples.',
            inputSchema: {
                type: 'object',
                properties: {
                    name: {
                        type: 'string',
                        enum: ['Button', 'Card', 'Input', 'Stack', 'Text', 'Tag', 'IconButton'],
                        description: 'Component name',
                    },
                    variant: {
                        type: 'string',
                        description: 'Optional specific variant to inspect',
                    },
                },
                required: ['name'],
            },
        },
        {
            name: 'audit_design',
            description: 'Run impeccable design audit on a path or URL. Detects 59 anti-patterns (AI slop tells, typography issues, color/contrast, layout, motion, quality). Returns JSON or human-readable findings.',
            inputSchema: {
                type: 'object',
                properties: {
                    target: {
                        type: 'string',
                        description: 'File path, directory path, or URL to audit',
                    },
                    json: {
                        type: 'boolean',
                        default: false,
                        description: 'Return JSON output instead of human-readable',
                    },
                    scope: {
                        type: 'string',
                        enum: ['all', 'type', 'layout', 'color', 'motion'],
                        description: 'Limit to specific design domain',
                    },
                },
                required: ['target'],
            },
        },
        {
            name: 'sync_design',
            description: 'Regenerate design tokens in all consuming apps (gv-analytics, academy-web, etc). Runs `npm run gv:design` under the hood.',
            inputSchema: {
                type: 'object',
                properties: {
                    app: {
                        type: 'string',
                        description: 'Specific app to sync (default: all consuming apps)',
                    },
                    dryRun: {
                        type: 'boolean',
                        default: false,
                        description: 'Show what would change without modifying files',
                    },
                },
            },
        },
        {
            name: 'get_design_md',
            description: 'Return the canonical Gentle-Vanguard DESIGN.md (the design language reference for the entire ecosystem).',
            inputSchema: {
                type: 'object',
                properties: {},
            },
        },
        {
            name: 'list_brand_waivers',
            description: 'List brand asset waivers — patterns that impeccable would flag as anti-patterns but are intentional Gentle-Vanguard brand signatures (wordmark gradient, grid background, etc).',
            inputSchema: {
                type: 'object',
                properties: {},
            },
        },
    ],
}));
// === Tool implementations ===
server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;
    try {
        switch (name) {
            case 'list_tokens': {
                const input = ListTokensInput.parse(args);
                if (input.category === 'all') {
                    return {
                        content: [
                            {
                                type: 'text',
                                text: JSON.stringify({
                                    version: '2.0.0',
                                    mode: 'dark-first',
                                    theme: input.theme,
                                    tokens,
                                }, null, 2),
                            },
                        ],
                    };
                }
                return {
                    content: [
                        {
                            type: 'text',
                            text: JSON.stringify({
                                category: input.category,
                                values: tokens[input.category] ?? null,
                            }, null, 2),
                        },
                    ],
                };
            }
            case 'get_component': {
                const input = GetComponentInput.parse(args);
                const tsxPath = join(process.cwd(), 'src', 'react', `${input.name}.tsx`);
                if (!existsSync(tsxPath)) {
                    return {
                        content: [{ type: 'text', text: `Component ${input.name} not found at ${tsxPath}` }],
                        isError: true,
                    };
                }
                const source = readFileSync(tsxPath, 'utf-8');
                const lines = source.split('\n');
                // Extract the interface (lines between `export interface` and closing `}`)
                const startIdx = lines.findIndex((l) => l.includes('export interface'));
                const propsInterface = startIdx >= 0 ? lines.slice(startIdx).join('\n') : '/* props not found */';
                return {
                    content: [
                        {
                            type: 'text',
                            text: `# ${input.name} (Gentle-Vanguard v2)\n\n## Props\n\n\`\`\`tsx\n${propsInterface}\n\`\`\`\n\n## Import\n\n\`\`\`tsx\nimport { ${input.name} } from '@gentle-vanguard/design-system/react';\n\`\`\`\n\n## Source\n\n${tsxPath}\n${input.variant ? `\n## Variant: ${input.variant}\n\nSee CSS file for variant-specific styles: \`src/react/${input.name}.css\`` : ''}`,
                        },
                    ],
                };
            }
            case 'audit_design': {
                const input = AuditDesignInput.parse(args);
                const target = input.target.startsWith('/') || input.target.match(/^[a-z]:\\/i)
                    ? input.target
                    : join(REPO_ROOT, input.target);
                const args2 = ['detect', target, input.json ? '--json' : '--quiet'];
                if (input.scope) {
                    args2.push('--scope', input.scope);
                }
                try {
                    const output = execSync(`npx impeccable ${args2.join(' ')}`, {
                        cwd: REPO_ROOT,
                        encoding: 'utf-8',
                        maxBuffer: 10 * 1024 * 1024,
                        stdio: ['ignore', 'pipe', 'pipe'],
                    });
                    return {
                        content: [
                            {
                                type: 'text',
                                text: output || 'No issues found (clean).',
                            },
                        ],
                    };
                }
                catch (err) {
                    // impeccable exits with code 2 when issues are found; that's expected
                    const execErr = err;
                    const text = execErr.stdout || execErr.stderr || `Audit failed: ${String(err)}`;
                    return {
                        content: [{ type: 'text', text }],
                        isError: (execErr.status ?? 1) > 2,
                    };
                }
            }
            case 'sync_design': {
                const input = SyncDesignInput.parse(args);
                const cmd = input.app
                    ? `npx tsx src/cli/sync.ts --app ${input.app}${input.dryRun ? ' --dry-run' : ''}`
                    : `npx tsx src/cli/sync.ts${input.dryRun ? ' --dry-run' : ''}`;
                try {
                    const output = execSync(cmd, {
                        cwd: process.cwd(),
                        encoding: 'utf-8',
                        stdio: ['ignore', 'pipe', 'pipe'],
                    });
                    return {
                        content: [{ type: 'text', text: output || 'Sync complete.' }],
                    };
                }
                catch (err) {
                    const execErr = err;
                    return {
                        content: [
                            {
                                type: 'text',
                                text: execErr.stdout || execErr.stderr || `Sync failed: ${String(err)}`,
                            },
                        ],
                        isError: true,
                    };
                }
            }
            case 'get_design_md': {
                if (!existsSync(DESIGN_MD_PATH)) {
                    return {
                        content: [{ type: 'text', text: `DESIGN.md not found at ${DESIGN_MD_PATH}` }],
                        isError: true,
                    };
                }
                const content = readFileSync(DESIGN_MD_PATH, 'utf-8');
                return {
                    content: [{ type: 'text', text: content }],
                };
            }
            case 'list_brand_waivers': {
                return {
                    content: [
                        {
                            type: 'text',
                            text: JSON.stringify(BRAND_WAIVERS, null, 2),
                        },
                    ],
                };
            }
            default:
                return {
                    content: [{ type: 'text', text: `Unknown tool: ${name}` }],
                    isError: true,
                };
        }
    }
    catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        return {
            content: [{ type: 'text', text: `Error: ${message}` }],
            isError: true,
        };
    }
});
// === Start server ===
async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error('gv-design-system MCP server v2.0.0 (v2 Premium canon) running on stdio');
}
main().catch((err) => {
    console.error('Fatal:', err);
    process.exit(1);
});
//# sourceMappingURL=server.js.map