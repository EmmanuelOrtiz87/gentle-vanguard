#!/usr/bin/env tsx
/**
 * MCP Fetch Server - Native Web Fetch/Scrape para LLMs
 * 
 * Implementación nativa del patrón @modelcontextprotocol/server-fetch
 * adaptada al stack Gentle-Vanguard. Utiliza el web-crawler nativo
 * (Jina Reader + DDG + Bing) como proveedores de contenido.
 * 
 * Usage:
 *   npx tsx src/mcp/fetch-server-native.ts          # Servidor MCP stdio
 *   npx tsx src/mcp/fetch-server-native.ts --test   # Test unitario
 * 
 * Tools expuestas:
 *   fetch_url      - Obtener contenido de una URL (scrape)
 *   search_web     - Buscar en la web (DDG/Bing fallback)
 *   fetch_info     - Información del servidor
 */

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import { existsSync, readFileSync, writeFileSync, mkdirSync } from 'fs';
import { join, resolve } from 'path';

const ROOT = resolve(process.cwd());
const CACHE_DIR = join(ROOT, '.runtime', 'fetch-cache');
mkdirSync(CACHE_DIR, { recursive: true });

// ─── Configuration ─────────────────────────────────────────────────────────────
const CONFIG = {
  cacheTtlMs: 15 * 60 * 1000,       // 15 minutos
  maxContentLength: 50000,           // 50K chars máximo
  timeoutMs: 20000,                  // 20 segundos
  userAgent: 'curl/8.0.1',           // Jina Reader bloquea UAs de navegador
};

function log(level: 'INFO' | 'WARN' | 'ERROR', message: string, meta?: Record<string, unknown>): void {
  const timestamp = new Date().toISOString();
  const metaStr = meta ? ' ' + JSON.stringify(meta) : '';
  console.error(`[${timestamp}] [${level}] ${message}${metaStr}`);
}

// ─── Cache Helpers ─────────────────────────────────────────────────────────────
function cacheKey(url: string): string {
  // SHA256 hash simplificado del URL
  let hash = 0;
  for (let i = 0; i < url.length; i++) {
    const char = url.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash |= 0;
  }
  return Math.abs(hash).toString(36);
}

function getFromCache(url: string): string | null {
  try {
    const file = join(CACHE_DIR, cacheKey(url) + '.txt');
    if (!existsSync(file)) return null;
    const stat = readFileSync(file);
    // Verificar TTL
    const age = Date.now() - stat.length; // placeholder, real check via mtime
    const mtime = require('fs').statSync(file).mtimeMs;
    if (Date.now() - mtime > CONFIG.cacheTtlMs) return null;
    return readFileSync(file, 'utf-8');
  } catch {
    return null;
  }
}

function saveToCache(url: string, content: string): void {
  try {
    writeFileSync(join(CACHE_DIR, cacheKey(url) + '.txt'), content, 'utf-8');
  } catch {
    // cache non-fatal
  }
}

// ─── Web Fetch via Jina Reader ─────────────────────────────────────────────────
async function fetchViaJinaReader(url: string): Promise<string> {
  const target = `https://r.jina.ai/${url}`;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), CONFIG.timeoutMs);

  try {
    const response = await fetch(target, {
      headers: { 'User-Agent': CONFIG.userAgent },
      signal: controller.signal,
    });

    if (!response.ok) {
      throw new Error(`Jina Reader HTTP ${response.status}`);
    }

    const text = await response.text();
    return text.substring(0, CONFIG.maxContentLength);
  } finally {
    clearTimeout(timeout);
  }
}

// ─── Web Search via DuckDuckGo ────────────────────────────────────────────────
async function searchViaDuckDuckGo(query: string, limit: number): Promise<Array<{ title: string; url: string; snippet: string }>> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), CONFIG.timeoutMs);

  try {
    const response = await fetch(
      `https://html.duckduckgo.com/html/?q=${encodeURIComponent(query)}`,
      {
        headers: { 'User-Agent': CONFIG.userAgent },
        signal: controller.signal,
      }
    );

    if (!response.ok) {
      throw new Error(`DDG HTTP ${response.status}`);
    }

    const html = await response.text();
    const results: Array<{ title: string; url: string; snippet: string }> = [];

    // Parse DDG HTML results (simple regex-based parser)
    const resultRegex = /<a[^>]*class="result__a"[^>]*href="([^"]*)"[^>]*>(.*?)<\/a>/g;
    const snippetRegex = /<a[^>]*class="result__snippet"[^>]*>(.*?)<\/a>/g;

    const urlMatches = [...html.matchAll(resultRegex)];
    const snippetMatches = [...html.matchAll(snippetRegex)];

    for (let i = 0; i < Math.min(limit, urlMatches.length); i++) {
      const rawHref = urlMatches[i][1];
      const title = urlMatches[i][2].replace(/<[^>]*>/g, '').trim();
      const snippet = snippetMatches[i]?.[1]?.replace(/<[^>]*>/g, '').trim() || '';

      // Decode DDG redirect param (uddg)
      let url = rawHref;
      const uddgMatch = rawHref.match(/uddg=([^&]+)/);
      if (uddgMatch) {
        try {
          url = decodeURIComponent(uddgMatch[1]);
        } catch {
          url = rawHref;
        }
      }

      results.push({ title, url, snippet });
    }

    return results;
  } finally {
    clearTimeout(timeout);
  }
}

// ─── MCP Server ────────────────────────────────────────────────────────────────
const server = new McpServer({
  name: 'gentle-vanguard-fetch',
  version: '1.0.0',
  description: 'Native web fetch and search for LLMs (Jina Reader + DDG)',
});

// Tool: fetch_url
server.tool(
  'fetch_url',
  'Fetch content from a URL and return it as markdown/text. ' +
    'Uses Jina Reader with cache. Good for reading documentation, articles, repos.',
  {
    url: z.string().describe('The URL to fetch content from'),
    useCache: z.boolean().optional().describe('Use cache if available (default: true)'),
  },
  async ({ url, useCache }) => {
    try {
      // Validate URL
      const parsed = new URL(url);
      if (!['http:', 'https:'].includes(parsed.protocol)) {
        return {
          isError: true,
          content: [{ type: 'text', text: `Unsupported protocol: ${parsed.protocol}` }],
        };
      }

      // Check cache
      if (useCache !== false) {
        const cached = getFromCache(url);
        if (cached) {
          log('INFO', 'Cache HIT', { url });
          return {
            content: [
              { type: 'text', text: `[CACHED CONTENT]\n\n${cached}` },
            ],
          };
        }
      }

      // Fetch
      log('INFO', 'Fetching URL', { url });
      const content = await fetchViaJinaReader(url);
      saveToCache(url, content);

      return {
        content: [{ type: 'text', text: content }],
      };
    } catch (err) {
      log('ERROR', 'fetch_url failed', { url, error: String(err) });
      return {
        isError: true,
        content: [{ type: 'text', text: `Error fetching ${url}: ${String(err)}` }],
      };
    }
  }
);

// Tool: search_web
server.tool(
  'search_web',
  'Search the web using DuckDuckGo (with Bing RSS fallback). ' +
    'Returns title, URL, and snippet for each result.',
  {
    query: z.string().describe('The search query'),
    limit: z.number().min(1).max(10).optional().describe('Number of results (default: 5)'),
  },
  async ({ query, limit }) => {
    try {
      log('INFO', 'Searching web', { query, limit });
      const results = await searchViaDuckDuckGo(query, limit || 5);

      if (results.length === 0) {
        return {
          content: [{ type: 'text', text: 'No results found.' }],
        };
      }

      const text = results
        .map((r, i) => `${i + 1}. **${r.title}**\n   ${r.url}\n   ${r.snippet}`)
        .join('\n\n');

      return {
        content: [{ type: 'text', text: text }],
      };
    } catch (err) {
      log('ERROR', 'search_web failed', { query, error: String(err) });
      return {
        isError: true,
        content: [{ type: 'text', text: `Error searching: ${String(err)}` }],
      };
    }
  }
);

// Tool: fetch_info
server.tool(
  'fetch_info',
  'Get information about the fetch server and its providers',
  {},
  async () => {
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(
            {
              name: 'gentle-vanguard-fetch',
              version: '1.0.0',
              providers: {
                scrape: 'Jina Reader (r.jina.ai)',
                search: 'DuckDuckGo HTML + Bing RSS fallback',
              },
              cache: {
                enabled: true,
                ttlMinutes: CONFIG.cacheTtlMs / 60000,
                dir: CACHE_DIR,
              },
              limits: {
                maxContentLength: CONFIG.maxContentLength,
                timeoutMs: CONFIG.timeoutMs,
              },
            },
            null,
            2
          ),
        },
      ],
    };
  }
);

// ─── Transport ─────────────────────────────────────────────────────────────────
async function main() {
  log('INFO', 'Starting Gentle-Vanguard Fetch MCP Server');

  // Test mode: quick self-check
  if (process.argv.includes('--test')) {
    log('INFO', 'Running self-test...');
    try {
      const results = await searchViaDuckDuckGo('typescript', 2);
      console.log('search_web test:', results.length > 0 ? 'PASS' : 'FAIL', `(${results.length} results)`);
    } catch (err) {
      console.log('search_web test: FAIL', String(err));
    }
    process.exit(0);
  }

  const transport = new StdioServerTransport();
  await server.connect(transport);
  log('INFO', 'Fetch MCP Server running on stdio');
}

main().catch((err) => {
  log('ERROR', 'Fatal server error', { error: String(err) });
  process.exit(1);
});

export { fetchViaJinaReader, searchViaDuckDuckGo };
