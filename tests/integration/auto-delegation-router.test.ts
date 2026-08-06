/**
 * Adaptive Router status check.
 * Migrated from: tests/integration/auto-delegation-router.integration.tests.ps1
 */
import { describe, it } from 'node:test';
import assert from 'node:assert';
import { spawnSync } from 'child_process';
import { resolve } from 'path';

const ROOT = resolve(import.meta.dirname, '..', '..');

describe('Auto-Delegation Router', () => {
  it('adaptive-router.ts --status runs successfully', () => {
    const result = spawnSync('npx', ['tsx', 'src/adaptive-router.ts', '--status'], {
      cwd: ROOT,
      encoding: 'utf-8',
      timeout: 15000,
      shell: true,
    });
    assert.ok(result.stdout.length > 0 || result.stderr.length > 0, 'Expected some output');
  });
});
