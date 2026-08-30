import Database from 'better-sqlite3';
import { existsSync, mkdirSync } from 'fs';
import { join, resolve } from 'path';
import type { AnalyticsReport } from '../src/types';

const ROOT = resolve(process.cwd(), '../..');
const RUNTIME_DIR = join(ROOT, '.runtime');
const DB_PATH = join(RUNTIME_DIR, 'gentle-vanguard.db');

export interface ReportListItem {
  id: string;
  createdAt: string;
  mode: string;
  summary: string;
  input: string;
}

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
    CREATE TABLE IF NOT EXISTS gv_analytics_reports (
      id TEXT PRIMARY KEY,
      created_at TEXT NOT NULL,
      mode TEXT NOT NULL,
      input TEXT NOT NULL,
      summary TEXT NOT NULL,
      report_json TEXT NOT NULL
    )
  `);
  return db;
}

export function saveReport(report: AnalyticsReport): void {
  getDb()
    .prepare(
      `INSERT OR REPLACE INTO gv_analytics_reports
        (id, created_at, mode, input, summary, report_json)
       VALUES (?, ?, ?, ?, ?, ?)`,
    )
    .run(
      report.id,
      report.createdAt,
      report.mode,
      report.input,
      report.summary,
      JSON.stringify(report),
    );
}

export function listReports(limit = 25): ReportListItem[] {
  const rows = getDb()
    .prepare(
      `SELECT id, created_at, mode, input, summary
       FROM gv_analytics_reports
       ORDER BY created_at DESC
       LIMIT ?`,
    )
    .all(Math.min(Math.max(limit, 1), 100)) as Array<Record<string, unknown>>;
  return rows.map((row) => ({
    id: String(row.id),
    createdAt: String(row.created_at),
    mode: String(row.mode),
    summary: String(row.summary),
    input: String(row.input),
  }));
}

export function getReport(id: string): AnalyticsReport | null {
  const row = getDb()
    .prepare('SELECT report_json FROM gv_analytics_reports WHERE id = ?')
    .get(id) as Record<string, unknown> | undefined;
  if (!row) return null;
  return JSON.parse(String(row.report_json)) as AnalyticsReport;
}

export function deleteReport(id: string): boolean {
  const result = getDb().prepare('DELETE FROM gv_analytics_reports WHERE id = ?').run(id);
  return result.changes > 0;
}

export function deleteReports(ids: string[]): number {
  if (ids.length === 0) return 0;
  // Chunk to stay well under SQLite's bound-parameter limit.
  let deleted = 0;
  for (let i = 0; i < ids.length; i += 100) {
    const chunk = ids.slice(i, i + 100);
    const placeholders = chunk.map(() => '?').join(',');
    const result = getDb()
      .prepare(`DELETE FROM gv_analytics_reports WHERE id IN (${placeholders})`)
      .run(...chunk);
    deleted += result.changes;
  }
  return deleted;
}

export function deleteAllReports(): number {
  return getDb().prepare('DELETE FROM gv_analytics_reports').run().changes;
}
