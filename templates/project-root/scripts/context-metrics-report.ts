#!/usr/bin/env node

/**
 * context-metrics-report.ts — Reports context usage metrics from CSV tracking
 *
 * Shows how many context-pack and compact-start events were recorded,
 * with daily breakdowns.
 *
 * Usage:
 *   npx tsx templates/project-root/scripts/context-metrics-report.ts
 *   npx tsx templates/project-root/scripts/context-metrics-report.ts --days 14
 *   npx tsx templates/project-root/scripts/context-metrics-report.ts --metrics-path ./data.csv
 */

import { existsSync, readFileSync } from 'fs';
import { join, resolve } from 'path';

const REPO_ROOT = resolve(join(__dirname, '..'));

const args = process.argv.slice(2);
const days = parseInt(args.includes('--days') ? args[args.indexOf('--days') + 1] || '7' : '7', 10);

let metricsPath = args.includes('--metrics-path')
  ? args[args.indexOf('--metrics-path') + 1] || ''
  : '';

if (!metricsPath) {
  metricsPath = join(REPO_ROOT, 'docs', 'sessions', 'metrics', 'context-usage.csv');
}

if (!existsSync(metricsPath)) {
  console.log(`[WARN] Metrics file not found: ${metricsPath}`);
  console.log('Run context-pack.ts or compact-start.ts to start collecting metrics.');
  process.exit(0);
}

// Parse CSV
const csvContent = readFileSync(metricsPath, 'utf-8');
const lines = csvContent.split('\n').filter((l) => l.trim());

if (lines.length <= 1) {
  console.log('[INFO] No context usage records found.');
  process.exit(0);
}

const headers = lines[0].split(',');
const cutoff = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

interface Row {
  timestamp: string;
  event: string;
  repository: string;
  branch: string;
  objective_chars: number;
  changed_count: number;
  prompt_chars: number;
  output_file: string;
}

const rows: Row[] = [];

for (let i = 1; i < lines.length; i++) {
  const cols = lines[i].split(',');
  if (cols.length < headers.length) continue;

  const ts = new Date(cols[0]);
  if (ts >= cutoff) {
    rows.push({
      timestamp: cols[0],
      event: cols[1] || '',
      repository: cols[2] || '',
      branch: cols[3] || '',
      objective_chars: parseInt(cols[4] || '0', 10),
      changed_count: parseInt(cols[5] || '0', 10),
      prompt_chars: parseInt(cols[6] || '0', 10),
      output_file: cols[7] || '',
    });
  }
}

if (rows.length === 0) {
  console.log(`[INFO] No context usage records in the last ${days} days.`);
  process.exit(0);
}

const total = rows.length;
const compactCount = rows.filter((r) => r.event === 'compact-start').length;
const packCount = rows.filter((r) => r.event === 'context-pack').length;
const avgObjective = Math.round(rows.reduce((s, r) => s + r.objective_chars, 0) / rows.length);
const avgPrompt = Math.round(rows.reduce((s, r) => s + r.prompt_chars, 0) / rows.length);

console.log(`Context Metrics (last ${days} days)`);
console.log(`  Total events: ${total}`);
console.log(`  context-pack: ${packCount}`);
console.log(`  compact-start: ${compactCount}`);
console.log(`  Avg objective chars: ${avgObjective}`);
console.log(`  Avg prompt chars: ${avgPrompt}`);
console.log('');

// Group by day
const byDay = new Map<string, Row[]>();
for (const row of rows) {
  const day = new Date(row.timestamp).toISOString().substring(0, 10);
  const existing = byDay.get(day) || [];
  existing.push(row);
  byDay.set(day, existing);
}

console.log('Daily usage:');
const sortedDays = [...byDay.keys()].sort();
for (const day of sortedDays) {
  const dayRows = byDay.get(day)!;
  const dTotal = dayRows.length;
  const dCompact = dayRows.filter((r) => r.event === 'compact-start').length;
  const dPack = dayRows.filter((r) => r.event === 'context-pack').length;
  console.log(`  ${day}: total=${dTotal}, context-pack=${dPack}, compact-start=${dCompact}`);
}
