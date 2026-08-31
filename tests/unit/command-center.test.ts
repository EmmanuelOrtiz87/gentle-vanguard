import { afterEach, describe, expect, it } from 'vitest';
import { existsSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { APPS_REGISTRY, createAppsController } from '../../apps/command-center/server.ts';

const roots: string[] = [];
afterEach(() => {
  for (const root of roots.splice(0)) rmSync(root, { recursive: true, force: true });
});
function testRoot(): string {
  const root = join(tmpdir(), `gv-command-center-${Date.now()}-${Math.random()}`);
  mkdirSync(join(root, '.runtime'), { recursive: true });
  roots.push(root);
  return root;
}
function fakeSpawn() {
  return { pid: 12345, unref: () => undefined } as never;
}

describe('Command Center app controller', () => {
  it('exposes the four normal managed apps', () =>
    expect(APPS_REGISTRY.map((app) => app.id)).toEqual([
      'dashboard',
      'analytics',
      'cms',
      'academy',
    ]));
  it('does not spawn when an app is already running', async () => {
    const root = testRoot();
    writeFileSync(join(root, '.runtime', 'app-academy-http.pid'), String(process.pid));
    const spawn = (() => {
      throw new Error('must not spawn');
    }) as never;
    const controller = createAppsController({ root, probe: async () => true, spawn });
    const result = await controller.start('academy');
    expect(result.status).toBe(200);
  });
  it('starts and stops a stopped app', async () => {
    const root = testRoot();
    let calls = 0;
    let probes = 0;
    const spawn = (() => {
      calls++;
      return fakeSpawn();
    }) as never;
    const controller = createAppsController({ root, probe: async () => ++probes > 1, spawn });
    await controller.start('academy');
    expect(calls).toBe(1);
    expect((await controller.stop('academy')).status).toBe(200);
  });
  it('uses a live legacy dashboard pidfile and trusts the port when that pid is stale', async () => {
    const root = testRoot();
    const legacy = join(root, '.runtime', 'dashboard-ws.pid');
    writeFileSync(legacy, '999999');
    const controller = createAppsController({ root, probe: async () => true });
    const dashboard = (await controller.list()).find((app) => app.id === 'dashboard');
    expect(dashboard?.processes[0]).toMatchObject({ alive: true, pid: null });
    expect(existsSync(legacy)).toBe(true);
  });
});
