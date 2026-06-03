export interface DashboardData {
  tokens: { used: number; limit: number; cost: number };
  sessions: { total: number; active: number; today: number };
  git: { commits: number; prsMerged: number; contributors: number };
  health: { status: string; routing: number };
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
