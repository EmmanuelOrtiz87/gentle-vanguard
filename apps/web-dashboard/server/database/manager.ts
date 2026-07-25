/**
 * DatabaseManager — SQLite persistence layer for Gentle-Vanguard
 *
 * Singleton that manages:
 * - SQLite connection (`.runtime/gentle-vanguard.db`)
 * - Schema migrations (tracked in `_migrations` table)
 * - CRUD helpers for metrics, sessions, traces, events, alerts, feedback
 *
 * Replaces the fragmented JSON-file persistence with a single ACID database.
 */
import Database from 'better-sqlite3';
import { join, dirname } from 'path';
import { existsSync, mkdirSync } from 'fs';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = join(__dirname, '..', '..', '..', '..');
const DB_DIR = join(ROOT, '.runtime');
const DB_PATH = join(DB_DIR, 'gentle-vanguard.db');

// ─── Types ────────────────────────────────────────────────────────────

export interface MetricSnapshot {
  id?: number;
  timestamp: string;
  tokens_used: number;
  tokens_limit: number;
  cost: number;
  sessions_total: number;
  sessions_active: number;
  sessions_today: number;
  latency_avg: number;
  latency_p50: number;
  latency_p95: number;
  commits: number;
  mcp_calls: number;
  mcp_skills: number;
  health_status: string;
}

export interface SessionRecord {
  id: string;
  agent: string;
  status: string;
  created_at: string;
  updated_at: string;
  tokens_used: number;
  cost: number;
  message_count: number;
  metadata?: string;
}

export interface TraceRecord {
  span_id: string;
  trace_id: string;
  parent_span_id?: string;
  name: string;
  start_time: number;
  end_time?: number;
  duration?: number;
  status: string;
  model?: string;
  input_tokens: number;
  output_tokens: number;
  cost: number;
  session_id?: string;
  attributes?: string;
}

export interface EventRecord {
  id?: number;
  type: string;
  payload?: string;
  created_at: string;
}

export interface AlertRecord {
  id?: number;
  name: string;
  rule: string;
  severity: string;
  triggered: number;
  actual: number;
  threshold: number;
  transition?: string;
  created_at: string;
}

export interface FeedbackRecord {
  id?: number;
  trace_id: string;
  span_id: string;
  type: 'up' | 'down';
  created_at: string;
}

// ─── Migrations ───────────────────────────────────────────────────────

const MIGRATIONS: Array<{ id: string; sql: string }> = [
  {
    id: '001_initial_schema',
    sql: `
      -- Metric snapshots (time-series, written every 30s)
      CREATE TABLE IF NOT EXISTS metric_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL DEFAULT (datetime('now')),
        tokens_used INTEGER DEFAULT 0,
        tokens_limit INTEGER DEFAULT 120000,
        cost REAL DEFAULT 0,
        sessions_total INTEGER DEFAULT 0,
        sessions_active INTEGER DEFAULT 0,
        sessions_today INTEGER DEFAULT 0,
        latency_avg REAL DEFAULT 0,
        latency_p50 REAL DEFAULT 0,
        latency_p95 REAL DEFAULT 0,
        commits INTEGER DEFAULT 0,
        mcp_calls INTEGER DEFAULT 0,
        mcp_skills INTEGER DEFAULT 0,
        health_status TEXT DEFAULT 'unknown'
      );

      -- Session history (upserted on session create/update)
      CREATE TABLE IF NOT EXISTS sessions (
        id TEXT PRIMARY KEY,
        agent TEXT NOT NULL,
        status TEXT DEFAULT 'idle',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        tokens_used INTEGER DEFAULT 0,
        cost REAL DEFAULT 0,
        message_count INTEGER DEFAULT 0,
        metadata TEXT
      );

      -- Trace spans (written during session execution)
      CREATE TABLE IF NOT EXISTS traces (
        span_id TEXT PRIMARY KEY,
        trace_id TEXT NOT NULL,
        parent_span_id TEXT,
        name TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        duration INTEGER,
        status TEXT DEFAULT 'running',
        model TEXT,
        input_tokens INTEGER DEFAULT 0,
        output_tokens INTEGER DEFAULT 0,
        cost REAL DEFAULT 0,
        session_id TEXT,
        attributes TEXT
      );

      -- Event store (event sourcing)
      CREATE TABLE IF NOT EXISTS events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        payload TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      );

      -- Alert evaluations (written every 5s broadcast)
      CREATE TABLE IF NOT EXISTS alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        rule TEXT,
        severity TEXT,
        triggered INTEGER DEFAULT 0,
        actual REAL,
        threshold REAL,
        transition TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      );

      -- User feedback (written on POST /api/feedback)
      CREATE TABLE IF NOT EXISTS feedback (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trace_id TEXT NOT NULL,
        span_id TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL CHECK(type IN ('up', 'down')),
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      );

      -- Indexes for common queries
      CREATE INDEX IF NOT EXISTS idx_metric_snapshots_ts ON metric_snapshots(timestamp);
      CREATE INDEX IF NOT EXISTS idx_sessions_status ON sessions(status);
      CREATE INDEX IF NOT EXISTS idx_sessions_agent ON sessions(agent);
      CREATE INDEX IF NOT EXISTS idx_traces_trace_id ON traces(trace_id);
      CREATE INDEX IF NOT EXISTS idx_traces_session_id ON traces(session_id);
      CREATE INDEX IF NOT EXISTS idx_traces_status ON traces(status);
      CREATE INDEX IF NOT EXISTS idx_events_type ON events(type);
      CREATE INDEX IF NOT EXISTS idx_events_created ON events(created_at);
      CREATE INDEX IF NOT EXISTS idx_alerts_name ON alerts(name);
      CREATE INDEX IF NOT EXISTS idx_feedback_span ON feedback(span_id);
    `,
  },
  {
    id: '002_stack_tables',
    sql: `
      -- Response cache (SHA256 key → response, TTL-aware)
      CREATE TABLE IF NOT EXISTS response_cache (
        key TEXT PRIMARY KEY,
        response TEXT NOT NULL,
        model TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        expires_at TEXT,
        hit_count INTEGER DEFAULT 0
      );

      -- Contract results (SDD contract validation)
      CREATE TABLE IF NOT EXISTS contract_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contract_id TEXT NOT NULL,
        session_id TEXT,
        status TEXT NOT NULL CHECK(status IN ('pass', 'fail', 'error', 'pending')),
        result TEXT,
        duration_ms INTEGER,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      );

      -- Skill usage tracking
      CREATE TABLE IF NOT EXISTS skill_usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        skill_id TEXT NOT NULL,
        session_id TEXT,
        count INTEGER DEFAULT 1,
        tokens_used INTEGER DEFAULT 0,
        cost REAL DEFAULT 0,
        last_used TEXT NOT NULL DEFAULT (datetime('now')),
        UNIQUE(skill_id, session_id)
      );

      -- Token usage per session
      CREATE TABLE IF NOT EXISTS token_usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        prompt_tokens INTEGER DEFAULT 0,
        completion_tokens INTEGER DEFAULT 0,
        total_tokens INTEGER GENERATED ALWAYS AS (prompt_tokens + completion_tokens) STORED,
        cost REAL DEFAULT 0,
        model TEXT,
        timestamp TEXT NOT NULL DEFAULT (datetime('now'))
      );

      -- Routing rules (adaptive router persistence)
      CREATE TABLE IF NOT EXISTS routing_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pattern TEXT NOT NULL,
        target TEXT NOT NULL,
        priority INTEGER DEFAULT 0,
        enabled INTEGER DEFAULT 1,
        hit_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      );

      -- Indexes for stack tables
      CREATE INDEX IF NOT EXISTS idx_response_cache_expires ON response_cache(expires_at);
      CREATE INDEX IF NOT EXISTS idx_contract_results_session ON contract_results(session_id);
      CREATE INDEX IF NOT EXISTS idx_contract_results_status ON contract_results(status);
      CREATE INDEX IF NOT EXISTS idx_skill_usage_skill ON skill_usage(skill_id);
      CREATE INDEX IF NOT EXISTS idx_token_usage_session ON token_usage(session_id);
      CREATE INDEX IF NOT EXISTS idx_token_usage_ts ON token_usage(timestamp);
      CREATE INDEX IF NOT EXISTS idx_routing_rules_pattern ON routing_rules(pattern);
    `,
  },
];

// ─── DatabaseManager ──────────────────────────────────────────────────

export class DatabaseManager {
  private db: Database.Database;
  private static instance: DatabaseManager;

  private constructor() {
    // Ensure the DB directory exists
    if (!existsSync(DB_DIR)) {
      mkdirSync(DB_DIR, { recursive: true });
    }
    this.db = new Database(DB_PATH);
    this.db.pragma('journal_mode = WAL');
    this.db.pragma('foreign_keys = ON');
    this.runMigrations();
  }

  /** Get or create the singleton instance */
  static getInstance(): DatabaseManager {
    if (!DatabaseManager.instance) {
      DatabaseManager.instance = new DatabaseManager();
    }
    return DatabaseManager.instance;
  }

  /** Run all pending migrations (idempotent) */
  runMigrations(): void {
    // Create migrations tracking table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS _migrations (
        id TEXT PRIMARY KEY,
        applied_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    `);

    // Get applied migrations
    const applied = new Set(
      this.db
        .prepare('SELECT id FROM _migrations')
        .all()
        .map((r: any) => r.id),
    );

    // Apply pending migrations
    for (const migration of MIGRATIONS) {
      if (!applied.has(migration.id)) {
        this.db.exec(migration.sql);
        this.db
          .prepare('INSERT INTO _migrations (id) VALUES (?)')
          .run(migration.id);
        console.log(`[DB] Migration applied: ${migration.id}`);
      }
    }
    console.log(`[DB] ${this.db.pragma('page_count', { simple: true })} pages, ${MIGRATIONS.length} migrations`);
  }

  /** Get the raw Database instance (for advanced queries) */
  getDb(): Database.Database {
    return this.db;
  }

  /** Check if the DB has data */
  hasData(): boolean {
    const row = this.db
      .prepare("SELECT COUNT(*) as count FROM metric_snapshots")
      .get() as { count: number };
    return row.count > 0;
  }

  // ─── Metric Snapshots ───────────────────────────────────────────────

  insertMetricSnapshot(data: Partial<MetricSnapshot>): void {
    this.db
      .prepare(
        `INSERT INTO metric_snapshots 
         (timestamp, tokens_used, tokens_limit, cost, sessions_total, 
          sessions_active, sessions_today, latency_avg, latency_p50, latency_p95,
          commits, mcp_calls, mcp_skills, health_status)
         VALUES (datetime('now'), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      )
      .run(
        data.tokens_used ?? 0,
        data.tokens_limit ?? 120000,
        data.cost ?? 0,
        data.sessions_total ?? 0,
        data.sessions_active ?? 0,
        data.sessions_today ?? 0,
        data.latency_avg ?? 0,
        data.latency_p50 ?? 0,
        data.latency_p95 ?? 0,
        data.commits ?? 0,
        data.mcp_calls ?? 0,
        data.mcp_skills ?? 0,
        data.health_status ?? 'unknown',
      );
  }

  getLatestMetricSnapshot(): MetricSnapshot | null {
    const row = this.db
      .prepare('SELECT * FROM metric_snapshots ORDER BY timestamp DESC LIMIT 1')
      .get() as MetricSnapshot | undefined;
    return row ?? null;
  }

  getMetricHistory(limit = 20): MetricSnapshot[] {
    return this.db
      .prepare('SELECT * FROM metric_snapshots ORDER BY timestamp DESC LIMIT ?')
      .all(limit) as MetricSnapshot[];
  }

  /** Delete old snapshots, keeping only the most recent N */
  pruneMetricSnapshots(keep = 1440): void {
    this.db
      .prepare(
        `DELETE FROM metric_snapshots WHERE id NOT IN (
          SELECT id FROM metric_snapshots ORDER BY timestamp DESC LIMIT ?
        )`,
      )
      .run(keep);
  }

  // ─── Sessions ───────────────────────────────────────────────────────

  upsertSession(session: Partial<SessionRecord>): void {
    if (!session.id) throw new Error('Session ID is required');
    this.db
      .prepare(
        `INSERT INTO sessions (id, agent, status, created_at, updated_at, tokens_used, cost, message_count, metadata)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(id) DO UPDATE SET
           status = excluded.status,
           updated_at = excluded.updated_at,
           tokens_used = excluded.tokens_used,
           cost = excluded.cost,
           message_count = excluded.message_count,
           metadata = excluded.metadata`,
      )
      .run(
        session.id,
        session.agent ?? 'unknown',
        session.status ?? 'idle',
        session.created_at ?? new Date().toISOString(),
        session.updated_at ?? new Date().toISOString(),
        session.tokens_used ?? 0,
        session.cost ?? 0,
        session.message_count ?? 0,
        session.metadata ?? null,
      );
  }

  getActiveSessions(): SessionRecord[] {
    return this.db
      .prepare(
        "SELECT * FROM sessions WHERE status IN ('active', 'awaiting_input') ORDER BY updated_at DESC",
      )
      .all() as SessionRecord[];
  }

  getAllSessions(): SessionRecord[] {
    return this.db
      .prepare('SELECT * FROM sessions ORDER BY updated_at DESC')
      .all() as SessionRecord[];
  }

  getSessionsToday(): SessionRecord[] {
    return this.db
      .prepare(
        "SELECT * FROM sessions WHERE date(created_at) = date('now') ORDER BY updated_at DESC",
      )
      .all() as SessionRecord[];
  }

  // ─── Traces ─────────────────────────────────────────────────────────

  insertTrace(trace: Partial<TraceRecord>): void {
    if (!trace.span_id) throw new Error('span_id is required');
    this.db
      .prepare(
        `INSERT OR REPLACE INTO traces 
         (span_id, trace_id, parent_span_id, name, start_time, end_time, duration,
          status, model, input_tokens, output_tokens, cost, session_id, attributes)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      )
      .run(
        trace.span_id,
        trace.trace_id ?? '',
        trace.parent_span_id ?? null,
        trace.name ?? '',
        trace.start_time ?? Date.now(),
        trace.end_time ?? null,
        trace.duration ?? null,
        trace.status ?? 'running',
        trace.model ?? null,
        trace.input_tokens ?? 0,
        trace.output_tokens ?? 0,
        trace.cost ?? 0,
        trace.session_id ?? null,
        trace.attributes ?? null,
      );
  }

  getTracesBySession(sessionId: string): TraceRecord[] {
    return this.db
      .prepare('SELECT * FROM traces WHERE session_id = ? ORDER BY start_time ASC')
      .all(sessionId) as TraceRecord[];
  }

  getLatencyStats(): { avg: number; p50: number; p95: number; count: number } {
    const stats = this.db
      .prepare(
        `SELECT 
           AVG(duration) as avg,
           COUNT(*) as count
         FROM traces WHERE duration > 0 AND status = 'completed'`,
      )
      .get() as { avg: number | null; count: number };

    const count = stats.count || 0;
    if (count === 0) return { avg: 0, p50: 0, p95: 0, count: 0 };

    // Percentiles
    const durations = this.db
      .prepare(
        `SELECT duration FROM traces 
         WHERE duration > 0 AND status = 'completed' 
         ORDER BY duration ASC`,
      )
      .all() as { duration: number }[];

    const values = durations.map((r) => r.duration);
    const p50 = values[Math.floor(values.length * 0.5)] || 0;
    const p95 = values[Math.floor(values.length * 0.95)] || 0;

    return {
      avg: Math.round(stats.avg ?? 0),
      p50,
      p95,
      count,
    };
  }

  // ─── Events ─────────────────────────────────────────────────────────

  insertEvent(type: string, payload?: unknown): void {
    this.db
      .prepare(
        'INSERT INTO events (type, payload, created_at) VALUES (?, ?, datetime(\'now\'))',
      )
      .run(type, payload ? JSON.stringify(payload) : null);
  }

  getRecentEvents(limit = 50): EventRecord[] {
    return this.db
      .prepare('SELECT * FROM events ORDER BY created_at DESC LIMIT ?')
      .all(limit) as EventRecord[];
  }

  // ─── Alerts ─────────────────────────────────────────────────────────

  insertAlert(alert: Omit<AlertRecord, 'id' | 'created_at'>): void {
    this.db
      .prepare(
        `INSERT INTO alerts (name, rule, severity, triggered, actual, threshold, transition, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))`,
      )
      .run(
        alert.name,
        alert.rule,
        alert.severity,
        alert.triggered ? 1 : 0,
        alert.actual,
        alert.threshold,
        alert.transition ?? null,
      );
  }

  getRecentAlerts(limit = 20): AlertRecord[] {
    return this.db
      .prepare('SELECT * FROM alerts ORDER BY created_at DESC LIMIT ?')
      .all(limit) as AlertRecord[];
  }

  getTriggeredAlerts(): AlertRecord[] {
    return this.db
      .prepare(
        "SELECT * FROM alerts WHERE triggered = 1 ORDER BY created_at DESC LIMIT 10",
      )
      .all() as AlertRecord[];
  }

  // ─── Feedback ───────────────────────────────────────────────────────

  insertFeedback(fb: Omit<FeedbackRecord, 'id' | 'created_at'>): void {
    this.db
      .prepare(
        `INSERT OR REPLACE INTO feedback (trace_id, span_id, type, created_at)
         VALUES (?, ?, ?, datetime('now'))`,
      )
      .run(fb.trace_id, fb.span_id, fb.type);
  }

  getFeedbackStats(): { thumbsUp: number; thumbsDown: number; total: number; score: number } {
    const stats = this.db
      .prepare(
        `SELECT 
           SUM(CASE WHEN type = 'up' THEN 1 ELSE 0 END) as thumbsUp,
           SUM(CASE WHEN type = 'down' THEN 1 ELSE 0 END) as thumbsDown
         FROM feedback`,
      )
      .get() as { thumbsUp: number | null; thumbsDown: number | null };
    const up = stats.thumbsUp ?? 0;
    const down = stats.thumbsDown ?? 0;
    const total = up + down;
    return {
      thumbsUp: up,
      thumbsDown: down,
      total,
      score: total > 0 ? Math.round((up / total) * 100) : 0,
    };
  }

  // ─── Housekeeping ───────────────────────────────────────────────────

  /** Prune old data, keeping the DB lean */
  housekeeping(): void {
    // Keep only last 7 days of events
    this.db.exec("DELETE FROM events WHERE created_at < datetime('now', '-7 days')");
    // Keep only last 1000 metric snapshots
    this.pruneMetricSnapshots(1000);
    // Keep only last 500 alerts
    this.db.exec(
      `DELETE FROM alerts WHERE id NOT IN (SELECT id FROM alerts ORDER BY created_at DESC LIMIT 500)`,
    );
    // Vacuum once a week (approximately every 500th write)
    const count = (this.db.prepare('SELECT COUNT(*) as c FROM metric_snapshots').get() as any).c;
    if (count % 500 === 0 && count > 0) {
      this.db.exec('VACUUM');
      console.log('[DB] Vacuum completed');
    }
    console.log('[DB] Housekeeping done');
  }

  /** Close the database connection */
  close(): void {
    this.db.close();
    console.log('[DB] Connection closed');
  }
}
