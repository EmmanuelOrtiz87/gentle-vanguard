/**
 * Tool config validation runs and exits cleanly.
 * Migrated from: tests/integration/pre-close-validator.integration.tests.ps1
 */
import { describe, it } from 'node:test';
import assert from 'node:assert';
import { spawnSync } from 'child_process';
import { resolve } from 'path';

const ROOT = resolve(import.meta.dirname, '..', '..');

describe('Pre-Close Validator', () => {
  it('validate-tool-configs.ts runs with exit code 0', () => {
    const result = spawnSync('npx', ['tsx', 'src/Core/validate-tool-configs.ts'], {
      cwd: ROOT, encoding: 'utf-8', timeout: 15000, shell: true
    });
    assert.strictEqual(result.status, 0, `stdout: ${result.stdout}\nstderr: ${result.stderr}`);
  });
});
