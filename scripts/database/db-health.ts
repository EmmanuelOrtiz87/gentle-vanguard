#!/usr/bin/env node

/**
 * db-health.ts — Health check for gentle-vanguard.db
 *
 * Checks:
 *   - File existence and size
 *   - WAL/shm presence
 *   - Integrity check (PRAGMA integrity_check)
 *   - Table and row counts
 *   - Migration status
 *   - Housekeeping suggestion (WAL size, age)
 *
 * Usage:
 *   npx tsx scripts/database/db-health.ts
 *   npx tsx scripts/database/db-health.ts --quiet
 *   npx tsx scripts/database/db-health.ts --json     # Machine-readable output
 */

import { existsSync, statSync } from 'fs';
import { join, resolve } from 'path';
import { runSyncShell } from '../../src/core/run-command.js';

const ROOT = resolve(process.cwd());
const DB_PATH = join(ROOT, '.runtime', 'gentle-vanguard.db');

const args = process.argv.slice(2);
const quiet = args.includes('--quiet');
const jsonOutput = args.includes('--json');

function log(msg: string, level: 'info' | 'warn' | 'error' = 'info'): void {
  if (quiet && level === 'info') return;
  const prefix = level === 'error' ? '[FAIL]' : level === 'warn' ? '[WARN]' : '[ OK ]';
  console.log(`${prefix} ${msg}`);
}

interface HealthResult {
  status: 'healthy' | 'degraded' | 'missing';
  path: string;
  exists: boolean;
  sizeBytes: number;
  sizeMB: string;
  hasShm: boolean;
  hasWal: boolean;
  walSizeBytes: number;
  integrity: 'ok' | 'error' | 'not_checked';
  tables: number;
  rows: number;
  migrations: string[];
  issues: string[];
}

async function main(): Promise<number> {
  const issues: string[] = [];
  const result: HealthResult = {
    status: 'healthy',
    path: DB_PATH,
    exists: false,
    sizeBytes: 0,
    sizeMB: '0.00',
    hasShm: false,
    hasWal: false,
    walSizeBytes: 0,
    integrity: 'not_checked',
    tables: 0,
    rows: 0,
    migrations: [],
    issues: [],
  };

  // 1. File existence
  if (!existsSync(DB_PATH)) {
    result.status = 'missing';
    result.issues.push('Database file not found');
    log(`gentle-vanguard.db — NOT FOUND at ${DB_PATH}`, 'error');
    if (jsonOutput) console.log(JSON.stringify(result, null, 2));
    return 1;
  }
  result.exists = true;

  // 2. File size
  result.sizeBytes = statSync(DB_PATH).size;
  result.sizeMB = (result.sizeBytes / 1024 / 1024).toFixed(2);
  log(`gentle-vanguard.db — ${result.sizeMB} MB`);

  // 3. WAL / SHM
  result.hasWal = existsSync(DB_PATH + '-wal');
  result.hasShm = existsSync(DB_PATH + '-shm');
  if (result.hasWal) {
    result.walSizeBytes = existsSync(DB_PATH + '-wal') ? statSync(DB_PATH + '-wal').size : 0;
    const walMB = (result.walSizeBytes / 1024 / 1024).toFixed(2);
    log(`WAL file: ${walMB} MB`, result.walSizeBytes > 5 * 1024 * 1024 ? 'warn' : 'info');
    if (result.walSizeBytes > 5 * 1024 * 1024) {
      issues.push(`WAL file large (${walMB}MB) — run PRAGMA wal_checkpoint(TRUNCATE)`);
    }
  }

  // 4. Integrity check (using sqlite3 CLI)
  try {
    const integrityOut = runSyncShell(`sqlite3 "${DB_PATH}" "PRAGMA integrity_check;"`, {
      timeout: 15000,
    }).stdout.trim();
    result.integrity = integrityOut === 'ok' ? 'ok' : 'error';
    if (result.integrity === 'error') {
      issues.push(`PRAGMA integrity_check failed: ${integrityOut}`);
      log(`Integrity: FAILED — ${integrityOut}`, 'error');
    } else {
      log('Integrity: ok');
    }
  } catch (e) {
    result.integrity = 'error';
    issues.push(`Integrity check error: ${(e as Error).message}`);
    log(`Integrity: ERROR — ${(e as Error).message}`, 'error');
  }

  // 5. Table and row counts
  try {
    const tablesOut = runSyncShell(`sqlite3 "${DB_PATH}" ".tables"`, {
      timeout: 5000,
    })
      .stdout.trim()
      .split(/\s+/)
      .filter((t) => t.length > 0 && !t.startsWith('_'));

    result.tables = tablesOut.length;
    for (const t of tablesOut) {
      try {
        const row = runSyncShell(`sqlite3 "${DB_PATH}" "SELECT COUNT(*) FROM [${t}];"`, {
          timeout: 5000,
        }).stdout.trim();
        result.rows += parseInt(row, 10) || 0;
      } catch {
        // skip individual table count errors
      }
    }
    log(`${result.tables} tables, ${result.rows} rows`);

    // Get migrations
    try {
      const migOut = runSyncShell(
        `sqlite3 "${DB_PATH}" "SELECT id, applied_at FROM _migrations ORDER BY applied_at;"`,
        { timeout: 5000 },
      )
        .stdout.trim()
        .split('\n')
        .filter((l) => l.length > 0);
      result.migrations = migOut;
      for (const m of migOut) log(`Migration: ${m}`);
    } catch {
      // _migrations table may not exist yet
    }
  } catch (e) {
    issues.push(`Table scan error: ${(e as Error).message}`);
    log(`Table scan: ERROR — ${(e as Error).message}`, 'error');
  }

  // 6. Determine overall status
  if (issues.length > 0) {
    result.issues = issues;
    result.status = issues.some((i) => i.includes('FAILED') || i.includes('ERROR'))
      ? 'degraded'
      : result.status;
  }

  // Output
  if (jsonOutput) {
    console.log(JSON.stringify(result, null, 2));
  }

  log(`Status: ${result.status}`, result.status === 'healthy' ? 'info' : 'warn');

  if (!quiet) {
    const summary = `[db-health] ${result.status.toUpperCase()} — ${result.tables} tables, ${result.rows} rows, ${result.sizeMB} MB, ${result.migrations.length} migrations`;
    console.log(`\n${'='.repeat(summary.length)}`);
    console.log(summary);
    console.log(`${'='.repeat(summary.length)}`);
  }

  return result.status === 'healthy' ? 0 : result.status === 'degraded' ? 1 : 2;
}

main()
  .then((code) => process.exit(code))
  .catch((err) => {
    console.error('[db-health] FATAL:', err.message);
    process.exit(1);
  });
