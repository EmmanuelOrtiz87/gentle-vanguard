#!/usr/bin/env node
/**
 * Token Metrics Store — JSON-based token usage database and aggregation.
 * TS migration of scripts/utilities/token/token-metrics-store.ps1
 *
 * Actions: init, record, query, aggregate, dashboard
 */

import * as fs from 'fs';
import * as path from 'path';
import { pathToFileURL } from 'url';

const ROOT = path.resolve(process.cwd());
const RUNTIME_DIR = path.join(ROOT, '.runtime');
const DB_PATH = path.join(RUNTIME_DIR, 'metrics.json');

interface TokenRecord {
  id: number;
  session_id: string;
  date: string;
  tokens_used: number;
  cost_usd: number;
  model: string;
  provider: string;
  created_at: string;
}

interface TokenDb {
  token_usage: TokenRecord[];
  version: string;
}

interface AggregatedRow {
  date?: string;
  week?: string;
  month?: string;
  total_tokens: number;
  total_cost: number;
  sessions: number;
  avg_daily?: number;
}

function ensureRuntimeDir(): void {
  if (!fs.existsSync(RUNTIME_DIR)) {
    fs.mkdirSync(RUNTIME_DIR, { recursive: true });
  }
}

function readDb(): TokenDb {
  ensureRuntimeDir();
  try {
    if (fs.existsSync(DB_PATH)) {
      const raw = fs.readFileSync(DB_PATH, 'utf-8');
      const db = JSON.parse(raw) as TokenDb;
      if (Array.isArray(db.token_usage)) return db;
    }
  } catch {
    const backupPath = DB_PATH.replace(/\.json$/, `.corrupted.${Date.now()}.json`);
    try { fs.copyFileSync(DB_PATH, backupPath); } catch { /* ignore */ }
    console.warn(`[METRICS-STORE] Corrupted DB, reinitializing: ${DB_PATH}`);
  }
  return { token_usage: [], version: '1.0' };
}

function writeDb(db: TokenDb): void {
  ensureRuntimeDir();
  fs.writeFileSync(DB_PATH, JSON.stringify(db, null, 2), 'utf-8');
}

function now(): string {
  return new Date().toISOString();
}

function todayDate(): string {
  return new Date().toISOString().slice(0, 10);
}

function initDb(): void {
  const db = readDb();
  if (!Array.isArray(db.token_usage)) db.token_usage = [];
  writeDb(db);
  console.log(`[METRICS-STORE] Database initialized: ${DB_PATH}`);
}

function recordUsage(sessionId: string, tokens: number, cost: number): void {
  const db = readDb();
  const record: TokenRecord = {
    id: db.token_usage.length + 1,
    session_id: sessionId,
    date: todayDate(),
    tokens_used: tokens,
    cost_usd: cost,
    model: process.env.AI_MODEL || 'unknown',
    provider: process.env.AI_PROVIDER || 'unknown',
    created_at: now(),
  };
  db.token_usage.push(record);
  writeDb(db);
  console.log(`[METRICS-STORE] Recorded: ${tokens} tokens, $${cost} for session ${sessionId}`);
}

function queryHistory(days: number): AggregatedRow[] {
  const db = readDb();
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - days);
  const cutoffStr = cutoff.toISOString().slice(0, 10);

  const filtered = db.token_usage.filter((r) => r.date >= cutoffStr);
  const grouped = new Map<string, { tokens: number; cost: number; sessions: Set<string> }>();

  for (const r of filtered) {
    let g = grouped.get(r.date);
    if (!g) {
      g = { tokens: 0, cost: 0, sessions: new Set() };
      grouped.set(r.date, g);
    }
    g.tokens += r.tokens_used;
    g.cost += r.cost_usd;
    g.sessions.add(r.session_id);
  }

  return Array.from(grouped.entries())
    .map(([date, g]) => ({
      date,
      total_tokens: g.tokens,
      total_cost: g.cost,
      sessions: g.sessions.size,
    }))
    .sort((a, b) => (a.date ?? '').localeCompare(b.date ?? ''));
}

function getWeeklyData(): AggregatedRow[] {
  const db = readDb();
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 84);
  const cutoffStr = cutoff.toISOString().slice(0, 10);

  const filtered = db.token_usage.filter((r) => r.date >= cutoffStr);
  const grouped = new Map<string, { tokens: number; cost: number; sessions: Set<string>; counts: number[] }>();

  for (const r of filtered) {
    const d = new Date(r.date);
    const weekKey = `${d.getFullYear()}-W${String(Math.ceil((d.getDate() + 6 - d.getDay()) / 7)).padStart(2, '0')}`;
    let g = grouped.get(weekKey);
    if (!g) {
      g = { tokens: 0, cost: 0, sessions: new Set(), counts: [] };
      grouped.set(weekKey, g);
    }
    g.tokens += r.tokens_used;
    g.cost += r.cost_usd;
    g.sessions.add(r.session_id);
    g.counts.push(r.tokens_used);
  }

  return Array.from(grouped.entries())
    .map(([week, g]) => ({
      week,
      total_tokens: g.tokens,
      total_cost: g.cost,
      sessions: g.sessions.size,
      avg_daily: g.counts.length > 0 ? Math.round(g.tokens / g.counts.length) : 0,
    }))
    .sort((a, b) => (a.week ?? '').localeCompare(b.week ?? ''));
}

function getMonthlyData(): AggregatedRow[] {
  const db = readDb();
  const cutoff = new Date();
  cutoff.setMonth(cutoff.getMonth() - 6);
  const cutoffStr = cutoff.toISOString().slice(0, 10);

  const filtered = db.token_usage.filter((r) => r.date >= cutoffStr);
  const grouped = new Map<string, { tokens: number; cost: number; sessions: Set<string>; counts: number[] }>();

  for (const r of filtered) {
    const monthKey = r.date.slice(0, 7);
    let g = grouped.get(monthKey);
    if (!g) {
      g = { tokens: 0, cost: 0, sessions: new Set(), counts: [] };
      grouped.set(monthKey, g);
    }
    g.tokens += r.tokens_used;
    g.cost += r.cost_usd;
    g.sessions.add(r.session_id);
    g.counts.push(r.tokens_used);
  }

  return Array.from(grouped.entries())
    .map(([month, g]) => ({
      month,
      total_tokens: g.tokens,
      total_cost: g.cost,
      sessions: g.sessions.size,
      avg_daily: g.counts.length > 0 ? Math.round(g.tokens / g.counts.length) : 0,
    }))
    .sort((a, b) => (a.month ?? '').localeCompare(b.month ?? ''));
}

function getDashboardData(): Record<string, unknown> {
  const daily = queryHistory(30);
  const weekly = getWeeklyData();
  const monthly = getMonthlyData();
  const today = todayDate();
  const db = readDb();
  const todayRecords = db.token_usage.filter((r) => r.date === today);
  const todayTokens = todayRecords.reduce((s, r) => s + r.tokens_used, 0);
  const todayCost = todayRecords.reduce((s, r) => s + r.cost_usd, 0);

  return {
    daily,
    weekly,
    monthly,
    today: { tokens: todayTokens, cost: todayCost },
    generatedAt: now(),
  };
}

function main(): void {
  const args = process.argv.slice(2);
  const actionIdx = args.indexOf('--action');
  const action = actionIdx >= 0 ? args[actionIdx + 1] : (args[0] || 'query');
  const sessionId = extractArg(args, '--session-id');
  const tokens = parseInt(extractArg(args, '--tokens') || '0', 10);
  const cost = parseFloat(extractArg(args, '--cost') || '0');
  const days = parseInt(extractArg(args, '--days') || '30', 10);
  const asJson = args.includes('--json') || args.includes('-AsJson');

  const result: Record<string, unknown> = { action, timestamp: now() };

  switch (action) {
    case 'init':
      initDb();
      result.status = 'initialized';
      result.dbPath = DB_PATH;
      break;

    case 'record':
      if (!sessionId) { console.error('-SessionId required'); process.exit(1); }
      if (tokens <= 0) { console.error('-Tokens must be > 0'); process.exit(1); }
      recordUsage(sessionId, tokens, cost);
      result.status = 'recorded';
      result.sessionId = sessionId;
      result.tokens = tokens;
      result.cost = cost;
      break;

    case 'query': {
      const data = queryHistory(days);
      result.status = 'queried';
      result.days = days;
      result.records = data;
      if (!asJson) {
        console.log(`\n=== Token History (last ${days} days) ===`);
        console.table(data);
      }
      break;
    }

    case 'aggregate': {
      const weekly = getWeeklyData();
      const monthly = getMonthlyData();
      result.status = 'aggregated';
      result.weekly = weekly;
      result.monthly = monthly;
      if (!asJson) {
        console.log('\n=== Weekly Aggregates ===');
        console.table(weekly);
        console.log('\n=== Monthly Aggregates ===');
        console.table(monthly);
      }
      break;
    }

    case 'dashboard':
      result.status = 'dashboard';
      result.data = getDashboardData();
      break;

    default:
      console.error(`Unknown action: ${action}`);
      process.exit(1);
  }

  if (asJson) console.log(JSON.stringify(result, null, 2));
}

function extractArg(args: string[], name: string): string | undefined {
  const idx = args.indexOf(name);
  return idx >= 0 ? args[idx + 1] : undefined;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
