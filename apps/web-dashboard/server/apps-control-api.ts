import type { IncomingMessage, ServerResponse } from 'node:http';
import { existsSync, mkdirSync, readFileSync, unlinkSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { connect } from 'node:net';
import { spawn as nodeSpawn, type ChildProcess } from 'node:child_process';
import { ROOT } from './shared.ts';

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
interface ProcessDefinition {
  name: string;
  port: number;
  pidFile: string;
  start: () => ChildProcess;
}
interface AppDefinition {
  id: AppId;
  name: string;
  description: string;
  url: string;
  self?: boolean;
  server?: string;
  client?: string;
  processes: () => ProcessDefinition[];
}
interface AppsControlOptions {
  root?: string;
  spawn?: typeof nodeSpawn;
  probe?: (port: number) => Promise<boolean>;
  readDashboardPort?: () => number;
}

const runtimeDir = (root: string) => join(root, '.runtime');
const pidPath = (root: string, appId: AppId, processName: string) =>
  join(runtimeDir(root), `app-${appId}-${processName}.pid`);
const appRoot = (name: string) => resolve(ROOT, 'apps', name);

function readPort(root: string): number {
  try {
    const value = JSON.parse(
      readFileSync(join(root, '.runtime', 'dashboard-ports.json'), 'utf8'),
    ) as { ws?: number; wsPort?: number; server?: number; port?: number };
    return Number(value.ws ?? value.wsPort ?? value.server ?? value.port ?? 8080);
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
  return new Promise((resolveProbe) => {
    const socket = connect({ host: '127.0.0.1', port });
    const finish = (value: boolean) => {
      socket.destroy();
      resolveProbe(value);
    };
    socket.setTimeout(1000, () => finish(false));
    socket.once('connect', () => finish(true));
    socket.once('error', () => finish(false));
  });
}

export const APPS_REGISTRY: ReadonlyArray<
  Pick<AppDefinition, 'id' | 'name' | 'description' | 'url' | 'self' | 'server' | 'client'>
> = [
  {
    id: 'dashboard',
    name: 'Dashboard',
    description: 'Gentle-Vanguard stack operations',
    url: 'http://127.0.0.1:5173',
    self: true,
    server: 'apps/web-dashboard/server/websocket-server.ts',
    client: 'vite',
  },
  {
    id: 'analytics',
    name: 'Analytics',
    description: 'Reports and operational analytics',
    url: 'http://127.0.0.1:5174',
    server: 'node --import tsx server/index.ts',
    client: 'vite',
  },
  {
    id: 'cms',
    name: 'Content CMS',
    description: 'Content workflow and publishing',
    url: 'http://127.0.0.1:5175',
    client: 'vite',
  },
  {
    id: 'academy',
    name: 'Academy',
    description: 'Gentle-Vanguard learning hub',
    url: 'http://127.0.0.1:4173',
    server: 'python -m http.server 4173',
  },
];

function json(res: ServerResponse, status: number, body: unknown, headers: Record<string, string>) {
  res.writeHead(status, headers);
  res.end(JSON.stringify(body));
}

export function createAppsController(options: AppsControlOptions = {}) {
  const root = options.root ?? ROOT;
  const spawn = options.spawn ?? nodeSpawn;
  const probe = options.probe ?? probePort;
  const vite = (cwd: string, args: string[]) =>
    spawn(process.execPath, [resolve(cwd, 'node_modules/vite/bin/vite.js'), ...args], {
      cwd,
      stdio: 'ignore',
      detached: true,
      windowsHide: true,
    });
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
          port: options.readDashboardPort?.() ?? readPort(root),
          pidFile: pidPath(root, 'dashboard', 'server'),
          start: () => process as unknown as ChildProcess,
        },
        {
          name: 'vite',
          port: 5173,
          pidFile: pidPath(root, 'dashboard', 'vite'),
          start: () => process as unknown as ChildProcess,
        },
      ],
    },
    {
      ...APPS_REGISTRY[1],
      processes: () => [
        {
          name: 'api',
          port: 4754,
          pidFile: pidPath(root, 'analytics', 'api'),
          start: () => ts(appRoot('gv-analytics'), 'server/index.ts'),
        },
        {
          name: 'vite',
          port: 5174,
          pidFile: pidPath(root, 'analytics', 'vite'),
          start: () =>
            vite(appRoot('gv-analytics'), [
              '--host',
              '127.0.0.1',
              '--port',
              '5174',
              '--strictPort',
            ]),
        },
      ],
    },
    {
      ...APPS_REGISTRY[2],
      processes: () => [
        {
          name: 'api',
          port: 3787,
          pidFile: pidPath(root, 'cms', 'api'),
          start: () => ts(appRoot('content-cms'), 'server/server.ts'),
        },
        {
          name: 'vite',
          port: 5175,
          pidFile: pidPath(root, 'cms', 'vite'),
          start: () =>
            vite(appRoot('content-cms'), ['--host', '127.0.0.1', '--port', '5175', '--strictPort']),
        },
      ],
    },
    {
      ...APPS_REGISTRY[3],
      processes: () => [
        {
          name: 'http',
          port: 4173,
          pidFile: pidPath(root, 'academy', 'http'),
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
                appRoot('academy-web'),
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
      try {
        if (existsSync(item.pidFile)) pid = Number(readFileSync(item.pidFile, 'utf8').trim());
      } catch {
        pid = null;
      }
      const alive =
        pid !== null && Number.isInteger(pid) && isAlive(pid) && (await probe(item.port));
      if (!alive && existsSync(item.pidFile))
        try {
          unlinkSync(item.pidFile);
        } catch {
          /* best effort */
        }
      processes.push({ name: item.name, pid: alive ? pid : null, port: item.port, alive });
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
    if (def.self)
      return {
        status: 409,
        body: { error: 'self-managed', detail: 'The dashboard server manages its own lifecycle.' },
      };
    const before = await inspect(def);
    if (before.status === 'running') return { status: 200, body: before };
    mkdirSync(runtimeDir(root), { recursive: true });
    for (const item of def.processes()) {
      const current = before.processes.find((processInfo) => processInfo.name === item.name);
      if (current?.alive) continue;
      const child = item.start();
      if (child.pid) writeFileSync(item.pidFile, String(child.pid));
      child.unref();
      const deadline = Date.now() + 15000;
      while (Date.now() < deadline && !(await probe(item.port)))
        await new Promise((resolveWait) => setTimeout(resolveWait, 500));
    }
    return { status: 200, body: await inspect(def) };
  }
  async function stop(id: string): Promise<{ status: number; body: unknown }> {
    const def = find(id);
    if (!def) return { status: 404, body: { error: 'app-not-found' } };
    if (def.self)
      return {
        status: 409,
        body: { error: 'self-managed', detail: 'The dashboard server manages its own lifecycle.' },
      };
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
          await new Promise((resolveWait) => setTimeout(resolveWait, 250));
          if (isAlive(pid)) {
            spawn('taskkill', ['/pid', String(pid), '/t', '/f'], {
              windowsHide: true,
              stdio: 'ignore',
            });
          }
        } catch {
          spawn('taskkill', ['/pid', String(pid), '/t', '/f'], {
            windowsHide: true,
            stdio: 'ignore',
          });
        }
      }
      try {
        unlinkSync(item.pidFile);
      } catch {
        /* already removed */
      }
    }
    return { status: 200, body: await inspect(def) };
  }
  return { list: async () => Promise.all(definitions().map(inspect)), start, stop };
}

const controller = createAppsController();
export async function appsControlHandler(
  req: IncomingMessage,
  res: ServerResponse,
  url: URL,
  _ctx: unknown,
  headers: Record<string, string>,
): Promise<boolean> {
  if (url.pathname === '/api/apps' && req.method === 'GET') {
    json(res, 200, await controller.list(), headers);
    return true;
  }
  const match = url.pathname.match(/^\/api\/apps\/([^/]+)\/(start|stop)$/);
  if (match && req.method === 'POST') {
    const result = await controller[match[2] as 'start' | 'stop'](decodeURIComponent(match[1]));
    json(res, result.status, result.body, headers);
    return true;
  }
  return false;
}
