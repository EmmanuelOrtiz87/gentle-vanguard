import { createServer as createHttpServer, type ServerResponse } from 'node:http';
import { existsSync, mkdirSync, readFileSync, unlinkSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { connect } from 'node:net';
import { request } from 'node:http';
import { spawn as nodeSpawn, type ChildProcess, type SpawnOptions } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { getFreePort } from '../dashboard-common';

export type AppStatus = 'running' | 'stopped' | 'partial';
export type AppId = 'dashboard' | 'analytics' | 'cms' | 'academy';
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
    for (const item of def.processes()) {
      if (!existsSync(item.pidFile)) continue;
      let pid = 0;
      try {
        pid = Number(readFileSync(item.pidFile, 'utf8').trim());
      } catch {
        /* stale */
      }
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
      try {
        unlinkSync(item.pidFile);
      } catch {
        /* already removed */
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
function validHost(host: string | undefined): boolean {
  if (!host) return false;
  const hostname = host.replace(/^\[/, '').split(']')[0].split(':')[0].toLowerCase();
  return hostname === '127.0.0.1' || hostname === 'localhost' || hostname === '::1';
}
export function createCommandCenterServer(controller = createAppsController()) {
  return createHttpServer(async (req, res) => {
    if (!validHost(req.headers.host)) return json(res, 400, { error: 'invalid-host' });
    const url = new URL(req.url ?? '/', 'http://127.0.0.1');
    if (url.pathname === '/api/health' && req.method === 'GET')
      return json(res, 200, { ok: true, app: 'command-center' });
    if (url.pathname === '/api/apps' && req.method === 'GET')
      return json(res, 200, await controller.list());
    const match = url.pathname.match(/^\/api\/apps\/([^/]+)\/(start|stop)$/);
    if (match && req.method === 'POST') {
      const result = await controller[match[2] as 'start' | 'stop'](decodeURIComponent(match[1]));
      return json(res, result.status, result.body);
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
    json(res, 404, { error: 'not-found' });
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
  const server = createCommandCenterServer(createAppsController({ root }));
  mkdirSync(runtimeDir(root), { recursive: true });
  writeFileSync(join(runtimeDir(root), 'command-center.pid'), String(process.pid));
  const cleanup = () => {
    try {
      unlinkSync(join(runtimeDir(root), 'command-center.pid'));
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
