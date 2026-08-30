import { existsSync, readFileSync } from 'fs';
import type { IncomingMessage, ServerResponse } from 'http';
import { join } from 'path';
import type { URL } from 'url';
import {
  loadManifest,
  loadPlatformRegistry,
  packageJob,
  saveManifest,
  transition,
  validate as validateContentJob,
  type Status,
} from '../../../../src/content-operations/engine.ts';
import { ROOT } from '../shared.ts';

export async function contentOperationsHandler(
  req: IncomingMessage,
  res: ServerResponse,
  url: URL,
  _ctx: typeof import('../ws-hub/context.ts'),
  headers: Record<string, string>,
): Promise<boolean> {
  if (url.pathname === '/api/content-operations' && req.method === 'GET') {
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
    res.writeHead(200, headers);
    res.end(
      JSON.stringify({ success: true, data: { jobs, byStatus, byPlatform, byDate, validation } }),
    );
    return true;
  }

  if (url.pathname === '/api/content-operations' && req.method === 'POST') {
    let body = '';
    req.on('data', (chunk) => {
      body += chunk;
    });
    req.on('end', () => {
      try {
        const payload = JSON.parse(body) as {
          id?: string;
          action?: 'transition' | 'package';
          to?: Status;
        };
        const jobs = loadManifest(ROOT);
        const index = jobs.findIndex((job) => job.id === payload.id);
        if (index < 0) throw new Error('Content job not found');
        const job = jobs[index];
        const registry = loadPlatformRegistry(ROOT);
        const errors = validateContentJob(job, registry);
        if (payload.action === 'transition') {
          if (!payload.to) throw new Error('Target status is required');
          const updated = transition(job, payload.to);
          jobs[index] = updated;
          saveManifest(ROOT, jobs);
          res.writeHead(200, headers);
          res.end(JSON.stringify({ success: true, data: updated }));
          return;
        }
        if (payload.action === 'package') {
          if (errors.length) throw new Error(`Validation failed: ${errors.join('; ')}`);
          const output = packageJob(ROOT, job);
          res.writeHead(200, headers);
          res.end(
            JSON.stringify({ success: true, data: { id: job.id, output, status: 'REVIEW' } }),
          );
          return;
        }
        throw new Error('Unsupported content operation');
      } catch (err) {
        res.writeHead(400, headers);
        res.end(
          JSON.stringify({
            success: false,
            error: err instanceof Error ? err.message : 'Invalid content operation',
          }),
        );
      }
    });
    return true;
  }

  const contentJobMatch = url.pathname.match(/^\/api\/content-operations\/([A-Za-z0-9._-]+)$/);
  if (contentJobMatch && req.method === 'GET') {
    const jobId = contentJobMatch[1];
    const job = loadManifest(ROOT).find((item) => item.id === jobId);
    if (!job) {
      res.writeHead(404, headers);
      res.end(JSON.stringify({ success: false, error: 'Content job not found' }));
      return true;
    }
    const packagePath = join(
      ROOT,
      '.runtime',
      'content-operations',
      job.date,
      job.platform,
      job.id,
    );
    const captionPath = join(packagePath, 'caption.txt');
    const publicationPath = join(packagePath, 'publication.json');
    res.writeHead(200, headers);
    res.end(
      JSON.stringify({
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
      }),
    );
    return true;
  }

  return false;
}
