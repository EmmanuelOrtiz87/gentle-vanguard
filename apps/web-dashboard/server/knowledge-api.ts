import { execSync } from 'child_process';
import { existsSync } from 'fs';
import { join, resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import type { IncomingMessage, ServerResponse } from 'http';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = resolve(__dirname, '../../..');
const QUERY_SCRIPT = join(ROOT, 'scripts', 'utilities', 'knowledge', 'knowledge-query.ps1');

function pwsh(script: string): string {
  try {
    return execSync(`pwsh -NoProfile -Command "${script}"`, { encoding: 'utf-8', timeout: 30000 });
  } catch {
    return '';
  }
}

export function knowledgeHandler(req: IncomingMessage, res: ServerResponse, headers: Record<string, string>) {
  const url = new URL(req.url!, `http://${req.headers.host || 'localhost'}`);
  const query = url.searchParams.get('q') || '';
  const sources = url.searchParams.get('sources') || 'events,traces,feedback,checkpoints';
  const limit = url.searchParams.get('limit') || '20';

  if (!existsSync(QUERY_SCRIPT)) {
    res.writeHead(200, headers);
    res.end(JSON.stringify({ type: 'knowledge', data: { query, sources, total: 0, results: [] } }));
    return;
  }

  const raw = pwsh(`& '${QUERY_SCRIPT}' -Query '${query.replace(/'/g, "''")}' -Sources @(${sources.split(',').map((s: string) => `'${s.trim()}'`).join(',')}) -Limit ${parseInt(limit)} -Format json -Quiet`);
  if (!raw) {
    res.writeHead(200, headers);
    res.end(JSON.stringify({ type: 'knowledge', data: { query, sources, total: 0, results: [] } }));
    return;
  }

  try {
    const parsed = JSON.parse(raw.trim());
    res.writeHead(200, headers);
    res.end(JSON.stringify({ type: 'knowledge', data: parsed }));
  } catch {
    res.writeHead(500, headers);
    res.end(JSON.stringify({ type: 'knowledge', data: { query, sources, total: 0, results: [] }, error: 'parse error' }));
  }
}
