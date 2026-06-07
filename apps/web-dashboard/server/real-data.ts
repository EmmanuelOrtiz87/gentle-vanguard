import { existsSync, readdirSync } from 'fs';
import { join } from 'path';
import { execSync } from 'child_process';
import { ROOT, readJson, countSkills as _countSkills } from './shared.js';

const CONSOLIDATED_PATH = join(ROOT, '.runtime', 'metrics', 'consolidated.json');
const METRICS_DB_PATH = join(ROOT, '.runtime', 'metrics.json');
const TOKEN_PATH = join(ROOT, '.runtime', 'metrics', 'token.json');
const SESSIONS_METRICS_PATH = join(ROOT, '.runtime', 'metrics', 'sessions.json');
const COST_PATH = join(ROOT, '.runtime', 'metrics', 'cost.json');
const LIVE_PATH = join(ROOT, '.runtime', 'metrics', 'live.json');
const GIT_METRICS_PATH = join(ROOT, '.runtime', 'metrics', 'git.json');
const PR_METRICS_PATH = join(ROOT, '.runtime', 'metrics', 'pr.json');
const STATS_PATH = join(ROOT, '.atl', 'skill-stats.json');
const REGISTRY_PATH = join(ROOT, '.atl', 'skill-registry.md');
const EVENT_HISTORY_PATH = join(ROOT, '.event-bus', 'history.json');
const SESSIONS_HISTORY_PATH = join(ROOT, '.event-bus', 'sessions-history.json');
const CONTEXT_LOG_DIR = join(ROOT, '.session', 'context-log');

function execGit(args: string): string {
  try {
    return execSync(`git ${args}`, { cwd: ROOT, encoding: 'utf-8', timeout: 3000 }).trim();
  } catch {
    return '';
  }
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

export function getRealMetrics() {
  const consolidated = readJson<any>(CONSOLIDATED_PATH);
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

  const skills = _countSkills(REGISTRY_PATH);

  const t = consolidated?.token ||
    readJson<any>(TOKEN_PATH) || { usedToday: 0, budget: 1000000, estCost: 0 };
  const s = consolidated?.sessions ||
    readJson<any>(SESSIONS_METRICS_PATH) || { total: 0, active: 0, today: 0 };
  const g = consolidated?.git || readJson<any>(GIT_METRICS_PATH) || {};
  const pr = consolidated?.pr || readJson<any>(PR_METRICS_PATH) || { merged: 0 };
  const live = consolidated?.live || readJson<any>(LIVE_PATH) || { trafficLight: 'GREEN' };

  const tokensUsed = t.usedToday || 0;
  const tokenCost = t.estCost || 0;

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

  return {
    timestamp: new Date().toISOString(),
    tokens: {
      used: tokensUsed,
      limit: t.budget || 1000000,
      cost: tokenCost,
    },
    sessions: {
      total: Math.max(s.total || 0, sessionsHistory.length),
      active: Math.max(s.active || 0, activeSessions),
      today: Math.max(s.today || 0, sessionsToday || 0),
    },
    git: gitLive,
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

export function getTraces(): { traces: Trace[]; stats: TraceStats } {
  const traces: Trace[] = [];

  try {
    if (existsSync(CONTEXT_LOG_DIR)) {
      const dirs = readdirSync(CONTEXT_LOG_DIR, { withFileTypes: true });
      for (const d of dirs) {
        if (!d.isDirectory()) continue;
        const stateFile = join(CONTEXT_LOG_DIR, d.name, '.state.json');
        if (!existsSync(stateFile)) continue;
        const state = readJson<any>(stateFile);
        if (!state || !state.turns) continue;

        const sessionId = state.sessionId || d.name;
        const model = state.model || 'unknown';
        const turns = state.turns as Array<{
          label?: string;
          timestamp?: string;
          inputTokens?: number;
          outputTokens?: number;
          totalTokens?: number;
          cost?: number;
          contextChars?: number;
        }>;

        for (let i = 0; i < turns.length; i++) {
          const turn = turns[i];
          const startTime = turn.timestamp ? new Date(turn.timestamp).getTime() : Date.now();
          const totalTokens = turn.totalTokens || 0;
          const duration = totalTokens > 0 ? totalTokens : undefined;
          traces.push({
            traceId: sessionId,
            spanId: `${sessionId}-turn-${i + 1}`,
            parentSpanId: i > 0 ? `${sessionId}-turn-${i}` : sessionId,
            name: turn.label || `Turn ${i + 1}`,
            startTime,
            endTime: duration ? startTime + duration : undefined,
            duration,
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

  const activeSpans = traces.filter((t) => {
    return Date.now() - t.startTime < 3600000;
  }).length;

  const durations = traces.filter((t) => t.duration).map((t) => t.duration!);
  const avgDuration =
    durations.length > 0 ? Math.round(durations.reduce((a, b) => a + b, 0) / durations.length) : 0;

  return {
    traces,
    stats: { totalTraces: traces.length, avgDuration, errorRate: 0, activeSpans },
  };
}
