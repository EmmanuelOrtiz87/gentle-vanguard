import { describe, it, expect } from 'vitest';
import { readFileSync, existsSync } from 'fs';
import { join } from 'path';

const ROOT = join(import.meta.dirname, '..', '..');
const CONFIG_PATH = join(ROOT, 'config', 'session-autostart.config.json');

describe('session-autostart pipeline', () => {
  const config = JSON.parse(readFileSync(CONFIG_PATH, 'utf-8'));

  it('has valid structure', () => {
    expect(config).toHaveProperty('pipeline');
    expect(config.pipeline).toHaveProperty('steps');
    expect(Array.isArray(config.pipeline.steps)).toBe(true);
  });

  it('has onStepFailure policy', () => {
    expect(config.pipeline.onStepFailure).toBe('continue');
  });

  it('every step has required fields', () => {
    for (const step of config.pipeline.steps) {
      expect(step).toHaveProperty('id');
      expect(step).toHaveProperty('script');
      expect(step).toHaveProperty('enabled');
      expect(typeof step.id).toBe('string');
      expect(step.id.length).toBeGreaterThan(0);
    }
  });

  it('no duplicate step IDs', () => {
    const ids = config.pipeline.steps.map((s: any) => s.id);
    const unique = new Set(ids);
    expect(unique.size).toBe(ids.length);
  });

  it('required steps are marked', () => {
    const required = config.pipeline.steps.filter((s: any) => s.required === true);
    expect(required.length).toBeGreaterThan(0);
    for (const step of required) {
      expect(step.id).toBeTruthy();
    }
  });

  it('lazy steps exist for background execution', () => {
    const lazy = config.pipeline.steps.filter((s: any) => s.lazy === true);
    expect(lazy.length).toBeGreaterThan(10);
  });

  it('step scripts reference existing files', () => {
    const missing: string[] = [];
    for (const step of config.pipeline.steps) {
      // Skip disabled steps — they may reference scripts that don't exist yet
      if (step.enabled === false) continue;
      const scriptPath = join(ROOT, step.script);
      if (!existsSync(scriptPath)) {
        missing.push(`${step.id}: ${step.script}`);
      }
    }
    if (missing.length > 0) {
      console.warn('Missing scripts:', missing);
    }
    expect(missing.length).toBe(0);
  });
});
