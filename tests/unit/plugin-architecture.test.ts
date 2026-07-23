import { describe, it } from 'node:test';
import assert from 'node:assert';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';

const ROOT = resolve(import.meta.dirname, '..', '..');

describe('plugin-architecture', () => {
  it('src/skill-factory.ts exists', () => {
    assert.ok(existsSync(resolve(ROOT, 'src', 'skill-factory.ts')));
  });

  it('src/skill-embedder.ts exists', () => {
    assert.ok(existsSync(resolve(ROOT, 'src', 'skill-embedder.ts')));
  });
});
