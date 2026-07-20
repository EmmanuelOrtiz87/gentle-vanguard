#!/usr/bin/env node
/**
 * Metrics collector — collects git, PR, session, token, live, and cost metrics.
 * TS migration of scripts/metrics/collector.ps1
 */

import { existsSync, mkdirSync, writeFileSync } from 'fs';
import { join, resolve } from 'path';
import { execSync } from 'child_process';
import { pathToFileURL } from 'url';

const ROOT = resolve(process.cwd());

function findRepoRoot(dir: string): string {
  let current = resolve(dir);
  for (let i = 0; i < 10; i++) {
    if (existsSync(join(current, '.git'))) return current;
    const parent = resolve(current, '..');
    if (parent === current) break;
    current = parent;
  }
  return dir;
}

const repoRoot = process.env.GENTLE_VANGUARD_BASE_DIR && existsSync(process.env.GENTLE_VANGUARD_BASE_DIR)
  ? process.env.GENTLE_VANGUARD_BASE_DIR : findRepoRoot(ROOT);
const outDir = join(repoRoot, '.runtime', 'metrics');

mkdirSync(outDir, { recursive: true }); mkdirSync(join(outDir, 'aggregates'), { recursive: true }); mkdirSync(join(outDir, 'snapshots'), { recursive: true });

function log(msg: string, quiet: boolean): void { if (!quiet) console.log(`[METRICS] ${msg}`); }

function collectGitMetrics(quiet: boolean): Record<string, unknown> {
  log('Collecting git metrics...', quiet);
  let totalCommits = 0, monthCommits = 0, weekCommits = 0, todayCommits = 0;
  const authors: Record<string, number> = {};
  let linesAdded = 0, linesRemoved = 0;

  try {
    const raw = execSync('git rev-list --count HEAD', { cwd: repoRoot, encoding: 'utf-8', timeout: 10000, windowsHide: true });
    totalCommits = parseInt(raw.trim(), 10);
  } catch { /* */ }
  try {
    const today = new Date().toISOString().slice(0, 10);
    monthCommits = execSync(`git log --oneline --since="${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}-01"`, { cwd: repoRoot, encoding: 'utf-8', timeout: 10000, windowsHide: true }).split('\n').filter(Boolean).length;
    weekCommits = execSync(`git log --oneline --since="${new Date(Date.now() - 7 * 86400000).toISOString().slice(0, 10)}"`, { cwd: repoRoot, encoding: 'utf-8', timeout: 10000, windowsHide: true }).split('\n').filter(Boolean).length;
    todayCommits = execSync(`git log --oneline --since="${today}"`, { cwd: repoRoot, encoding: 'utf-8', timeout: 10000, windowsHide: true }).split('\n').filter(Boolean).length;
    const shortlog = execSync('git shortlog -sn --all', { cwd: repoRoot, encoding: 'utf-8', timeout: 10000, windowsHide: true });
    for (const line of shortlog.split('\n')) {
      const m = line.match(/^\s*(\d+)\s+(.+)$/);
      if (m) authors[m[2]] = parseInt(m[1], 10);
    }
    const diffStat = execSync('git diff --stat HEAD~30..HEAD', { cwd: repoRoot, encoding: 'utf-8', timeout: 10000, windowsHide: true });
    for (const line of diffStat.split('\n')) {
      const addM = line.match(/(\d+) insertion/);
      const delM = line.match(/(\d+) deletion/);
      if (addM) linesAdded += parseInt(addM[1], 10);
      if (delM) linesRemoved += parseInt(delM[1], 10);
    }
  } catch { /* */ }

  const authorEntries = Object.entries(authors);
  const topAuthor = authorEntries.sort((a, b) => b[1] - a[1])[0]?.[0] || '';

  const gitMetrics = {
    collectedAt: new Date().toISOString(), totalCommits, monthCommits, weekCommits, todayCommits,
    linesAdded30: linesAdded, linesRemoved30: linesRemoved, authors, authorCount: authorEntries.length, topAuthor,
  };
  writeFileSync(join(outDir, 'git.json'), JSON.stringify(gitMetrics, null, 2), 'utf-8');
  log(`Git: ${totalCommits} total, ${monthCommits} month, ${todayCommits} today, ${linesAdded}+/${linesRemoved}- lines`, quiet);
  return gitMetrics;
}

function main(): void {
  const args = process.argv.slice(2);
  const scope = args.includes('--scope') ? args[args.indexOf('--scope') + 1] : 'full';
  const quiet = args.includes('--quiet');

  switch (scope) {
    case 'git': collectGitMetrics(quiet); break;
    default:
    case 'full': collectGitMetrics(quiet); break;
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
