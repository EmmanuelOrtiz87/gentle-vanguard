/**
 * Gentle-Vanguard Analytics — Metrics store.
 *
 * Tracks request-level metrics (latency, status, model source, cache hit) in
 * the shared Nexus DB. Provides aggregate summaries for the dashboard widget
 * and per-day/per-hour breakdowns for trend reporting.
 *
 * Schema (gv_analytics_metrics):
 *   id          INTEGER PRIMARY KEY AUTOINCREMENT
 *   created_at  TEXT    ISO-8601
 *   endpoint    TEXT    e.g. "/api/analyze", "/api/reports"
 *   status      INTEGER HTTP status
 *   duration_ms INTEGER
 *   llm_source  TEXT    "agent" | "cache" | "fallback" | "heuristic" | null
 *   llm_cached  INTEGER 0/1
 *   metadata    TEXT    JSON blob (free-form)
 */

import Database from 'better-sqlite3';
import { existsSync, mkdirSync } from 'fs';
import { join, resolve } from 'path';

const ROOT = resolve(process.cwd(), '../..');
const RUNTIME_DIR = join(ROOT, '.runtime');
const DB_PATH = join(RUNTIME_DIR, 'gentle-vanguard.db');

let db: Database.Database | null = null;

function getDb(): Database.Database {
  if (db) return db;
  if (!existsSync(RUNTIME_DIR)) {
    mkdirSync(RUNTIME_DIR, { recursive: true });
  }
  db = new Database(DB_PATH);
  db.pragma('busy_timeout = 5000');
  db.pragma('journal_mode = WAL');
  db.exec(`
    CREATE TABLE IF NOT EXISTS gv_analytics_metrics (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      created_at TEXT NOT NULL,
      endpoint TEXT NOT NULL,
      status INTEGER NOT NULL,
      duration_ms INTEGER NOT NULL,
      llm_source TEXT,
      llm_cached INTEGER NOT NULL DEFAULT 0,
      metadata TEXT
    );
    CREATE INDEX IF NOT EXISTS gv_analytics_metrics_created_idx
      ON gv_analytics_metrics(created_at);
    CREATE INDEX IF NOT EXISTS gv_analytics_metrics_endpoint_idx
      ON gv_analytics_metrics(endpoint);
  `);
  return db;
}

export interface MetricEntry {
  endpoint: string;
  status: number;
  durationMs: number;
  llmSource?: 'agent' | 'cache' | 'fallback' | 'heuristic' | null;
  llmCached?: boolean;
  metadata?: Record<string, unknown>;
}

export function recordMetric(entry: MetricEntry): void {
  try {
    getDb()
      .prepare(
        `INSERT INTO gv_analytics_metrics
          (created_at, endpoint, status, duration_ms, llm_source, llm_cached, metadata)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
      )
      .run(
        new Date().toISOString(),
        entry.endpoint,
        entry.status,
        Math.max(0, Math.round(entry.durationMs)),
        entry.llmSource ?? null,
        entry.llmCached ? 1 : 0,
        entry.metadata ? JSON.stringify(entry.metadata) : null,
      );
  } catch (error) {
    // Metrics are best-effort: never break a request because of a metric write.
    console.warn(`[gv-analytics] metric write failed: ${(error as Error).message}`);
  }
}

export interface MetricsSummary {
  totals: {
    requests: number;
    analyzeRequests: number;
    errorCount: number;
    errorRate: number;
    llmHits: number;
    cacheHits: number;
    fallbackHits: number;
    heuristicHits: number;
  };
  latencyMs: {
    p50: number;
    p95: number;
    mean: number;
  };
  windowHours: number;
  byEndpoint: Array<{ endpoint: string; count: number; errors: number; meanMs: number }>;
  bySource: Array<{ source: string; count: number }>;
}

function percentile(values: number[], p: number): number {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const idx = Math.min(sorted.length - 1, Math.floor(sorted.length * p));
  return sorted[idx];
}

export function summarize(windowHours = 24): MetricsSummary {
  const since = new Date(Date.now() - windowHours * 3_600_000).toISOString();
  const rows = getDb()
    .prepare(
      `SELECT endpoint, status, duration_ms, llm_source, llm_cached
       FROM gv_analytics_metrics
       WHERE created_at >= ?
       ORDER BY created_at DESC`,
    )
    .all(since) as Array<Record<string, unknown>>;

  const totals = {
    requests: rows.length,
    analyzeRequests: 0,
    errorCount: 0,
    errorRate: 0,
    llmHits: 0,
    cacheHits: 0,
    fallbackHits: 0,
    heuristicHits: 0,
  };
  const latencies: number[] = [];
  const endpointMap = new Map<string, { count: number; errors: number; latencies: number[] }>();
  const sourceMap = new Map<string, number>();

  for (const row of rows) {
    const endpoint = String(row.endpoint);
    const status = Number(row.status);
    const duration = Number(row.duration_ms);
    const llmSource = row.llm_source ? String(row.llm_source) : null;
    const llmCached = Number(row.llm_cached) === 1;

    if (endpoint === '/api/analyze') totals.analyzeRequests += 1;
    if (status >= 400) totals.errorCount += 1;
    if (llmSource === 'agent' || llmSource === 'cache') totals.llmHits += 1;
    if (llmSource === 'cache') totals.cacheHits += 1;
    if (llmSource === 'fallback') totals.fallbackHits += 1;
    if (llmSource === 'heuristic') totals.heuristicHits += 1;
    latencies.push(duration);

    const slot = endpointMap.get(endpoint) ?? { count: 0, errors: 0, latencies: [] };
    slot.count += 1;
    if (status >= 400) slot.errors += 1;
    slot.latencies.push(duration);
    endpointMap.set(endpoint, slot);

    if (llmSource) {
      sourceMap.set(llmSource, (sourceMap.get(llmSource) ?? 0) + 1);
    }
  }

  totals.errorRate = totals.requests > 0 ? totals.errorCount / totals.requests : 0;

  return {
    totals,
    latencyMs: {
      p50: percentile(latencies, 0.5),
      p95: percentile(latencies, 0.95),
      mean:
        latencies.length > 0
          ? Math.round(latencies.reduce((a, b) => a + b, 0) / latencies.length)
          : 0,
    },
    windowHours,
    byEndpoint: Array.from(endpointMap.entries()).map(([endpoint, slot]) => ({
      endpoint,
      count: slot.count,
      errors: slot.errors,
      meanMs:
        slot.latencies.length > 0
          ? Math.round(slot.latencies.reduce((a, b) => a + b, 0) / slot.latencies.length)
          : 0,
    })),
    bySource: Array.from(sourceMap.entries())
      .map(([source, count]) => ({ source, count }))
      .sort((a, b) => b.count - a.count),
  };
}
