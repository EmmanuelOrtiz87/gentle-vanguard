#!/usr/bin/env node
/**
 * Staged Review — Review only the files in the Git staging area.
 *
 * Freezes the complete Git index at review time, excluding worktree
 * untracked/unstaged content. Issues receipt bound to staged snapshot.
 *
 * Usage:
 *   npx tsx scripts/utilities/ops/REVIEW/staged-review.ts start
 *   npx tsx scripts/utilities/ops/REVIEW/staged-review.ts status
 *   npx tsx scripts/utilities/ops/REVIEW/staged-review.ts validate
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { join, resolve } from 'path';
import { pathToFileURL } from 'url';
import { createHash } from 'crypto';
import { execSync } from 'child_process';

// ─── Types ─────────────────────────────────────────────────────────────────────

interface StagedReviewSession {
  id: string;
  startedAt: string;
  stagedSnapshot: {
    sha: string;
    files: string[];
    contentHash: string;
  };
  status: 'active' | 'completed' | 'cancelled';
  completedAt?: string;
  receiptId?: string;
}

interface StagedFile {
  path: string;
  status: 'added' | 'modified' | 'deleted' | 'renamed';
  diff: string;
}

// ─── Config ───────────────────────────────────────────────────────────────────

const ROOT = resolve(process.cwd());
const REVIEW_DIR = join(ROOT, '.session', 'staged-reviews');
const SESSION_FILE = join(REVIEW_DIR, 'current-session.json');

// ─── Logger ───────────────────────────────────────────────────────────────────

function log(message: string, level: 'INFO' | 'WARN' | 'ERROR' | 'SUCCESS' = 'INFO'): void {
  const timestamp = new Date().toISOString().replace('T', ' ').slice(0, 19);
  const colors: Record<string, string> = {
    INFO: '\x1b[36m',
    WARN: '\x1b[33m',
    ERROR: '\x1b[31m',
    SUCCESS: '\x1b[32m',
  };
  console.log(`${colors[level]}[${timestamp}] [STAGED-REVIEW] [${level}] ${message}\x1b[0m`);
}

// ─── Git Operations ───────────────────────────────────────────────────────────

function getStagedFiles(): StagedFile[] {
  try {
    // Get staged files with status
    const statusOutput = execSync('git diff --cached --name-status', {
      encoding: 'utf-8',
      cwd: ROOT,
    });
    const lines = statusOutput.split('\n').filter((l) => l.trim());

    const files: StagedFile[] = [];

    for (const line of lines) {
      const [statusChar, ...pathParts] = line.split('\t');
      const path = pathParts.join('\t');

      let status: StagedFile['status'] = 'modified';
      if (statusChar === 'A') status = 'added';
      else if (statusChar === 'M') status = 'modified';
      else if (statusChar === 'D') status = 'deleted';
      else if (statusChar === 'R') status = 'renamed';

      // Get diff for this file
      let diff = '';
      try {
        diff = execSync(`git diff --cached -- "${path}"`, { encoding: 'utf-8', cwd: ROOT });
      } catch {
        // May fail for new files
      }

      files.push({ path, status, diff });
    }

    return files;
  } catch (err) {
    throw new Error(
      `Failed to get staged files: ${err instanceof Error ? err.message : String(err)}`,
    );
  }
}

function getCurrentSHA(): string {
  return execSync('git rev-parse HEAD', { encoding: 'utf-8', cwd: ROOT }).trim();
}

function computeSnapshotHash(files: StagedFile[]): string {
  const hash = createHash('sha256');
  const sorted = [...files].sort((a, b) => a.path.localeCompare(b.path));

  for (const file of sorted) {
    hash.update(file.path);
    hash.update(file.status);
    hash.update(file.diff);
  }

  return hash.digest('hex').slice(0, 16);
}

function hasUnstagedChanges(): boolean {
  try {
    const output = execSync('git status --porcelain', { encoding: 'utf-8', cwd: ROOT });
    return output.trim().length > 0;
  } catch {
    return false;
  }
}

// ─── Session Operations ───────────────────────────────────────────────────────

function loadSession(): StagedReviewSession | null {
  if (!existsSync(SESSION_FILE)) return null;
  try {
    return JSON.parse(readFileSync(SESSION_FILE, 'utf-8'));
  } catch {
    return null;
  }
}

function saveSession(session: StagedReviewSession): void {
  mkdirSync(REVIEW_DIR, { recursive: true });
  writeFileSync(SESSION_FILE, JSON.stringify(session, null, 2), 'utf-8');
}

function actionStart(): StagedReviewSession {
  // Check for existing active session
  const existing = loadSession();
  if (existing && existing.status === 'active') {
    log(`Active session ${existing.id} already exists. Use 'status' to view.`, 'WARN');
    return existing;
  }

  // Verify staged files exist
  const stagedFiles = getStagedFiles();
  if (stagedFiles.length === 0) {
    throw new Error('No staged files found. Use "git add <files>" to stage changes for review.');
  }

  const currentSHA = getCurrentSHA();
  const contentHash = computeSnapshotHash(stagedFiles);

  const session: StagedReviewSession = {
    id: `staged-${Date.now()}`,
    startedAt: new Date().toISOString(),
    stagedSnapshot: {
      sha: currentSHA,
      files: stagedFiles.map((f) => f.path),
      contentHash,
    },
    status: 'active',
  };

  saveSession(session);

  log(`Staged review session ${session.id} started`, 'SUCCESS');
  log(`Snapshot: ${currentSHA.slice(0, 7)} with ${stagedFiles.length} files`, 'INFO');
  log(`Content hash: ${contentHash}`, 'INFO');

  // Warn about unstaged changes
  if (hasUnstagedChanges()) {
    log('Warning: Unstaged changes exist but are excluded from this review', 'WARN');
  }

  return session;
}

function actionStatus(): StagedReviewSession | null {
  const session = loadSession();

  if (!session) {
    log('No active staged review session', 'INFO');
    return null;
  }

  console.log(JSON.stringify(session, null, 2));
  return session;
}

function actionValidate(): { valid: boolean; issues: string[] } {
  const session = loadSession();

  if (!session) {
    return { valid: false, issues: ['No active staged review session'] };
  }

  if (session.status !== 'active') {
    return { valid: false, issues: [`Session is ${session.status}`] };
  }

  const issues: string[] = [];

  // Check SHA hasn't changed
  const currentSHA = getCurrentSHA();
  if (session.stagedSnapshot.sha !== currentSHA) {
    issues.push(
      `HEAD SHA changed: ${session.stagedSnapshot.sha.slice(0, 7)} → ${currentSHA.slice(0, 7)}`,
    );
  }

  // Check staged files match snapshot
  const currentStaged = getStagedFiles();
  const currentHash = computeSnapshotHash(currentStaged);

  if (session.stagedSnapshot.contentHash !== currentHash) {
    issues.push('Staged files have changed since review started');
  }

  // Check for new unstaged changes
  if (hasUnstagedChanges()) {
    issues.push('New unstaged changes detected (excluded from review)');
  }

  return {
    valid: issues.length === 0,
    issues,
  };
}

function actionComplete(receiptId?: string): StagedReviewSession | null {
  const session = loadSession();

  if (!session || session.status !== 'active') {
    log('No active session to complete', 'ERROR');
    return null;
  }

  session.status = 'completed';
  session.completedAt = new Date().toISOString();
  if (receiptId) {
    session.receiptId = receiptId;
  }

  saveSession(session);

  log(`Staged review session ${session.id} completed`, 'SUCCESS');
  return session;
}

function actionCancel(): StagedReviewSession | null {
  const session = loadSession();

  if (!session || session.status !== 'active') {
    log('No active session to cancel', 'ERROR');
    return null;
  }

  session.status = 'cancelled';
  session.completedAt = new Date().toISOString();

  saveSession(session);

  log(`Staged review session ${session.id} cancelled`, 'WARN');
  return session;
}

// ─── CLI Entry ─────────────────────────────────────────────────────────────────

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  void (async () => {
    const args = process.argv.slice(2);
    const action = args[0] ?? 'status';

    try {
      switch (action) {
        case 'start': {
          const session = actionStart();
          console.log(JSON.stringify(session, null, 2));
          break;
        }

        case 'status': {
          actionStatus();
          break;
        }

        case 'validate': {
          const result = actionValidate();
          console.log(JSON.stringify(result, null, 2));
          process.exit(result.valid ? 0 : 1);
          break;
        }

        case 'complete': {
          const receiptIdx = args.indexOf('--receipt');
          const receiptId = receiptIdx >= 0 ? args[receiptIdx + 1] : undefined;
          const session = actionComplete(receiptId);
          if (session) {
            console.log(JSON.stringify(session, null, 2));
          }
          break;
        }

        case 'cancel': {
          actionCancel();
          break;
        }

        default:
          console.log(`Usage: staged-review.ts <action>`);
          console.log('');
          console.log('Actions:');
          console.log('  start              Start a new staged review (requires staged files)');
          console.log('  status              Show current session status');
          console.log('  validate            Validate session is still valid');
          console.log('  complete [--receipt]  Complete the review session');
          console.log('  cancel              Cancel the review session');
          console.log('');
          console.log('Examples:');
          console.log('  git add apps/my-service');
          console.log('  npx tsx scripts/utilities/ops/REVIEW/staged-review.ts start');
          console.log('  # ... review the staged changes ...');
          console.log('  npx tsx scripts/utilities/ops/REVIEW/staged-review.ts complete');
          process.exit(1);
      }
    } catch (err) {
      log(`Error: ${err instanceof Error ? err.message : String(err)}`, 'ERROR');
      process.exit(1);
    }
  })();
}

export type { StagedReviewSession, StagedFile };
