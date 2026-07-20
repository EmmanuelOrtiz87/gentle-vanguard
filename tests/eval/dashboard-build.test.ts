import { describe, it, expect } from 'vitest';
import { readFileSync, existsSync } from 'fs';
import { join } from 'path';
import { execSync } from 'child_process';

const ROOT = join(import.meta.dirname, '..', '..');
const DASHBOARD_ROOT = join(ROOT, 'apps', 'web-dashboard');

describe('dashboard build eval', () => {
  it('dashboard package.json exists', () => {
    expect(existsSync(join(DASHBOARD_ROOT, 'package.json'))).toBe(true);
  });

  it('dashboard has required runtime dependencies', () => {
    const pkg = JSON.parse(readFileSync(join(DASHBOARD_ROOT, 'package.json'), 'utf-8'));
    expect(pkg.dependencies).toHaveProperty('react');
    expect(pkg.dependencies).toHaveProperty('recharts');
    expect(pkg.dependencies).toHaveProperty('ws');
  });

  it('dashboard has required dev dependencies', () => {
    const pkg = JSON.parse(readFileSync(join(DASHBOARD_ROOT, 'package.json'), 'utf-8'));
    expect(pkg.devDependencies).toHaveProperty('vite');
    expect(pkg.devDependencies).toHaveProperty('typescript');
    expect(pkg.devDependencies).toHaveProperty('@vitejs/plugin-react');
  });

  it('vite config exists', () => {
    expect(existsSync(join(DASHBOARD_ROOT, 'vite.config.ts'))).toBe(true);
  });

  it('tsconfig exists', () => {
    expect(existsSync(join(DASHBOARD_ROOT, 'tsconfig.json'))).toBe(true);
  });

  it('dashboard builds successfully', () => {
    execSync('npm run build', {
      cwd: DASHBOARD_ROOT,
      encoding: 'utf-8',
      timeout: 120000,
    });
  }, 150000);
});
