/**
 * Session Autostart runs without errors.
 * Migrated from: tests/integration/session-autostart.integration.tests.ps1
 */
import { describe, it } from 'node:test';
import assert from 'node:assert';
import { existsSync, readFileSync } from 'fs';
import { resolve, join } from 'path';

const ROOT = resolve(import.meta.dirname, '..', '..');

describe('Session Autostart', () => {
  it('session-autostart config is valid JSON', () => {
    const configPath = join(ROOT, 'config', 'session-autostart.config.json');
    assert.ok(existsSync(configPath), 'Config file exists');
    
    const config = JSON.parse(readFileSync(configPath, 'utf-8'));
    assert.ok(config.pipeline, 'Config has pipeline section');
    assert.ok(Array.isArray(config.pipeline.steps), 'Pipeline has steps array');
    assert.ok(config.pipeline.steps.length > 0, 'Pipeline has at least one step');
    
    const bootstrap = config.pipeline.steps.find((s: any) => s.id === 'bootstrap-symlink');
    assert.ok(bootstrap, 'Bootstrap-symlink step exists');
    assert.ok(bootstrap.required !== false, 'Bootstrap step is required');
  });

  it('session-autostart module chain resolves', () => {
    // Verify entry module exists and points to core
    const entryPath = join(ROOT, 'src', 'session-autostart.ts');
    assert.ok(existsSync(entryPath), 'Entry module session-autostart.ts exists');
    
    const entry = readFileSync(entryPath, 'utf-8');
    assert.ok(entry.includes('./core/session-autostart'), 'Entry imports core module');

    // Verify core module exists
    const corePath = join(ROOT, 'src', 'core', 'session-autostart.ts');
    assert.ok(existsSync(corePath), 'Core module src/core/session-autostart.ts exists');
  });

  it('pipeline provides expected lazy steps', () => {
    const configPath = join(ROOT, 'config', 'session-autostart.config.json');
    const config = JSON.parse(readFileSync(configPath, 'utf-8'));
    
    const lazySteps = config.pipeline.steps.filter((s: any) => s.lazy === true);
    assert.ok(lazySteps.length >= 60, `Expected 60+ lazy steps, got ${lazySteps.length}`);
    
    // Verify critical lazy steps exist
    const criticalIds = ['maintenance-watchtower', 'predictive-governor', 'auto-norm-learner', 
                         'skill-evolution-engine', 'convergence-monitor', 'findings-ledger-init',
                         'auto-optimization', 'self-reflection'];
    for (const id of criticalIds) {
      const step = config.pipeline.steps.find((s: any) => s.id === id);
      assert.ok(step, `Critical lazy step '${id}' must exist in config`);
    }
  });
});
