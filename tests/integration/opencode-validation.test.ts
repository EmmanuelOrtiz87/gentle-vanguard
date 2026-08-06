import { describe, it, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'child_process';

const ROOT = join(import.meta.dirname, '..', '..');

describe('OpenCode validation workflow', () => {
  let tempDbDir: string;

  beforeEach(() => {
    tempDbDir = mkdtempSync(join(tmpdir(), 'gv-opencode-'));
  });

  afterEach(() => {
    rmSync(tempDbDir, { recursive: true, force: true });
  });

  it('runs validate-opencode-all.ts successfully against repo config', () => {
    const result = spawnSync('pnpm', ['exec', 'tsx', 'src/hooks/validate-opencode-all.ts'], {
      cwd: ROOT,
      env: { ...process.env, GENTLE_VANGUARD_DB_DIR: tempDbDir },
      encoding: 'utf-8',
      shell: true,
      timeout: 30000,
    });

    assert.equal(
      result.status,
      0,
      `Expected zero exit code, got ${result.status}
stdout: ${result.stdout}
stderr: ${result.stderr}`,
    );
  });

  it('runs opencode-validation-monitor.ts with no active alerts', () => {
    const result = spawnSync(
      'pnpm',
      ['exec', 'tsx', 'src/monitor/opencode-validation-monitor.ts'],
      {
        cwd: ROOT,
        env: { ...process.env, GENTLE_VANGUARD_DB_DIR: tempDbDir },
        encoding: 'utf-8',
        shell: true,
        timeout: 30000,
      },
    );

    assert.equal(
      result.status,
      0,
      `Expected zero exit code, got ${result.status}
stdout: ${result.stdout}
stderr: ${result.stderr}`,
    );
    assert.match(result.stdout ?? '', /No active OpenCode validation alerts\./);
  });
});
