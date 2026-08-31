import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { request } from 'node:http';

const port = 18090;
const pidFile = '.runtime/command-center-smoke.pid';
const child = spawn(process.execPath, ['--import', 'tsx', 'apps/command-center/server.ts'], {
      env: {
        ...process.env,
        CC_PORT: String(port),
        // Isolated pidfile — never touch the production command-center.pid.
        CC_PID_FILE: pidFile,
      },
  stdio: 'ignore',
  windowsHide: true,
});
const get = (path, method = 'GET') =>
  new Promise((resolve, reject) => {
    const req = request({ host: '127.0.0.1', port, path, method }, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(body) }));
    });
    req.on('error', reject);
    req.end();
  });
try {
  for (let i = 0; i < 40; i++) {
    try {
      if ((await get('/api/health')).status === 200) break;
    } catch {}
    await new Promise((r) => setTimeout(r, 250));
  }
  const apps = await get('/api/apps');
  assert.equal(apps.status, 200);
  assert.deepEqual(
    apps.body.map((app) => app.id),
    ['dashboard', 'analytics', 'cms', 'academy'],
  );
  const academyWasRunning = apps.body.find((app) => app.id === 'academy').status === 'running';
  const start = await get('/api/apps/academy/start', 'POST');
  assert.equal(start.status, 200);
  assert.equal(start.body.status, 'running');
  const repeat = await get('/api/apps/academy/start', 'POST');
  assert.equal(repeat.status, 200);
  assert.equal(repeat.body.status, 'running');
  if (!academyWasRunning) {
    const stop = await get('/api/apps/academy/stop', 'POST');
    assert.equal(stop.status, 200);
    assert.equal(stop.body.status, 'stopped');
  }
  const dashboard = await get('/api/apps/dashboard/start', 'POST');
  assert.equal(dashboard.status, 200);
  assert.notEqual(dashboard.status, 409);
  console.log('command-center smoke: PASS');
} finally {
  child.kill('SIGTERM');
}
