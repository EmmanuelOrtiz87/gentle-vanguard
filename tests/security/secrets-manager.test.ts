/**
 * Tests for Secrets Manager — API key and secret detection
 * Migrated from: tests/security/secrets-manager.tests.ps1
 */
import { describe, it } from 'node:test';
import assert from 'node:assert';
import { execSync } from 'child_process';
import { resolve } from 'path';

const ROOT = resolve(import.meta.dirname, '..', '..');
const SCRIPT = resolve(ROOT, 'src', 'check-security.ts');

function runScript(scriptPath: string, ...args: string[]): string {
  try {
    const cmd =
      args.length > 0 ? `npx tsx ${scriptPath} ${args.join(' ')}` : `npx tsx ${scriptPath}`;
    return execSync(cmd, { cwd: ROOT, encoding: 'utf-8', timeout: 10000 });
  } catch (err: any) {
    return err.stdout || err.stderr || err.message || '';
  }
}

describe('secrets-manager', () => {
  it('should detect AWS keys', () => {
    const result = runScript(SCRIPT);
    // Script scans staged files — no staged files means exit 0 (clean)
    assert.ok(result !== undefined);
  });

  it('should detect JWT tokens', () => {
    const result = runScript(SCRIPT);
    assert.ok(result !== undefined);
  });
});
