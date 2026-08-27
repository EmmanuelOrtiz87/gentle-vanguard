import { describe, it } from 'node:test';
import { strict as assert } from 'node:assert';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = process.cwd();

describe('CI/CD Workflows', () => {
  it('ci.yml is the single entrypoint and contains required jobs', () => {
    const path = join(ROOT, '.github', 'workflows', 'ci.yml');
    assert.ok(existsSync(path), 'ci.yml should exist');
    const content = readFileSync(path, 'utf8');
    // Reusable workflow calls (consolidated pipeline)
    assert.ok(content.includes('reusable-lint.yml'), 'Should call reusable-lint');
    assert.ok(content.includes('reusable-test.yml'), 'Should call reusable-test');
    assert.ok(
      content.includes('reusable-security-scan.yml'),
      'Should call reusable-security-scan (single security surface)',
    );
    // Jobs kept inline in ci.yml
    assert.ok(content.includes('mcp-servers'), 'Should have mcp-servers job');
    assert.ok(content.includes('sbom-generation'), 'Should have sbom-generation job');
    assert.ok(content.includes('version-sync'), 'Should have version-sync job');
    assert.ok(content.includes('node-compat'), 'Should have node-compat matrix job');
    // Hygiene
    assert.ok(content.includes('concurrency:'), 'Should declare concurrency');
    assert.ok(content.includes('cancel-in-progress'), 'Should cancel in-progress runs');
    assert.ok(content.includes('permissions:'), 'Should declare permissions');
    assert.ok(content.includes('timeout-minutes:'), 'Jobs should have timeouts');
    assert.ok(content.includes('pnpm/action-setup'), 'Should use pnpm');
    assert.ok(content.includes('frozen-lockfile'), 'Should use frozen lockfile');
    assert.ok(content.includes('cache: pnpm'), 'Should cache pnpm store');
    assert.ok(content.includes('static-gates'), 'Should run static deployment/artifact gates');
    assert.ok(
      content.includes('ci:static-gates'),
      'Should invoke static deployment/artifact validation',
    );
  });

  it('security scanning lives in reusable-security-scan.yml with real gates', () => {
    const path = join(ROOT, '.github', 'workflows', 'reusable-security-scan.yml');
    assert.ok(existsSync(path), 'reusable-security-scan.yml should exist');
    const content = readFileSync(path, 'utf8');
    assert.ok(content.includes('gitleaks'), 'Should have gitleaks job');
    assert.ok(content.includes('secretlint'), 'Should have secretlint job');
    assert.ok(content.includes('trivy-action'), 'Should have trivy scan');
    // Gates must be real: no swallowed failures
    assert.ok(
      !content.includes('|| echo "Audit found issues"'),
      'npm audit must not swallow failures',
    );
    assert.ok(!content.includes('exit-code: 0'), 'trivy must gate (exit-code 1), not just report');
  });

  it('duplicate entrypoint workflows were removed (single CI surface)', () => {
    const workflowsDir = join(ROOT, '.github', 'workflows');
    for (const removed of ['pr.yml', 'push-checks.yml', 'security.yml']) {
      assert.ok(
        !existsSync(join(workflowsDir, removed)),
        `${removed} should not exist (consolidated into ci.yml)`,
      );
    }
  });

  it('e2e tests run in CI (reusable-test.yml)', () => {
    const path = join(ROOT, '.github', 'workflows', 'reusable-test.yml');
    const content = readFileSync(path, 'utf8');
    assert.ok(content.includes('tests/e2e/'), 'Should run e2e tests');
    assert.ok(content.includes('vitest') || content.includes('pnpm test'), 'Dashboard vitest');
  });
});
