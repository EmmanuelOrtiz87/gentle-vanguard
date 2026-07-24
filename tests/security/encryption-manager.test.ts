/**
 * Tests for Encryption Manager — status and secret detection
 * Migrated from: tests/security/encryption-manager.tests.ps1
 */
import { describe, it } from 'node:test';
import assert from 'node:assert';
import { execSync } from 'child_process';
import { resolve } from 'path';

const ROOT = resolve(import.meta.dirname, '..', '..');
const SCRIPT = resolve(ROOT, 'src', 'Security', 'security-orchestrator.ts');

function runScript(scriptPath: string, ...args: string[]): string {
  try {
    const cmd = args.length > 0 ? `npx tsx ${scriptPath} ${args.join(' ')}` : `npx tsx ${scriptPath}`;
    return execSync(cmd, { cwd: ROOT, encoding: 'utf-8', timeout: 10000 });
  } catch (err: any) {
    return err.stdout || err.stderr || err.message || '';
  }
}

describe('encryption-manager', () => {
  it('should run status', () => {
    const result = runScript(SCRIPT, 'status');
    const parsed = JSON.parse(result);
    assert.equal(parsed.status, 'OK');
  });

  it('should detect AWS keys', () => {
    const result = runScript(SCRIPT, 'block', 'prompt', 'AKIAIOSFODNN7EXAMPLE');
    const parsed = JSON.parse(result);
    assert.equal(parsed.status, 'BLOCKED');
  });

  it('should detect GitHub tokens', () => {
    const result = runScript(SCRIPT, 'block', 'prompt', 'ghp_A0B1C2D3E4F5G6H7I8J9K0L1M2N3O4P5Q6R7S8T');
    const parsed = JSON.parse(result);
    assert.equal(parsed.status, 'BLOCKED');
  });
});
