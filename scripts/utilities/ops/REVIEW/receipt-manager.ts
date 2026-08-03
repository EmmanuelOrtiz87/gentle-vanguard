#!/usr/bin/env node
/**
 * Receipt Manager — Content-bound review receipts linked to Git candidates.
 *
 * Creates, validates, and manages review receipts that bind to specific Git SHAs
 * to prevent scope/identity drift between review and delivery.
 *
 * Actions: create, validate, list, prune, export
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { join, resolve } from 'path';
import { pathToFileURL } from 'url';
import { createHash } from 'crypto';
import { execSync } from 'child_process';

// ─── Types ─────────────────────────────────────────────────────────────────────

interface Finding {
  severity: 'critical' | 'required' | 'nit' | 'optional' | 'info';
  message: string;
  file?: string;
  line?: number;
}

interface ReviewReceipt {
  id: string;
  candidateHash: string;
  contentHash: string;
  author: string;
  timestamp: string;
  files: string[];
  findings: Finding[];
  approved: boolean;
  notes?: string;
}

interface GitCandidate {
  sha: string;
  author: string;
  email: string;
  date: string;
  message: string;
  stagedFiles: string[];
  stagedContent: Map<string, string>;
}

interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}

// ─── Config ───────────────────────────────────────────────────────────────────

const ROOT = resolve(process.cwd());
const RECEIPT_DIR = join(ROOT, '.session', 'receipts');
const RECEIPT_INDEX = join(RECEIPT_DIR, 'index.json');

// ─── Logger ───────────────────────────────────────────────────────────────────

function log(message: string, level: 'INFO' | 'WARN' | 'ERROR' | 'SUCCESS' = 'INFO'): void {
  const timestamp = new Date().toISOString().replace('T', ' ').slice(0, 19);
  const colors: Record<string, string> = {
    INFO: '\x1b[36m',
    WARN: '\x1b[33m',
    ERROR: '\x1b[31m',
    SUCCESS: '\x1b[32m',
  };
  console.log(`${colors[level]}[${timestamp}] [RECEIPT] [${level}] ${message}\x1b[0m`);
}

// ─── Git Operations ───────────────────────────────────────────────────────────

function getGitCandidate(stagedOnly = false): GitCandidate {
  try {
    const sha = execSync('git rev-parse HEAD', { encoding: 'utf-8', cwd: ROOT }).trim();
    const author = execSync('git log -1 --format="%an"', { encoding: 'utf-8', cwd: ROOT }).trim();
    const email = execSync('git log -1 --format="%ae"', { encoding: 'utf-8', cwd: ROOT }).trim();
    const date = execSync('git log -1 --format="%ai"', { encoding: 'utf-8', cwd: ROOT }).trim();
    const message = execSync('git log -1 --format="%s"', { encoding: 'utf-8', cwd: ROOT }).trim();

    let files: string[];
    if (stagedOnly) {
      files = execSync('git diff --cached --name-only', { encoding: 'utf-8', cwd: ROOT })
        .split('\n')
        .filter((f) => f.trim());
    } else {
      files = execSync('git diff --name-only', { encoding: 'utf-8', cwd: ROOT })
        .split('\n')
        .filter((f) => f.trim());
    }

    const stagedContent = new Map<string, string>();
    for (const file of files) {
      try {
        const content = stagedOnly
          ? execSync(`git show :${file}`, { encoding: 'utf-8', cwd: ROOT })
          : execSync(`git show HEAD:${file}`, { encoding: 'utf-8', cwd: ROOT });
        stagedContent.set(file, content);
      } catch {
        // File might be new/untracked
        stagedContent.set(file, '');
      }
    }

    return { sha, author, email, date, message, stagedFiles: files, stagedContent };
  } catch (err) {
    throw new Error(
      `Failed to get Git candidate: ${err instanceof Error ? err.message : String(err)}`,
    );
  }
}

function computeContentHash(files: string[], content: Map<string, string>): string {
  const hash = createHash('sha256');
  const sortedFiles = [...files].sort();

  for (const file of sortedFiles) {
    hash.update(file);
    hash.update(content.get(file) || '');
  }

  return hash.digest('hex').slice(0, 16);
}

// ─── Receipt Operations ───────────────────────────────────────────────────────

function loadIndex(): { receipts: ReviewReceipt[]; nextId: number } {
  if (!existsSync(RECEIPT_INDEX)) {
    return { receipts: [], nextId: 1 };
  }
  try {
    return JSON.parse(readFileSync(RECEIPT_INDEX, 'utf-8'));
  } catch {
    return { receipts: [], nextId: 1 };
  }
}

function saveIndex(index: { receipts: ReviewReceipt[]; nextId: number }): void {
  mkdirSync(RECEIPT_DIR, { recursive: true });
  writeFileSync(RECEIPT_INDEX, JSON.stringify(index, null, 2), 'utf-8');
}

function actionCreate(
  approved: boolean,
  findings: Finding[] = [],
  notes?: string,
  stagedOnly = false,
): ReviewReceipt {
  const candidate = getGitCandidate(stagedOnly);
  const contentHash = computeContentHash(candidate.stagedFiles, candidate.stagedContent);

  const receipt: ReviewReceipt = {
    id: `rcpt-${String(Date.now()).slice(-8)}`,
    candidateHash: candidate.sha,
    contentHash,
    author: candidate.author,
    timestamp: new Date().toISOString(),
    files: candidate.stagedFiles,
    findings,
    approved,
    notes,
  };

  const index = loadIndex();
  index.receipts.push(receipt);
  saveIndex(index);

  log(`Receipt ${receipt.id} created for ${candidate.sha.slice(0, 7)}`, 'SUCCESS');
  return receipt;
}

function actionValidate(receiptId: string): ValidationResult {
  const index = loadIndex();
  const receipt = index.receipts.find((r) => r.id === receiptId);

  if (!receipt) {
    return { valid: false, errors: [`Receipt ${receiptId} not found`], warnings: [] };
  }

  const errors: string[] = [];
  const warnings: string[] = [];

  try {
    const currentCandidate = getGitCandidate(false);

    // Check SHA match
    if (receipt.candidateHash !== currentCandidate.sha) {
      errors.push(
        `Candidate SHA mismatch: expected ${receipt.candidateHash.slice(0, 7)}, got ${currentCandidate.sha.slice(0, 7)}`,
      );
    }

    // Check content hash
    const currentContentHash = computeContentHash(
      currentCandidate.stagedFiles,
      currentCandidate.stagedContent,
    );
    if (receipt.contentHash !== currentContentHash) {
      errors.push(`Content hash mismatch: files may have changed since review`);
    }

    // Check approval status
    if (!receipt.approved) {
      warnings.push('Receipt marked as not approved');
    }

    // Check for critical findings
    const criticalFindings = receipt.findings.filter((f) => f.severity === 'critical');
    if (criticalFindings.length > 0) {
      warnings.push(`${criticalFindings.length} critical findings not addressed`);
    }
  } catch (err) {
    errors.push(`Validation failed: ${err instanceof Error ? err.message : String(err)}`);
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
  };
}

function actionList(filter?: string): ReviewReceipt[] {
  const index = loadIndex();
  let receipts = index.receipts;

  if (filter === 'approved') {
    receipts = receipts.filter((r) => r.approved);
  } else if (filter === 'pending') {
    receipts = receipts.filter((r) => !r.approved);
  }

  return receipts.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
}

function actionPrune(days = 30): number {
  const index = loadIndex();
  const cutoff = Date.now() - days * 24 * 60 * 60 * 1000;

  const before = index.receipts.length;
  index.receipts = index.receipts.filter((r) => new Date(r.timestamp).getTime() > cutoff);

  const removed = before - index.receipts.length;
  saveIndex(index);

  log(`Pruned ${removed} receipts older than ${days} days`, 'SUCCESS');
  return removed;
}

function actionExport(receiptId: string): string | null {
  const index = loadIndex();
  const receipt = index.receipts.find((r) => r.id === receiptId);

  if (!receipt) {
    log(`Receipt ${receiptId} not found`, 'ERROR');
    return null;
  }

  return JSON.stringify(receipt, null, 2);
}

// ─── CLI Entry ─────────────────────────────────────────────────────────────────

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  void (async () => {
    const args = process.argv.slice(2);
    const action = args[0] ?? 'list';

    try {
      switch (action) {
        case 'create': {
          const approved = args.includes('--approved');
          const staged = args.includes('--staged');
          const notesIdx = args.indexOf('--notes');
          const notes = notesIdx >= 0 ? args[notesIdx + 1] : undefined;

          // Parse findings from JSON if provided
          let findings: Finding[] = [];
          const findingsIdx = args.indexOf('--findings');
          if (findingsIdx >= 0) {
            try {
              findings = JSON.parse(args[findingsIdx + 1]);
            } catch {
              log('Invalid findings JSON, ignoring', 'WARN');
            }
          }

          const receipt = actionCreate(approved, findings, notes, staged);
          console.log(JSON.stringify(receipt, null, 2));
          break;
        }

        case 'validate': {
          const receiptId = args.find((a) => a.startsWith('--id='))?.split('=')[1];
          if (!receiptId) {
            console.error('Usage: validate --id=<receipt-id>');
            process.exit(1);
          }
          const result = actionValidate(receiptId);
          console.log(JSON.stringify(result, null, 2));
          process.exit(result.valid ? 0 : 1);
          break;
        }

        case 'list': {
          const filter = args.includes('--approved')
            ? 'approved'
            : args.includes('--pending')
              ? 'pending'
              : undefined;
          const receipts = actionList(filter);
          console.log(JSON.stringify(receipts, null, 2));
          break;
        }

        case 'prune': {
          const daysIdx = args.indexOf('--days');
          const days = daysIdx >= 0 ? parseInt(args[daysIdx + 1], 10) : 30;
          const removed = actionPrune(days);
          console.log(JSON.stringify({ removed }, null, 2));
          break;
        }

        case 'export': {
          const receiptId = args.find((a) => a.startsWith('--id='))?.split('=')[1];
          if (!receiptId) {
            console.error('Usage: export --id=<receipt-id>');
            process.exit(1);
          }
          const exported = actionExport(receiptId);
          if (exported) {
            console.log(exported);
          }
          break;
        }

        default:
          console.log(`Usage: receipt-manager.ts <action> [options]`);
          console.log('');
          console.log('Actions:');
          console.log('  create    Create a new receipt');
          console.log('  validate  Validate a receipt against current Git state');
          console.log('  list      List all receipts');
          console.log('  prune     Remove old receipts');
          console.log('  export    Export a receipt as JSON');
          console.log('');
          console.log('Options:');
          console.log('  --approved    Mark receipt as approved');
          console.log('  --staged      Only include staged files');
          console.log('  --findings    JSON array of findings');
          console.log('  --notes       Review notes');
          console.log('  --id=<>       Receipt ID');
          console.log('  --days=<>     Days for prune');
          process.exit(1);
      }
    } catch (err) {
      log(`Error: ${err instanceof Error ? err.message : String(err)}`, 'ERROR');
      process.exit(1);
    }
  })();
}

export type { ReviewReceipt, GitCandidate, ValidationResult, Finding };
