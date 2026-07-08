import { existsSync, readdirSync, readFileSync } from 'fs';
import { join } from 'path';
import { execSync } from 'child_process';
import { ROOT, readJson, countSkills as _countSkills } from './shared.js';
import type { CloudMetrics, DashboardData } from '../src/types/dashboard.js';

const CONSOLIDATED_PATH = join(ROOT, '.runtime', 'metrics', 'consolidated.json');
const TOKEN_PATH = join(ROOT, '.runtime', 'metrics', 'token.json');
const COST_PATH = join(ROOT, '.runtime', 'metrics', 'cost.json');
const SESSIONS_METRICS_PATH = join(ROOT, '.runtime', 'metrics', 'sessions.json');
const LIVE_PATH = join(ROOT, '.runtime', 'metrics', 'live.json');
const GIT_METRICS_PATH = join(ROOT, '.runtime', 'metrics', 'git.json');
const PR_METRICS_PATH = join(ROOT, '.runtime', 'metrics', 'pr.json');
const TELEMETRY_PATH = join(ROOT, '.runtime', 'metrics', 'telemetry.json');
const PERFORMANCE_PATH = join(ROOT, '.runtime', 'metrics', 'performance-analytics.json');
const STATS_PATH = join(ROOT, '.atl', 'skill-stats.json');
const REGISTRY_PATH = join(ROOT, '.atl', 'skill-registry.md');
const EVENT_HISTORY_PATH = join(ROOT, '.event-bus', 'history.json');
const SESSIONS_HISTORY_PATH = join(ROOT, '.event-bus', 'sessions-history.json');
const CONTEXT_LOG_DIR = join(ROOT, '.session', 'context-log');
const TOKEN_USAGE_PATH = join(ROOT, '.session', 'token-usage.json');
const FEEDBACK_PATH = join(ROOT, '.runtime', 'metrics', 'feedback.json');

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

function execGit(args: string): string {
  try {
    return execSync(`git ${args}`, { cwd: ROOT, encoding: 'utf-8', timeout: 3000 }).trim();
  } catch {
    return '';
  }
}

interface ContextTurn {
  label?: string;
  timestamp?: string;
  inputTokens?: number;
  outputTokens?: number;
  totalTokens?: number;
  cost?: number;
  contextChars?: number;
  turn?: number;
}

interface ContextState {
  model?: string;
  turnCount?: number;
  totalContextChars?: number;
  totalCost?: number;
  totalOutputTokens?: number;
  totalInputTokens?: number;
  totalTokens?: number;
  startedAt?: string;
  sessionId?: string;
  turns?: ContextTurn[];
}

export function getGitStats(): { commits: number; prsMerged: number; contributors: number } {
  const gitFile = readJson<{ totalCommits: number; authorCount: number }>(GIT_METRICS_PATH);
  const prFile = readJson<{ merged: number }>(PR_METRICS_PATH);
  return {
    commits: gitFile?.totalCommits ?? (parseInt(execGit('rev-list --count HEAD'), 10) || 0),
    prsMerged: prFile?.merged ?? 0,
    contributors: gitFile?.authorCount ?? 0,
  };
}

export function getOSMetrics() {
  const mem = process.memoryUsage();
  const cpu = process.cpuUsage();
  return {
    memory: {
      rss: Math.round(mem.rss / 1024 / 1024),
      heapUsed: Math.round(mem.heapUsed / 1024 / 1024),
      heapTotal: Math.round(mem.heapTotal / 1024 / 1024),
    },
    cpu: {
      user: Math.round(cpu.user / 1000),
      system: Math.round(cpu.system / 1000),
    },
    uptime: Math.round(process.uptime()),
    pid: process.pid,
  };
}

function loadContextStates(): ContextState[] {
  const states: ContextState[] = [];
  try {
    if (!existsSync(CONTEXT_LOG_DIR)) return states;
    const dirs = readdirSync(CONTEXT_LOG_DIR, { withFileTypes: true });
    for (const d of dirs) {
      if (!d.isDirectory()) continue;
      const stateFile = join(CONTEXT_LOG_DIR, d.name, '.state.json');
      if (!existsSync(stateFile)) continue;
      const state = readJson<ContextState>(stateFile);
      if (state) states.push(state);
    }
  } catch {
    /* best-effort */
  }
  return states;
}

function computeByModel(contextStates: ContextState[]) {
  const modelMap: Record<
    string,
    { inputTokens: number; outputTokens: number; totalTokens: number; cost: number; calls: number }
  > = {};

  for (const state of contextStates) {
    const model = state.model || 'unknown';
    if (!modelMap[model]) {
      modelMap[model] = { inputTokens: 0, outputTokens: 0, totalTokens: 0, cost: 0, calls: 0 };
    }
    const m = modelMap[model];
    m.totalTokens += state.totalTokens || 0;
    m.cost += state.totalCost || 0;
    m.calls += state.turnCount || 0;

    if (state.turns) {
      for (const turn of state.turns) {
        m.inputTokens += turn.inputTokens || 0;
        m.outputTokens += turn.outputTokens || 0;
      }
    }
  }

  return Object.entries(modelMap).map(([model, vals]) => ({
    model,
    inputTokens: vals.inputTokens,
    outputTokens: vals.outputTokens,
    totalTokens: vals.totalTokens,
    cost: vals.cost,
    calls: vals.calls,
  }));
}

function computeLatency(contextStates: ContextState[]): {
  avg: number;
  p50: number;
  p95: number;
  p99: number;
  max: number;
  samples: number;
} {
  const allDurations: number[] = [];
  for (const state of contextStates) {
    if (state.turns) {
      for (const turn of state.turns) {
        if (turn.totalTokens) allDurations.push(turn.totalTokens);
      }
    }
  }
  if (allDurations.length === 0) return { avg: 0, p50: 0, p95: 0, p99: 0, max: 0, samples: 0 };
  allDurations.sort((a, b) => a - b);
  const sum = allDurations.reduce((a, b) => a + b, 0);
  return {
    avg: Math.round(sum / allDurations.length),
    p50: allDurations[Math.floor(allDurations.length * 0.5)] || 0,
    p95: allDurations[Math.floor(allDurations.length * 0.95)] || 0,
    p99:
      allDurations[Math.floor(allDurations.length * 0.99)] ||
      allDurations[allDurations.length - 1] ||
      0,
    max: allDurations[allDurations.length - 1] || 0,
    samples: allDurations.length,
  };
}

function computeFeedback(): { thumbsUp: number; thumbsDown: number; total: number; score: number } {
  const fb = readJson<{ thumbsUp: number; thumbsDown: number }>(FEEDBACK_PATH);
  if (!fb) return { thumbsUp: 0, thumbsDown: 0, total: 0, score: 0 };
  const total = fb.thumbsUp + fb.thumbsDown;
  return {
    thumbsUp: fb.thumbsUp || 0,
    thumbsDown: fb.thumbsDown || 0,
    total,
    score: total > 0 ? Math.round((fb.thumbsUp / total) * 100) : 0,
  };
}

function computeCostInsights(byModel: ReturnType<typeof computeByModel>, totalCost: number) {
  return byModel
    .map((m) => {
      const pct = totalCost > 0 ? Math.round((m.cost / totalCost) * 100) : 0;
      const pricing = MODEL_PRICING[m.model] || MODEL_PRICING['default'];
      const estimatedCost =
        (m.inputTokens / 1_000_000) * pricing.input + (m.outputTokens / 1_000_000) * pricing.output;
      const savings =
        estimatedCost > 0 ? Math.round(((estimatedCost - m.cost) / estimatedCost) * 100) : 0;
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
      };
    })
    .sort((a, b) => b.cost - a.cost);
}

function computeSLA(): {
  uptime: number;
  incidents: number;
  lastIncident: string | null;
  sloCompliance: number;
} {
  const consolidated = readJson<any>(CONSOLIDATED_PATH);
  const telemetry = readJson<{ toolCalls?: number; eventsCount?: number }>(TELEMETRY_PATH);
  const uptime = consolidated?.live?.routingAcc === '100%' ? 99.95 : 99.5;
  const incidents = telemetry?.eventsCount
    ? Math.max(0, Math.floor(telemetry.eventsCount / 10))
    : 0;
  return {
    uptime,
    incidents,
    lastIncident: null,
    sloCompliance: uptime >= 99.9 ? 100 : uptime >= 99.5 ? 95 : 80,
  };
}

export function getRealMetrics() {
  const consolidated = readJson<any>(CONSOLIDATED_PATH);
  const costFile = readJson<{ actualCost: number; savingsPct: number }>(COST_PATH);
  const skillStats = readJson<{
    totalCalls: number;
    callsByTool: Record<string, number>;
    callsBySkill: Record<string, number>;
    lastCall: string | null;
  }>(STATS_PATH) || { totalCalls: 0, callsByTool: {}, callsBySkill: {}, lastCall: null };
  const sessionsFile = readJson<{ events: unknown[] }>(EVENT_HISTORY_PATH);
  const sessionsHistory =
    readJson<Array<{ id: string; agent: string; status: string; createdAt: string }>>(
      SESSIONS_HISTORY_PATH,
    ) || [];
  const performanceAnalytics = readJson<any>(PERFORMANCE_PATH);
  const tokenUsage = readJson<{ totalTokens?: number }>(TOKEN_USAGE_PATH);

  const cloudMetricsFile = readJson<{ executions: unknown[] }>(
    join(ROOT, '.session', 'cloud-metrics.json'),
  );
  const cloudExecutions = cloudMetricsFile?.executions?.length || 0;
  const cloudTotalCost =
    cloudMetricsFile?.executions?.reduce((s: number, e: any) => s + (e.cost || 0), 0) || 0;

  const checkpointDir = join(ROOT, '.session', 'checkpoints');
  const checkpointCount = existsSync(checkpointDir)
    ? readdirSync(checkpointDir).filter(
        (d) => existsSync(join(checkpointDir, d, d)) || !d.includes('.'),
      ).length
    : 0;

  const auditDir = join(ROOT, '.session', 'audit', 'logs');
  const auditFileCount = existsSync(auditDir)
    ? readdirSync(auditDir).filter((f) => f.endsWith('.jsonl')).length
    : 0;

  const traceDir = join(ROOT, '.telemetry', 'traces');
  const traceFileCount = existsSync(traceDir)
    ? readdirSync(traceDir).filter((f) => f.endsWith('.jsonl')).length
    : 0;

  const docAnalysisDir = join(ROOT, '.session', 'document-analysis');
  const docAnalysisResults = existsSync(docAnalysisDir)
    ? readdirSync(docAnalysisDir).filter((f) => f.startsWith('result-')).length
    : 0;
  const docAnalysisReports = existsSync(join(ROOT, 'docs', 'requirements-analysis'))
    ? readdirSync(join(ROOT, 'docs', 'requirements-analysis')).filter((f) => f.endsWith('.md'))
        .length
    : 0;

  const skills = _countSkills(REGISTRY_PATH);

  const t = consolidated?.token ||
    readJson<any>(TOKEN_PATH) || { usedToday: 0, budget: 1000000, estCost: 0 };
  const s = consolidated?.sessions ||
    readJson<any>(SESSIONS_METRICS_PATH) || { total: 0, active: 0, today: 0 };
  const g = consolidated?.git || readJson<any>(GIT_METRICS_PATH) || {};
  const live = consolidated?.live || readJson<any>(LIVE_PATH) || { trafficLight: 'GREEN' };

  const contextStates = loadContextStates();
  const byModel = computeByModel(contextStates);
  const latency = computeLatency(contextStates);
  const feedback = computeFeedback();

  const tokensUsed = t.usedToday || tokenUsage?.totalTokens || 0;
  const tokenCost = t.estCost || costFile?.actualCost || 0;
  const costInsights = computeCostInsights(byModel, tokenCost);
  const sla = computeSLA();

  const topSkills = Object.entries(skillStats.callsBySkill || {})
    .sort(([, a], [, b]) => b - a)
    .slice(0, 5)
    .map(([name]) => name);

  const today = new Date().toISOString().slice(0, 10);
  const sessionsToday = sessionsHistory.filter((s) => (s.createdAt || '').startsWith(today)).length;
  const activeSessions = sessionsHistory.filter(
    (s) => s.status === 'active' || s.status === 'awaiting_input',
  ).length;

  const gitLive = getGitStats();
  const avgDuration = performanceAnalytics?.sessions?.avgDurationMinutes
    ? performanceAnalytics.sessions.avgDurationMinutes * 60
    : 0;

  return {
    timestamp: new Date().toISOString(),
    tokens: {
      used: tokensUsed,
      limit: t.budget || 120000,
      cost: tokenCost,
      byModel,
    },
    sessions: {
      total: Math.max(s.total || 0, sessionsHistory.length),
      active: Math.max(s.active || 0, activeSessions),
      today: Math.max(s.today || 0, sessionsToday || 0),
      avgDuration,
    },
    latency,
    feedback,
    costInsights,
    sla,
    git: gitLive,
    system: getOSMetrics(),
    health: {
      status:
        live.trafficLight === 'GREEN'
          ? 'healthy'
          : live.trafficLight === 'YELLOW'
            ? 'degraded'
            : 'critical',
      routing: g.routingTotal
        ? Math.min(1, (g.routingTotal || 0) / 100)
        : skillStats.totalCalls > 0
          ? Math.min(1, 0.5 + skillStats.totalCalls * 0.01)
          : 0,
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
      },
    },
    events: sessionsFile?.events || [],
    cloud: { executions: cloudExecutions, totalCost: cloudTotalCost },
    checkpoints: checkpointCount,
    auditLogs: auditFileCount,
    traceFiles: traceFileCount,
    documentAnalysis: {
      results: docAnalysisResults,
      reports: docAnalysisReports,
    },
  };
}

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

  const byProvider: Record<
    string,
    { executions: number[]; costs: number[]; successes: boolean[] }
  > = {};
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
      execs.length > 0 ? Math.round(execs.reduce((s, e) => s + e.duration, 0) / execs.length) : 0,
    byProvider: {} as Record<
      string,
      { executions: number; cost: number; successRate: number; avgLatency: number }
    >,
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

export function getTraces(): { traces: Trace[]; stats: TraceStats } {
  const traces: Trace[] = [];
  let errorCount = 0;

  try {
    if (existsSync(CONTEXT_LOG_DIR)) {
      const dirs = readdirSync(CONTEXT_LOG_DIR, { withFileTypes: true });
      for (const d of dirs) {
        if (!d.isDirectory()) continue;
        const stateFile = join(CONTEXT_LOG_DIR, d.name, '.state.json');
        if (!existsSync(stateFile)) continue;
        const state = readJson<ContextState>(stateFile);
        if (!state || !state.turns) continue;

        const sessionId = state.sessionId || d.name;
        const model = state.model || 'unknown';
        const turns = state.turns;

        for (let i = 0; i < turns.length; i++) {
          const turn = turns[i];
          const startTime = turn.timestamp ? new Date(turn.timestamp).getTime() : Date.now();
          const totalTokens = turn.totalTokens || 0;
          const cost = turn.cost || 0;
          traces.push({
            traceId: sessionId,
            spanId: `${sessionId}-turn-${i + 1}`,
            parentSpanId: i > 0 ? `${sessionId}-turn-${i}` : sessionId,
            name: turn.label || `Turn ${i + 1}`,
            startTime,
            endTime: totalTokens ? startTime + totalTokens : undefined,
            duration: totalTokens,
            status: 'completed',
            attributes: {
              model,
              inputTokens: String(turn.inputTokens || 0),
              outputTokens: String(turn.outputTokens || 0),
              cost: String(cost),
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

  const activeSpans = traces.filter((t) => {
    return Date.now() - t.startTime < 3600000;
  }).length;

  const durations = traces
    .filter((t): t is typeof t & { duration: number } => t.duration !== undefined)
    .map((t) => t.duration);
  const avgDuration =
    durations.length > 0 ? Math.round(durations.reduce((a, b) => a + b, 0) / durations.length) : 0;

  return {
    traces,
    stats: {
      totalTraces: traces.length,
      avgDuration,
      errorRate: traces.length > 0 ? errorCount / traces.length : 0,
      activeSpans,
    },
  };
}

export function getTenantScopedMetrics(tenantId: string): DashboardData {
  const registryPath = join(ROOT, 'config', 'tenant-registry.json');
  let tenantName = tenantId;
  try {
    if (existsSync(registryPath)) {
      const registry = JSON.parse(readFileSync(registryPath, 'utf-8'));
      const found = (registry.tenants || []).find((t: any) => t.id === tenantId);
      if (found) tenantName = found.name || tenantId;
    }
  } catch { /* fallback to tenantId */ }

  const tenantSessionDir = join(ROOT, '.session', 'tenants', tenantId);
  const tenantTokenPath = join(tenantSessionDir, 'token-usage.json');
  const tenantTracesDir = join(ROOT, '.telemetry', 'tenants', tenantId, 'traces');
  const tenantTokens = existsSync(tenantTokenPath)
    ? readJson<{ totalTokens?: number }>(tenantTokenPath)
    : null;
  const traceCount = existsSync(tenantTracesDir)
    ? readdirSync(tenantTracesDir).filter((f) => f.endsWith('.jsonl')).length
    : 0;
  const tenantSessionsPath = join(ROOT, '.session', 'context-log', tenantId);
  const sessionDirs = existsSync(tenantSessionsPath)
    ? readdirSync(tenantSessionsPath).filter((d) => {
        const statePath = join(tenantSessionsPath, d, '.state.json');
        return existsSync(statePath);
      })
    : [];
  const base = getRealMetrics();
  return {
    ...base,
    sessions: { ...base.sessions, total: sessionDirs.length },
    traceFiles: traceCount,
    tokens: { ...base.tokens, used: tenantTokens?.totalTokens ?? base.tokens.used },
    health: { ...base.health, status: sessionDirs.length > 0 ? 'healthy' : 'degraded' },
    tenantId,
    tenantName,
  };
}
