export interface RepositoryHealth {
  name: string;
  status: 'healthy' | 'degraded' | 'down';
  lastCommit: string;
  openPRs: number;
  ciStatus: 'passing' | 'failing' | 'unknown';
  coverage: number;
  contributors: number;
  updatedAt: string;
}

export interface GlobalHealth {
  repositories: RepositoryHealth[];
  overallStatus: 'healthy' | 'degraded' | 'critical';
  totalRepos: number;
  healthyRepos: number;
  degradedRepos: number;
  criticalRepos: number;
  avgCoverage: number;
  totalOpenPRs: number;
  lastUpdated: string;
}

export interface DashboardData {
  tokens: { used: number; limit: number; cost: number };
  sessions: { total: number; active: number; today: number };
  git: { commits: number; prsMerged: number; contributors: number };
  health: { status: string; routing: number };
  globalHealth?: GlobalHealth;
  mcp?: { skills: { total: number; byAgent: Record<string, number>; recentlyUsed: string[] }; calls: { total: number; byTool: Record<string, number>; bySkill: Record<string, number>; lastCall: string | null }; performance: { avgResponseTime: number; errorRate: number } };
}

export interface Session {
  id: string;
  agent: string;
  status: 'active' | 'idle' | 'completed';
  startTime: string;
  tokensUsed: number;
}

export interface MetricHistory {
  timestamp: string;
  tokens: number;
  sessions: number;
  cost: number;
}
