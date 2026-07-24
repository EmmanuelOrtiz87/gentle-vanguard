import { describe, it } from 'node:test';
import assert from 'node:assert';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';

const ROOT = resolve(import.meta.dirname, '..', '..');

describe('engine-scripts', () => {
  it('maintenance-watchtower.ts exists', () => {
    assert.ok(existsSync(resolve(ROOT, 'src', 'Core', 'maintenance-watchtower.ts')));
  });

  it('health-check.ts exists', () => {
    assert.ok(existsSync(resolve(ROOT, 'src', 'Core', 'health-check.ts')));
  });
});
