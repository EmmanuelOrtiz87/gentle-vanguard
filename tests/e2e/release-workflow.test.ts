#!/usr/bin/env node
/**
 * E2E Test: Release Workflow
 *
 * Verifies the real release gates against throwaway git repositories:
 *   1. SDD gate (src/sdd/check-sdd-gate.ts) blocks an incomplete release on main
 *      and is bypassed by .sdd-exempt.
 *   2. RDD release gate (src/rdd/rdd-gates.ts) responds with a structured
 *      GateValidation even when it fails for lack of a receipt.
 *   3. The five RDD delivery gates exist and are reported in release order.
 *
 * Uses node:test + assert (same runner as tests/unit). Temp repos are created
 * under os.tmpdir() and removed in after(). No real git push is performed.
 */

import { describe, it, before, after } from 'node:test';
import { strict as assert } from 'node:assert';
import { mkdtempSync, rmSync, mkdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { execSync } from 'node:child_process';
import { runNpxTsxSync } from '../../src/core/run-command.ts';
import type { DeliveryGate, GateValidation } from '../../src/rdd/rdd-gates.ts';

const ROOT = resolve(import.meta.dirname, '..', '..');
const SDD_GATE_SCRIPT = join(ROOT, 'src', 'sdd', 'check-sdd-gate.ts');
const RDD_GATES_SCRIPT = join(ROOT, 'src', 'rdd', 'rdd-gates.ts');

const RDD_GATE_ORDER: DeliveryGate[] = [
  'post-apply',
  'pre-commit',
  'pre-push',
  'pre-pr',
  'release',
];

const tempRepos: string[] = [];
let gitAvailable = true;

function git(cwd: string, ...args: string[]): void {
  const cmd = `git ${args.map((a) => (/\s/.test(a) ? `"${a}"` : a)).join(' ')}`;
  execSync(cmd, { cwd, stdio: 'pipe' });
}

function initRepo(): string {
  const dir = mkdtempSync(join(tmpdir(), 'gv-e2e-release-'));
  tempRepos.push(dir);
  git(dir, 'init', '-b', 'develop');
  git(dir, 'config', 'user.email', 'e2e@test.local');
  git(dir, 'config', 'user.name', 'E2E Test');
  writeFileSync(join(dir, 'README.md'), '# e2e release workflow\n', 'utf8');
  git(dir, 'add', '.');
  git(dir, 'commit', '-m', 'initial');
  return dir;
}

function extractJson<T>(output: string): T {
  const start = output.indexOf('{');
  const end = output.lastIndexOf('}');
  assert.ok(start !== -1 && end > start, `no JSON object found in output: ${output}`);
  return JSON.parse(output.slice(start, end + 1)) as T;
}

before(() => {
  try {
    execSync('git --version', { stdio: 'pipe' });
  } catch {
    gitAvailable = false;
  }
});

after(() => {
  for (const dir of tempRepos) {
    rmSync(dir, { recursive: true, force: true });
  }
});

describe('release workflow E2E', () => {
  describe('SDD gate', () => {
    it('blocks release on main when SDD docs are drafts', (t) => {
      if (!gitAvailable) return t.skip('git not available');
      const repo = initRepo();
      git(repo, 'checkout', '-b', 'main');
      mkdirSync(join(repo, 'docs', 'sdd'), { recursive: true });
      writeFileSync(join(repo, 'docs', 'sdd', 'release.md'), '**Status**: draft\n', 'utf8');

      const result = runNpxTsxSync(SDD_GATE_SCRIPT, [], { cwd: repo });
      assert.notEqual(result.status, 0, 'draft SDD on main must block the release');
      assert.match(result.stdout, /BLOCKING/);
    });

    it('does not block on develop without SDD docs (advisory only)', (t) => {
      if (!gitAvailable) return t.skip('git not available');
      const repo = initRepo(); // already on develop
      const result = runNpxTsxSync(SDD_GATE_SCRIPT, [], { cwd: repo });
      assert.equal(result.status, 0);
      assert.match(result.stdout, /ADVISORY/);
    });

    it('is bypassed by .sdd-exempt', (t) => {
      if (!gitAvailable) return t.skip('git not available');
      const repo = initRepo();
      git(repo, 'checkout', '-b', 'main');
      mkdirSync(join(repo, 'docs', 'sdd'), { recursive: true });
      writeFileSync(join(repo, 'docs', 'sdd', 'release.md'), '**Status**: draft\n', 'utf8');
      writeFileSync(join(repo, '.sdd-exempt'), 'e2e-test-exemption\n', 'utf8');

      const result = runNpxTsxSync(SDD_GATE_SCRIPT, [], { cwd: repo });
      assert.equal(result.status, 0);
      assert.match(result.stdout, /SDD-EXEMPT/);
    });
  });

  describe('RDD release gate', () => {
    it('responds with a GateValidation structure even without a receipt', (t) => {
      if (!gitAvailable) return t.skip('git not available');
      const repo = initRepo();
      const result = runNpxTsxSync(RDD_GATES_SCRIPT, ['validate', 'release', '--json'], {
        cwd: repo,
      });

      assert.notEqual(result.status, 0, 'release gate must fail without a receipt');
      const validation = extractJson<GateValidation>(result.stdout);
      assert.equal(validation.gate, 'release');
      assert.equal(validation.valid, false);
      assert.equal(validation.receiptId, null);
      assert.ok(Array.isArray(validation.errors));
      assert.ok(validation.errors.length > 0);
      assert.match(validation.errors[0], /No receipt found/);
      assert.equal(validation.currentSha.length, 40);
    });

    it('defines the 5 delivery gates in release order', (t) => {
      if (!gitAvailable) return t.skip('git not available');
      const repo = initRepo();
      const result = runNpxTsxSync(RDD_GATES_SCRIPT, ['status'], { cwd: repo });
      assert.equal(result.status, 0);

      const expected = RDD_GATE_ORDER.map((g) => g.toUpperCase());
      const positions = expected.map((g) => result.stdout.indexOf(g));
      for (let i = 0; i < expected.length; i++) {
        assert.ok(positions[i] !== -1, `gate ${expected[i]} missing from status output`);
      }
      for (let i = 1; i < positions.length; i++) {
        assert.ok(positions[i] > positions[i - 1], `gate order violated at ${expected[i]}`);
      }
    });

    it('every gate responds with its own GateValidation structure', (t) => {
      if (!gitAvailable) return t.skip('git not available');
      const repo = initRepo();
      for (const gate of RDD_GATE_ORDER) {
        const result = runNpxTsxSync(RDD_GATES_SCRIPT, ['validate', gate, '--json'], {
          cwd: repo,
        });
        assert.notEqual(result.status, 0, `gate ${gate} must fail without a receipt`);
        const validation = extractJson<GateValidation>(result.stdout);
        assert.equal(validation.gate, gate);
        assert.equal(validation.valid, false);
        assert.equal(validation.receiptId, null);
        assert.ok(validation.errors.length > 0);
      }
    });
  });
});
