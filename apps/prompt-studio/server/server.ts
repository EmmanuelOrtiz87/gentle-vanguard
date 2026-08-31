/**
 * GV Prompt Studio — servidor local de biblioteca de prompts.
 *
 * REST nativo (node:http, sin dependencias nuevas) + SQLite (better-sqlite3).
 * Persistencia en .runtime/prompt-studio/prompts.db. Buscador: FTS5 con
 * tokenización de lenguaje natural (consulta libre → prompts más relevantes).
 */
import { createServer, IncomingMessage, ServerResponse } from 'http';
import { mkdirSync } from 'fs';
import { join, resolve } from 'path';
import { fileURLToPath, pathToFileURL } from 'url';
import Database from 'better-sqlite3';

const __filename = fileURLToPath(import.meta.url);
const ROOT = join(__filename, '..', '..', '..', '..');
const DATA_DIR = resolve(ROOT, '.runtime', 'prompt-studio');
const PORT = Number(process.env.PROMPT_STUDIO_PORT ?? 5177);

mkdirSync(DATA_DIR, { recursive: true });
const db = new Database(join(DATA_DIR, 'prompts.db'));
db.pragma('journal_mode = WAL');

db.exec(`
CREATE TABLE IF NOT EXISTS prompts (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  type TEXT NOT NULL,
  role TEXT DEFAULT '',
  goal TEXT DEFAULT '',
  context TEXT DEFAULT '',
  criteria TEXT DEFAULT '',
  format TEXT DEFAULT '',
  tone TEXT DEFAULT '',
  body TEXT NOT NULL,
  tags TEXT DEFAULT '',
  favorite INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);
CREATE VIRTUAL TABLE IF NOT EXISTS prompts_fts USING fts5(
  title, body, tags, role, goal,
  content='prompts', content_rowid='rowid',
  tokenize='porter unicode61'
);
CREATE TRIGGER IF NOT EXISTS prompts_ai AFTER INSERT ON prompts BEGIN
  INSERT INTO prompts_fts(rowid, title, body, tags, role, goal)
  VALUES (new.rowid, new.title, new.body, new.tags, new.role, new.goal);
END;
CREATE TRIGGER IF NOT EXISTS prompts_au AFTER UPDATE ON prompts BEGIN
  INSERT INTO prompts_fts(prompts_fts, rowid, title, body, tags, role, goal)
  VALUES ('delete', old.rowid, old.title, old.body, old.tags, old.role, old.goal);
  INSERT INTO prompts_fts(rowid, title, body, tags, role, goal)
  VALUES (new.rowid, new.title, new.body, new.tags, new.role, new.goal);
END;
CREATE TRIGGER IF NOT EXISTS prompts_ad AFTER DELETE ON prompts BEGIN
  INSERT INTO prompts_fts(prompts_fts, rowid, title, body, tags, role, goal)
  VALUES ('delete', old.rowid, old.title, old.body, old.tags, old.role, old.goal);
END;
`);
// Migración ligera: categoría de taxonomía (benchmark alpackaai — docs/reference/PROMPT-LIBRARY-BENCHMARK.md)
{
  const cols = db.prepare(`PRAGMA table_info(prompts)`).all() as { name: string }[];
  if (!cols.some((c) => c.name === 'category')) {
    db.exec(`ALTER TABLE prompts ADD COLUMN category TEXT DEFAULT ''`);
  }
}

const FIELDS = ['title', 'type', 'category', 'role', 'goal', 'context', 'criteria', 'format', 'tone', 'body', 'tags'] as const;
type PromptRow = Record<string, unknown> & { id: string };

function json(res: ServerResponse, status: number, data: unknown): void {
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'access-control-allow-origin': '*',
    'access-control-allow-headers': 'content-type',
    'access-control-allow-methods': 'GET,POST,PUT,DELETE,OPTIONS',
  });
  res.end(JSON.stringify(data));
}

async function readBody(req: IncomingMessage): Promise<Record<string, unknown> | null> {
  const chunks: Buffer[] = [];
  for await (const c of req) chunks.push(c as Buffer);
  if (!chunks.length) return null;
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8')) as Record<string, unknown>;
  } catch {
    return null;
  }
}

/** Consulta de lenguaje natural → tokens FTS (sin operadores, sin vacías). */
function toFtsQuery(q: string): string {
  const stop = new Set([
    'de', 'la', 'el', 'los', 'las', 'un', 'una', 'para', 'por', 'con', 'que', 'del', 'al',
    'como', 'más', 'mas', 'the', 'a', 'an', 'for', 'with', 'how', 'to', 'mejor', 'prompts',
  ]);
  return q
    .toLowerCase()
    .split(/[^a-záéíóúñü0-9]+/i)
    .filter((t) => t.length > 2 && !stop.has(t))
    .slice(0, 12)
    .map((t) => `${t}*`)
    .join(' OR ');
}

async function handler(req: IncomingMessage, res: ServerResponse): Promise<void> {
  const url = new URL(req.url ?? '/', `http://localhost:${PORT}`);
  const path = url.pathname;

  if (req.method === 'OPTIONS') {
    json(res, 204, {});
    return;
  }
  if (req.method === 'GET' && path === '/api/health') {
    json(res, 200, { ok: true, app: 'prompt-studio' });
    return;
  }

  if (req.method === 'GET' && path === '/api/prompts') {
    const q = url.searchParams.get('q')?.trim() ?? '';
    const category = url.searchParams.get('category')?.trim() ?? '';
    let rows: PromptRow[];
    if (q) {
      const fts = toFtsQuery(q);
      if (fts) {
        rows = db
          .prepare(
            `SELECT p.* FROM prompts_fts f JOIN prompts p ON p.rowid = f.rowid
             WHERE prompts_fts MATCH ? ORDER BY rank LIMIT 100`,
          )
          .all(fts) as PromptRow[];
      } else {
        rows = [];
      }
    } else if (category) {
      rows = db
        .prepare(
          `SELECT * FROM prompts WHERE category = ? ORDER BY favorite DESC, updated_at DESC LIMIT 200`,
        )
        .all(category) as PromptRow[];
    } else {
      rows = db
        .prepare(
          `SELECT * FROM prompts ORDER BY favorite DESC, updated_at DESC LIMIT 200`,
        )
        .all() as PromptRow[];
    }
    const categories = db
      .prepare(
        `SELECT category, COUNT(*) as count FROM prompts WHERE category != '' GROUP BY category ORDER BY count DESC`,
      )
      .all() as { category: string; count: number }[];
    json(res, 200, { prompts: rows, categories });
    return;
  }

  if (req.method === 'POST' && path === '/api/prompts') {
    const body = await readBody(req);
    if (!body?.title || !body?.body) {
      json(res, 400, { error: 'title y body son obligatorios' });
      return;
    }
    const id = `ps-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
    const cols = ['id', ...FIELDS, 'created_at', 'updated_at'];
    const vals = [
      id,
      ...FIELDS.map((f) => String(body[f] ?? '')),
      new Date().toISOString(),
      new Date().toISOString(),
    ];
    db.prepare(`INSERT INTO prompts (${cols.join(',')}) VALUES (${cols.map(() => '?').join(',')})`).run(...vals);
    json(res, 201, { id });
    return;
  }

  const match = path.match(/^\/api\/prompts\/([A-Za-z0-9._-]+)$/);
  if (match) {
    const id = match[1];
    if (req.method === 'GET') {
      const row = db.prepare('SELECT * FROM prompts WHERE id = ?').get(id) as PromptRow | undefined;
      if (!row) json(res, 404, { error: 'no encontrado' });
      else json(res, 200, { prompt: row });
      return;
    }
    if (req.method === 'PUT') {
      const body = await readBody(req);
      if (!body) {
        json(res, 400, { error: 'body inválido' });
        return;
      }
      const sets = FIELDS.filter((f) => body[f] !== undefined).map((f) => `${f} = ?`);
      const vals: string[] = FIELDS.filter((f) => body[f] !== undefined).map((f) => String(body[f]));
      if (body.favorite !== undefined) {
        sets.push('favorite = ?');
        vals.push(body.favorite ? '1' : '0');
      }
      if (!sets.length) {
        json(res, 400, { error: 'nada que actualizar' });
        return;
      }
      sets.push(`updated_at = datetime('now')`);
      const r = db.prepare(`UPDATE prompts SET ${sets.join(', ')} WHERE id = ?`).run(...vals, id);
      json(res, 200, { updated: r.changes });
      return;
    }
    if (req.method === 'DELETE') {
      const r = db.prepare('DELETE FROM prompts WHERE id = ?').run(id);
      json(res, 200, { deleted: r.changes });
      return;
    }
  }

  json(res, 404, { error: `ruta desconocida: ${req.method} ${path}` });
}

const server = createServer((req, res) => {
  void handler(req, res).catch((err) => {
    json(res, 500, { error: err instanceof Error ? err.message : 'error interno' });
  });
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`[prompt-studio] API en http://127.0.0.1:${PORT}`);
});

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  // direct execution — nothing extra (server is the main purpose)
}
