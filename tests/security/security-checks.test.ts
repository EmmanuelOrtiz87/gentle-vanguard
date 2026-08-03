/**
 * Tests for Security Checks — config file existence and trufflehog integration
 * Migrated from: tests/security/security-checks.tests.ps1
 */
import { describe, it } from 'node:test';
import assert from 'node:assert';
import { existsSync, readFileSync } from 'fs';
import { resolve } from 'path';

const ROOT = resolve(import.meta.dirname, '..', '..');

describe('security-checks', () => {
  it('opencode.json should exist', () => {
    const file = resolve(ROOT, 'opencode.json');
    assert.ok(existsSync(file), 'opencode.json not found');
  });

  it('lefthook.yml should exist', () => {
    const file = resolve(ROOT, '.lefthook.yml');
    assert.ok(existsSync(file), '.lefthook.yml not found');
  });

  it('should have security patterns file', () => {
    const file = resolve(ROOT, 'config', 'security-privacy.json');
    assert.ok(existsSync(file), 'security-privacy.json not found');
    const content = readFileSync(file, 'utf-8');
    const parsed = JSON.parse(content);
    assert.ok(parsed.privacy);
    assert.ok(parsed.privacy.criticalBlock);
  });
});
