import { spawn } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { request } from 'node:http';

const root = resolve(process.cwd());
const runtime = join(root, '.runtime');
function port(): number {
  try {
    return Number(
      (
        JSON.parse(readFileSync(join(runtime, 'command-center-ports.json'), 'utf8')) as {
          ccPort: number;
        }
      ).ccPort,
    );
  } catch {
    return Number(process.env.CC_PORT ?? 8090);
  }
}
function health(p: number): Promise<boolean> {
  return new Promise((done) => {
    const req = request(
      { host: '127.0.0.1', port: p, path: '/api/health', timeout: 500 },
      (res) => {
        let data = '';
        res.on('data', (chunk) => {
          data += chunk;
        });
        res.on('end', () => {
          try {
            done(res.statusCode === 200 && JSON.parse(data).app === 'command-center');
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
}
function openBrowser(url: string): void {
  try {
    if (process.platform === 'win32')
      spawn('cmd.exe', ['/d', '/c', 'start', '""', url], {
        windowsHide: true,
        detached: true,
        stdio: 'ignore',
      }).unref();
    else
      spawn(process.platform === 'darwin' ? 'open' : 'xdg-open', [url], {
        detached: true,
        stdio: 'ignore',
      }).unref();
  } catch {}
}
const p = port();
if (await health(p)) openBrowser(`http://127.0.0.1:${p}/`);
else {
  const child = spawn(
    process.execPath,
    ['--import', 'tsx', join(root, 'src/ops/command-center/server.ts')],
    {
      cwd: root,
      detached: true,
      windowsHide: true,
      stdio: 'ignore',
      env: { ...process.env, CC_PORT: String(p) },
    },
  );
  child.unref();
  for (let i = 0; i < 30 && !(await health(p)); i++)
    await new Promise((done) => setTimeout(done, 300));
  openBrowser(`http://127.0.0.1:${p}/`);
}
