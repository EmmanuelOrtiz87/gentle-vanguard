import { readFileSync, existsSync } from 'fs';
import { join, dirname, resolve } from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = resolve(__dirname, '../../..');
const STATS_PATH = join(ROOT, '.atl', 'skill-stats.json');
const REGISTRY_PATH = join(ROOT, '.atl', 'skill-registry.md');
const EVENT_HISTORY_PATH = join(ROOT, '.event-bus', 'history.json');

interface SkillStats {
  totalCalls: number;
  callsByTool: Record<string, number>;
  callsBySkill: Record<string, number>;
  lastCall: string | null;
}

interface EventHistory {
  events: unknown[];
  version: string;
  max_history: number;
}

export function loadSkillStats(): SkillStats {
  try {
    return JSON.parse(readFileSync(STATS_PATH, 'utf-8'));
  } catch {
    return { totalCalls: 0, callsByTool: {}, callsBySkill: {}, lastCall: null };
  }
}

export function countSkills(): { total: number; byAgent: Record<string, number> } {
  try {
    const content = readFileSync(REGISTRY_PATH, 'utf-8');
    const lines = content.split('\n');
    let count = 0;
    const byAgent: Record<string, number> = {};
    for (const line of lines) {
      const match = line.match(/^\|\s*([^|]+)\|\s*([^|]+)\|/);
      if (!match) continue;
      const agent = match[1].trim();
      if (agent === 'Agent' || agent.startsWith('---')) continue;
      byAgent[agent] = (byAgent[agent] || 0) + 1;
      count++;
    }
    return { total: count, byAgent };
  } catch {
    return { total: 0, byAgent: {} };
  }
}

export function loadEventHistory(): EventHistory {
  try {
    if (!existsSync(EVENT_HISTORY_PATH)) return { events: [], version: '1.0', max_history: 100 };
    return JSON.parse(readFileSync(EVENT_HISTORY_PATH, 'utf-8'));
  } catch {
    return { events: [], version: '1.0', max_history: 100 };
  }
}

function execGit(args: string): string {
  try {
    return execSync(`git ${args}`, { cwd: ROOT, encoding: 'utf-8', timeout: 3000 }).trim();
  } catch {
    return '';
  }
}

export function getGitStats(): { commits: number; prsMerged: number; contributors: number } {
  try {
    const totalCommits = parseInt(execGit('rev-list --count HEAD'), 10) || 0;
    const prLog = execGit('log --oneline --grep="Merge pull request" --all');
    const prCount = prLog ? prLog.split('\n').filter(Boolean).length : 0;
    const contributorOutput = execGit('shortlog -sn --all');
    const contributorCount = contributorOutput ? contributorOutput.split('\n').filter(Boolean).length : 0;
    return {
      commits: totalCommits,
      prsMerged: prCount,
      contributors: contributorCount,
    };
  } catch {
    return { commits: 0, prsMerged: 0, contributors: 0 };
  }
}

export function getRealMetrics() {
  const stats = loadSkillStats();
  const skills = countSkills();
  const eventHistory = loadEventHistory();
  const gitStats = getGitStats();

  const topSkills = Object.entries(stats.callsBySkill || {})
    .sort(([, a], [, b]) => b - a)
    .slice(0, 5)
    .map(([name]) => name);

  return {
    timestamp: new Date().toISOString(),
    tokens: { used: 0, limit: 0, cost: 0 },
    sessions: { total: 0, active: 0, today: 0 },
    git: gitStats,
    health: { status: 'healthy', routing: 1 },
    mcp: {
      skills: { total: skills.total, byAgent: skills.byAgent, recentlyUsed: topSkills },
      calls: {
        total: stats.totalCalls,
        byTool: stats.callsByTool,
        bySkill: stats.callsBySkill,
        lastCall: stats.lastCall,
      },
      performance: { avgResponseTime: 0, errorRate: 0 },
    },
    events: eventHistory.events,
  };
}

export function getTraces() {
  return { traces: [], stats: { totalTraces: 0, avgDuration: 0, errorRate: 0, activeSpans: 0 } };
}
