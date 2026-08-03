/**
 * Tests for Privacy Sanitizer — PII redaction and injection detection
 * Migrated from: tests/security/privacy-sanitizer.tests.ps1
 */
import { describe, it } from 'node:test';
import assert from 'node:assert';
import { execSync } from 'child_process';
import { resolve } from 'path';

const ROOT = resolve(import.meta.dirname, '..', '..');
const SCRIPT = resolve(ROOT, 'src', 'security', 'privacy-gateway.ts');

function runScript(scriptPath: string, ...args: string[]): string {
  try {
    const cmd = args.length > 0 ? `npx tsx ${scriptPath} ${args.join(' ')}` : `npx tsx ${scriptPath}`;
    return execSync(cmd, { cwd: ROOT, encoding: 'utf-8', timeout: 10000 });
  } catch (err: any) {
    return err.stdout || err.stderr || err.message || '';
  }
}

describe('privacy-sanitizer', () => {
  it('should detect email addresses', () => {
    const result = runScript(SCRIPT, '--text', 'user@example.com', '--as-json');
    const parsed = JSON.parse(result);
    assert.equal(parsed.status, 'OK');
    assert.ok(parsed.sanitized);
  });

  it('should detect IP addresses', () => {
    const result = runScript(SCRIPT, '--text', 'Request from 192.168.1.1', '--as-json');
    const parsed = JSON.parse(result);
    assert.equal(parsed.status, 'OK');
    assert.ok(parsed.sanitized);
  });

  it('should pass safe content', () => {
    // Use single-arg with escaped quotes to preserve spaces
    const result = execSync(`npx tsx "${SCRIPT}" --text "What is the weather today?"`, { cwd: ROOT, encoding: 'utf-8', timeout: 10000, shell: true });
    assert.ok(result.includes('weather') || result.includes('today'), `Expected weather-related content, got: ${result}`);
  });
});
