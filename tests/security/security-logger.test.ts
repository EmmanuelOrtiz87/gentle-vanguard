/**
 * Tests for Security Logger — audit pipeline status
 * Migrated from: tests/security/security-logger.tests.ps1
 */
import { describe, it } from 'node:test';
import assert from 'node:assert';
import { execSync } from 'child_process';
import { resolve } from 'path';

const ROOT = resolve(import.meta.dirname, '..', '..');
const SCRIPT = resolve(ROOT, 'src', 'infrastructure', 'audit-pipeline.ts');

function runScript(scriptPath: string, ...args: string[]): string {
  try {
    const cmd = args.length > 0 ? `npx tsx ${scriptPath} ${args.join(' ')}` : `npx tsx ${scriptPath}`;
    return execSync(cmd, { cwd: ROOT, encoding: 'utf-8', timeout: 10000 });
  } catch (err: any) {
    return err.stdout || err.stderr || err.message || '';
  }
}

describe('security-logger', () => {
  it('should run without errors', () => {
    const result = runScript(SCRIPT, '-Action', 'status');
    const parsed = JSON.parse(result);
    assert.ok(parsed);
    assert.equal(typeof parsed.totalEvents, 'number');
  });

  it('should return valid JSON', () => {
    const result = runScript(SCRIPT, '-Action', 'status');
    const parsed = JSON.parse(result);
    assert.ok(parsed.totalSizeFormatted);
    assert.ok(Array.isArray(parsed.logFiles));
  });
});
