import { createServer as createHttpServer, type ServerResponse } from 'node:http';
import { existsSync, mkdirSync, readFileSync, unlinkSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { connect } from 'node:net';
import { request } from 'node:http';
import {
  spawn as nodeSpawn,
  spawnSync,
  type ChildProcess,
  type SpawnOptions,
} from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { getFreePort } from '../../src/ops/dashboard-common';

export type AppStatus = 'running' | 'stopped' | 'partial';
export type AppId = 'dashboard' | 'analytics' | 'cms' | 'academy' | 'prompts';
export interface AppProcess {
  name: string;
  pid: number | null;
  port: number;
  alive: boolean;
}
export interface AppInfo {
  id: AppId;
  name: string;
  description: string;
  status: AppStatus;
  url: string;
  processes: AppProcess[];
}
type Spawn = (file: string, args: readonly string[], options?: SpawnOptions) => ChildProcess;
interface ProcessDefinition {
  name: string;
  port: number;
  pidFile: string;
  legacyPidFiles?: string[];
  start: () => ChildProcess;
}
interface AppDefinition {
  id: AppId;
  name: string;
  description: string;
  url: string;
  /** PIDs to kill BEFORE the servers — watchdogs respawn them otherwise. */
  watchdogPidFiles?: string[];
  processes: () => ProcessDefinition[];
}
export interface AppsControllerOptions {
  root?: string;
  spawn?: Spawn;
  probe?: (port: number) => Promise<boolean>;
  readDashboardPort?: () => number;
}

const rootDefault = resolve(process.cwd());
const runtimeDir = (root: string) => join(root, '.runtime');
const ownPidPath = (root: string, id: AppId, processName: string) =>
  join(runtimeDir(root), `app-${id}-${processName}.pid`);
const appRoot = (root: string, name: string) => resolve(root, 'apps', name);

function readDashboardPort(root: string): number {
  try {
    const value = JSON.parse(
      readFileSync(join(root, '.runtime', 'dashboard-ports.json'), 'utf8'),
    ) as { wsPort?: number; ws?: number; server?: number; port?: number };
    return Number(value.wsPort ?? value.ws ?? value.server ?? value.port ?? 8080);
  } catch {
    return 8080;
  }
}

function isAlive(pid: number): boolean {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

export function probePort(port: number): Promise<boolean> {
  return new Promise((done) => {
    const socket = connect({ host: '127.0.0.1', port });
    const finish = (value: boolean) => {
      socket.destroy();
      done(value);
    };
    socket.setTimeout(1000, () => finish(false));
    socket.once('connect', () => finish(true));
    socket.once('error', () => finish(false));
  });
}

/** PID listening on 127.0.0.1:<port>, or 0. Port-owner fallback for stop(). */
export function portOwner(port: number): number {
  if (process.platform !== 'win32') return 0;
  try {
    const r = spawnSync(
      'powershell',
      [
        '-NoProfile',
        '-Command',
        `@(Get-NetTCPConnection -LocalPort ${port} -State Listen -ErrorAction SilentlyContinue | ` +
          `Where-Object { $_.LocalAddress -eq '127.0.0.1' -or $_.LocalAddress -eq '0.0.0.0' } | ` +
          `Select-Object -First 1).OwningProcess`,
      ],
      { windowsHide: true, encoding: 'utf8', timeout: 5000 },
    );
    const pid = Number((r.stdout ?? '').trim());
    return pid && Number.isInteger(pid) ? pid : 0;
  } catch {
    return 0;
  }
}

export const APPS_REGISTRY = [
  {
    id: 'dashboard' as const,
    name: 'Dashboard',
    description: 'Operaciones del stack Gentle-Vanguard',
    url: 'http://127.0.0.1:5173',
    server: 'node --import tsx apps/web-dashboard/server/websocket-server.ts',
    client: 'vite',
  },
  {
    id: 'analytics' as const,
    name: 'Analytics',
    description: 'Informes y analítica operativa',
    url: 'http://127.0.0.1:5174',
    server: 'node --import tsx server/index.ts',
    client: 'vite',
  },
  {
    id: 'cms' as const,
    name: 'Content CMS',
    description: 'Flujo editorial y publicación',
    client: 'vite',
    url: 'http://127.0.0.1:5175',
  },
  {
    id: 'academy' as const,
    name: 'Academy',
    description: 'Centro de aprendizaje Gentle-Vanguard',
    server: 'python -m http.server 4173',
    url: 'http://127.0.0.1:4173',
  },
  {
    id: 'prompts' as const,
    name: 'Prompt Studio',
    description: 'Generador de prompts profesionales (extraído de Academy/dashboard)',
    client: 'vite',
    url: 'http://127.0.0.1:5176',
  },
] as const;

export function createAppsController(options: AppsControllerOptions = {}) {
  const root = options.root ?? rootDefault;
  const spawn = options.spawn ?? nodeSpawn;
  const probe = options.probe ?? probePort;
  const vite = (cwd: string, port: number) =>
    spawn(
      process.execPath,
      [
        resolve(cwd, 'node_modules/vite/bin/vite.js'),
        '--host',
        '127.0.0.1',
        '--port',
        String(port),
        '--strictPort',
      ],
      { cwd, stdio: 'ignore', detached: true, windowsHide: true },
    );
  const ts = (cwd: string, script: string) =>
    spawn(process.execPath, ['--import', 'tsx', resolve(cwd, script)], {
      cwd,
      stdio: 'ignore',
      detached: true,
      windowsHide: true,
    });
  const definitions = (): AppDefinition[] => [
    {
      ...APPS_REGISTRY[0],
      watchdogPidFiles: [
        join(runtimeDir(root), 'dashboard-ws-watchdog.pid'),
        join(runtimeDir(root), 'dashboard-vite-watchdog.pid'),
      ],
      processes: () => [
        {
          name: 'server',
          port: options.readDashboardPort?.() ?? readDashboardPort(root),
          pidFile: ownPidPath(root, 'dashboard', 'server'),
          legacyPidFiles: [join(runtimeDir(root), 'dashboard-ws.pid')],
          start: () => ts(appRoot(root, 'web-dashboard'), 'server/websocket-server.ts'),
        },
        {
          name: 'vite',
          port: 5173,
          pidFile: ownPidPath(root, 'dashboard', 'vite'),
          legacyPidFiles: [join(runtimeDir(root), 'dashboard-vite.pid')],
          start: () => vite(appRoot(root, 'web-dashboard'), 5173),
        },
      ],
    },
    {
      ...APPS_REGISTRY[1],
      processes: () => [
        {
          name: 'api',
          port: 4754,
          pidFile: ownPidPath(root, 'analytics', 'api'),
          start: () => ts(appRoot(root, 'gv-analytics'), 'server/index.ts'),
        },
        {
          name: 'vite',
          port: 5174,
          pidFile: ownPidPath(root, 'analytics', 'vite'),
          start: () => vite(appRoot(root, 'gv-analytics'), 5174),
        },
      ],
    },
    {
      ...APPS_REGISTRY[2],
      processes: () => [
        {
          name: 'api',
          port: 3787,
          pidFile: ownPidPath(root, 'cms', 'api'),
          start: () => ts(appRoot(root, 'content-cms'), 'server/server.ts'),
        },
        {
          name: 'vite',
          port: 5175,
          pidFile: ownPidPath(root, 'cms', 'vite'),
          start: () => vite(appRoot(root, 'content-cms'), 5175),
        },
      ],
    },
    {
      ...APPS_REGISTRY[3],
      processes: () => [
        {
          name: 'http',
          port: 4173,
          pidFile: ownPidPath(root, 'academy', 'http'),
          start: () =>
            spawn(
              'python',
              [
                '-m',
                'http.server',
                '4173',
                '--bind',
                '127.0.0.1',
                '--directory',
                appRoot(root, 'academy-web'),
              ],
              { cwd: root, stdio: 'ignore', detached: true, windowsHide: true },
            ),
        },
      ],
    },
    {
      ...APPS_REGISTRY[4],
      processes: () => [
        {
          name: 'api',
          port: 5177,
          pidFile: ownPidPath(root, 'prompts', 'api'),
          start: () => ts(appRoot(root, 'prompt-studio'), 'server/server.ts'),
        },
        {
          name: 'vite',
          port: 5176,
          pidFile: ownPidPath(root, 'prompts', 'vite'),
          start: () => vite(appRoot(root, 'prompt-studio'), 5176),
        },
      ],
    },
  ];
  const find = (id: string) => definitions().find((app) => app.id === id);
  async function inspect(def: AppDefinition): Promise<AppInfo> {
    const processes: AppProcess[] = [];
    for (const item of def.processes()) {
      let pid: number | null = null;
      let pidFile = item.pidFile;
      for (const candidate of [item.pidFile, ...(item.legacyPidFiles ?? [])]) {
        try {
          if (existsSync(candidate)) {
            pid = Number(readFileSync(candidate, 'utf8').trim());
            pidFile = candidate;
            break;
          }
        } catch {
          pid = null;
        }
      }
      const portAlive = await probe(item.port);
      const alive = portAlive;
      const reportedPid = pid !== null && Number.isInteger(pid) && isAlive(pid) ? pid : null;
      if (
        pidFile === item.pidFile &&
        pid !== null &&
        reportedPid === null &&
        existsSync(item.pidFile)
      ) {
        try {
          unlinkSync(item.pidFile);
        } catch {
          /* best effort */
        }
      }
      processes.push({ name: item.name, pid: alive ? reportedPid : null, port: item.port, alive });
    }
    const aliveCount = processes.filter((item) => item.alive).length;
    return {
      id: def.id,
      name: def.name,
      description: def.description,
      status:
        aliveCount === 0 ? 'stopped' : aliveCount === processes.length ? 'running' : 'partial',
      url: def.url,
      processes,
    };
  }
  async function start(id: string): Promise<{ status: number; body: unknown }> {
    const def = find(id);
    if (!def) return { status: 404, body: { error: 'app-not-found' } };
    const before = await inspect(def);
    if (before.status === 'running') return { status: 200, body: before };
    mkdirSync(runtimeDir(root), { recursive: true });
    for (const item of def.processes()) {
      const current = before.processes.find((entry) => entry.name === item.name);
      if (current?.alive) continue;
      const child = item.start();
      if (child.pid) writeFileSync(item.pidFile, String(child.pid));
      child.unref();
      const deadline = Date.now() + 15000;
      while (Date.now() < deadline && !(await probe(item.port)))
        await new Promise((done) => setTimeout(done, 500));
    }
    return { status: 200, body: await inspect(def) };
  }
  async function stop(id: string): Promise<{ status: number; body: unknown }> {
    const def = find(id);
    if (!def) return { status: 404, body: { error: 'app-not-found' } };
    // 1. Watchdogs first — they respawn the servers within seconds, which made
    //    stop() look like a no-op for the dashboard.
    for (const wdFile of def.watchdogPidFiles ?? []) {
      try {
        if (!existsSync(wdFile)) continue;
        const wdPid = Number(readFileSync(wdFile, 'utf8').trim());
        if (wdPid && isAlive(wdPid))
          spawn('taskkill', ['/pid', String(wdPid), '/t', '/f'], {
            windowsHide: true,
            stdio: 'ignore',
          });
        unlinkSync(wdFile);
      } catch {
        /* best effort */
      }
    }
    // 2. Kill each process: own pidfile → legacy pidfiles → port-owner fallback
    //    (processes started by other launchers may have no pidfile at all).
    for (const item of def.processes()) {
      let pid = 0;
      for (const candidate of [item.pidFile, ...(item.legacyPidFiles ?? [])]) {
        try {
          if (!existsSync(candidate)) continue;
          const value = Number(readFileSync(candidate, 'utf8').trim());
          if (value && isAlive(value)) {
            pid = value;
            break;
          }
          unlinkSync(candidate);
        } catch {
          /* stale */
        }
      }
      if (!pid) pid = await portOwner(item.port);
      if (pid && isAlive(pid)) {
        try {
          process.kill(pid, 'SIGTERM');
        } catch {
          /* fallback below */
        }
        if (isAlive(pid))
          spawn('taskkill', ['/pid', String(pid), '/t', '/f'], {
            windowsHide: true,
            stdio: 'ignore',
          });
      }
      for (const candidate of [item.pidFile, ...(item.legacyPidFiles ?? [])]) {
        try {
          if (existsSync(candidate)) unlinkSync(candidate);
        } catch {
          /* already removed */
        }
      }
      const deadline = Date.now() + 3000;
      while (Date.now() < deadline && (await probe(item.port))) {
        await new Promise((done) => setTimeout(done, 100));
      }
    }
    return { status: 200, body: await inspect(def) };
  }
  return { list: async () => Promise.all(definitions().map(inspect)), start, stop };
}

function json(res: ServerResponse, status: number, body: unknown): void {
  res.writeHead(status, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
  res.end(JSON.stringify(body));
}
function loopbackOrigin(origin: string | undefined): string | undefined {
  if (!origin) return undefined;
  try {
    const parsed = new URL(origin);
    return ['127.0.0.1', 'localhost', '::1'].includes(parsed.hostname) ? origin : undefined;
  } catch {
    return undefined;
  }
}
function corsHeaders(origin: string | undefined): Record<string, string> {
  const allowed = loopbackOrigin(origin);
  return allowed ? { 'Access-Control-Allow-Origin': allowed, Vary: 'Origin' } : {};
}
function writeJson(
  res: ServerResponse,
  status: number,
  body: unknown,
  origin: string | undefined,
): void {
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Cache-Control': 'no-store',
    ...corsHeaders(origin),
  });
  res.end(JSON.stringify(body));
}
function validHost(host: string | undefined): boolean {
  if (!host) return false;
  const hostname = host.replace(/^\[/, '').split(']')[0].split(':')[0].toLowerCase();
  return hostname === '127.0.0.1' || hostname === 'localhost' || hostname === '::1';
}
export function createCommandCenterServer(controller = createAppsController(), root = rootDefault) {
  return createHttpServer(async (req, res) => {
    if (!validHost(req.headers.host)) return json(res, 400, { error: 'invalid-host' });
    const url = new URL(req.url ?? '/', 'http://127.0.0.1');
    const origin = req.headers.origin;
    if (url.pathname.startsWith('/api/') && req.method === 'OPTIONS') {
      res.writeHead(204, {
        ...corsHeaders(origin),
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Max-Age': '600',
      });
      res.end();
      return;
    }
    if (url.pathname === '/api/health' && req.method === 'GET')
      return writeJson(res, 200, { ok: true, app: 'command-center' }, origin);
    if (url.pathname === '/api/apps' && req.method === 'GET')
      return writeJson(res, 200, await controller.list(), origin);
    const match = url.pathname.match(/^\/api\/apps\/([^/]+)\/(start|stop)$/);
    if (match && req.method === 'POST') {
      const result = await controller[match[2] as 'start' | 'stop'](decodeURIComponent(match[1]));
      return writeJson(res, result.status, result.body, origin);
    }
    const preset = url.pathname.match(/^\/api\/presets\/(start-all|stop-all)$/);
    if (preset && req.method === 'POST') {
      const action = preset[1] === 'start-all' ? 'start' : 'stop';
      const apps = await controller.list();
      const results: Array<{ id: AppId; status: AppStatus }> = [];
      for (const app of apps) {
        const shouldAct = action === 'start' ? app.status !== 'running' : app.status !== 'stopped';
        if (shouldAct) {
          const result = await controller[action](app.id);
          if (result.status >= 400) return writeJson(res, result.status, result.body, origin);
          const finalApp = result.body as AppInfo;
          results.push({ id: app.id, status: finalApp.status });
        } else {
          results.push({ id: app.id, status: app.status });
        }
      }
      return writeJson(res, 200, { results }, origin);
    }
    if (url.pathname === '/widget.js' && req.method === 'GET') {
      res.writeHead(200, {
        'Content-Type': 'text/javascript; charset=utf-8',
        'Cache-Control': 'no-store',
        ...corsHeaders(origin),
      });
      res.end(readFileSync(new URL('./public/widget.js', import.meta.url), 'utf8'));
      return;
    }
    if (url.pathname === '/gv-design-system.css' && req.method === 'GET') {
      res.writeHead(200, {
        'Content-Type': 'text/css; charset=utf-8',
        'Cache-Control': 'no-store',
      });
      res.end(readFileSync(join(root, 'assets', 'gv-design-system.css'), 'utf8'));
      return;
    }
    if (url.pathname === '/' || url.pathname === '/index.html') {
      // no-store: the UI is a single evolving file — a stale cached copy would
      // silently break the page (apps never render, no visible error).
      res.writeHead(200, {
        'Content-Type': 'text/html; charset=utf-8',
        'Cache-Control': 'no-store',
      });
      res.end(readFileSync(new URL('./public/index.html', import.meta.url), 'utf8'));
      return;
    }
    return url.pathname.startsWith('/api/')
      ? writeJson(res, 404, { error: 'not-found' }, origin)
      : json(res, 404, { error: 'not-found' });
  });
}

export async function startServer(): Promise<void> {
  const root = rootDefault;
  const preferred = Number(process.env.CC_PORT ?? 8090);
  const alreadyRunning = await new Promise<boolean>((done) => {
    const req = request(
      { host: '127.0.0.1', port: preferred, path: '/api/health', timeout: 300 },
      (res) => {
        let body = '';
        res.on('data', (chunk) => {
          body += chunk;
        });
        res.on('end', () => {
          try {
            done(res.statusCode === 200 && JSON.parse(body).app === 'command-center');
          } catch {
            done(false);
          }
        });
      },
    );
    req.on('error', () => done(false));
    req.on('timeout', () => {
      req.destroy();
      done(false);
    });
    req.end();
  });
  if (alreadyRunning) {
    console.error(`[CC] Ya existe un Command Center en http://127.0.0.1:${preferred}`);
    return;
  }
  const port = await getFreePort(preferred);
  if (port !== preferred) {
    mkdirSync(runtimeDir(root), { recursive: true });
    writeFileSync(
      join(runtimeDir(root), 'command-center-ports.json'),
      JSON.stringify({ ccPort: port, updated: new Date().toISOString() }, null, 2),
    );
  }
  const server = createCommandCenterServer(createAppsController({ root }), root);
  mkdirSync(runtimeDir(root), { recursive: true });
  // CC_PID_FILE: tests/smoke run their own server instance — without this
  // override they would clobber the production pidfile (write + SIGTERM unlink).
  const pidFile = process.env.CC_PID_FILE ?? join(runtimeDir(root), 'command-center.pid');
  writeFileSync(pidFile, String(process.pid));
  const cleanup = () => {
    try {
      unlinkSync(pidFile);
    } catch {}
    server.close(() => process.exit(0));
  };
  process.once('SIGTERM', cleanup);
  process.once('SIGINT', cleanup);
  server.listen(port, '127.0.0.1', () =>
    console.log(`[CC] Command Center on http://127.0.0.1:${port}`),
  );
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) void startServer();
