import { describe, expect, it, vi } from 'vitest';
import { mkdirSync, writeFileSync, existsSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { APPS_REGISTRY, createAppsController } from '../server/apps-control-api';

describe('apps control API', () => {
  it('exports the four registered apps', () => {
    expect(APPS_REGISTRY.map((app) => app.id)).toEqual([
      'dashboard',
      'analytics',
      'cms',
      'academy',
    ]);
    expect(APPS_REGISTRY.find((app) => app.id === 'dashboard')?.self).toBe(true);
  });

  it('does not spawn an already running app', async () => {
    const spawn = vi.fn();
    const root = join(tmpdir(), `gv-apps-control-${Date.now()}`);
    mkdirSync(join(root, '.runtime'), { recursive: true });
    writeFileSync(join(root, '.runtime', 'app-academy-http.pid'), String(process.pid));
    const controller = createAppsController({
      root,
      probe: vi.fn().mockResolvedValue(true),
      spawn,
    });
    const result = await controller.start('academy');
    expect(result.status).toBe(200);
    expect(spawn).not.toHaveBeenCalled();
    rmSync(root, { recursive: true, force: true });
  });

  it('rejects lifecycle changes for the dashboard', async () => {
    const controller = createAppsController({ probe: vi.fn().mockResolvedValue(false) });
    expect((await controller.stop('dashboard')).status).toBe(409);
    expect((await controller.start('dashboard')).body).toMatchObject({ error: 'self-managed' });
  });

  it('removes stale pidfiles during status detection', async () => {
    const root = join(tmpdir(), `gv-apps-control-${Date.now()}`);
    mkdirSync(join(root, '.runtime'), { recursive: true });
    const pidFile = join(root, '.runtime', 'app-academy-http.pid');
    writeFileSync(pidFile, '999999');
    const controller = createAppsController({ root, probe: vi.fn().mockResolvedValue(true) });
    const apps = await controller.list();
    expect(apps.find((app) => app.id === 'academy')?.status).toBe('stopped');
    expect(existsSync(pidFile)).toBe(false);
    rmSync(root, { recursive: true, force: true });
  });
});
