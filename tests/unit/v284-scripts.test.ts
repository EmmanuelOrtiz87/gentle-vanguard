import { describe, it } from 'node:test';
import assert from 'node:assert';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';

const ROOT = resolve(import.meta.dirname, '..', '..');

describe('v284-scripts', () => {
  it('src/audit-pipeline.ts exists', () => {
    assert.ok(existsSync(resolve(ROOT, 'src', 'v4.0-Infrastructure', 'audit-pipeline.ts')));
  });

  it('src/privacy-gateway.ts exists', () => {
    assert.ok(existsSync(resolve(ROOT, 'src', 'Security', 'privacy-gateway.ts')));
  });
});
