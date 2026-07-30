import { describe, it, expect } from 'vitest';
import { existsSync, readFileSync } from 'fs';
import { join } from 'path';
import { execSync } from 'child_process';

const ROOT = join(import.meta.dirname, '..', '..');

describe('health-check eval', () => {
  it('health check script exists', () => {
    expect(existsSync(join(ROOT, 'src', 'core', 'health-check.ts'))).toBe(true);
  });

  it('watchtower script exists', () => {
    expect(existsSync(join(ROOT, 'src', 'core', 'maintenance-watchtower.ts'))).toBe(true);
  });

  it('session-autostart script exists', () => {
    expect(existsSync(join(ROOT, 'src', 'session-autostart.ts'))).toBe(true);
  });

  it('typecheck passes with 0 errors', () => {
    execSync('npx tsc --noEmit', {
      cwd: ROOT,
      encoding: 'utf-8',
      timeout: 60000,
    });
  }, 90000);

  it('MCP skill-server registers 5 tools', () => {
    const skillServer = join(ROOT, 'scripts', 'mcp', 'skill-server.ts');
    expect(existsSync(skillServer)).toBe(true);
    const content = readFileSync(skillServer, 'utf-8');
    const toolMatches = content.match(/server\.tool\(/g);
    expect(toolMatches).not.toBeNull();
    expect(toolMatches!.length).toBe(5);
  });
});
