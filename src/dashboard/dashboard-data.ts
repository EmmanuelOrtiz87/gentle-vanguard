export interface DashboardData {
  tokens: { used: number; limit: number; cost: number };
  sessions: { total: number; active: number; today: number };
  git: { commits: number; prsMerged: number; contributors: number };
  health: { status: string; routing: number };
}

export function getMockDashboardData(): DashboardData {
  return {
    tokens: { used: 15000, limit: 30000, cost: 0.45 },
    sessions: { total: 42, active: 3, today: 5 },
    git: { commits: 128, prsMerged: 15, contributors: 4 },
    health: { status: 'healthy', routing: 0.95 },
  };
}
