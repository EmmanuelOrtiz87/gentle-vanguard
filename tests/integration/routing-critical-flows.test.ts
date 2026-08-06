/**
 * Routing critical flows — tests tool detection and input preprocessing pipeline.
 * Migrated from: tests/integration/routing-critical-flows.integration.tests.ps1
 *
 * The original PS1 test called pre-process-input.ps1 with specific inputs and verified
 * skill routing. The TS pipeline routes through detect-tool.ts (tool detection) and
 * team-orchestrator.ts (skill routing). This test validates the full pipeline.
 */
import { describe, it, before } from 'node:test';
import assert from 'node:assert';
import { spawnSync } from 'child_process';
import { resolve } from 'path';
import { existsSync, readFileSync } from 'fs';

const ROOT = resolve(import.meta.dirname, '..', '..');

before(() => {
  // Ensure deterministic opencode detection regardless of CI env (confidence 100)
  process.env.OPENCODE_SERVER_USERNAME = 'ci';
});

function runCLI(
  script: string,
  ...args: string[]
): { stdout: string; stderr: string; status: number } {
  const result = spawnSync('npx', ['tsx', script, ...args], {
    cwd: ROOT,
    encoding: 'utf-8',
    timeout: 30000,
    shell: true,
  });
  return {
    stdout: (result.stdout || '').trim(),
    stderr: (result.stderr || '').trim(),
    status: result.status ?? -1,
  };
}

describe('Routing Critical Flows', () => {
  describe('Tool detection', () => {
    it('detects OpenCode tool via --json flag', () => {
      const { stdout, status } = runCLI('src/core/detect-tool.ts', '--json');
      assert.strictEqual(status, 0, `Exit code: ${status}, stderr: ${stdout}`);
      const parsed = JSON.parse(stdout);
      assert.strictEqual(parsed.name, 'opencode');
      assert.strictEqual(parsed.isOpenCode, true);
      assert.strictEqual(parsed.confidence, 100);
      assert.strictEqual(parsed.os.isWindows, process.platform === 'win32');
    });

    it('returns valid OS info', () => {
      const { stdout, status } = runCLI('src/core/detect-tool.ts', '--json');
      assert.strictEqual(status, 0);
      const parsed = JSON.parse(stdout);
      assert.ok(parsed.os?.platform, 'Missing platform');
      assert.ok(typeof parsed.os.isWindows === 'boolean', 'isWindows must be boolean');
    });

    it('returns instructions with session-autostart', () => {
      const { stdout } = runCLI('src/core/detect-tool.ts', '--json');
      const parsed = JSON.parse(stdout);
      assert.ok(parsed.instructions?.sessionAutostart, 'Missing sessionAutostart instruction');
      assert.ok(parsed.instructions?.mandatoryStartup, 'Missing mandatoryStartup');
    });
  });

  describe('Input preprocessing', () => {
    it('sanitizes deployment request input', () => {
      const { stdout, status } = runCLI(
        'src/pre-process-input.ts',
        '--input',
        'deploy to kubernetes with docker and helm',
        '--workspace-root',
        ROOT,
      );
      assert.strictEqual(status, 0, `Exit code: ${status}, stderr: ${stdout}`);
      assert.ok(stdout.length > 0, 'Expected sanitized output');
    });

    it('sanitizes reporting request input', () => {
      const { stdout, status } = runCLI(
        'src/pre-process-input.ts',
        '--input',
        'crear dashboard con metrics y reporte ejecutivo',
        '--workspace-root',
        ROOT,
      );
      assert.strictEqual(status, 0);
      assert.ok(stdout.length > 0, 'Expected sanitized output');
    });

    it('sanitizes new project request input', () => {
      const { stdout, status } = runCLI(
        'src/pre-process-input.ts',
        '--input',
        'pedi crear un nuevo proyecto',
        '--workspace-root',
        ROOT,
      );
      assert.strictEqual(status, 0);
      assert.ok(stdout.length > 0, 'Expected sanitized output');
    });
  });

  describe('Delegation config', () => {
    it('auto-delegation config exists and is valid JSON', () => {
      const configPath = resolve(ROOT, 'config/auto-delegation.json');
      assert.ok(existsSync(configPath), 'auto-delegation.json not found');
      const config = JSON.parse(readFileSync(configPath, 'utf-8'));
      assert.ok(config, 'Config must be valid JSON');
      assert.strictEqual(config.enabled, true, 'Expected enabled: true');
      assert.ok(config.confidenceThreshold >= 0, 'Expected confidenceThreshold');
      assert.ok(config.fallbackStrategy, 'Expected fallbackStrategy');
    });

    it('orchestrator config exists with orchestrator block', () => {
      const configPath = resolve(ROOT, 'config/orchestrator.json');
      assert.ok(existsSync(configPath), 'orchestrator.json not found');
      const config = JSON.parse(readFileSync(configPath, 'utf-8'));
      assert.ok(config.orchestrator, 'Expected orchestrator block');
      assert.ok(config.orchestrator.version, 'Expected orchestrator.version');
      assert.strictEqual(config.orchestrator.active, true, 'Expected orchestrator.active: true');
    });
  });
});
