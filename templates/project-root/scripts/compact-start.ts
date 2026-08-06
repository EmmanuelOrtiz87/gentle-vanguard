#!/usr/bin/env node

/**
 * compact-start.ts — Generates a compact AI prompt for starting fresh threads
 *
 * Calls context-pack.ts to gather state, then produces a compact prompt
 * that can be copied to clipboard for starting a new AI assistant thread
 * while preserving context.
 *
 * Usage:
 *   npx tsx templates/project-root/scripts/compact-start.ts
 *   npx tsx templates/project-root/scripts/compact-start.ts --objective "Fix login bug"
 *   npx tsx templates/project-root/scripts/compact-start.ts --no-clipboard
 */

import { existsSync, mkdirSync, appendFileSync, writeFileSync } from 'fs';
import { join, resolve, basename } from 'path';
import { execSync } from 'child_process';
import { createHash } from 'crypto';

const SCRIPT_DIR = resolve(__dirname);
const REPO_ROOT = resolve(join(SCRIPT_DIR, '..'));

const args = process.argv.slice(2);
const objective = args.includes('--objective')
  ? args[args.indexOf('--objective') + 1] || ''
  : args.includes('-Objective')
    ? args[args.indexOf('-Objective') + 1] || ''
    : '';

const noClipboard = args.includes('--no-clipboard') || args.includes('-NoClipboard');

function writeMetric(
  event: string,
  objective: string,
  promptChars: number,
  outputFile: string,
): void {
  const metricsDir = join(REPO_ROOT, 'docs', 'sessions', 'metrics');
  if (!existsSync(metricsDir)) mkdirSync(metricsDir, { recursive: true });

  const metricsFile = join(metricsDir, 'context-usage.csv');
  if (!existsSync(metricsFile)) {
    const header =
      'timestamp,event,repository,branch,objective_chars,changed_count,prompt_chars,output_file\n';
    writeFileSync(metricsFile, header, 'utf-8');
  }

  let branchName = '(unknown)';
  try {
    branchName = execSync('git rev-parse --abbrev-ref HEAD', {
      encoding: 'utf8',
      timeout: 5000,
    }).trim();
  } catch {}

  const line =
    [
      new Date().toISOString(),
      event,
      basename(REPO_ROOT),
      branchName,
      objective.length,
      0,
      promptChars,
      outputFile.replace(/,/g, ';'),
    ].join(',') + '\n';

  appendFileSync(metricsFile, line, 'utf-8');
}

// Call context-pack to get the context file
const contextPackScript = join(SCRIPT_DIR, 'context-pack.ts');
if (!existsSync(contextPackScript)) {
  console.error(`[ERROR] Context pack script not found: ${contextPackScript}`);
  process.exit(1);
}

let contextPath: string | null = null;
try {
  const contextRaw = execSync(
    `npx tsx "${contextPackScript}"${objective ? ` --objective "${objective}"` : ''} --passthru`,
    { encoding: 'utf8', timeout: 30000, cwd: REPO_ROOT },
  ).trim();

  // Extract the last line that looks like a file path
  const lines = contextRaw.split('\n').filter((l) => l.trim());
  for (const line of lines.reverse()) {
    const trimmed = line.trim();
    if (
      trimmed.endsWith('-context-pack.md') &&
      (trimmed.includes(':\\\\') ||
        trimmed.includes(':\\') ||
        trimmed.startsWith('/') ||
        trimmed.startsWith('\\\\'))
    ) {
      contextPath = trimmed;
      break;
    }
  }

  // Fallback: find the latest context-pack file
  if (!contextPath) {
    const sessionsDir = join(REPO_ROOT, 'docs', 'sessions');
    if (existsSync(sessionsDir)) {
      const { readdirSync } = require('fs');
      const files = readdirSync(sessionsDir)
        .filter((f) => f.endsWith('-context-pack.md'))
        .sort()
        .reverse();
      if (files.length > 0) {
        contextPath = join(sessionsDir, files[0]);
      }
    }
  }
} catch (e) {
  console.error(`[ERROR] Failed to run context-pack: ${(e as Error).message}`);
  process.exit(1);
}

if (!contextPath) {
  console.error('[ERROR] Unable to resolve context-pack path.');
  process.exit(1);
}

const objectiveLine = objective || 'continue current objective';

const prompt = `Use this context file as source of truth:
${contextPath}

Immediate request:
Continue objective: "${objectiveLine}".
Keep only the last 5-10 chat messages active.
Avoid repeating long instructions unless they changed.
Apply minimal required changes and validate outcomes.
`;

if (!noClipboard) {
  try {
    // Use a child process to pipe to clip
    execSync(`echo ${JSON.stringify(prompt)} | clip`, {
      stdio: 'pipe',
      timeout: 5000,
      shell: true,
    });
    console.log('[OK] Compact prompt copied to clipboard.');
  } catch {
    console.log('[INFO] Clipboard copy not available. Prompt shown below.');
  }
}

console.log('');
console.log('--- Compact Prompt ---');
console.log(prompt);
console.log('----------------------');

writeMetric('compact-start', objectiveLine, prompt.length, contextPath);
