import { describe, it } from 'node:test';
import { strict as assert } from 'node:assert';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = process.cwd();

describe('CI/CD Workflows', () => {
  it('ci.yml exists and contains required jobs', () => {
    const path = join(ROOT, '.github', 'workflows', 'ci.yml');
    assert.ok(existsSync(path), 'ci.yml should exist');
    const content = readFileSync(path, 'utf-8');
    assert.ok(content.includes('lint-typecheck'), 'Should have lint-typecheck job');
    assert.ok(content.includes('test:'), 'Should have test job');
    assert.ok(content.includes('dashboard-build'), 'Should have dashboard-build job');
    assert.ok(content.includes('security-scan'), 'Should have security-scan job');
    assert.ok(content.includes('workflow-lint'), 'Should have workflow-lint job');
  });

  it('security.yml exists and contains required jobs', () => {
    const path = join(ROOT, '.github', 'workflows', 'security.yml');
    assert.ok(existsSync(path), 'security.yml should exist');
    const content = readFileSync(path, 'utf-8');
    assert.ok(content.includes('gitleaks'), 'Should have gitleaks job');
    assert.ok(content.includes('secretlint'), 'Should have secretlint job');
    assert.ok(content.includes('trivy'), 'Should have trivy job');
  });
});
