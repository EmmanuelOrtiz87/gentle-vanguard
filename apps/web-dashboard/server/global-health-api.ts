import type { GlobalHealth, RepositoryHealth } from '../src/types/dashboard.js';

const REPOSITORIES = [
  'gentle-vanguard',
  'dashboard-app',
  'skill-marketplace',
  'agent-orchestrator',
];

function generateRepoHealth(name: string): RepositoryHealth {
  const statuses: RepositoryHealth['status'][] = ['healthy', 'healthy', 'healthy', 'degraded', 'down'];
  const ciStatuses: RepositoryHealth['ciStatus'][] = ['passing', 'passing', 'passing', 'failing', 'unknown'];
  const status = statuses[Math.floor(Math.random() * statuses.length)];

  return {
    name,
    status,
    lastCommit: new Date(Date.now() - Math.floor(Math.random() * 604800000)).toISOString(),
    openPRs: Math.floor(Math.random() * 20),
    ciStatus: ciStatuses[Math.floor(Math.random() * ciStatuses.length)],
    coverage: Math.floor(Math.random() * 40) + 55,
    contributors: Math.floor(Math.random() * 8) + 2,
    updatedAt: new Date().toISOString(),
  };
}

export function getGlobalHealth(): GlobalHealth {
  const repositories = REPOSITORIES.map(generateRepoHealth);
  const totalRepos = repositories.length;
  const healthyRepos = repositories.filter((r) => r.status === 'healthy').length;
  const degradedRepos = repositories.filter((r) => r.status === 'degraded').length;
  const criticalRepos = repositories.filter((r) => r.status === 'down').length;
  const avgCoverage = Math.round(repositories.reduce((s, r) => s + r.coverage, 0) / totalRepos);
  const totalOpenPRs = repositories.reduce((s, r) => s + r.openPRs, 0);

  let overallStatus: GlobalHealth['overallStatus'] = 'healthy';
  if (criticalRepos > 0) overallStatus = 'critical';
  else if (degradedRepos > 0) overallStatus = 'degraded';

  return {
    repositories,
    overallStatus,
    totalRepos,
    healthyRepos,
    degradedRepos,
    criticalRepos,
    avgCoverage,
    totalOpenPRs,
    lastUpdated: new Date().toISOString(),
  };
}

export function healthHandler(_req: any, res: any): void {
  res.writeHead(200, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
  res.end(JSON.stringify(getGlobalHealth()));
}
