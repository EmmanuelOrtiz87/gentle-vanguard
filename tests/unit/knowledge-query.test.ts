import { describe, it } from 'node:test';
import assert from 'node:assert';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';

const ROOT = resolve(import.meta.dirname, '..', '..');

describe('knowledge-query', () => {
  it('src/knowledge/knowledge-base-init.ts exists', () => {
    assert.ok(existsSync(resolve(ROOT, 'src', 'knowledge', 'knowledge-base-init.ts')));
  });

  it('src/knowledge/knowledge-base-manager.ts exists', () => {
    assert.ok(existsSync(resolve(ROOT, 'src', 'knowledge', 'knowledge-base-manager.ts')));
  });
});
