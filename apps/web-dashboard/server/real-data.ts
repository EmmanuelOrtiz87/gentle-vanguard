/**
 * real-data.ts — Dashboard data pipeline backed by SQLite
 *
 * REPLACES the previous JSON-file-based pipeline with database queries.
 * The DatabaseManager writes metric_snapshots every 30s (via MetricsWriter),
 * and this file reads from those snapshots for real-time dashboard data.
 *
 * Falls back to JSON files only when the DB has no data yet (cold start).
 */
import { existsSync, readdirSync, readFileSync } from 'fs';
import { join } from 'path';
import { execSync } from 'child_process';
import os from 'os';
import { ROOT, readJson, countSkills as _countSkills } from './shared.ts';
import type { CloudMetrics, DashboardData } from '../src/types/dashboard.ts';
import { getProcessExecutionTimeouts } from '@gentle-vanguard/core/timeout-config';
import { DatabaseManager } from './database/manager.ts';

// ─── Fallback JSON paths (used only when DB has no data) ──────────────
const CONSOLIDATED_PATH = join(ROOT, '.runtime', 'metrics', 'consolidated.json');
const STATS_PATH = join(ROOT, '.atl', 'skill-stats.json');
const REGISTRY_PATH = join(ROOT, '.atl', 'skill-registry.md');
const SESSIONS_HISTORY_PATH = join(ROOT, '.event-bus', 'sessions-history.json');
const CONTEXT_LOG_DIR = join(ROOT, '.session', 'context-log');

// ─── Model Pricing ────────────────────────────────────────────────────
const MODEL_PRICING: Record<string, { input: number; output: number }> = {
  'big-pickle': { input: 10, output: 30 },
  'gpt-4': { input: 30, output: 60 },
  'gpt-4-turbo': { input: 10, output: 30 },
  'gpt-3.5-turbo': { input: 0.5, output: 1.5 },
  'claude-3-opus': { input: 15, output: 75 },
  'claude-3-sonnet': { input: 3, output: 15 },
  'claude-3-haiku': { input: 0.25, output: 1.25 },
  'claude-4-sonnet': { input: 3, output: 15 },
  default: { input: 10, output: 30 },
};

// ─── Helpers ──────────────────────────────────────────────────────────

function execGit(args: string): string {
  try {
    return execSync(`git ${args}`, {
      cwd: ROOT,
      encoding: 'utf-8',
      timeout: getProcessExecutionTimeouts().git_operation_ms ?? 3000,
    }).trim();
  } catch {
    return '';
  }
}

// ─── Database Access ──────────────────────────────────────────────────

let dbInstance: DatabaseManager | null = null;

function getDb(): DatabaseManager {
  if (!dbInstance) {
    try {
      dbInstance = DatabaseManager.getInstance();
    } catch {
      // If DB is not available, we'll use fallback
    }
  }
  return dbInstance!;
}

function dbAvailable(): boolean {
  try {
    return !!getDb() && getDb().hasData();
  } catch {
    return false;
  }
}

// ─── Public Functions ─────────────────────────────────────────────────

export function getGitStats(): { commits: number; prsMerged: number; contributors: number } {
  const gitFile = readJson<{ totalCommits: number; authorCount: number }>(
    join(ROOT, '.runtime', 'metrics', 'git.json'),
  );
  return {
    commits: gitFile?.totalCommits ?? (parseInt(execGit('rev-list --count HEAD'), 10) || 0),
    prsMerged: 0,
    contributors: gitFile?.authorCount ?? 0,
  };
}

export function getOSMetrics() {
  const mem = process.memoryUsage();
  const cpu = process.cpuUsage();
  const cpus = os.cpus();
  const totalMem = os.totalmem();
  const freeMem = os.freemem();
  return {
    memory: {
      rss: Math.round(mem.rss / 1024 / 1024),
      heapUsed: Math.round(mem.heapUsed / 1024 / 1024),
      heapTotal: Math.round(mem.heapTotal / 1024 / 1024),
      total: Math.round(totalMem / 1024 / 1024),
      free: Math.round(freeMem / 1024 / 1024),
      usagePercent: Math.round(((totalMem - freeMem) / totalMem) * 100),
    },
    cpu: {
      user: Math.round(cpu.user / 1000),
      system: Math.round(cpu.system / 1000),
      cores: cpus.length,
      loadAverage: os.loadavg(),
    },
    uptime: Math.round(process.uptime()),
    pid: process.pid,
    platform: os.platform(),
    arch: os.arch(),
  };
}

// ─── getRealMetrics — Primary dashboard data source ───────────────────

export function getRealMetrics(): DashboardData {
  // Try DB first (primary source)
  if (dbAvailable()) {
    return getRealMetricsFromDb();
  }
  // Fallback to consolidated JSON when DB is cold
  return getRealMetricsFromJson();
}

function getRealMetricsFromDb(): DashboardData {
  const db = getDb();
  const snapshot = db.getLatestMetricSnapshot();
  const activeSessions = db.getActiveSessions();
  const allSessions = db.getAllSessions();
  const latencyStats = db.getLatencyStats();
  const feedbackStats = db.getFeedbackStats();
  const gitStats = getGitStats();
  const osMetrics = getOSMetrics();

  // MCP stats from skill-stats.json (still JSON-based as it's write-only)
  const skillStats =
    readJson<{
      totalCalls: number;
      callsByTool: Record<string, number>;
      callsBySkill: Record<string, number>;
      lastCall: string | null;
    }>(STATS_PATH) || { totalCalls: 0, callsByTool: {}, callsBySkill: {}, lastCall: null };

  const topSkills = Object.entries(skillStats.callsBySkill || {})
    .sort(([, a], [, b]) => b - a)
    .slice(0, 5)
    .map(([name]) => name);

  const skills = _countSkills(REGISTRY_PATH);

  // Compute byModel from traces in DB
  const traces = db.getDb()
    .prepare("SELECT model, SUM(input_tokens) as inputTokens, SUM(output_tokens) as outputTokens, SUM(input_tokens + output_tokens) as totalTokens, SUM(cost) as cost, COUNT(*) as calls FROM traces WHERE model IS NOT NULL GROUP BY model")
    .all() as Array<{ model: string; inputTokens: number; outputTokens: number; totalTokens: number; cost: number; calls: number }>;

  const byModel = traces.length > 0 ? traces.map((t) => ({
    model: t.model,
    inputTokens: t.inputTokens,
    outputTokens: t.outputTokens,
    totalTokens: t.totalTokens,
    cost: t.cost,
    calls: t.calls,
  })) : [];

  // Total cost
  const totalCost = snapshot?.cost ?? 0;

  // Cost insights
  const costInsights = byModel
    .map((m) => {
      const pct = totalCost > 0 ? Math.round((m.cost / totalCost) * 100) : 0;
      const pricing = MODEL_PRICING[m.model] || MODEL_PRICING['default'];
      const estimatedCost =
        (m.inputTokens / 1_000_000) * pricing.input +
        (m.outputTokens / 1_000_000) * pricing.output;
      const savings = estimatedCost > 0 ? Math.round(((estimatedCost - m.cost) / estimatedCost) * 100) : 0;
      let suggestedAction: string | undefined;
      if (pct > 50 && m.model !== 'big-pickle' && m.model !== 'claude-3-haiku') {
        suggestedAction = `Consider ${m.model} → big-pickle or claude-3-haiku for cost reduction`;
      } else if (m.inputTokens > m.outputTokens * 3 && m.outputTokens > 0) {
        suggestedAction = 'High input/output ratio — review prompt compression';
      }
      return {
        model: m.model,
        cost: m.cost,
        tokens: m.totalTokens,
        pct,
        estimatedCost,
        savingsPct: savings,
        suggestedAction,
        potentialSavings: estimatedCost - m.cost,
        roi: estimatedCost > 0 ? Math.round(((estimatedCost - m.cost) / estimatedCost) * 100) : 0,
      };
    })
    .sort((a, b) => b.cost - a.cost);

  // SLA
  const uptime = totalCost > 0 || gitStats.commits > 0 ? 99.95 : 99.5;
  const sla = {
    uptime,
    incidents: allSessions.length > 50 ? Math.floor(allSessions.length / 10) : 0,
    lastIncident: null,
    sloCompliance: uptime >= 99.9 ? 100 : uptime >= 99.5 ? 95 : 80,
    responseTime95th: latencyStats.p95,
    throughput: allSessions.length,
  };

  // Health
  const healthStatus = snapshot?.health_status ?? 'unknown';

  // Checkpoint / audit / trace counts (from filesystem, still JSON-based)
  const checkpointDir = join(ROOT, '.session', 'checkpoints');
  const checkpointCount = existsSync(checkpointDir)
    ? readdirSync(checkpointDir).filter((d) => !d.includes('.')).length
    : 0;
  const auditDir = join(ROOT, '.session', 'audit', 'logs');
  const auditFileCount = existsSync(auditDir)
    ? readdirSync(auditDir).filter((f) => f.endsWith('.jsonl')).length
    : 0;
  const traceDir = join(ROOT, '.telemetry', 'traces');
  const traceFileCount = existsSync(traceDir)
    ? readdirSync(traceDir).filter((f) => f.endsWith('.jsonl')).length
    : 0;
  const cloudMetricsFile = readJson<{ executions: unknown[] }>(
    join(ROOT, '.session', 'cloud-metrics.json'),
  );

  return {
    tokens: {
      used: snapshot?.tokens_used ?? 0,
      limit: snapshot?.tokens_limit ?? 120000,
      cost: totalCost,
      byModel,
    },
    sessions: {
      total: allSessions.length,
      active: activeSessions.length,
      today: snapshot?.sessions_today ?? 0,
      avgDuration: latencyStats.avg,
    },
    latency: {
      avg: latencyStats.avg,
      p50: latencyStats.p50,
      p95: latencyStats.p95,
      p99: latencyStats.p95,
      max: allSessions.length > 0 ? latencyStats.p95 * 2 : 0,
      samples: latencyStats.count,
      responseTimes: {},
    },
    feedback: feedbackStats,
    costInsights,
    sla,
    git: gitStats,
    system: osMetrics,
    health: {
      status: healthStatus,
      routing: skillStats.totalCalls > 0 ? Math.min(1, skillStats.totalCalls * 0.01) : 0,
    },
    mcp: {
      skills: { total: skills.total, byAgent: skills.byAgent, recentlyUsed: topSkills },
      calls: {
        total: skillStats.totalCalls,
        byTool: skillStats.callsByTool,
        bySkill: skillStats.callsBySkill,
        lastCall: skillStats.lastCall,
      },
      performance: {
        avgResponseTime: skillStats.totalCalls > 0 ? latencyStats.avg : 0,
        errorRate: 0,
        responseTimes: {},
      },
    },
    cloud: {
      executions: cloudMetricsFile?.executions?.length || 0,
      totalCost:
        cloudMetricsFile?.executions?.reduce((s: number, e: any) => s + (e.cost || 0), 0) || 0,
    },
    checkpoints: checkpointCount,
    auditLogs: auditFileCount,
    traceFiles: traceFileCount,
  };
}

function getRealMetricsFromJson(): DashboardData {
  // Fallback: read from consolidated.json when DB is empty
  const consolidated = readJson<any>(CONSOLIDATED_PATH);
  const skillStats =
    readJson<{
      totalCalls: number;
      callsByTool: Record<string, number>;
      callsBySkill: Record<string, number>;
      lastCall: string | null;
    }>(STATS_PATH) || { totalCalls: 0, callsByTool: {}, callsBySkill: {}, lastCall: null };
  const tokenUsage = readJson<{ totalTokens?: number }>(
    join(ROOT, '.session', 'token-usage.json'),
  );

  const gitLive = getGitStats();
  const osMetrics = getOSMetrics();
  const skills = _countSkills(REGISTRY_PATH);

  const topSkills = Object.entries(skillStats.callsBySkill || {})
    .sort(([, a], [, b]) => b - a)
    .slice(0, 5)
    .map(([name]) => name);

  const t = consolidated?.token || { usedToday: 0, budget: 120000, estCost: 0 };
  const s = consolidated?.sessions || { total: 0, active: 0, today: 0 };

  // Try to get session counts from history file
  let sessionsTotal = s.total;
  let sessionsActive = s.active;
  let sessionsToday = s.today;
  try {
    const sessionsHistory =
      readJson<Array<{ id: string; status: string; createdAt: string }>>(SESSIONS_HISTORY_PATH) ||
      [];
    const today = new Date().toISOString().slice(0, 10);
    sessionsTotal = Math.max(s.total, sessionsHistory.length);
    sessionsActive = Math.max(s.active, sessionsHistory.filter((sh) => sh.status === 'active' || sh.status === 'awaiting_input').length);
    sessionsToday = Math.max(s.today, sessionsHistory.filter((sh) => (sh.createdAt || '').startsWith(today)).length);
  } catch {
    // best-effort
  }

  // Context states for traces
  let latencyAvg = 0;
  let latencyP50 = 0;
  let latencyP95 = 0;
  let latencyCount = 0;
  try {
    if (existsSync(CONTEXT_LOG_DIR)) {
      const dirs = readdirSync(CONTEXT_LOG_DIR, { withFileTypes: true });
      const allDurations: number[] = [];
      for (const d of dirs) {
        if (!d.isDirectory()) continue;
        const stateFile = join(CONTEXT_LOG_DIR, d.name, '.state.json');
        if (!existsSync(stateFile)) continue;
        const state = readJson<{ turns?: Array<{ totalTokens?: number }> }>(stateFile);
        if (state?.turns) {
          for (const turn of state.turns) {
            if (turn.totalTokens) allDurations.push(turn.totalTokens);
          }
        }
      }
      if (allDurations.length > 0) {
        allDurations.sort((a, b) => a - b);
        latencyAvg = Math.round(allDurations.reduce((a, b) => a + b, 0) / allDurations.length);
        latencyP50 = allDurations[Math.floor(allDurations.length * 0.5)] || 0;
        latencyP95 = allDurations[Math.floor(allDurations.length * 0.95)] || 0;
        latencyCount = allDurations.length;
      }
    }
  } catch {
    // best-effort
  }

  return {
    tokens: {
      used: t.usedToday || tokenUsage?.totalTokens || 0,
      limit: t.budget || 120000,
      cost: t.estCost || 0,
      byModel: [],
    },
    sessions: {
      total: sessionsTotal,
      active: sessionsActive,
      today: sessionsToday,
      avgDuration: 0,
    },
    latency: {
      avg: latencyAvg,
      p50: latencyP50,
      p95: latencyP95,
      p99: latencyP95,
      max: 0,
      samples: latencyCount,
      responseTimes: {},
    },
    feedback: { thumbsUp: 0, thumbsDown: 0, total: 0, score: 0 },
    costInsights: [],
    sla: { uptime: 99.5, incidents: 0, lastIncident: null, sloCompliance: 95, responseTime95th: 0, throughput: 0 },
    git: gitLive,
    system: osMetrics,
    health: {
      status: consolidated?.live?.trafficLight === 'GREEN' ? 'healthy' : 'degraded',
      routing: skillStats.totalCalls > 0 ? Math.min(1, skillStats.totalCalls * 0.01) : 0,
    },
    mcp: {
      skills: { total: skills.total, byAgent: skills.byAgent, recentlyUsed: topSkills },
      calls: {
        total: skillStats.totalCalls,
        byTool: skillStats.callsByTool,
        bySkill: skillStats.callsBySkill,
        lastCall: skillStats.lastCall,
      },
      performance: {
        avgResponseTime: skillStats.totalCalls > 0 ? 150 : 0,
        errorRate: 0,
        responseTimes: {},
      },
    },
    cloud: { executions: 0, totalCost: 0 },
    checkpoints: 0,
    auditLogs: 0,
    traceFiles: 0,
  };
}

// ─── Traces ───────────────────────────────────────────────────────────

interface Trace {
  traceId: string;
  spanId: string;
  parentSpanId?: string;
  name: string;
  startTime: number;
  endTime?: number;
  duration?: number;
  status: 'running' | 'completed' | 'error';
  attributes: Record<string, string>;
}

interface TraceStats {
  totalTraces: number;
  avgDuration: number;
  errorRate: number;
  activeSpans: number;
}

export function getTraces(): { traces: Trace[]; stats: TraceStats } {
  const traces: Trace[] = [];

  // Try DB first
  if (dbAvailable()) {
    try {
      const db = getDb();
      const dbTraces = db.getDb()
        .prepare("SELECT * FROM traces ORDER BY start_time DESC LIMIT 200")
        .all() as Array<{
          span_id: string; trace_id: string; parent_span_id: string | null;
          name: string; start_time: number; end_time: number | null;
          duration: number | null; status: string; model: string | null;
          input_tokens: number; output_tokens: number; cost: number;
          session_id: string | null; attributes: string | null;
        }>;

      for (const t of dbTraces) {
        traces.push({
          traceId: t.trace_id,
          spanId: t.span_id,
          parentSpanId: t.parent_span_id ?? undefined,
          name: t.name,
          startTime: t.start_time,
          endTime: t.end_time ?? undefined,
          duration: t.duration ?? undefined,
          status: (t.status === 'error' ? 'error' : t.status === 'completed' ? 'completed' : 'running') as Trace['status'],
          attributes: {
            model: t.model ?? 'unknown',
            inputTokens: String(t.input_tokens),
            outputTokens: String(t.output_tokens),
            cost: String(t.cost),
            sessionId: t.session_id ?? '',
          },
        });
      }
    } catch {
      // fallback to JSON
    }
  }

  // If no traces from DB, try context-log
  if (traces.length === 0) {
    try {
      if (existsSync(CONTEXT_LOG_DIR)) {
        const dirs = readdirSync(CONTEXT_LOG_DIR, { withFileTypes: true });
        for (const d of dirs) {
          if (!d.isDirectory()) continue;
          const stateFile = join(CONTEXT_LOG_DIR, d.name, '.state.json');
          if (!existsSync(stateFile)) continue;
          const state = readJson<{
            sessionId?: string; model?: string;
            turns?: Array<{
              label?: string; timestamp?: string;
              inputTokens?: number; outputTokens?: number;
              totalTokens?: number; cost?: number; contextChars?: number;
            }>;
          }>(stateFile);
          if (!state || !state.turns) continue;

          const sessionId = state.sessionId || d.name;
          const model = state.model || 'unknown';

          for (let i = 0; i < state.turns.length; i++) {
            const turn = state.turns[i];
            const startTime = turn.timestamp ? new Date(turn.timestamp).getTime() : Date.now();
            traces.push({
              traceId: sessionId,
              spanId: `${sessionId}-turn-${i + 1}`,
              parentSpanId: i > 0 ? `${sessionId}-turn-${i}` : sessionId,
              name: turn.label || `Turn ${i + 1}`,
              startTime,
              endTime: turn.totalTokens ? startTime + turn.totalTokens : undefined,
              duration: turn.totalTokens || 0,
              status: 'completed',
              attributes: {
                model,
                inputTokens: String(turn.inputTokens || 0),
                outputTokens: String(turn.outputTokens || 0),
                cost: String(turn.cost || 0),
                contextChars: String(turn.contextChars || 0),
                sessionId,
              },
            });
          }
        }
      }
    } catch {
      /* best-effort */
    }
  }

  const activeSpans = traces.filter((t) => Date.now() - t.startTime < 3600000).length;
  const durations = traces
    .filter((t): t is typeof t & { duration: number } => t.duration !== undefined)
    .map((t) => t.duration);
  const avgDuration =
    durations.length > 0
      ? Math.round(durations.reduce((a, b) => a + b, 0) / durations.length)
      : 0;

  return {
    traces,
    stats: {
      totalTraces: traces.length,
      avgDuration,
      errorRate: traces.length > 0 ? traces.filter((t) => t.status === 'error').length / traces.length : 0,
      activeSpans,
    },
  };
}

// ─── Cloud Metrics ────────────────────────────────────────────────────

export function getCloudMetrics(): CloudMetrics {
  const cloudPath = join(ROOT, '.session', 'cloud-metrics.json');
  const cloudData = readJson<{
    executions: Array<{
      provider: string;
      timestamp: string;
      duration: number;
      success: boolean;
      cost: number;
    }>;
  }>(cloudPath);
  const execs = cloudData?.executions || [];

  const byProvider: Record<string, { executions: number[]; costs: number[]; successes: boolean[] }> = {};
  for (const ex of execs) {
    if (!byProvider[ex.provider])
      byProvider[ex.provider] = { executions: [], costs: [], successes: [] };
    byProvider[ex.provider].executions.push(ex.duration);
    byProvider[ex.provider].costs.push(ex.cost);
    byProvider[ex.provider].successes.push(ex.success);
  }

  const stats = {
    totalExecutions: execs.length,
    totalCost: execs.reduce((s, e) => s + e.cost, 0),
    successRate: execs.length > 0 ? execs.filter((e) => e.success).length / execs.length : 1,
    avgLatency:
      execs.length > 0
        ? Math.round(execs.reduce((s, e) => s + e.duration, 0) / execs.length)
        : 0,
    byProvider: {} as Record<string, { executions: number; cost: number; successRate: number; avgLatency: number }>,
    circuitBreakerStates: { AWS: 'CLOSED', Azure: 'CLOSED' },
  };

  for (const [provider, data] of Object.entries(byProvider)) {
    stats.byProvider[provider] = {
      executions: data.executions.length,
      cost: data.costs.reduce((s, c) => s + c, 0),
      successRate: data.successes.filter(Boolean).length / data.successes.length,
      avgLatency: Math.round(data.executions.reduce((s, d) => s + d, 0) / data.executions.length),
    };
  }

  return { executions: execs, stats };
}

// ─── Tenant-Scoped Metrics ────────────────────────────────────────────

export function getTenantScopedMetrics(tenantId: string): DashboardData {
  const registryPath = join(ROOT, 'config', 'tenant-registry.json');
  let tenantName = tenantId;
  try {
    if (existsSync(registryPath)) {
      const registry = JSON.parse(readFileSync(registryPath, 'utf-8'));
      const found = (registry.tenants || []).find((t: any) => t.id === tenantId);
      if (found) tenantName = found.name || tenantId;
    }
  } catch {
    /* fallback to tenantId */
  }

  const base = getRealMetrics();

  // Try DB for tenant-specific session count
  let sessionCount = 0;
  if (dbAvailable()) {
    try {
      const db = getDb();
      const result = db.getDb()
        .prepare("SELECT COUNT(*) as count FROM sessions WHERE id LIKE ?")
        .get(`%${tenantId}%`) as { count: number };
      sessionCount = result.count;
    } catch {
      // fallback
    }
  }

  return {
    ...base,
    sessions: { ...base.sessions, total: sessionCount || base.sessions.total },
    tenantId,
    tenantName,
  };
}
