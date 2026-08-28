import { createServer, type IncomingMessage, type ServerResponse } from 'http';
import { readFileSync, statSync } from 'fs';
import { extname, join, resolve } from 'path';
import { analyzeInput, configureConnection, getConnectionStatus } from './atlassian';
import { getReport, listReports, saveReport } from './reports';
import { toDocx, toHtml, toMarkdown, toPdf, type ExportFormat } from './export';
import { recordMetric, summarize as summarizeMetrics } from './metrics';
import {
  buildAuthorizationUrl,
  cancelPendingFlow,
  clearOAuth,
  consumePendingFlow,
  exchangeCodeForTokens,
  getActiveTokens,
  getCallbackInfo,
  getOAuthConfig,
  isTokenValid,
  persistTokensToVault,
  REDIRECT_URI,
  SCOPES,
} from './oauth';

const PORT = Number(process.env.GV_ANALYTICS_PORT || 4754);
const APP_ROOT = resolve(process.cwd());
const DIST_DIR = join(APP_ROOT, 'dist');

function sendJson(res: ServerResponse, status: number, body: unknown) {
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
  });
  res.end(JSON.stringify(body));
}

function sendHtml(res: ServerResponse, status: number, body: string) {
  res.writeHead(status, {
    'Content-Type': 'text/html; charset=utf-8',
    'Cache-Control': 'no-store',
  });
  res.end(body);
}

function sendFile(
  res: ServerResponse,
  body: Buffer | string,
  contentType: string,
  filename: string,
) {
  res.writeHead(200, {
    'Content-Type': contentType,
    'Content-Disposition': `attachment; filename="${filename}"`,
    'Cache-Control': 'no-store',
  });
  res.end(body);
}

async function readBody(req: IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = [];
  for await (const chunk of req) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }
  if (chunks.length === 0) return {};
  return JSON.parse(Buffer.concat(chunks).toString('utf-8'));
}

async function handleExport(req: IncomingMessage, res: ServerResponse, pathname: string) {
  const match = pathname.match(/^\/api\/reports\/([^/]+)\/export$/);
  if (!match) {
    sendJson(res, 404, { error: 'Export route not found' });
    return;
  }
  const report = getReport(decodeURIComponent(match[1]));
  if (!report) {
    sendJson(res, 404, { error: 'Report not found' });
    return;
  }
  const url = new URL(req.url || '/', `http://${req.headers.host || '127.0.0.1'}`);
  const format = (url.searchParams.get('format') || 'md') as ExportFormat;
  const safeId = report.id.replace(/[^A-Za-z0-9_-]/g, '');
  if (format === 'md') {
    sendFile(res, toMarkdown(report), 'text/markdown; charset=utf-8', `gv-analytics-${safeId}.md`);
    return;
  }
  if (format === 'html') {
    sendFile(res, toHtml(report), 'text/html; charset=utf-8', `gv-analytics-${safeId}.html`);
    return;
  }
  if (format === 'docx') {
    sendFile(
      res,
      await toDocx(report),
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      `gv-analytics-${safeId}.docx`,
    );
    return;
  }
  if (format === 'pdf') {
    sendFile(res, await toPdf(report), 'application/pdf', `gv-analytics-${safeId}.pdf`);
    return;
  }
  sendJson(res, 400, { error: `Unsupported format: ${format}` });
}

async function routeApi(
  req: IncomingMessage,
  res: ServerResponse,
  pathname: string,
  llmMetaRef: { current: { llmSource?: string; llmCached?: boolean } } = { current: {} },
) {
  try {
    if (req.method === 'GET' && pathname === '/api/connection/status') {
      sendJson(res, 200, await getConnectionStatus());
      return;
    }
    if (req.method === 'POST' && pathname === '/api/connection') {
      sendJson(res, 200, await configureConnection((await readBody(req)) as any));
      return;
    }
    if (req.method === 'POST' && pathname === '/api/analyze') {
      const body = (await readBody(req)) as { mode?: 'url' | 'request'; input?: string };
      const report = await analyzeInput(body.mode || 'request', body.input || '');
      saveReport(report);
      llmMetaRef.current.llmSource = report.llmSource ?? 'heuristic';
      llmMetaRef.current.llmCached = report.llmCached === true;
      sendJson(res, 200, report);
      return;
    }
    if (req.method === 'GET' && pathname === '/api/reports') {
      const url = new URL(req.url || '/', `http://${req.headers.host || '127.0.0.1'}`);
      const limit = Number(url.searchParams.get('limit') || 5);
      const safeLimit = Math.min(Math.max(Number.isFinite(limit) ? limit : 5, 1), 25);
      sendJson(res, 200, { reports: listReports(safeLimit) });
      return;
    }
    if (req.method === 'GET' && /^\/api\/reports\/[^/]+$/.test(pathname)) {
      const report = getReport(decodeURIComponent(pathname.split('/')[3]));
      if (!report) {
        sendJson(res, 404, { error: 'Report not found' });
        return;
      }
      sendJson(res, 200, report);
      return;
    }
    if (req.method === 'GET' && /^\/api\/reports\/[^/]+\/export$/.test(pathname)) {
      await handleExport(req, res, pathname);
      return;
    }
    if (req.method === 'GET' && pathname === '/api/metrics') {
      const url = new URL(req.url || '/', `http://${req.headers.host || '127.0.0.1'}`);
      const hours = Number(url.searchParams.get('hours') || 24);
      const safeHours = Math.min(Math.max(Number.isFinite(hours) ? hours : 24, 1), 168);
      sendJson(res, 200, summarizeMetrics(safeHours));
      return;
    }
    if (req.method === 'GET' && pathname === '/api/oauth/status') {
      const config = getOAuthConfig();
      const tokens = getActiveTokens();
      sendJson(res, 200, {
        configured: Boolean(config),
        redirectUri: REDIRECT_URI,
        scopes: SCOPES.split(' '),
        callback: getCallbackInfo(),
        connected: isTokenValid(tokens),
        expiresAt: tokens?.expiresAt ?? null,
      });
      return;
    }
    if (req.method === 'POST' && pathname === '/api/oauth/start') {
      const config = getOAuthConfig();
      if (!config) {
        sendJson(res, 400, {
          error:
            'OAuth no configurado. Setear GVA_OAUTH_CLIENT_ID y GVA_OAUTH_CLIENT_SECRET, o registrar la app en Atlassian Developer Console con callback ' +
            REDIRECT_URI,
        });
        return;
      }
      const flow = buildAuthorizationUrl(config.clientId);
      sendJson(res, 200, { url: flow.url, state: flow.state });
      return;
    }
    if (req.method === 'POST' && pathname === '/api/oauth/disconnect') {
      clearOAuth();
      sendJson(res, 200, { ok: true });
      return;
    }
    if (req.method === 'GET' && pathname === '/oauth/callback') {
      const url = new URL(req.url || '/', `http://${req.headers.host || '127.0.0.1'}`);
      const code = url.searchParams.get('code');
      const state = url.searchParams.get('state');
      const errorParam = url.searchParams.get('error');
      if (errorParam) {
        sendHtml(
          res,
          400,
          `<!doctype html><html><body style="font-family:system-ui;padding:40px;background:#0a0e17;color:#e5e7eb"><h1>OAuth cancelado</h1><p>${errorParam}</p><p>Podes cerrar esta ventana y volver a la app.</p></body></html>`,
        );
        cancelPendingFlow();
        return;
      }
      if (!code || !state) {
        sendHtml(
          res,
          400,
          `<!doctype html><html><body style="font-family:system-ui;padding:40px;background:#0a0e17;color:#e5e7eb"><h1>Callback incompleto</h1><p>Faltan parametros code o state.</p></body></html>`,
        );
        return;
      }
      const flow = consumePendingFlow(state);
      if (!flow) {
        sendHtml(
          res,
          400,
          `<!doctype html><html><body style="font-family:system-ui;padding:40px;background:#0a0e17;color:#e5e7eb"><h1>State invalido o expirado</h1><p>Inicia el flujo OAuth nuevamente desde la app.</p></body></html>`,
        );
        return;
      }
      const config = getOAuthConfig();
      if (!config || config.clientId !== flow.clientId) {
        sendHtml(
          res,
          400,
          `<!doctype html><html><body style="font-family:system-ui;padding:40px;background:#0a0e17;color:#e5e7eb"><h1>Configuracion OAuth perdida</h1><p>Reintenta desde la app.</p></body></html>`,
        );
        return;
      }
      try {
        const tokens = await exchangeCodeForTokens({
          clientId: config.clientId,
          clientSecret: config.clientSecret,
          code,
          codeVerifier: flow.codeVerifier,
        });
        persistTokensToVault(tokens);
        sendHtml(
          res,
          200,
          `<!doctype html><html><body style="font-family:system-ui;padding:40px;background:#0a0e17;color:#e5e7eb"><h1 style="color:#4ade80">Conectado a Atlassian</h1><p>Ya podes cerrar esta ventana y volver a la app. Los tokens quedan guardados cifrados en el vault local.</p></body></html>`,
        );
      } catch (error) {
        sendHtml(
          res,
          500,
          `<!doctype html><html><body style="font-family:system-ui;padding:40px;background:#0a0e17;color:#e5e7eb"><h1 style="color:#ee6d75">Error de OAuth</h1><pre>${(error as Error).message}</pre></body></html>`,
        );
      }
      return;
    }
    sendJson(res, 404, { error: 'API route not found' });
  } catch (error) {
    sendJson(res, 500, { error: error instanceof Error ? error.message : String(error) });
  }
}

function serveStatic(req: IncomingMessage, res: ServerResponse, pathname: string) {
  const target = pathname === '/' ? join(DIST_DIR, 'index.html') : join(DIST_DIR, pathname);
  try {
    const stats = statSync(target);
    if (!stats.isFile()) throw new Error('Not a file');
    const type =
      extname(target) === '.html'
        ? 'text/html; charset=utf-8'
        : extname(target) === '.js'
          ? 'text/javascript; charset=utf-8'
          : extname(target) === '.css'
            ? 'text/css; charset=utf-8'
            : extname(target) === '.svg'
              ? 'image/svg+xml'
              : 'application/octet-stream';
    res.writeHead(200, { 'Content-Type': type });
    res.end(readFileSync(target));
  } catch {
    try {
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end(readFileSync(join(DIST_DIR, 'index.html')));
    } catch {
      sendJson(res, 404, { error: 'Static build not found. Run pnpm build or use pnpm dev.' });
    }
  }
}

const server = createServer((req, res) => {
  const url = new URL(req.url || '/', `http://${req.headers.host || '127.0.0.1'}`);
  if (url.pathname.startsWith('/api/')) {
    const start = Date.now();
    const pathname = url.pathname;
    const llmMetaRef: { current: { llmSource?: string; llmCached?: boolean } } = { current: {} };
    void routeApi(req, res, pathname, llmMetaRef)
      .catch((error) => {
        console.error(`[gv-analytics] api error on ${pathname}:`, error);
        if (!res.headersSent) {
          sendJson(res, 500, { error: error instanceof Error ? error.message : String(error) });
        }
      })
      .finally(() => {
        recordMetric({
          endpoint: pathname,
          status: res.statusCode,
          durationMs: Date.now() - start,
          llmSource:
            (llmMetaRef.current.llmSource as
              | 'agent'
              | 'cache'
              | 'fallback'
              | 'heuristic'
              | null) ?? null,
          llmCached: llmMetaRef.current.llmCached,
        });
      });
    return;
  }
  serveStatic(req, res, url.pathname);
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`Gentle-Vanguard Analytics API listening on http://127.0.0.1:${PORT}`);
});
