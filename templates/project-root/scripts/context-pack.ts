#!/usr/bin/env node

/**
 * context-pack.ts — Generates a context pack markdown file for AI session continuity
 *
 * Captures current git state, changed files, recent commits, and the session objective
 * into a structured markdown file for starting fresh AI threads while preserving context.
 *
 * Usage:
 *   npx tsx templates/project-root/scripts/context-pack.ts
 *   npx tsx templates/project-root/scripts/context-pack.ts --objective "Fix login bug"
 *   npx tsx templates/project-root/scripts/context-pack.ts --max-commits 5 --output ./ctx.md
 */

import { existsSync, mkdirSync, appendFileSync, writeFileSync } from 'fs';
import { join, resolve, basename } from 'path';
import { execSync } from 'child_process';

const REPO_ROOT = resolve(join(__dirname, '..'));

function getTimestamp(): string {
  return new Date().toISOString().replace('T', ' ').replace(/\.\d+Z$/, '');
}

function getDateTag(): string {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  const hh = String(now.getHours()).padStart(2, '0');
  const mm = String(now.getMinutes()).padStart(2, '0');
  const ss = String(now.getSeconds()).padStart(2, '0');
  return `${y}-${m}-${d}-${hh}${mm}${ss}`;
}

function writeMetric(event: string, objective: string, changedCount: number, promptChars: number, outputFile: string): void {
  const metricsDir = join(REPO_ROOT, 'docs', 'sessions', 'metrics');
  if (!existsSync(metricsDir)) mkdirSync(metricsDir, { recursive: true });

  const metricsFile = join(metricsDir, 'context-usage.csv');
  if (!existsSync(metricsFile)) {
    writeFileSync(metricsFile, 'timestamp,event,repository,branch,objective_chars,changed_count,prompt_chars,output_file\n', 'utf-8');
  }

  let branchName = '(unknown)';
  try {
    branchName = execSync('git rev-parse --abbrev-ref HEAD', { encoding: 'utf8', timeout: 5000 }).trim();
  } catch {}

  const line = [
    new Date().toISOString(),
    event,
    basename(REPO_ROOT),
    branchName,
    objective.length,
    changedCount,
    promptChars,
    outputFile.replace(/,/g, ';'),
  ].join(',') + '\n';

  appendFileSync(metricsFile, line, 'utf-8');
}

function getChangedFiles(limit: number): string[] {
  try {
    const lines = execSync('git status --porcelain', { encoding: 'utf8', timeout: 5000 })
      .split('\n')
      .filter(l => l.trim().length >= 4)
      .slice(0, limit);

    return lines.map(line => {
      const status = line.substring(0, 2).trim();
      const path = line.substring(3).trim();
      return `- [${status}] ${path}`;
    });
  } catch {
    return [];
  }
}

function getRecentCommits(limit: number): string[] {
  try {
    const lines = execSync(`git log --oneline -n ${limit}`, { encoding: 'utf8', timeout: 5000 })
      .split('\n')
      .filter(l => l.trim());
    return lines.map(l => `- ${l.trim()}`);
  } catch {
    return ['- none'];
  }
}

// Parse args
const args = process.argv.slice(2);
const objective = args.includes('--objective')
  ? args[args.indexOf('--objective') + 1] || ''
  : args.includes('-Objective')
    ? args[args.indexOf('-Objective') + 1] || ''
    : '';

const maxChangedFiles = parseInt(
  args.includes('--max-files') ? args[args.indexOf('--max-files') + 1] || '12' : '12', 10
);

const maxCommits = parseInt(
  args.includes('--max-commits') ? args[args.indexOf('--max-commits') + 1] || '8' : '8', 10
);

const outputPath = args.includes('--output')
  ? args[args.indexOf('--output') + 1] || ''
  : args.includes('-OutputPath')
    ? args[args.indexOf('-OutputPath') + 1] || ''
    : '';

const passThru = args.includes('--passthru') || args.includes('-PassThru');

let branch = '(unknown)';
try {
  branch = execSync('git rev-parse --abbrev-ref HEAD', { encoding: 'utf8', timeout: 5000 }).trim();
} catch {}

const changedFiles = getChangedFiles(maxChangedFiles);
const changedSection = changedFiles.length > 0 ? changedFiles.join('\n') : '- clean working tree';

const recentCommits = getRecentCommits(maxCommits);
const commitSection = recentCommits.join('\n');

const timestamp = getTimestamp();
const dateTag = getDateTag();

const sessionsDir = join(REPO_ROOT, 'docs', 'sessions');
if (!existsSync(sessionsDir)) mkdirSync(sessionsDir, { recursive: true });

const resolvedOutputPath = outputPath || join(sessionsDir, `${dateTag}-context-pack.md`);

const objectiveLine = objective || '[define objective in one sentence]';

const content = `# Context Pack

Generated: ${timestamp}
Repository: ${basename(REPO_ROOT)}
Branch: ${branch}

## Objective
${objectiveLine}

## Current State
${changedSection}

## Recent Commits
${commitSection}

## Continue Prompt (Compact)
Use this context and continue the same objective.

Constraints:
- Keep only the last 5-10 chat messages in active context.
- Use this context pack as source of truth for previous state.
- Avoid repeating long instructions unless they changed.
- Prefer short prompts and explicit acceptance criteria.

Request template:
Continue objective: "${objectiveLine}".
Apply only minimal required changes.
Validate changes and report concise results.

## Daily Token Control
1. Run \`npx tsx templates/project-root/scripts/context-pack.ts --objective "<objective>"\` before starting a new thread.
2. Start a fresh chat and paste only this file plus the immediate request.
3. Regenerate a new context pack after major milestones.
`;

writeFileSync(resolvedOutputPath, content, 'utf-8');
console.log(`[OK] Context pack generated: ${resolvedOutputPath}`);

writeMetric('context-pack', objectiveLine, changedFiles.length, content.length, resolvedOutputPath);

if (passThru) {
  console.log(resolvedOutputPath);
}
