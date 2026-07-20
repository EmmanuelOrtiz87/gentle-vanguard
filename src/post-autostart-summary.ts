#!/usr/bin/env node
/**
 * Post-Autostart Summary — Generates a startup summary JSON with session,
 * git, and timezone info. Writes to reports/startup-summary.json.
 *
 * Migrated from: scripts/utilities/post-autostart-summary.ps1
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync } from 'fs';
import { join } from 'path';
import { execSync } from 'child_process';

interface Args {
  TimeZone?: string;
  PeakStart?: number;
  PeakEnd?: number;
  Region?: string;
}

function parseArgs(argv: string[]): Args {
  const args: Args = {};
  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '-TimeZone' && argv[i + 1]) args.TimeZone = argv[++i];
    else if (arg === '-PeakStart' && argv[i + 1]) args.PeakStart = Number(argv[++i]);
    else if (arg === '-PeakEnd' && argv[i + 1]) args.PeakEnd = Number(argv[++i]);
    else if (arg === '-Region' && argv[i + 1]) args.Region = argv[++i];
  }
  return args;
}

function resolveRoot(): string {
  if (process.env.GENTLE_VANGUARD_BASE_DIR) {
    const base = process.env.GENTLE_VANGUARD_BASE_DIR;
    if (existsSync(join(base, 'config', 'orchestrator.json'))) return base;
  }
  let dir = process.cwd();
  for (let i = 0; i < 10; i++) {
    if (existsSync(join(dir, 'config', 'orchestrator.json'))) return dir;
    const parent = join(dir, '..');
    if (parent === dir) break;
    dir = parent;
  }
  console.error('[SUMMARY] ERROR: Could not locate repository root.');
  process.exit(1);
}

function gitCmd(root: string, cmd: string): string | null {
  try {
    return execSync(`git -C "${root}" ${cmd}`, {
      encoding: 'utf-8',
      stdio: ['pipe', 'pipe', 'pipe'],
    }).trim();
  } catch {
    return null;
  }
}

function getLatestSessionId(root: string): string | null {
  const sessionDir = join(root, 'session');
  if (!existsSync(sessionDir)) return null;
  try {
    const files = readdirSync(sessionDir)
      .filter((f: string) => f.startsWith('session-') && f.endsWith('.json'))
      .sort()
      .reverse();
    if (files.length === 0) return null;
    const data = JSON.parse(readFileSync(join(sessionDir, files[0]), 'utf-8'));
    return data.sessionId ?? null;
  } catch {
    return null;
  }
}

function main() {
  const args = parseArgs(process.argv);
  const root = resolveRoot();
  const timestamp = new Date().toISOString();
  const sessionId = getLatestSessionId(root);
  const branch = gitCmd(root, 'rev-parse --abbrev-ref HEAD');
  const lastCommit = gitCmd(root, 'log -1 --format="%H"');

  const summary = {
    timestamp,
    sessionId,
    timezone: args.TimeZone ?? null,
    peakStart: args.PeakStart ?? null,
    peakEnd: args.PeakEnd ?? null,
    region: args.Region ?? null,
    workspace: {
      branch,
      lastCommit,
    },
  };

  const outDir = join(root, 'reports');
  if (!existsSync(outDir)) mkdirSync(outDir, { recursive: true });
  const outPath = join(outDir, 'startup-summary.json');
  writeFileSync(outPath, JSON.stringify(summary, null, 2) + '\n', 'utf-8');

  console.log(`[SUMMARY] Startup summary written to ${outPath}`);
  console.log(`  timestamp : ${timestamp}`);
  console.log(`  sessionId : ${sessionId}`);
  console.log(`  branch    : ${branch}`);
  console.log(`  lastCommit: ${lastCommit}`);
  console.log(`  timezone  : ${args.TimeZone}`);
  console.log(`  peakStart : ${args.PeakStart}`);
  console.log(`  peakEnd   : ${args.PeakEnd}`);
  console.log(`  region    : ${args.Region}`);

  process.exit(0);
}

main();
