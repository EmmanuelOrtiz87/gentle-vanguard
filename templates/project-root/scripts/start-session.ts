#!/usr/bin/env node

/**
 * start-session.ts — Session bootstrap for Gentle-Vanguard template projects
 *
 * Creates a session brief markdown file documenting context, objective, and working set.
 *
 * Usage:
 *   npx tsx templates/project-root/scripts/start-session.ts --task "Fix login bug"
 *   npx tsx templates/project-root/scripts/start-session.ts --task "Add auth" --force
 */

import { existsSync, mkdirSync, writeFileSync } from 'fs';
import { join, resolve, basename } from 'path';
import { execSync } from 'child_process';

const SCRIPT_DIR = resolve(__dirname);
const REPO_ROOT = resolve(join(SCRIPT_DIR, '..'));
const PROJECT_NAME = basename(REPO_ROOT);

function toSlug(value: string): string {
  return (
    value
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '') || 'task'
  );
}

function getTimestamp(): string {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  const hh = String(now.getHours()).padStart(2, '0');
  const mm = String(now.getMinutes()).padStart(2, '0');
  const ss = String(now.getSeconds()).padStart(2, '0');
  return `${y}-${m}-${d}-${hh}${mm}${ss}`;
}

function getDateFormatted(): string {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')} ${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}:${String(now.getSeconds()).padStart(2, '0')}`;
}

function getDateTag(): string {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
}

function getTimeTag(): string {
  const now = new Date();
  return `${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}${String(now.getSeconds()).padStart(2, '0')}`;
}

const args = process.argv.slice(2);
const taskName = args.includes('--task') ? args[args.indexOf('--task') + 1] || '' : '';
const force = args.includes('--force') || args.includes('-Force');

// Ensure directories
const sessionsDir = join(REPO_ROOT, 'docs', 'sessions');
const tasksDir = join(REPO_ROOT, 'docs', 'tasks');
if (!existsSync(sessionsDir)) mkdirSync(sessionsDir, { recursive: true });
if (!existsSync(tasksDir)) mkdirSync(tasksDir, { recursive: true });

// Git info
let branch = 'unknown';
let gitState = 'unknown';
try {
  branch = execSync('git rev-parse --abbrev-ref HEAD', { encoding: 'utf8', timeout: 5000 }).trim();
  const status = execSync('git status --short', { encoding: 'utf8', timeout: 5000 }).trim();
  gitState = status ? 'has uncommitted changes' : 'clean';
} catch {
  branch = 'unknown';
  gitState = 'unknown';
}

// Session file
const sessionFileName = `${getTimestamp()}-session-start.md`;
let sessionFile = join(sessionsDir, sessionFileName);

if (existsSync(sessionFile) && !force) {
  sessionFile = join(sessionsDir, `${getDateTag()}-session-start-${getTimeTag()}.md`);
}

// Task note
let taskNote = '- Task brief: create if the session scope is non-trivial';

if (taskName) {
  const taskFile = join(tasksDir, `${toSlug(taskName)}.md`);
  const taskContent = `# Task Brief: ${taskName}

## Goal

- Problem to solve:
- Desired outcome:

## Scope

- In scope:
- Out of scope:

## Key Files

- Primary implementation files:
- Validation files:
- Documentation files:

## Acceptance Criteria

- [ ] Behavior is implemented
- [ ] Focused validation passes
- [ ] Documentation updated if needed
`;
  writeFileSync(taskFile, taskContent, 'utf-8');
  taskNote = `- Task brief: ${taskFile}`;
}

const sessionContent = `# Session Start Brief

## Context

- Project: ${PROJECT_NAME}
- Date: ${getDateFormatted()}
- Branch: ${branch}
- Git state: ${gitState}

## Objective

- Primary goal for this session:
- Expected outcome at handoff:

## Working Set

- Primary files or directories:
- Related decisions or documents:
- Known blockers or assumptions:

## Acceptance Criteria

- [ ] Scope is clear and bounded
- [ ] Validation command is known before editing
- [ ] Documentation impact is identified
- [ ] Repository publication expectation is clear

## Notes

${taskNote}
`;

writeFileSync(sessionFile, sessionContent, 'utf-8');
console.log(`[OK] Session brief created: ${sessionFile}`);
