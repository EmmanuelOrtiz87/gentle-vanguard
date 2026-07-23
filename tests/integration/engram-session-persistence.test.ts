/**
 * Session directories exist for engram persistence.
 * Migrated from: tests/integration/engram-session-persistence.integration.tests.ps1
 */
import { describe, it } from 'node:test';
import assert from 'node:assert';
import { existsSync } from 'fs';
import { resolve, join } from 'path';

const ROOT = resolve(import.meta.dirname, '..', '..');

describe('Engram Session Persistence', () => {
  it('.session directory exists', () => {
    const dir = join(ROOT, '.session');
    assert.ok(existsSync(dir), `.session directory expected at ${dir}`);
  });

  it('context-log dir exists', () => {
    const dir = join(ROOT, '.session', 'context-log');
    assert.ok(existsSync(dir), `context-log directory expected at ${dir}`);
  });
});
