/**
 * Engram integrity check runs and produces output.
 * Migrated from: tests/integration/engram-orchestrator.integration.tests.ps1
 */
import { describe, it } from 'node:test';
import assert from 'node:assert';
import { spawnSync } from 'child_process';
import { resolve } from 'path';

const ROOT = resolve(import.meta.dirname, '..', '..');

describe('Engram Orchestrator', () => {
  it('engram-integrity-check.ts runs and produces output', () => {
    const result = spawnSync('npx', ['tsx', 'src/engram-integrity-check.ts'], {
      cwd: ROOT,
      encoding: 'utf-8',
      timeout: 15000,
      shell: true,
    });
    assert.ok(result.stdout.length > 0, 'Expected stdout output');
  });
});
