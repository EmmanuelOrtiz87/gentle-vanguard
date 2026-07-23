/**
 * Post-session learning summary generation.
 * Migrated from: tests/integration/post-session-learning.integration.tests.ps1
 */
import { describe, it } from 'node:test';
import assert from 'node:assert';
import { spawnSync } from 'child_process';
import { resolve } from 'path';

const ROOT = resolve(import.meta.dirname, '..', '..');

describe('Post-Session Learning', () => {
  it('post-autostart-summary.ts runs and produces output', () => {
    const result = spawnSync('npx', ['tsx', 'src/post-autostart-summary.ts'], {
      cwd: ROOT, encoding: 'utf-8', timeout: 15000, shell: true
    });
    assert.ok(result.stdout.length > 0, 'Expected stdout output');
  });
});
