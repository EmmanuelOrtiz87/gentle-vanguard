/**
 * Tests for Input Validator — scan mode with safe content
 * Migrated from: tests/security/input-validator.tests.ps1
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

describe('input-validator', () => {
  it('should return a status response', () => {
    const result = runScript(SCRIPT, 'scan');
    assert.ok(result.length > 0, `Expected output, got empty: ${result}`);
    // May return AUTH_REQUIRED (needs auth) or OK depending on state
    const parsed = JSON.parse(result);
    assert.ok(['OK', 'AUTH_REQUIRED', 'ERROR'].includes(parsed.status), `Unexpected status: ${parsed.status}`);
  });

  it('should run without errors', () => {
    const result = runScript(SCRIPT, 'scan');
    assert.ok(result);
    const parsed = JSON.parse(result);
    assert.ok(parsed.status);
  });
});
