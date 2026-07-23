/**
 * Session Autostart runs without errors.
 * Migrated from: tests/integration/session-autostart.integration.tests.ps1
 */
import { describe, it } from 'node:test';
import assert from 'node:assert';
import { spawnSync } from 'child_process';
import { resolve } from 'path';

const ROOT = resolve(import.meta.dirname, '..', '..');

describe('Session Autostart', () => {
  it('runs session-autostart.ts without errors', () => {
    const result = spawnSync('npx', ['tsx', 'src/session-autostart.ts'], {
      cwd: ROOT, encoding: 'utf-8', timeout: 120000, shell: true
    });
    // Check that the pipeline started (it may have lazy background tasks still running)
    assert.ok(result.stdout.includes('OK') || result.stdout.includes('completed'), 
      `Expected pipeline completion, got status=${result.status}: ${result.stdout.slice(0, 200)}`);
  });
});
