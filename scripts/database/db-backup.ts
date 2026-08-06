#!/usr/bin/env node

/**
 * db-backup.ts — Backup & restore for gentle-vanguard.db
 *
 * Usage:
 *   npx tsx scripts/database/db-backup.ts backup           # Backup to .runtime/backups/
 *   npx tsx scripts/database/db-backup.ts backup --dir D:\backups
 *   npx tsx scripts/database/db-backup.ts list              # List available backups
 *   npx tsx scripts/database/db-backup.ts restore latest    # Restore latest backup
 *   npx tsx scripts/database/db-backup.ts restore <name>    # Restore specific backup
 *   npx tsx scripts/database/db-backup.ts optimize          # Free page space + reindex
 *   npx tsx scripts/database/db-backup.ts prune --keep 5    # Delete old backups, keep N
 */

import { existsSync, mkdirSync, readdirSync, statSync, unlinkSync, writeFileSync } from 'fs';
import { join, resolve } from 'path';
import { runSync } from '../../src/core/run-command.js';

const ROOT = resolve(process.cwd());
const DB_PATH = join(ROOT, '.runtime', 'gentle-vanguard.db');
const BACKUP_DIR = join(ROOT, '.runtime', 'backups');

const args = process.argv.slice(2);
const action = args[0] || 'backup';

function log(msg: string): void {
  console.log(`[db-backup] ${msg}`);
}

function ensureBackupDir(): void {
  if (!existsSync(BACKUP_DIR)) {
    mkdirSync(BACKUP_DIR, { recursive: true });
    log(`Created backup directory: ${BACKUP_DIR}`);
  }
}

function getTimestamp(): string {
  return new Date().toISOString().replace(/[:.]/g, '-').replace('T', '_').slice(0, 19);
}

function listBackups(): { name: string; sizeMB: string; date: string }[] {
  if (!existsSync(BACKUP_DIR)) return [];
  return readdirSync(BACKUP_DIR)
    .filter((f) => f.endsWith('.db') || f.endsWith('.sqlite'))
    .map((f) => {
      const fp = join(BACKUP_DIR, f);
      const size = (statSync(fp).size / 1024 / 1024).toFixed(2);
      const date = new Date(statSync(fp).mtime).toISOString();
      return { name: f, sizeMB: size, date };
    })
    .sort((a, b) => b.date.localeCompare(a.date));
}

// ─── Actions ──────────────────────────────────────────────────────────────

function doBackup(): number {
  if (!existsSync(DB_PATH)) {
    log(`ERROR: ${DB_PATH} not found`);
    return 1;
  }

  ensureBackupDir();

  // Get the custom dir if provided
  const dirIdx = args.indexOf('--dir');
  const targetDir = dirIdx !== -1 && args[dirIdx + 1] ? args[dirIdx + 1] : BACKUP_DIR;
  if (!existsSync(targetDir)) {
    mkdirSync(targetDir, { recursive: true });
  }

  const ts = getTimestamp();
  const backupName = `gentle-vanguard_${ts}.db`;
  const targetPath = join(targetDir, backupName);

  // Use SQLite backup API via CLI for safe online backup
  try {
    const result = runSync('sqlite3', [DB_PATH, `.backup '${targetPath}'`], { timeout: 30000 });
    if (result.status !== 0) {
      log(`Backup failed: ${result.stderr || 'Unknown error'}`);
      return 1;
    }
    // Verify backup was created
    if (!existsSync(targetPath)) {
      log('Backup failed: File was not created');
      return 1;
    }
    const sizeMB = (statSync(targetPath).size / 1024 / 1024).toFixed(2);
    log(`Backup created: ${targetPath} (${sizeMB} MB)`);
  } catch (e) {
    log(`Backup failed: ${(e as Error).message}`);
    return 1;
  }

  // Write manifest
  const manifest = {
    backup_name: backupName,
    source: DB_PATH,
    created_at: new Date().toISOString(),
    size_bytes: statSync(targetPath).size,
  };
  writeFileSync(join(BACKUP_DIR, `${backupName}.manifest.json`), JSON.stringify(manifest, null, 2));

  return 0;
}

function doList(): number {
  const backups = listBackups();
  if (backups.length === 0) {
    log('No backups found');
    return 0;
  }

  log(`${backups.length} backup(s) available:`);
  console.log('');
  for (const b of backups) {
    console.log(`  ${b.name.padEnd(45)} ${b.sizeMB.padStart(8)} MB  ${b.date.slice(0, 19)}`);
  }
  console.log('');
  return 0;
}

function doRestore(): number {
  if (!existsSync(BACKUP_DIR)) {
    log('ERROR: No backups directory found');
    return 1;
  }

  const backups = listBackups();
  if (backups.length === 0) {
    log('ERROR: No backups available');
    return 1;
  }

  let targetName: string;
  const restoreArg = args[1];

  if (!restoreArg || restoreArg === 'latest') {
    targetName = backups[0].name;
  } else {
    // Find matching backup
    const match = backups.find((b) => b.name.startsWith(restoreArg) || b.name.includes(restoreArg));
    if (!match) {
      log(`ERROR: No backup matching "${restoreArg}"`);
      log(
        `Available: ${backups
          .slice(0, 5)
          .map((b) => b.name)
          .join(', ')}`,
      );
      return 1;
    }
    targetName = match.name;
  }

  const backupPath = join(BACKUP_DIR, targetName);
  if (!existsSync(backupPath)) {
    log(`ERROR: Backup file not found: ${backupPath}`);
    return 1;
  }

  log(`Restoring from: ${backupPath}`);
  const backupSizeMB = (statSync(backupPath).size / 1024 / 1024).toFixed(2);

  // Safe restore: use .restore CLI command
  try {
    const restoreResult = runSync('sqlite3', [DB_PATH, `.restore '${backupPath}'`], {
      timeout: 60000,
    });
    if (restoreResult.status !== 0) {
      log(`Restore failed: ${restoreResult.stderr || 'Unknown error'}`);
      return 1;
    }
    log(`Restore complete from ${targetName} (${backupSizeMB} MB)`);
  } catch (e) {
    log(`Restore failed: ${(e as Error).message}`);
    return 1;
  }

  return 0;
}

function doOptimize(): number {
  if (!existsSync(DB_PATH)) {
    log('ERROR: Database not found');
    return 1;
  }

  const beforeSize = statSync(DB_PATH).size;

  log('Running PRAGMA wal_checkpoint(TRUNCATE)...');
  runSync('sqlite3', [DB_PATH, 'PRAGMA wal_checkpoint(TRUNCATE);'], {
    timeout: 30000,
  });

  log('Running REINDEX...');
  runSync('sqlite3', [DB_PATH, 'REINDEX;'], {
    timeout: 60000,
  });

  log('Running VACUUM...');
  runSync('sqlite3', [DB_PATH, 'VACUUM;'], {
    timeout: 120000,
  });

  const afterSize = statSync(DB_PATH).size;
  const savedMB = ((beforeSize - afterSize) / 1024 / 1024).toFixed(2);
  log(
    `Optimization complete: ${(beforeSize / 1024 / 1024).toFixed(2)} MB → ${(afterSize / 1024 / 1024).toFixed(2)} MB (saved ${savedMB} MB)`,
  );

  return 0;
}

function doPrune(): number {
  const keepIdx = args.indexOf('--keep');
  const keep = keepIdx !== -1 && args[keepIdx + 1] ? parseInt(args[keepIdx + 1], 10) : 5;

  if (keep < 1) {
    log('ERROR: --keep must be >= 1');
    return 1;
  }

  const backups = listBackups();
  if (backups.length <= keep) {
    log(`Only ${backups.length} backup(s), keeping all (--keep=${keep})`);
    return 0;
  }

  const toDelete = backups.slice(keep);
  for (const b of toDelete) {
    const bp = join(BACKUP_DIR, b.name);
    const mp = join(BACKUP_DIR, `${b.name}.manifest.json`);
    try {
      unlinkSync(bp);
      log(`Deleted: ${b.name}`);
    } catch {
      log(`WARN: Could not delete ${b.name}`);
    }
    // Remove manifest too
    try {
      if (existsSync(mp)) unlinkSync(mp);
    } catch {
      // ignore
    }
  }

  log(`Pruned ${toDelete.length} backup(s), kept ${keep}`);
  return 0;
}

// ─── Main ────────────────────────────────────────────────────────────────

function usage(): void {
  console.log(`
Usage:
  npx tsx scripts/database/db-backup.ts backup           Backup to .runtime/backups/
  npx tsx scripts/database/db-backup.ts backup --dir <d>  Backup to custom directory
  npx tsx scripts/database/db-backup.ts list              List available backups
  npx tsx scripts/database/db-backup.ts restore latest    Restore latest backup
  npx tsx scripts/database/db-backup.ts restore <name>    Restore specific backup
  npx tsx scripts/database/db-backup.ts optimize          Free page space + reindex
  npx tsx scripts/database/db-backup.ts prune --keep N    Delete old backups, keep N
`);
}

function main(): number {
  switch (action) {
    case 'backup':
      return doBackup();
    case 'list':
      return doList();
    case 'restore':
      return doRestore();
    case 'optimize':
      return doOptimize();
    case 'prune':
      return doPrune();
    case 'help':
    case '--help':
      usage();
      return 0;
    default:
      console.error(`Unknown action: ${action}`);
      usage();
      return 1;
  }
}

const code = main();
process.exit(code);
