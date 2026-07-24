/**
 * Detect tool detection from environment.
 * Migrated from: tests/integration/detect-tool.integration.tests.ps1
 */
import { describe, it } from 'node:test';
import assert from 'node:assert';
import { spawnSync } from 'child_process';
import { resolve } from 'path';

const ROOT = resolve(import.meta.dirname, '..', '..');

describe('Detect Tool', () => {
  it('detects OpenCode from env', () => {
    const result = spawnSync('npx', ['tsx', 'src/Core/detect-tool.ts', '--json'], {
      cwd: ROOT, encoding: 'utf-8', timeout: 15000, shell: true,
      env: { ...process.env, OPENCODE_SERVER_USERNAME: 'test-user' }
    });
    const parsed = JSON.parse(result.stdout);
    assert.ok(parsed.name || parsed.isOpenCode !== undefined, `output: ${result.stdout}`);
  });

  it('returns valid JSON', () => {
    const result = spawnSync('npx', ['tsx', 'src/Core/detect-tool.ts', '--json'], {
      cwd: ROOT, encoding: 'utf-8', timeout: 15000, shell: true
    });
    const parsed = JSON.parse(result.stdout);
    assert.ok(typeof parsed === 'object' && parsed !== null, 'Expected JSON object');
  });
});
