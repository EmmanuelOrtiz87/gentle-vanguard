import { describe, it } from 'node:test';
import assert from 'node:assert';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';

const ROOT = resolve(import.meta.dirname, '..', '..');

describe('gentle-vanguard-core', () => {
  it('src/session-autostart.ts exists', () => {
    assert.ok(existsSync(resolve(ROOT, 'src', 'session-autostart.ts')));
  });

  it('src/health-check.ts exists', () => {
    assert.ok(existsSync(resolve(ROOT, 'src', 'health-check.ts')));
  });

  it('src/maintenance-watchtower.ts exists', () => {
    assert.ok(existsSync(resolve(ROOT, 'src', 'maintenance-watchtower.ts')));
  });
});
