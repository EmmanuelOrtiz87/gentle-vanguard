#!/usr/bin/env node

/**
 * db-prune.ts — Prune old data from gentle-vanguard.db (Wave 37 D)
 *
 * Deletes:
 *   - events older than 30 days
 *   - response_cache entries older than 7 days
 *   - token_usage records older than 90 days
 *   - orphaned skill_usage records (no matching session)
 *   - Then runs housekeeping (metric snapshots, alerts, vacuum)
 *
 * Usage:
 *   npx tsx scripts/database/db-prune.ts
 *   npx tsx scripts/database/db-prune.ts --quiet
 *   npx tsx scripts/database/db-prune.ts --json     # Machine-readable output
 */

import { db } from '../../src/database/db.js';

const args = process.argv.slice(2);
const quiet = args.includes('--quiet');
const jsonOutput = args.includes('--json');

function log(msg: string): void {
  if (!quiet) console.log(`[db-prune] ${msg}`);
}

try {
  const mgr = db();
  log('Starting prune...');

  const result = mgr.pruneAll();

  if (jsonOutput) {
    console.log(JSON.stringify({ success: true, pruned: result }));
  } else {
    log(`Prune complete:
  events:       ${result.events} rows deleted
  cache:        ${result.cache} rows deleted
  token_usage:  ${result.tokenUsage} rows deleted
  skill_usage:  ${result.skillUsage} rows deleted
  housekeeping: done (metric_snapshots, alerts, vacuum)`);
  }

  mgr.close();
  process.exit(0);
} catch (err) {
  const msg = err instanceof Error ? err.message : String(err);
  if (jsonOutput) {
    console.log(JSON.stringify({ success: false, error: msg }));
  } else {
    console.error(`[db-prune] ERROR: ${msg}`);
  }
  process.exit(1);
}
