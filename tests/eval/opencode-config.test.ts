import { describe, it, expect } from 'vitest';
import { readFileSync, existsSync } from 'fs';
import { join } from 'path';

const ROOT = join(import.meta.dirname, '..', '..');

describe('opencode agent files eval', () => {
  const agentsDir = join(ROOT, '.opencode', 'agents');

  const expectedAgents = [
    'orchestrator',
    'sdd-explore',
    'sdd-design',
    'sdd-apply',
    'sdd-verify',
    'doc-agent',
    'ops-agent',
    'gov-agent',
    'session-agent',
    'premortem-agent',
  ];

  it('agents directory exists', () => {
    expect(existsSync(agentsDir)).toBe(true);
  });

  for (const agent of expectedAgents) {
    it(`agent file exists: ${agent}.md`, () => {
      expect(existsSync(join(agentsDir, `${agent}.md`))).toBe(true);
    });
  }

  for (const agent of expectedAgents) {
    it(`agent ${agent} has valid frontmatter`, () => {
      const content = readFileSync(join(agentsDir, `${agent}.md`), 'utf-8');
      expect(content.startsWith('---')).toBe(true);
      const endIdx = content.indexOf('---', 3);
      expect(endIdx).toBeGreaterThan(3);
      const frontmatter = content.substring(4, endIdx);
      expect(frontmatter).toContain('description:');
      expect(frontmatter).toContain('mode:');
    });
  }
});

describe('opencode commands eval', () => {
  const commandsDir = join(ROOT, '.opencode', 'commands');

  const expectedCommands = ['health', 'release', 'deploy', 'review', 'status', 'test', 'cost'];

  it('commands directory exists', () => {
    expect(existsSync(commandsDir)).toBe(true);
  });

  for (const cmd of expectedCommands) {
    it(`command file exists: ${cmd}.md`, () => {
      expect(existsSync(join(commandsDir, `${cmd}.md`))).toBe(true);
    });
  }
});

describe('opencode.json enhanced config eval', () => {
  const config = JSON.parse(readFileSync(join(ROOT, 'opencode.json'), 'utf-8'));

  it('has $schema declaration', () => {
    expect(config.$schema).toBe('https://opencode.ai/config.json');
  });

  it('has compaction with tail_turns', () => {
    expect(config.compaction.tail_turns).toBe(15);
  });

  it('has compaction with keep_recent', () => {
    expect(config.compaction.keep_recent).toBe(5);
  });

  it('has references with docs', () => {
    expect(config.references.docs.path).toBe('docs');
  });

  it('has references with config', () => {
    expect(config.references.config.path).toBe('config');
  });

  it('has references with src', () => {
    expect(config.references.src.path).toBe('src');
  });

  it('has 10 agents defined', () => {
    const agentCount = Object.keys(config.agent).length;
    expect(agentCount).toBe(10);
  });

  it('has 2 MCP servers', () => {
    const mcpCount = Object.keys(config.mcp).length;
    expect(mcpCount).toBe(2);
  });

  it('has permission model with doom_loop deny', () => {
    expect(config.permission.doom_loop).toBe('deny');
  });

  it('has watcher ignore patterns', () => {
    expect(config.watcher.ignore.length).toBeGreaterThan(5);
  });
});
