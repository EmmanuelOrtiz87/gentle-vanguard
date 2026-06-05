import { execSync } from 'child_process';
import { join, dirname, resolve } from 'path';
import { fileURLToPath } from 'url';
import type { GlobalHealth, RepositoryHealth } from '../src/types/dashboard.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = resolve(__dirname, '../../..');

function execGit(args: string): string {
  try {
    return execSync(`git ${args}`, { cwd: ROOT, encoding: 'utf-8', timeout: 3000 }).trim();
  } catch {
    return '';
  }
}

function getRealRepoHealth(name: string): RepositoryHealth {
  const lastCommit = execGit('log -1 --format=%cI');
  const openPRs = 0;
  const contributors = execGit('shortlog -sn')
    ? execGit('shortlog -sn').split('\n').length
    : 0;

  return {
    name,
    status: 'healthy',
    lastCommit: lastCommit || new Date().toISOString(),
    openPRs,
    ciStatus: 'unknown',
    coverage: 0,
    contributors,
    updatedAt: new Date().toISOString(),
  };
}

export function getGlobalHealth(): GlobalHealth {
  const repo = getRealRepoHealth('gentle-vanguard');
  const repositories = [repo];

  return {
    repositories,
    overallStatus: 'healthy',
    totalRepos: 1,
    healthyRepos: 1,
    degradedRepos: 0,
    criticalRepos: 0,
    avgCoverage: 0,
    totalOpenPRs: repo.openPRs,
    lastUpdated: new Date().toISOString(),
  };
}
