/**
 * GV Content OS — servidor REST local (ADR-0021).
 *
 * Native TS, node:http sin dependencias nuevas. Persistencia en Nexus vía
 * DatabaseManager (singleton compartido con el dashboard). Arranque:
 *   node --import tsx apps/content-cms/server/server.ts
 * (usar runNpxTsx de src/core/run-command.ts para spawns ocultos — regla de oro)
 */
import { createServer, IncomingMessage, ServerResponse } from 'http';
import { randomUUID } from 'crypto';
import { mkdirSync, writeFileSync, readFileSync, unlinkSync, existsSync } from 'fs';
import { join, resolve } from 'path';
import { fileURLToPath, pathToFileURL } from 'url';

const __filename = fileURLToPath(import.meta.url);
const ROOT = join(__filename, '..', '..', '..', '..');

import { DatabaseManager, DEFAULT_TENANT_ID } from '../../web-dashboard/server/database/manager';
import type { ContentVariantRecord } from '../../web-dashboard/server/database/repositories/ContentOSRepo';
import { resolveGenerator, GenerateBrief } from './generator';
import { PLATFORM_SPECS, ContentFormat, MVP_PLATFORM_IDS, recommendSlot } from './platform-specs';
import {
  loadManifest,
  loadPlatformRegistry,
  packageJob,
  saveManifest,
  transition,
  validate as validateContentJob,
  type Status,
} from '../../../src/content-operations/engine';

const PORT = Number(process.env.CONTENT_OS_PORT ?? 3787);
const MEDIA_DIR = resolve(ROOT, '.runtime', 'content-os', 'media');

function json(res: ServerResponse, status: number, data: unknown): void {
  const body = JSON.stringify(data);
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'access-control-allow-origin': '*',
    'access-control-allow-headers': 'content-type',
    'access-control-allow-methods': 'GET,POST,PATCH,DELETE,OPTIONS',
  });
  res.end(body);
}

async function readBody(req: IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = [];
  for await (const chunk of req) chunks.push(chunk as Buffer);
  if (!chunks.length) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    return null;
  }
}

function variantToJson(v: ContentVariantRecord): Record<string, unknown> {
  return { ...v, spec: JSON.parse(v.spec_json || '{}'), spec_json: undefined };
}

/** Media id de referencia `media:<id>` en variant.image_path (attach sin migrar schema). */
export function mediaRefFromPath(imagePath: string): string | null {
  return imagePath.startsWith('media:') ? imagePath.slice(6) : null;
}

const SLOT_TRANSITIONS: Record<string, Set<string>> = {
  proposed: new Set(['confirmed', 'rejected']),
  confirmed: new Set(['proposed', 'rejected']),
  rejected: new Set(['proposed']),
};

function createContentOSHandler(db: DatabaseManager) {
  return async (req: IncomingMessage, res: ServerResponse): Promise<void> => {
    const url = new URL(req.url ?? '/', `http://localhost:${PORT}`);
    const path = url.pathname;
    const repo = db.contentOS;
    const tenant = DEFAULT_TENANT_ID;

    if (req.method === 'OPTIONS') {
      res.writeHead(204, {
        'access-control-allow-origin': '*',
        'access-control-allow-headers': 'content-type',
        'access-control-allow-methods': 'GET,POST,PATCH,DELETE,OPTIONS',
      });
      res.end();
      return;
    }

    if (req.method === 'GET' && path === '/api/health') {
      json(res, 200, { ok: true, service: 'content-os', migrations: 'ok' });
      return;
    }

    if (req.method === 'GET' && path === '/api/platforms') {
      json(res, 200, { platforms: PLATFORM_SPECS, mvpIds: MVP_PLATFORM_IDS });
      return;
    }

    if (req.method === 'GET' && path === '/api/items') {
      const status = url.searchParams.get('status') ?? undefined;
      json(res, 200, {
        items: repo.listItems(tenant, { status }).map((item) => ({
          ...item,
          variants: repo.listVariantsByItem(item.id, tenant).map(variantToJson),
        })),
      });
      return;
    }

    if (req.method === 'GET' && path.startsWith('/api/items/')) {
      const id = path.split('/')[3];
      const item = repo.getItem(id, tenant);
      if (!item) {
        json(res, 404, { error: 'item no encontrado' });
        return;
      }
      json(res, 200, {
        item: { ...item, variants: repo.listVariantsByItem(id, tenant).map(variantToJson) },
      });
      return;
    }

    if (req.method === 'POST' && path === '/api/generate') {
      const body = (await readBody(req)) as
        (Partial<GenerateBrief> & { schedule?: boolean }) | null;
      if (!body?.brief || !body.brief.trim()) {
        json(res, 400, { error: 'brief es obligatorio' });
        return;
      }
      const platforms = (body.platforms?.length ? body.platforms : ['linkedin']).filter(
        (p) => PLATFORM_SPECS[p],
      );
      if (!platforms.length) {
        json(res, 400, { error: 'sin plataformas válidas' });
        return;
      }
      const briefTitle = body.title?.trim() || body.brief.trim().slice(0, 60);
      const brief: GenerateBrief = {
        title: briefTitle,
        brief: body.brief.trim(),
        objective: body.objective?.trim() ?? '',
        voice: body.voice?.trim() ?? '',
        platforms,
        format: (body.format as ContentFormat) ?? 'text',
      };
      const generator = resolveGenerator();
      try {
        const variants = await generator.generate(brief);
        const itemId = `co-${Date.now()}-${randomUUID().slice(0, 6)}`;
        repo.createItem(tenant, {
          id: itemId,
          title: brief.title,
          brief: brief.brief,
          objective: brief.objective,
          voice: brief.voice,
          tags: '[]',
          status: 'draft',
        });
        const created: string[] = [];
        for (const v of variants) {
          const vid = `cv-${Date.now()}-${randomUUID().slice(0, 6)}`;
          repo.createVariant(tenant, {
            id: vid,
            item_id: itemId,
            platform: v.platform,
            format: v.format,
            body: v.body,
            image_prompt: v.imagePrompt,
            image_path: '',
            spec_json: JSON.stringify(v.spec),
            status: 'generated',
            score: v.score,
            provider: v.provider,
          });
          created.push(vid);
          db.insertEvent('content_os.variant_generated', {
            itemId,
            variantId: vid,
            platform: v.platform,
            provider: v.provider,
          });
        }
        const proposedSlots = body.schedule
          ? platforms.map((p) => {
              const rec = recommendSlot(p);
              if (!rec) return null;
              const sid = `cs-${Date.now()}-${randomUUID().slice(0, 6)}`;
              repo.createSlot(tenant, {
                id: sid,
                item_id: itemId,
                variant_id: null,
                platform: p,
                scheduled_at: rec.scheduledAt,
                status: 'proposed',
                rationale: rec.rationale,
              });
              return sid;
            })
          : [];
        json(res, 201, {
          itemId,
          provider: generator.provider,
          variants: created,
          slots: proposedSlots.filter(Boolean),
        });
      } catch (err) {
        json(res, 502, { error: `generación falló: ${(err as Error).message}` });
      }
      return;
    }

    if (req.method === 'PATCH' && path.startsWith('/api/variants/')) {
      const id = path.split('/')[3];
      const body = (await readBody(req)) as Record<string, unknown> | null;
      if (!body) {
        json(res, 400, { error: 'body inválido' });
        return;
      }
      const patch: Record<string, unknown> = {};
      for (const key of ['body', 'image_prompt', 'status', 'score']) {
        if (key in body) patch[key] = body[key];
      }
      if ('imagePrompt' in body) patch.image_prompt = body.imagePrompt;
      if (body.media_id === '') {
        patch.image_path = ''; // desadjuntar
      }
      if (typeof body.media_id === 'string' && body.media_id) {
        // Adjuntar media de la biblioteca: la referencia vive en image_path como `media:<id>`
        const media = repo
          .listMedia(tenant)
          .find((m) => m.id === body.media_id);
        if (!media) {
          json(res, 404, { error: 'media no encontrado' });
          return;
        }
        patch.image_path = `media:${media.id}`;
      }
      repo.updateVariant(id, tenant, patch);
      if (patch.status === 'approved') {
        const variant = repo.getVariant(id, tenant);
        if (variant) {
          // Export asistido (patrón export-kit): snapshot del cuerpo aprobado en publish_log,
          // publicación queda gated al humano (sin APIs de red — ADR-0021).
          const mediaId = mediaRefFromPath(variant.image_path);
          repo.logPublish(tenant, id, variant.platform, 'assisted', 'approved', {
            body: variant.body,
            imagePrompt: variant.image_prompt,
            mediaId,
            exportedAt: new Date().toISOString(),
          });
          db.insertEvent('content_os.variant_approved', { variantId: id, platform: variant.platform });
        }
      }
      json(res, 200, { variant: repo.getVariant(id, tenant) });
      return;
    }

    if (req.method === 'POST' && path === '/api/slots') {
      const body = (await readBody(req)) as Record<string, string> | null;
      if (!body?.item_id || !body.platform || !body.scheduled_at) {
        json(res, 400, { error: 'item_id, platform y scheduled_at son obligatorios' });
        return;
      }
      const sid = `cs-${Date.now()}-${randomUUID().slice(0, 6)}`;
      repo.createSlot(tenant, {
        id: sid,
        item_id: body.item_id,
        variant_id: body.variant_id || null,
        platform: body.platform,
        scheduled_at: body.scheduled_at,
        status: body.status || 'proposed',
        rationale: body.rationale ?? '',
      });
      json(res, 201, { slotId: sid });
      return;
    }

    if (req.method === 'POST' && path === '/api/slots/recommend') {
      const body = (await readBody(req)) as Record<string, unknown> | null;
      const platform = typeof body?.platform === 'string' ? body.platform : '';
      const itemId = typeof body?.item_id === 'string' ? body.item_id : '';
      if (!itemId || !platform) {
        json(res, 400, { error: 'item_id y platform son obligatorios' });
        return;
      }
      const rec = recommendSlot(platform);
      if (!rec) {
        json(res, 400, { error: `plataforma desconocida: ${platform}` });
        return;
      }
      const variantId = typeof body?.variant_id === 'string' && body.variant_id ? body.variant_id : null;
      const sid = `cs-${Date.now()}-${randomUUID().slice(0, 6)}`;
      repo.createSlot(tenant, {
        id: sid,
        item_id: itemId,
        variant_id: variantId,
        platform,
        scheduled_at: rec.scheduledAt,
        status: 'proposed',
        rationale: rec.rationale,
      });
      json(res, 201, { slotId: sid, scheduledAt: rec.scheduledAt, rationale: rec.rationale });
      return;
    }

    if (req.method === 'GET' && path === '/api/slots') {
      json(res, 200, {
        slots: repo.listSlots(tenant, {
          from: url.searchParams.get('from') ?? undefined,
          to: url.searchParams.get('to') ?? undefined,
          platform: url.searchParams.get('platform') ?? undefined,
        }),
      });
      return;
    }

    if (req.method === 'PATCH' && path.startsWith('/api/slots/')) {
      const id = path.split('/')[3];
      const body = (await readBody(req)) as Record<string, string> | null;
      if (!body) {
        json(res, 400, { error: 'body inválido' });
        return;
      }
      const current = repo.listSlots(tenant).find((s) => s.id === id);
      if (!current) {
        json(res, 404, { error: 'slot no encontrado' });
        return;
      }
      if (body.status && body.status !== current.status) {
        const allowed = SLOT_TRANSITIONS[current.status] ?? new Set();
        if (!allowed.has(body.status)) {
          json(res, 409, {
            error: `transición inválida: ${current.status} → ${body.status}`,
          });
          return;
        }
      }
      const patch: Record<string, unknown> = {};
      for (const key of ['status', 'scheduled_at', 'variant_id']) {
        if (key in body) patch[key] = body[key];
      }
      repo.updateSlot(id, tenant, patch);
      if (patch.status === 'confirmed') {
        db.insertEvent('content_os.slot_confirmed', { slotId: id, platform: current.platform });
      }
      const slot = repo.listSlots(tenant).find((s) => s.id === id) ?? null;
      json(res, 200, { slot });
      return;
    }

    if (req.method === 'DELETE' && path.startsWith('/api/slots/')) {
      const id = path.split('/')[3];
      const result = db.database
        .prepare('DELETE FROM calendar_slots WHERE id = ? AND tenant_id = ?')
        .run(id, tenant);
      if (!result.changes) {
        json(res, 404, { error: 'slot no encontrado' });
        return;
      }
      json(res, 200, { deleted: id });
      return;
    }

    if (req.method === 'GET' && path === '/api/media') {
      json(res, 200, { media: repo.listMedia(tenant) });
      return;
    }

    if (req.method === 'POST' && path === '/api/media') {
      const body = (await readBody(req)) as Record<string, unknown> | null;
      const dataUrl = typeof body?.dataUrl === 'string' ? body.dataUrl : '';
      const mime = typeof body?.mime === 'string' ? body.mime : '';
      const validMimes = new Set(['image/png', 'image/jpeg', 'image/webp']);
      const match = /^data:(image\/(?:png|jpeg|webp));base64,/.exec(dataUrl);
      if (!body || !match || mime !== match[1] || !validMimes.has(mime)) {
        json(res, 400, { error: 'dataUrl debe ser una imagen png/jpeg/webp en base64' });
        return;
      }
      const size = Math.floor((dataUrl.length - match[0].length) * 0.75);
      if (size > 10 * 1024 * 1024) {
        json(res, 413, { error: 'imagen supera 10MB' });
        return;
      }
      mkdirSync(MEDIA_DIR, { recursive: true });
      const ext = mime.split('/')[1].replace('jpeg', 'jpg');
      const id = `cm-${Date.now()}-${randomUUID().slice(0, 6)}`;
      const filePath = join(MEDIA_DIR, `${id}.${ext}`);
      writeFileSync(filePath, Buffer.from(dataUrl.slice(match[0].length), 'base64'));
      repo.createMedia(tenant, {
        id,
        name: String(body.name ?? id),
        path: filePath,
        mime,
        size,
        width: null,
        height: null,
        alt: String(body.alt ?? ''),
        source: (body.source as string) === 'generated' ? 'generated' : 'upload',
      });
      json(res, 201, { mediaId: id, path: filePath });
      return;
    }

    if (req.method === 'GET' && /^\/api\/media\/[^/]+\/file$/.test(path)) {
      const id = path.split('/')[3];
      const media = repo.listMedia(tenant).find((m) => m.id === id);
      if (!media || !existsSync(media.path)) {
        json(res, 404, { error: 'media no encontrado' });
        return;
      }
      const bytes = readFileSync(media.path);
      res.writeHead(200, {
        'content-type': media.mime,
        'content-length': bytes.length,
        'access-control-allow-origin': '*',
        'cache-control': 'no-store',
      });
      res.end(bytes);
      return;
    }

    if (
      (req.method === 'PATCH' || req.method === 'DELETE') &&
      path.startsWith('/api/media/')
    ) {
      const id = path.split('/')[3];
      const media = repo.listMedia(tenant).find((m) => m.id === id);
      if (!media) {
        json(res, 404, { error: 'media no encontrado' });
        return;
      }
      if (req.method === 'PATCH') {
        const body = (await readBody(req)) as Record<string, unknown> | null;
        const alt = typeof body?.alt === 'string' ? body.alt : null;
        const name = typeof body?.name === 'string' ? body.name : null;
        if (alt === null && name === null) {
          json(res, 400, { error: 'alt o name requeridos' });
          return;
        }
        if (alt !== null && !alt.trim()) {
          json(res, 400, { error: 'alt text no puede quedar vacío (accesibilidad)' });
          return;
        }
        const sets: string[] = [];
        const values: unknown[] = [];
        if (alt !== null) {
          sets.push('alt = ?');
          values.push(alt.trim());
        }
        if (name !== null && name.trim()) {
          sets.push('name = ?');
          values.push(name.trim());
        }
        db.database
          .prepare(`UPDATE media_library SET ${sets.join(', ')} WHERE id = ? AND tenant_id = ?`)
          .run(...values, id, tenant);
        json(res, 200, { media: repo.listMedia(tenant).find((m) => m.id === id) });
        return;
      }
      // DELETE: no permitir borrar media adjuntado a una variante
      const attached = db.database
        .prepare('SELECT COUNT(*) AS n FROM content_variants WHERE tenant_id = ? AND image_path = ?')
        .get(tenant, `media:${id}`) as { n: number };
      if (attached.n > 0) {
        json(res, 409, { error: `media adjuntado a ${attached.n} variante(s); desadjuntá primero` });
        return;
      }
      db.database
        .prepare('DELETE FROM media_library WHERE id = ? AND tenant_id = ?')
        .run(id, tenant);
      try {
        if (existsSync(media.path)) unlinkSync(media.path);
      } catch {
        // best-effort: el registro ya se borró
      }
      json(res, 200, { deleted: id });
      return;
    }

    if (req.method === 'GET' && path === '/api/publish-log') {
      const rows = db.database
        .prepare(
          'SELECT * FROM publish_log WHERE tenant_id = ? ORDER BY created_at DESC LIMIT 50',
        )
        .all(tenant);
      json(res, 200, { entries: rows });
      return;
    }

    // ── Content Operations Engine (ADR-0018) — moved from web-dashboard (Sesión 13) ──
    if (path === '/api/content-operations' && req.method === 'GET') {
      const jobs = loadManifest(ROOT);
      const registry = loadPlatformRegistry(ROOT);
      const validation = jobs.map((job) => ({
        id: job.id,
        errors: validateContentJob(job, registry),
      }));
      const byStatus = jobs.reduce<Record<string, number>>((counts, job) => {
        counts[job.status] = (counts[job.status] || 0) + 1;
        return counts;
      }, {});
      const byPlatform = jobs.reduce<Record<string, number>>((counts, job) => {
        counts[job.platform] = (counts[job.platform] || 0) + 1;
        return counts;
      }, {});
      const byDate = jobs.reduce<Record<string, number>>((counts, job) => {
        counts[job.date] = (counts[job.date] || 0) + 1;
        return counts;
      }, {});
      json(res, 200, { success: true, data: { jobs, byStatus, byPlatform, byDate, validation } });
      return;
    }

    if (path === '/api/content-operations' && req.method === 'POST') {
      const body = (await readBody(req)) as { id?: string; action?: string; to?: Status } | null;
      try {
        if (!body?.id) throw new Error('Content job not found');
        const jobs = loadManifest(ROOT);
        const index = jobs.findIndex((job) => job.id === body.id);
        if (index < 0) throw new Error('Content job not found');
        const job = jobs[index];
        const registry = loadPlatformRegistry(ROOT);
        const errors = validateContentJob(job, registry);
        if (body.action === 'transition') {
          if (!body.to) throw new Error('Target status is required');
          const updated = transition(job, body.to);
          jobs[index] = updated;
          saveManifest(ROOT, jobs);
          json(res, 200, { success: true, data: updated });
          return;
        }
        if (body.action === 'package') {
          if (errors.length) throw new Error(`Validation failed: ${errors.join('; ')}`);
          const output = packageJob(ROOT, job);
          json(res, 200, { success: true, data: { id: job.id, output, status: 'REVIEW' } });
          return;
        }
        throw new Error('Unsupported content operation');
      } catch (err) {
        json(res, 400, { success: false, error: err instanceof Error ? err.message : 'Invalid content operation' });
        return;
      }
    }

    const opsJobMatch = path.match(/^\/api\/content-operations\/([A-Za-z0-9._-]+)$/);
    if (opsJobMatch && req.method === 'GET') {
      const job = loadManifest(ROOT).find((item) => item.id === opsJobMatch[1]);
      if (!job) {
        json(res, 404, { success: false, error: 'Content job not found' });
        return;
      }
      const packagePath = join(ROOT, '.runtime', 'content-operations', job.date, job.platform, job.id);
      const captionPath = join(packagePath, 'caption.txt');
      const publicationPath = join(packagePath, 'publication.json');
      json(res, 200, {
        success: true,
        data: {
          job,
          validation: validateContentJob(job, loadPlatformRegistry(ROOT)),
          packaged: existsSync(publicationPath),
          output: existsSync(publicationPath) ? packagePath : null,
          caption: existsSync(captionPath) ? readFileSync(captionPath, 'utf8') : null,
          publication: existsSync(publicationPath)
            ? JSON.parse(readFileSync(publicationPath, 'utf8'))
            : null,
        },
      });
      return;
    }

    json(res, 404, { error: `ruta desconocida: ${req.method} ${path}` });
  };
}

export function startServer(opts: { port?: number } = {}): void {
  const db = DatabaseManager.getInstance();
  db.runMigrations();
  const handler = createContentOSHandler(db);
  const server = createServer((req, res) => {
    handler(req, res).catch((err) => {
      json(res, 500, { error: (err as Error).message });
    });
  });
  const port = opts.port ?? PORT;
  server.listen(port, '127.0.0.1', () => {
    console.log(
      `[content-os] REST en http://127.0.0.1:${port} (Nexus: ${ROOT}/.runtime/gentle-vanguard.db)`,
    );
  });
  const stop = (): void => {
    server.close();
    process.exit(0);
  };
  process.on('SIGTERM', stop);
  process.on('SIGINT', stop);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  startServer();
}
