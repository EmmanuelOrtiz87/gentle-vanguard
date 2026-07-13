import { execSync } from 'child_process';
import {
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  writeFileSync,
  copyFileSync,
  rmSync,
  statSync,
} from 'fs';
import { join, resolve } from 'path';

const ROOT = resolve(process.cwd());
const TS = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
const LOG = (m: string, c = '') => console.log(c + m + '\x1b[0m');
const RED = '\x1b[31m',
  GREEN = '\x1b[32m',
  YELLOW = '\x1b[33m',
  CYAN = '\x1b[36m',
  GRAY = '\x1b[90m';

const args = process.argv.slice(2);
const ACTION = args[0] || 'list';
const TARGET = args[1] || '';

const RECOVERY_DIR = join(ROOT, '.recovery');
const BACKUP_DIR = join(RECOVERY_DIR, 'schema-backups');
const CHECKPOINT_DIR = join(ROOT, '.session', 'checkpoints');
const RESTORE_DIR = join(ROOT, '.session', 'restore-points');

function findDbFiles(dir: string): string[] {
  if (!existsSync(dir)) return [];
  const results: string[] = [];
  try {
    const entries = readdirSync(dir, { withFileTypes: true });
    for (const e of entries) {
      const full = join(dir, e.name);
      if (e.isDirectory() && !e.name.startsWith('.')) {
        results.push(...findDbFiles(full));
      } else if (e.name.endsWith('.db') || e.name.endsWith('.sqlite')) {
        results.push(full);
      }
    }
  } catch {
    /* skip */
  }
  return results;
}

function getTables(db: string): string[] {
  try {
    const r = execSync(`sqlite3 "${db}" ".tables"`, { encoding: 'utf8', timeout: 10000 }).trim();
    return r.split(/\s+/).filter((t) => t.length > 0 && !t.startsWith('sqlite_'));
  } catch {
    return [];
  }
}

function getRowCount(db: string, table: string): number {
  try {
    const r = execSync(`sqlite3 "${db}" "SELECT COUNT(*) FROM [${table}];"`, {
      encoding: 'utf8',
      timeout: 5000,
    }).trim();
    return parseInt(r, 10) || 0;
  } catch {
    return -1;
  }
}

function getIntegrity(db: string): 'ok' | 'error' | 'missing' {
  try {
    const r = execSync(`sqlite3 "${db}" "PRAGMA integrity_check;"`, {
      encoding: 'utf8',
      timeout: 10000,
    }).trim();
    return r === 'ok' ? 'ok' : 'error';
  } catch {
    return 'missing';
  }
}

function rebuildDb(dbPath: string): boolean {
  try {
    const tmpPath = dbPath + '.rebuild';
    execSync(`sqlite3 "${dbPath}" ".dump" | sqlite3 "${tmpPath}"`, {
      encoding: 'utf8',
      timeout: 60000,
      shell: true,
    });
    const integrity = getIntegrity(tmpPath);
    if (integrity === 'ok') {
      copyFileSync(dbPath, dbPath + '.pre-rebuild');
      copyFileSync(tmpPath, dbPath);
      rmSync(tmpPath, { force: true });
      return true;
    }
    rmSync(tmpPath, { force: true });
    return false;
  } catch {
    return false;
  }
}

function listBackups(): void {
  LOG('=== AVAILABLE BACKUPS ===', CYAN);

  if (!existsSync(BACKUP_DIR)) {
    LOG('  No backups found', GRAY);
    return;
  }

  const backupDirs = readdirSync(BACKUP_DIR, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .sort()
    .reverse();

  if (backupDirs.length === 0) {
    LOG('  No backup directories found', GRAY);
    return;
  }

  for (const dir of backupDirs) {
    const dirPath = join(BACKUP_DIR, dir);
    const files = readdirSync(dirPath).filter((f) => f.endsWith('.bak'));
    const manifestPath = join(dirPath, 'manifest.json');
    let manifest: any = null;
    if (existsSync(manifestPath)) {
      try {
        manifest = JSON.parse(readFileSync(manifestPath, 'utf-8'));
      } catch {
        /* skip */
      }
    }

    LOG(`\n  Backup: ${dir}`, CYAN);
    if (manifest) {
      LOG(`    Reason: ${manifest.actions?.join(', ') || 'unknown'}`, GRAY);
      LOG(`    Issues: ${manifest.issues?.length || 0}`, GRAY);
    }
    for (const f of files) {
      const size = statSync(join(dirPath, f)).size;
      LOG(`    ${f} (${(size / 1024).toFixed(1)}KB)`, GRAY);
    }
  }

  LOG(`\n  Restore: npx tsx scripts/recovery/db-restore.ts restore <backup-name>`, YELLOW);
}

function listCheckpoints(): void {
  LOG('=== AVAILABLE CHECKPOINTS ===', CYAN);

  if (!existsSync(CHECKPOINT_DIR)) {
    LOG('  No checkpoints directory', GRAY);
    return;
  }

  const checkpoints = readdirSync(CHECKPOINT_DIR)
    .filter((f) => f.endsWith('.json'))
    .sort()
    .reverse();

  if (checkpoints.length === 0) {
    LOG('  No checkpoint files found', GRAY);
    return;
  }

  for (const cp of checkpoints.slice(0, 10)) {
    try {
      const data = JSON.parse(readFileSync(join(CHECKPOINT_DIR, cp), 'utf-8'));
      LOG(`  ${cp}`, CYAN);
      LOG(`    ID: ${data.id || 'unknown'}`, GRAY);
      LOG(`    Time: ${data.timestamp || 'unknown'}`, GRAY);
      if (data.files) LOG(`    Files: ${data.files.length}`, GRAY);
    } catch {
      LOG(`  ${cp} (corrupt)`, RED);
    }
  }
}

function restoreBackup(backupName: string): void {
  LOG(`=== RESTORE FROM BACKUP: ${backupName} ===`, CYAN);

  const backupPath = join(BACKUP_DIR, backupName);
  if (!existsSync(backupPath)) {
    LOG(`  Backup not found: ${backupPath}`, RED);
    process.exit(1);
  }

  const bakFiles = readdirSync(backupPath).filter((f) => f.endsWith('.bak'));
  if (bakFiles.length === 0) {
    LOG(`  No .bak files in backup`, RED);
    process.exit(1);
  }

  LOG(`  Found ${bakFiles.length} backup file(s)`, GRAY);

  const preRestoreDir = join(RESTORE_DIR, `pre-restore-${TS}`);
  mkdirSync(preRestoreDir, { recursive: true });

  for (const bak of bakFiles) {
    const originalName = bak.replace(/_\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}\.bak$/, '.db');
    let targetDir = '';

    if (originalName.includes('codegraph')) {
      targetDir = join(ROOT, '.codegraph');
    } else if (originalName.includes('engram')) {
      targetDir = join(ROOT, '.engram-data');
    }

    if (!targetDir) {
      LOG(`  [SKIP] ${bak} — can't determine target directory`, YELLOW);
      continue;
    }

    const targetDb = join(targetDir, originalName);
    if (existsSync(targetDb)) {
      const prePath = join(preRestoreDir, originalName);
      copyFileSync(targetDb, prePath);
      LOG(`  Pre-restore snapshot: ${originalName}`, GRAY);
    }

    const srcBak = join(backupPath, bak);
    copyFileSync(srcBak, targetDb);

    const shmBak = srcBak + '-shm';
    const walBak = srcBak + '-wal';
    if (existsSync(shmBak)) copyFileSync(shmBak, targetDb + '-shm');
    if (existsSync(walBak)) copyFileSync(walBak, targetDb + '-wal');

    const integrity = getIntegrity(targetDb);
    LOG(`  Restored: ${originalName} — integrity: ${integrity}`, integrity === 'ok' ? GREEN : RED);
  }

  mkdirSync(RESTORE_DIR, { recursive: true });
  writeFileSync(
    join(RESTORE_DIR, `restore-${TS}.json`),
    JSON.stringify(
      {
        id: `restore-${TS}`,
        timestamp: TS,
        type: 'backup-restore',
        backupName,
        filesRestored: bakFiles.length,
        preRestoreDir,
      },
      null,
      2,
    ),
  );

  LOG(`\n  Restore complete. Pre-restore snapshot: ${preRestoreDir}`, GREEN);
  LOG(`  Restart opencode to apply changes.`, YELLOW);
}

function repairDb(dbPath: string): void {
  const dbName = dbPath.split(/[/\\]/).pop() || 'unknown';
  LOG(`\n  Repairing: ${dbName}`, CYAN);

  const backupDir = join(BACKUP_DIR, TS);
  mkdirSync(backupDir, { recursive: true });
  copyFileSync(dbPath, join(backupDir, `${dbName}.bak`));
  LOG(`    Backup created`, GRAY);

  try {
    execSync(`sqlite3 "${dbPath}" "PRAGMA wal_checkpoint(TRUNCATE);"`, {
      encoding: 'utf8',
      timeout: 30000,
    });
    LOG(`    WAL checkpoint done`, GRAY);
  } catch {
    /* skip */
  }

  try {
    execSync(`sqlite3 "${dbPath}" "REINDEX;"`, { encoding: 'utf8', timeout: 30000 });
    LOG(`    REINDEX done`, GRAY);
  } catch {
    /* skip */
  }

  try {
    execSync(`sqlite3 "${dbPath}" "VACUUM;"`, { encoding: 'utf8', timeout: 60000 });
    LOG(`    VACUUM done`, GRAY);
  } catch {
    /* skip */
  }

  const integrity = getIntegrity(dbPath);
  if (integrity === 'ok') {
    LOG(`    Status: REPAIRED`, GREEN);
  } else {
    LOG(`    Status: Still failing — attempting full rebuild...`, YELLOW);
    if (rebuildDb(dbPath)) {
      LOG(`    Status: REBUILT successfully`, GREEN);
    } else {
      LOG(`    Status: REBUILD FAILED — use backup restore`, RED);
    }
  }
}

function repairAll(): void {
  LOG('=== REPAIR ALL DATABASES ===', CYAN);

  const targets = [join(ROOT, '.codegraph'), join(ROOT, '.engram-data')];

  for (const dir of targets) {
    if (!existsSync(dir)) continue;
    const dbs = findDbFiles(dir);
    for (const db of dbs) {
      const integrity = getIntegrity(db);
      if (integrity === 'error') {
        repairDb(db);
      } else {
        LOG(`  [OK] ${db.split(/[/\\]/).pop()} — no repair needed`, GREEN);
      }
    }
  }
}

// ===== MAIN =====
LOG('=== DB RESTORE ===', CYAN);
LOG(`Timestamp: ${TS}\n`, GRAY);

switch (ACTION) {
  case 'list':
    listBackups();
    LOG('');
    listCheckpoints();
    break;
  case 'restore':
    if (!TARGET) {
      LOG('Usage: npx tsx scripts/recovery/db-restore.ts restore <backup-name>', RED);
      LOG("Run 'list' to see available backups", YELLOW);
      process.exit(1);
    }
    restoreBackup(TARGET);
    break;
  case 'repair':
    repairAll();
    break;
  default:
    LOG('Actions: list | restore <backup-name> | repair', RED);
    LOG('  list     — show available backups and checkpoints', GRAY);
    LOG('  restore  — restore databases from a backup', GRAY);
    LOG('  repair   — auto-repair all corrupted databases', GRAY);
    process.exit(1);
}
