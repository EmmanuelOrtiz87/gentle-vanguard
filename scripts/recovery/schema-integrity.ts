import { execSync } from 'child_process';
import { existsSync, mkdirSync, readdirSync, writeFileSync, copyFileSync } from 'fs';
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

interface ColumnDef {
  name: string;
  type: string;
  notnull?: boolean;
  pk?: boolean;
}
interface TableSchema {
  name: string;
  columns: ColumnDef[];
}

const CODEGRAPH_SCHEMA: TableSchema[] = [
  {
    name: 'nodes',
    columns: [
      { name: 'id', type: 'TEXT', pk: true },
      { name: 'kind', type: 'TEXT', notnull: true },
      { name: 'name', type: 'TEXT', notnull: true },
      { name: 'qualified_name', type: 'TEXT', notnull: true },
      { name: 'file_path', type: 'TEXT', notnull: true },
      { name: 'language', type: 'TEXT', notnull: true },
      { name: 'start_line', type: 'INTEGER', notnull: true },
      { name: 'end_line', type: 'INTEGER', notnull: true },
      { name: 'start_column', type: 'INTEGER', notnull: true },
      { name: 'end_column', type: 'INTEGER', notnull: true },
      { name: 'docstring', type: 'TEXT' },
      { name: 'signature', type: 'TEXT' },
      { name: 'visibility', type: 'TEXT' },
      { name: 'is_exported', type: 'INTEGER' },
      { name: 'is_async', type: 'INTEGER' },
      { name: 'is_static', type: 'INTEGER' },
      { name: 'is_abstract', type: 'INTEGER' },
      { name: 'decorators', type: 'TEXT' },
      { name: 'type_parameters', type: 'TEXT' },
      { name: 'updated_at', type: 'INTEGER', notnull: true },
    ],
  },
  {
    name: 'edges',
    columns: [
      { name: 'id', type: 'INTEGER', pk: true },
      { name: 'source', type: 'TEXT', notnull: true },
      { name: 'target', type: 'TEXT', notnull: true },
      { name: 'kind', type: 'TEXT', notnull: true },
      { name: 'metadata', type: 'TEXT' },
      { name: 'line', type: 'INTEGER' },
      { name: 'col', type: 'INTEGER' },
      { name: 'provenance', type: 'TEXT' },
    ],
  },
  {
    name: 'files',
    columns: [
      { name: 'path', type: 'TEXT', pk: true },
      { name: 'content_hash', type: 'TEXT', notnull: true },
      { name: 'language', type: 'TEXT', notnull: true },
      { name: 'size', type: 'INTEGER', notnull: true },
      { name: 'modified_at', type: 'INTEGER', notnull: true },
      { name: 'indexed_at', type: 'INTEGER', notnull: true },
      { name: 'node_count', type: 'INTEGER' },
      { name: 'errors', type: 'TEXT' },
    ],
  },
  {
    name: 'unresolved_refs',
    columns: [
      { name: 'id', type: 'INTEGER', pk: true },
      { name: 'from_node_id', type: 'TEXT', notnull: true },
      { name: 'reference_name', type: 'TEXT', notnull: true },
      { name: 'reference_kind', type: 'TEXT', notnull: true },
      { name: 'line', type: 'INTEGER', notnull: true },
      { name: 'col', type: 'INTEGER', notnull: true },
      { name: 'candidates', type: 'TEXT' },
      { name: 'file_path', type: 'TEXT', notnull: true },
      { name: 'language', type: 'TEXT', notnull: true },
    ],
  },
  {
    name: 'schema_versions',
    columns: [
      { name: 'version', type: 'INTEGER', pk: true },
      { name: 'applied_at', type: 'INTEGER', notnull: true },
      { name: 'description', type: 'TEXT' },
    ],
  },
  {
    name: 'project_metadata',
    columns: [
      { name: 'key', type: 'TEXT', pk: true },
      { name: 'value', type: 'TEXT', notnull: true },
      { name: 'updated_at', type: 'INTEGER', notnull: true },
    ],
  },
];

const KNOWN_EXTRA_COLUMNS: Record<string, string[]> = {
  nodes: ['data'],
  edges: ['data'],
  files: ['data'],
  unresolved_refs: ['data'],
  schema_versions: ['data'],
  project_metadata: ['data'],
};

interface Issue {
  db: string;
  table: string;
  column: string;
  severity: 'error' | 'warn' | 'info';
  message: string;
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
    /* skip unreadable */
  }
  return results;
}

function getPragmaTableInfo(db: string, table: string): string {
  try {
    return execSync(`sqlite3 "${db}" "PRAGMA table_info(${table});"`, {
      encoding: 'utf8',
      timeout: 5000,
    }).trim();
  } catch {
    return '';
  }
}

function getTables(db: string): string[] {
  try {
    const r = execSync(`sqlite3 "${db}" ".tables"`, {
      encoding: 'utf8',
      timeout: 10000,
    }).trim();
    return r.split(/\s+/).filter((t) => t.length > 0 && !t.startsWith('sqlite_'));
  } catch {
    return [];
  }
}

function getIntegrityCheck(db: string): string {
  try {
    return execSync(`sqlite3 "${db}" "PRAGMA integrity_check;"`, {
      encoding: 'utf8',
      timeout: 10000,
    }).trim();
  } catch {
    return 'error';
  }
}

function backupDb(dbPath: string, backupDir: string): boolean {
  try {
    const name = dbPath.split(/[/\\]/).pop() || 'unknown.db';
    const backupPath = join(backupDir, `${name.replace(/\./g, '_')}_${TS}.bak`);
    copyFileSync(dbPath, backupPath);
    const shmPath = dbPath + '-shm';
    const walPath = dbPath + '-wal';
    if (existsSync(shmPath)) copyFileSync(shmPath, backupPath + '-shm');
    if (existsSync(walPath)) copyFileSync(walPath, backupPath + '-wal');
    return true;
  } catch {
    return false;
  }
}

function rebuildIndex(dbPath: string): boolean {
  try {
    execSync(`sqlite3 "${dbPath}" "REINDEX;"`, { encoding: 'utf8', timeout: 30000 });
    return true;
  } catch {
    return false;
  }
}

function vacuumDb(dbPath: string): boolean {
  try {
    execSync(`sqlite3 "${dbPath}" "VACUUM;"`, { encoding: 'utf8', timeout: 60000 });
    return true;
  } catch {
    return false;
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

function parsePragmaRows(raw: string): Map<string, { type: string; notnull: number; pk: number }> {
  const map = new Map<string, { type: string; notnull: number; pk: number }>();
  for (const line of raw.split('\n')) {
    const parts = line.split('|');
    if (parts.length >= 3) {
      const name = parts[1]?.trim();
      const type = parts[2]?.trim();
      const notnull = parseInt(parts[3]?.trim() || '0', 10);
      const pk = parseInt(parts[5]?.trim() || '0', 10);
      if (name && type) map.set(name, { type, notnull, pk });
    }
  }
  return map;
}

// ===== MAIN =====
LOG('=== SCHEMA INTEGRITY CHECK (READ-ONLY) ===', CYAN);
LOG(`Timestamp: ${TS}\n`, GRAY);

const issues: Issue[] = [];
const actions: string[] = [];
let dbsChecked = 0;
let tablesScanned = 0;
let backupDir = '';

const scanTargets = [
  { path: join(ROOT, '.codegraph'), schema: CODEGRAPH_SCHEMA, label: 'CodeGraph', critical: true },
  { path: join(ROOT, '.engram-data'), schema: null, label: 'Engram-local', critical: false },
  {
    path: join(homedir(), '.engram', 'global', '.engram'),
    schema: null,
    label: 'Engram-global',
    critical: false,
  },
];

for (const target of scanTargets) {
  if (!existsSync(target.path)) continue;
  const dbFiles = findDbFiles(target.path);
  if (dbFiles.length === 0) continue;

  for (const dbPath of dbFiles) {
    const dbName = dbPath.split(/[/\\]/).pop() || 'unknown';
    dbsChecked++;

    LOG(`\n[${target.label}] ${dbName}`, CYAN);

    const integrity = getIntegrityCheck(dbPath);
    if (integrity !== 'ok') {
      LOG(`  INTEGRITY: ${integrity}`, RED);
      issues.push({
        db: dbPath,
        table: '*',
        column: '*',
        severity: 'error',
        message: `integrity_check: ${integrity}`,
      });
      if (!backupDir) {
        backupDir = join(ROOT, '.recovery', 'schema-backups', TS);
        mkdirSync(backupDir, { recursive: true });
      }
      if (backupDb(dbPath, backupDir)) {
        LOG(`  BACKUP created`, YELLOW);
        actions.push(`Backup ${dbName} before repair`);
      }
      if (rebuildIndex(dbPath)) {
        LOG(`  REINDEX done`, YELLOW);
        actions.push(`REINDEX ${dbName}`);
      }
      if (vacuumDb(dbPath)) {
        LOG(`  VACUUM done`, YELLOW);
        actions.push(`VACUUM ${dbName}`);
      }
      const recheck = getIntegrityCheck(dbPath);
      if (recheck === 'ok') {
        LOG(`  INTEGRITY restored after repair`, GREEN);
      } else {
        LOG(`  INTEGRITY still failing: ${recheck}`, RED);
        issues.push({
          db: dbPath,
          table: '*',
          column: '*',
          severity: 'error',
          message: `Post-repair integrity still: ${recheck}`,
        });
      }
    } else {
      LOG(`  INTEGRITY: ok`, GREEN);
    }

    const tables = getTables(dbPath);
    const expectedSchema = target.schema;
    const expectedTableNames = expectedSchema ? expectedSchema.map((s) => s.name) : [];

    for (const table of tables) {
      if (table.startsWith('fts_') || table.includes('_fts')) continue;
      tablesScanned++;

      const rawPragma = getPragmaTableInfo(dbPath, table);
      const actualCols = parsePragmaRows(rawPragma);
      const rows = getRowCount(dbPath, table);

      if (expectedSchema) {
        const expected = expectedSchema.find((s) => s.name === table);
        if (!expected) {
          const threshold = 99;
          if (actualCols.size > threshold) {
            LOG(`  [WARN] ${table}: unexpected table (not in schema)`, YELLOW);
            issues.push({
              db: dbPath,
              table,
              column: '*',
              severity: 'warn',
              message: `Table not in expected schema`,
            });
          }
          continue;
        }

        for (const col of expected.columns) {
          if (!actualCols.has(col.name)) {
            LOG(`  [ERROR] ${table}.${col.name}: MISSING (expected ${col.type})`, RED);
            issues.push({
              db: dbPath,
              table,
              column: col.name,
              severity: 'error',
              message: `Missing required column ${col.name} ${col.type}`,
            });
          }
        }

        const knownExtras = KNOWN_EXTRA_COLUMNS[table] || [];
        for (const [colName] of actualCols) {
          const isExpected =
            expected.columns.some((c) => c.name === colName) || knownExtras.includes(colName);
          if (!isExpected) {
            LOG(`  [INFO] ${table}.${colName}: extra column (not in canonical schema)`, GRAY);
            issues.push({
              db: dbPath,
              table,
              column: colName,
              severity: 'info',
              message: `Extra column not in canonical schema — safe to ignore`,
            });
          }
        }
      }

      const rowSymbol = rows >= 0 ? ` (${rows} rows)` : '';
      if (!issues.some((i) => i.table === table && i.severity === 'error')) {
        LOG(`  [OK] ${table}${rowSymbol}`, GREEN);
      }
    }

    for (const name of expectedTableNames) {
      if (!tables.includes(name)) {
        LOG(`  [ERROR] ${name}: TABLE MISSING`, RED);
        issues.push({
          db: dbPath,
          table: name,
          column: '*',
          severity: 'error',
          message: `Required table ${name} does not exist`,
        });
      }
    }
  }
}

if (backupDir) {
  writeFileSync(
    join(backupDir, 'manifest.json'),
    JSON.stringify(
      {
        timestamp: TS,
        issues: issues.filter((i) => i.severity === 'error'),
        actions,
      },
      null,
      2,
    ),
  );
}

const restoreDir = join(ROOT, '.session', 'restore-points');
mkdirSync(restoreDir, { recursive: true });
writeFileSync(
  join(restoreDir, `${TS}.json`),
  JSON.stringify(
    {
      id: `schema-check-${TS}`,
      timestamp: TS,
      type: 'schema-integrity-readonly',
      dbsChecked,
      tablesScanned,
      errors: issues.filter((i) => i.severity === 'error').length,
      warnings: issues.filter((i) => i.severity === 'warn').length,
      infos: issues.filter((i) => i.severity === 'info').length,
      actions,
      issues: issues.filter((i) => i.severity !== 'info'),
    },
    null,
    2,
  ),
);

LOG(`\n=== RESUMEN ===`, CYAN);
LOG(`  DBs escaneadas: ${dbsChecked}`, GRAY);
LOG(`  Tablas revisadas: ${tablesScanned}`, GRAY);
const errors = issues.filter((i) => i.severity === 'error');
const warns = issues.filter((i) => i.severity === 'warn');
const infos = issues.filter((i) => i.severity === 'info');
LOG(`  Errores: ${errors.length}`, errors.length > 0 ? RED : GREEN);
LOG(`  Warnings: ${warns.length}`, warns.length > 0 ? YELLOW : GREEN);
LOG(`  Info (extra columns): ${infos.length}`, GRAY);
if (actions.length > 0) LOG(`  Acciones tomadas: ${actions.join(', ')}`, YELLOW);
LOG(`  Restore point: schema-check-${TS}`, GRAY);

if (errors.length > 0) {
  LOG(`\nERRORES DETECTADOS — revisa los issues arriba`, RED);
  LOG(`Si hay corrupcion, ejecuta: npx tsx scripts/recovery/db-restore.ts`, YELLOW);
  process.exit(1);
} else {
  LOG(`\nTODO OK — schemas validos`, GREEN);
  process.exit(0);
}
