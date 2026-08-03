import { describe, it, expect } from 'vitest';
import { readFileSync, existsSync } from 'fs';
import { join } from 'path';

const ROOT = join(import.meta.dirname, '..', '..');

const REQUIRED_CONFIGS = [
  'opencode.json',
  'config/session-autostart.config.json',
  'config/model-router.json',
  'config/auto-delegation.json',
  'config/security-policy.json',
  'config/rbac-policy.json',
  'config/mcp-registry.json',
  'config/plugins.json',
  'config/resilience-config.json',
  'config/circuit-breaker.json',
];

const REQUIRED_TOOL_CONFIGS = [
  'config/tool-opencode.json',
  'config/tool-cursor.json',
  'config/tool-cline.json',
  'config/tool-codex.json',
  'config/tool-windsurf.json',
  'config/tool-vscode.json',
  'config/tool-claude-code.json',
];

describe('config validation eval', () => {
  for (const cfg of REQUIRED_CONFIGS) {
    it(`config file exists: ${cfg}`, () => {
      expect(existsSync(join(ROOT, cfg))).toBe(true);
    });
  }

  for (const cfg of REQUIRED_TOOL_CONFIGS) {
    it(`tool config exists: ${cfg}`, () => {
      expect(existsSync(join(ROOT, cfg))).toBe(true);
    });
  }

  it('opencode.json has $schema', () => {
    const config = JSON.parse(readFileSync(join(ROOT, 'opencode.json'), 'utf-8'));
    expect(config.$schema).toBe('https://opencode.ai/config.json');
  });

  it('opencode.json has default_agent', () => {
    const config = JSON.parse(readFileSync(join(ROOT, 'opencode.json'), 'utf-8'));
    expect(config.default_agent).toBe('orchestrator');
  });

  it('opencode.json has compaction settings', () => {
    const config = JSON.parse(readFileSync(join(ROOT, 'opencode.json'), 'utf-8'));
    expect(config.compaction).toBeDefined();
    expect(config.compaction.auto).toBe(true);
  });

  it('opencode.json has references', () => {
    const config = JSON.parse(readFileSync(join(ROOT, 'opencode.json'), 'utf-8'));
    expect(config.references).toBeDefined();
    expect(typeof config.references).toBe('object');
  });

  it('model-router.json has agent bindings', () => {
    const router = JSON.parse(readFileSync(join(ROOT, 'config', 'model-router.json'), 'utf-8'));
    expect(router.agentBindings).toBeDefined();
    expect(Object.keys(router.agentBindings).length).toBeGreaterThan(5);
  });

  it('all JSON configs are valid JSON', () => {
    const configs = [...REQUIRED_CONFIGS, ...REQUIRED_TOOL_CONFIGS];
    const invalid: string[] = [];
    for (const cfg of configs) {
      try {
        JSON.parse(readFileSync(join(ROOT, cfg), 'utf-8'));
      } catch {
        invalid.push(cfg);
      }
    }
    expect(invalid).toEqual([]);
  });
});
