import { runSyncShell } from '../../src/core/run-command.js';
import { existsSync, mkdirSync, readdirSync, writeFileSync, statSync } from 'fs';
import { join, resolve } from 'path';
import { homedir } from 'os';

const ROOT = resolve(process.cwd());
const TS = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
const LOG = (m: string, c = '') => console.log(c + m + '\x1b[0m');
const RED = '\x1b[31m',
  GREEN = '\x1b[32m',
  YELLOW = '\x1b[33m',
  CYAN = '\x1b[36m',
  GRAY = '\x1b[90m';

interface DbTarget {
  path: string;
  label: string;
  critical: boolean;
  expectedTables: string[];
  readWrite?: boolean;
}

const TARGETS: DbTarget[] = [
  {
    path: join(ROOT, '.codegraph'),
    label: 'CodeGraph',
    critical: true,
    expectedTables: [
      'nodes',
      'edges',
      'files',
      'unresolved_refs',
      'schema_versions',
      'project_metadata',
    ],
  },
  {
    path: join(ROOT, '.engram-data'),
    label: 'Engram-local',
    critical: false,
    expectedTables: [],
  },
  {
    path: join(homedir(), '.engram', 'global', '.engram'),
    label: 'Engram-global',
    critical: false,
    expectedTables: [],
  },
];

interface HealthResult {
  db: string;
  label: string;
  critical: boolean;
  exists: boolean;
  integrity: 'ok' | 'error' | 'missing';
  tables: number;
  rows: number;
  sizeBytes: number;
  hasShm: boolean;
  hasWal: boolean;
  issues: string[];
}

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
    const r = runSyncShell(`sqlite3 "${db}" ".tables"`, { timeout: 10000 }).stdout.trim();
    return r.split(/\s+/).filter((t) => t.length > 0 && !t.startsWith('sqlite_'));
  } catch {
    return [];
  }
}

function getTotalRows(db: string, tables: string[]): number {
  let total = 0;
  for (const t of tables) {
    try {
      const r = runSyncShell(`sqlite3 "${db}" "SELECT COUNT(*) FROM [${t}];"`, {
        timeout: 5000,
      }).stdout.trim();
      total += parseInt(r, 10) || 0;
    } catch {
      /* skip */
    }
  }
  return total;
}

function getIntegrity(db: string): 'ok' | 'error' | 'missing' {
  try {
    const r = runSyncShell(`sqlite3 "${db}" "PRAGMA integrity_check;"`, {
      timeout: 10000,
    }).stdout.trim();
    return r === 'ok' ? 'ok' : 'error';
  } catch {
    return 'missing';
  }
}

function checkpointWal(db: string): boolean {
  try {
    runSyncShell(`sqlite3 "${db}" "PRAGMA wal_checkpoint(TRUNCATE);"`, {
      timeout: 30000,
    }).stdout;
    return true;
  } catch {
    return false;
  }
}

// ===== MAIN =====
LOG('=== DB HEALTH CHECK ===', CYAN);
LOG(`Timestamp: ${TS}\n`, GRAY);

const results: HealthResult[] = [];
let criticalIssues = 0;

for (const target of TARGETS) {
  if (!existsSync(target.path)) {
    LOG(`  [SKIP] ${target.label} — directory not found`, GRAY);
    results.push({
      db: target.path,
      label: target.label,
      critical: target.critical,
      exists: false,
      integrity: 'missing',
      tables: 0,
      rows: 0,
      sizeBytes: 0,
      hasShm: false,
      hasWal: false,
      issues: ['Directory not found'],
    });
    continue;
  }

  const dbFiles = findDbFiles(target.path);
  if (dbFiles.length === 0) {
    LOG(`  [SKIP] ${target.label} — no .db files`, GRAY);
    results.push({
      db: target.path,
      label: target.label,
      critical: target.critical,
      exists: true,
      integrity: 'missing',
      tables: 0,
      rows: 0,
      sizeBytes: 0,
      hasShm: false,
      hasWal: false,
      issues: ['No .db files found'],
    });
    continue;
  }

  for (const dbPath of dbFiles) {
    const dbName = dbPath.split(/[/\\]/).pop() || 'unknown';
    const issues: string[] = [];

    let sizeBytes = 0;
    try {
      sizeBytes = statSync(dbPath).size;
    } catch {
      /* skip */
    }

    const hasShm = existsSync(dbPath + '-shm');
    const hasWal = existsSync(dbPath + '-wal');

    const integrity = getIntegrity(dbPath);
    const tables = getTables(dbPath);
    const rows = getTotalRows(dbPath, tables);

    if (integrity === 'error') {
      issues.push('INTEGRITY_CHECK failed — possible corruption');
      criticalIssues++;
    }

    const expectedMissing = target.expectedTables.filter((t) => !tables.includes(t));
    if (expectedMissing.length > 0) {
      issues.push(`Missing expected tables: ${expectedMissing.join(', ')}`);
      criticalIssues++;
    }

    if (hasWal && rows > 10000) {
      const walSize = existsSync(dbPath + '-wal') ? statSync(dbPath + '-wal').size : 0;
      if (walSize > 1024 * 1024) {
        issues.push(
          `WAL file large (${(walSize / 1024 / 1024).toFixed(1)}MB) — consider checkpoint`,
        );
      }
    }

    const sizeMB = (sizeBytes / 1024 / 1024).toFixed(2);
    const statusColor = integrity === 'ok' && issues.length === 0 ? GREEN : RED;
    const statusText = integrity === 'ok' && issues.length === 0 ? 'HEALTHY' : 'DEGRADED';

    LOG(
      `  [${statusText}] ${target.label}/${dbName} — ${tables.length} tables, ${rows} rows, ${sizeMB}MB`,
      statusColor,
    );

    if (issues.length > 0) {
      for (const issue of issues) LOG(`    ! ${issue}`, YELLOW);
    }

    if (integrity === 'error' && target.critical) {
      LOG(`    -> Attempting WAL checkpoint + REINDEX...`, YELLOW);
      checkpointWal(dbPath);
      try {
        runSyncShell(`sqlite3 "${dbPath}" "REINDEX;"`, { timeout: 30000 }).stdout;
      } catch {
        /* skip */
      }
      const recheck = getIntegrity(dbPath);
      if (recheck === 'ok') {
        LOG(`    -> Repaired successfully`, GREEN);
        issues.length = 0;
        criticalIssues--;
      } else {
        LOG(`    -> Still failing — manual intervention required`, RED);
      }
    }

    results.push({
      db: dbPath,
      label: target.label,
      critical: target.critical,
      exists: true,
      integrity,
      tables: tables.length,
      rows,
      sizeBytes,
      hasShm,
      hasWal,
      issues,
    });
  }
}

const healthDir = join(ROOT, '.session', 'health');
mkdirSync(healthDir, { recursive: true });
writeFileSync(
  join(healthDir, `db-health-${TS}.json`),
  JSON.stringify(
    {
      timestamp: TS,
      criticalIssues,
      results,
    },
    null,
    2,
  ),
);

const latestPath = join(healthDir, 'db-health-latest.json');
writeFileSync(
  latestPath,
  JSON.stringify(
    {
      timestamp: TS,
      criticalIssues,
      results,
    },
    null,
    2,
  ),
);

LOG(`\n=== RESUMEN ===`, CYAN);
const healthy = results.filter((r) => r.integrity === 'ok' && r.issues.length === 0).length;
const degraded = results.filter((r) => r.integrity === 'error' || r.issues.length > 0).length;
LOG(`  Saludables: ${healthy}/${results.length}`, healthy === results.length ? GREEN : YELLOW);
LOG(`  Con issues: ${degraded}/${results.length}`, degraded > 0 ? RED : GREEN);
LOG(`  Issues criticos: ${criticalIssues}`, criticalIssues > 0 ? RED : GREEN);
LOG(`  Reporte: ${latestPath}`, GRAY);

process.exit(criticalIssues > 0 ? 1 : 0);
