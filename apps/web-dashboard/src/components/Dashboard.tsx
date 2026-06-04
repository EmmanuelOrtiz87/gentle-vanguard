import { useState, useEffect } from 'react';
import { Coins, Users, GitBranch, Activity, Moon, Sun, RefreshCw, Server, Zap, Bot } from 'lucide-react';
import { useMetrics } from '../hooks/useMetrics';
import { MetricsCard } from './MetricsCard';
import { LiveChart } from './LiveChart';
import { SessionTable } from './SessionTable';
import { AgentMessage } from './AgentMessage';
import { useAgentStream } from '../hooks/useAgentStream';
import type { Session } from '../types/dashboard';

const MOCK_SESSIONS: Session[] = [
  { id: 'sess-001', agent: 'DEV', status: 'active', startTime: new Date(Date.now() - 3600000).toISOString(), tokensUsed: 5234 },
  { id: 'sess-002', agent: 'QA', status: 'active', startTime: new Date(Date.now() - 1800000).toISOString(), tokensUsed: 3456 },
  { id: 'sess-003', agent: 'BA', status: 'idle', startTime: new Date(Date.now() - 7200000).toISOString(), tokensUsed: 8901 },
  { id: 'sess-004', agent: 'DEV', status: 'completed', startTime: new Date(Date.now() - 14400000).toISOString(), tokensUsed: 12345 },
];

export default function Dashboard() {
  const [darkMode, setDarkMode] = useState(false);
  const [useWebSocket, setUseWebSocket] = useState(true);
  const { data, history, loading, wsConnected, refetch } = useMetrics(useWebSocket);
  const { session: agentSession, bridgeConnected, createSession } = useAgentStream();

  useEffect(() => {
    if (bridgeConnected && !agentSession) {
      createSession('DEV');
    }
  }, [bridgeConnected]);

  const toggleDarkMode = () => {
    setDarkMode(!darkMode);
    document.documentElement.classList.toggle('dark');
  };

  const mcpData = (data as any)?.mcp;
  const totalSkills = mcpData?.skills?.total || 0;
  const totalCalls = mcpData?.calls?.total || 0;
  const avgResponseTime = mcpData?.performance?.avgResponseTime || 0;
  const recentMessages = agentSession?.messages.slice(-5) || [];

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <header className="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Gentle Vanguard Dashboard</h1>
              <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                Real-time metrics and monitoring
                {wsConnected && <span className="ml-2 text-green-500">● WS Connected</span>}
                {!wsConnected && useWebSocket && <span className="ml-2 text-yellow-500">● WS Reconnecting...</span>}
              </p>
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={() => setUseWebSocket(!useWebSocket)}
                className={`p-2 rounded-lg transition-colors ${
                  useWebSocket 
                    ? 'bg-green-100 dark:bg-green-900 text-green-600 dark:text-green-400' 
                    : 'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300'
                }`}
                title={useWebSocket ? 'WebSocket Mode' : 'HTTP Polling Mode'}
              >
                {useWebSocket ? <Zap className="w-5 h-5" /> : <Server className="w-5 h-5" />}
              </button>
              <button
                onClick={refetch}
                disabled={loading}
                className="p-2 rounded-lg bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors disabled:opacity-50"
              >
                <RefreshCw className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
              </button>
              <button
                onClick={toggleDarkMode}
                className="p-2 rounded-lg bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
              >
                {darkMode ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
              </button>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <MetricsCard
            title="Tokens Used"
            value={data.tokens.used.toLocaleString()}
            subtitle={`of ${data.tokens.limit.toLocaleString()} (${((data.tokens.used / data.tokens.limit) * 100).toFixed(1)}%)`}
            icon={Coins}
            color="blue"
          />
          <MetricsCard
            title="Active Sessions"
            value={data.sessions.active}
            subtitle={`${data.sessions.today} today, ${data.sessions.total} total`}
            icon={Users}
            color="green"
          />
          <MetricsCard
            title="Git Activity"
            value={data.git.commits}
            subtitle={`${data.git.prsMerged} PRs merged, ${data.git.contributors} contributors`}
            icon={GitBranch}
            color="yellow"
          />
          <MetricsCard
            title="Health Status"
            value={data.health.status}
            subtitle={`Routing: ${(data.health.routing * 100).toFixed(0)}%`}
            icon={Activity}
            color={data.health.status === 'healthy' ? 'green' : 'red'}
          />
        </div>

        {mcpData && (
          <div className="mb-8">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">MCP Server Metrics</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="card">
                <p className="metric-label">Total Skills</p>
                <p className="metric-value">{totalSkills.toLocaleString()}</p>
              </div>
              <div className="card">
                <p className="metric-label">Total Calls</p>
                <p className="metric-value">{totalCalls.toLocaleString()}</p>
              </div>
              <div className="card">
                <p className="metric-label">Avg Response</p>
                <p className="metric-value">{avgResponseTime.toFixed(0)}ms</p>
              </div>
            </div>
          </div>
        )}

        <div className="mb-8">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Agent Activity</h2>
            <span className="flex items-center gap-1 text-xs text-gray-500">
              {bridgeConnected ? <Bot className="w-3.5 h-3.5 text-green-500" /> : <Bot className="w-3.5 h-3.5 text-gray-400" />}
              {bridgeConnected ? 'Bridge Online' : 'Bridge Offline'}
            </span>
          </div>
          <div className="card">
            {recentMessages.length === 0 && (
              <div className="text-center py-6 text-gray-400 dark:text-gray-500">
                <Bot className="w-8 h-8 mx-auto mb-2 opacity-50" />
                <p className="text-sm">No agent activity yet</p>
                <button
                  onClick={() => createSession('DEV')}
                  className="mt-2 text-xs text-purple-500 hover:text-purple-600 underline"
                >
                  Start a session
                </button>
              </div>
            )}
            {recentMessages.length > 0 && (
              <div className="space-y-3">
                {recentMessages.map((msg: any) => (
                  <AgentMessage key={msg.id} message={msg} />
                ))}
              </div>
            )}
          </div>
        </div>

        <div className="mb-8">
          <LiveChart data={history} />
        </div>

        <SessionTable sessions={MOCK_SESSIONS} />
      </main>
    </div>
  );
}
