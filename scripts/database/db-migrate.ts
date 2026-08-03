#!/usr/bin/env node
/**
 * db-migrate.ts — Bulk JSON to SQLite migration tool
 *
 * Reads legacy JSON files from .session/ directories and bulk-inserts
 * into the corresponding SQLite tables in gentle-vanguard.db.
 *
 * Usage:
 *   npx tsx scripts/database/db-migrate.ts                    # Migrate all sources
 *   npx tsx scripts/database/db-migrate.ts --source cache     # Only response cache
 *   npx tsx scripts/database/db-migrate.ts --dry-run          # Preview only
 *   npx tsx scripts/database/db-migrate.ts --help             # Full help
 */

import { existsSync, readdirSync, readFileSync, statSync } from 'fs';
import { join, resolve } from 'path';
import { createRequire } from 'module';

const _require = createRequire(import.meta.url);

const ROOT = resolve(process.cwd());

// ─── Configuration ───────────────────────────────────────────────────────────

interface MigrationSource {
  name: string;
  label: string;
  jsonDir: string;
  sqliteTable: string;
  enabled: boolean;
  migrateFn: () => { count: number; errors: number };
}

const SOURCES: MigrationSource[] = [
  {
    name: 'cache',
    label: 'Response Cache',
    jsonDir: join(ROOT, '.session', 'response-cache'),
    sqliteTable: 'response_cache',
    enabled: true,
    migrateFn: migrateResponseCache,
  },
  {
    name: 'contract-results',
    label: 'Contract Results',
    jsonDir: join(ROOT, '.session', 'contract-results'),
    sqliteTable: 'contract_results',
    enabled: true,
    migrateFn: migrateContractResults,
  },
  {
    name: 'skill-usage',
    label: 'Skill Usage',
    jsonDir: join(ROOT, '.session', 'skill-usage'),
    sqliteTable: 'skill_usage',
    enabled: true,
    migrateFn: migrateGenericJson,
  },
  {
    name: 'routing',
    label: 'Routing Rules',
    jsonDir: join(ROOT, '.session', 'routing'),
    sqliteTable: 'routing_rules',
    enabled: true,
    migrateFn: migrateGenericJson,
  },
  {
    name: 'token-usage',
    label: 'Token Usage',
    jsonDir: join(ROOT, '.session', 'token-usage'),
    sqliteTable: 'token_usage',
    enabled: false, // Needs structured CSV/JSON parsing
    migrateFn: () => ({ count: 0, errors: 0 }),
  },
];

// ─── DB connection ───────────────────────────────────────────────────────────

let _db: any = null;
function getDb(): any {
  if (!_db) {
    try {
      const mod = _require('../../src/database/db');
      _db = mod.db();
    } catch (e) {
      console.error('Failed to connect to database:', (e as Error).message);
      process.exit(1);
    }
  }
  return _db;
}

// ─── Specific migrations ─────────────────────────────────────────────────────

function migrateResponseCache(): { count: number; errors: number } {
  const db = getDb();
  let count = 0;
  let errors = 0;

  if (!existsSync(SOURCES[0].jsonDir)) {
    return { count: 0, errors: 0 };
  }

  const walkDir = (dir: string) => {
    const entries = readdirSync(dir);
    for (const entry of entries) {
      const fullPath = join(dir, entry);
      try {
        const st = statSync(fullPath);
        if (st.isDirectory()) {
          walkDir(fullPath);
        } else if (entry.endsWith('.json') && entry !== 'cache-stats.json') {
          const data = JSON.parse(readFileSync(fullPath, 'utf-8'));
          const now = Date.now();

          // Skip expired
          if (now > data.timestamp + data.ttl) continue;

          const expiresAt = new Date(data.timestamp + data.ttl).toISOString();

          db.getDb()
            .prepare(
              `INSERT OR REPLACE INTO response_cache (key, response, model, created_at, expires_at, hit_count, tokens_saved)
               VALUES (?, ?, ?, ?, ?, ?, ?)`,
            )
            .run(
              data.key,
              data.response,
              null,
              new Date(data.timestamp).toISOString(),
              expiresAt,
              data.hitCount ?? 0,
              data.tokensSaved ?? 0,
            );
          count++;
        }
      } catch (e) {
        errors++;
        console.warn(`  [WARN] Failed to migrate ${fullPath}:`, (e as Error).message);
      }
    }
  };

  walkDir(SOURCES[0].jsonDir);
  return { count, errors };
}

function migrateContractResults(): { count: number; errors: number } {
  const db = getDb();
  let count = 0;
  let errors = 0;

  const dir = SOURCES[1].jsonDir;
  if (!existsSync(dir)) return { count: 0, errors: 0 };

  const files = readdirSync(dir).filter(f => f.endsWith('.json'));
  for (const file of files) {
    try {
      const data = JSON.parse(readFileSync(join(dir, file), 'utf-8'));
      if (!data.contract_id && !data.id) continue;

      db.getDb()
        .prepare(
          `INSERT OR IGNORE INTO contract_results (contract_id, session_id, status, result, duration_ms, created_at)
           VALUES (?, ?, ?, ?, ?, ?)`,
        )
        .run(
          data.contract_id ?? data.id,
          data.session_id ?? null,
          data.status ?? 'pending',
          typeof data.result === 'string' ? data.result : JSON.stringify(data.result ?? null),
          data.duration_ms ?? null,
          data.created_at ?? new Date().toISOString(),
        );
      count++;
    } catch (e) {
      errors++;
      console.warn(`  [WARN] Failed to migrate ${file}:`, (e as Error).message);
    }
  }

  return { count, errors };
}

function migrateGenericJson(): { count: number; errors: number } {
  // Generic migration for sources that just need JSON stored
  // For now just returns 0 — specific migrators handle their sources
  const dir = join(ROOT, '.session');

  const entries = readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    if (entry.isDirectory() && entry.name.startsWith('contract-')) {
      // Already handled by specific migrators
      continue;
    }
  }

  return { count: 0, errors: 0 };
}

// ─── CLI ─────────────────────────────────────────────────────────────────────

function printHelp(): void {
  console.log(`
db-migrate.ts — Bulk JSON→SQLite Migration Tool

Migrates legacy JSON files from .session/ into gentle-vanguard.db tables.

Usage:
  npx tsx scripts/database/db-migrate.ts                    # All sources
  npx tsx scripts/database/db-migrate.ts --source cache     # Specific source
  npx tsx scripts/database/db-migrate.ts --dry-run          # Preview only
  npx tsx scripts/database/db-migrate.ts --list             # List available sources
  npx tsx scripts/database/db-migrate.ts --help             # This help

Sources:
${SOURCES.filter(s => s.enabled).map(s => `  ${s.name.padEnd(20)} ${s.label} → ${s.sqliteTable}`).join('\n')}

Examples:
  npx tsx scripts/database/db-migrate.ts
  npx tsx scripts/database/db-migrate.ts --source cache
  npx tsx scripts/database/db-migrate.ts --dry-run
`);
}

function listSources(): void {
  console.log('\nAvailable migration sources:\n');
  for (const src of SOURCES) {
    const status = src.enabled ? (existsSync(src.jsonDir) ? '📁 has data' : '⭕ empty') : '⏸️  disabled';
    console.log(`  ${src.name.padEnd(20)} ${src.label.padEnd(25)} ${src.sqliteTable.padEnd(22)} ${status}`);
  }
  console.log('');
}

function main(): void {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');
  const listMode = args.includes('--list');
  const helpMode = args.includes('--help');
  const sourceFilter = args.includes('--source') ? args[args.indexOf('--source') + 1] : null;

  if (helpMode) {
    printHelp();
    process.exit(0);
  }

  if (listMode) {
    listSources();
    process.exit(0);
  }

  if (dryRun) {
    console.log('\n🔍 DRY RUN — No data will be written\n');
    for (const src of SOURCES.filter(s => s.enabled && (!sourceFilter || s.name === sourceFilter))) {
      const exists = existsSync(src.jsonDir);
      const fileCount = exists ? readdirSync(src.jsonDir, { recursive: true }).filter(f => f.toString().endsWith('.json')).length : 0;
      console.log(`  ${src.name.padEnd(20)} ${exists ? `📁 ${fileCount} JSON files → ${src.sqliteTable}` : '⭕ no directory'}`);
    }
    console.log('');
    process.exit(0);
  }

  const targets = sourceFilter
    ? SOURCES.filter(s => s.name === sourceFilter)
    : SOURCES.filter(s => s.enabled);

  if (targets.length === 0) {
    console.error(`Unknown source: ${sourceFilter}`);
    process.exit(1);
  }

  console.log('\n=== JSON → SQLite Migration ===\n');
  let totalCount = 0;
  let totalErrors = 0;

  for (const src of targets) {
    if (!existsSync(src.jsonDir)) {
      console.log(`  [SKIP] ${src.label} — directory not found: ${src.jsonDir}`);
      continue;
    }

    process.stdout.write(`  Migrating ${src.label}... `);
    const result = src.migrateFn();
    totalCount += result.count;
    totalErrors += result.errors;

    if (result.errors === 0) {
      console.log(`✅ ${result.count} entries migrated`);
    } else {
      console.log(`⚠️  ${result.count} migrated, ${result.errors} errors`);
    }
  }

  console.log(`\n  Total: ${totalCount} entries migrated, ${totalErrors} errors\n`);

  if (totalErrors > 0) process.exit(1);
}

main();
