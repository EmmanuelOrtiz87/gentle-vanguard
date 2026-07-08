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

export interface ModelCost {
  model: string;
  inputTokens: number;
  outputTokens: number;
  totalTokens: number;
  cost: number;
  calls: number;
}

export interface LatencyMetrics {
  avg: number;
  p50: number;
  p95: number;
  p99: number;
  max: number;
  samples: number;
}

export interface FeedbackMetric {
  thumbsUp: number;
  thumbsDown: number;
  total: number;
  score: number;
}

export interface CostInsight {
  model: string;
  cost: number;
  tokens: number;
  pct: number;
  estimatedCost?: number;
  savingsPct?: number;
  suggestedAction?: string;
}

export interface DashboardData {
  tokens: { used: number; limit: number; cost: number; byModel: ModelCost[] };
  sessions: { total: number; active: number; today: number; avgDuration: number };
  git: { commits: number; prsMerged: number; contributors: number };
  health: { status: string; routing: number };
  globalHealth?: GlobalHealth;
  latency?: LatencyMetrics;
  feedback?: FeedbackMetric;
  costInsights?: CostInsight[];
  cloud?: { executions: number; totalCost: number };
  checkpoints?: number;
  auditLogs?: number;
  traceFiles?: number;
  mcp?: {
    skills: { total: number; byAgent: Record<string, number>; recentlyUsed: string[] };
    calls: {
      total: number;
      byTool: Record<string, number>;
      bySkill: Record<string, number>;
      lastCall: string | null;
    };
    performance: { avgResponseTime: number; errorRate: number };
  };
  system?: {
    memory: { rss: number; heapUsed: number; heapTotal: number };
    cpu: { user: number; system: number };
    uptime: number;
    pid: number;
  };
  sla?: {
    uptime: number;
    incidents: number;
    lastIncident: string | null;
    sloCompliance: number;
  };
  tenantId?: string;
  tenantName?: string;
}

export interface Session {
  id: string;
  agent: string;
  status: 'active' | 'idle' | 'completed';
  startTime: string;
  tokensUsed: number;
  model?: string;
  cost?: number;
}

export interface CloudConnectorExecution {
  provider: string;
  timestamp: string;
  duration: number;
  success: boolean;
  cost: number;
}

export interface CloudMetrics {
  executions: CloudConnectorExecution[];
  stats: {
    totalExecutions: number;
    totalCost: number;
    successRate: number;
    avgLatency: number;
    byProvider: Record<
      string,
      {
        executions: number;
        cost: number;
        successRate: number;
        avgLatency: number;
      }
    >;
    circuitBreakerStates: Record<string, string>;
  };
}

export interface MetricHistory {
  timestamp: string;
  tokens: number;
  sessions: number;
  cost: number;
  latency?: number;
}
