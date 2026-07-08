import { useState, useEffect, useCallback } from 'react';
import { Globe, Cpu, Play, Square, RefreshCw, AlertCircle, CheckCircle, PauseCircle } from 'lucide-react';

interface RepoServer {
  name: string;
  type: string;
  status: string;
  pid: number | null;
  autoStart: boolean;
  description: string;
}

interface RepoInfo {
  name: string;
  path: string;
  servers: RepoServer[];
  status: string;
}

function MultiRepoViewInner() {
  const [repos, setRepos] = useState<RepoInfo[]>([]);
  const [loading, setLoading] = useState(true);
  const [expanded, setExpanded] = useState<string | null>(null);

  const fetchRepos = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/mcp/servers');
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const msg = await res.json();
      if (msg.type === 'mcp-servers') {
        const servers = msg.data.servers || [];
        const localRepos: RepoInfo = {
          name: 'local',
          path: '.',
          servers: servers.map((s: any) => ({
            name: s.name, type: s.type || 'user', status: s.status || 'unknown',
            pid: s.pid || null, autoStart: s.autoStart || false, description: s.description || '',
          })),
          status: servers.some((s: any) => s.status === 'running') ? 'healthy' : 'inactive',
        };
        setRepos([localRepos]);
      }
    } catch {
      setRepos([]);
    }
    setLoading(false);
  }, []);

  useEffect(() => { void fetchRepos(); }, [fetchRepos]);

  const statusIcon = (status: string) => {
    switch (status) {
      case 'running': return <CheckCircle className="w-4 h-4 text-green-500" />;
      case 'error': return <AlertCircle className="w-4 h-4 text-red-500" />;
      default: return <PauseCircle className="w-4 h-4 text-gray-400" />;
    }
  };

  const repoStatusIcon = (status: string) => {
    switch (status) {
      case 'healthy': return <CheckCircle className="w-5 h-5 text-green-500" />;
      case 'degraded': return <AlertCircle className="w-5 h-5 text-yellow-500" />;
      default: return <PauseCircle className="w-5 h-5 text-gray-400" />;
    }
  };

  const toggleServer = async (name: string, action: 'start' | 'stop') => {
    try {
      await fetch(`/api/mcp/servers/${name}/${action}`, { method: 'POST' });
      setTimeout(fetchRepos, 1000);
    } catch { /* ignore */ }
  };

  const countByStatus = (servers: RepoServer[]) => ({
    running: servers.filter((s) => s.status === 'running').length,
    stopped: servers.filter((s) => s.status !== 'running' && s.status !== 'error').length,
    error: servers.filter((s) => s.status === 'error').length,
  });

  return (
    <div className="max-w-5xl mx-auto px-4 py-8">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Multi-repo MCP</h1>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
            MCP server orchestration across workspaces
          </p>
        </div>
        <button
          onClick={fetchRepos}
          className="flex items-center gap-1.5 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
        >
          <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} /> Refresh
        </button>
      </div>

      <div className="space-y-4">
        {loading && repos.length === 0 ? (
          <div className="p-8 text-center text-gray-500 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
            Loading repositories...
          </div>
        ) : repos.length === 0 ? (
          <div className="p-8 text-center text-gray-500 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
            <Globe className="w-12 h-12 mx-auto mb-3 opacity-50" />
            <p>No repositories with MCP servers found.</p>
          </div>
        ) : (
          repos.map((repo) => {
            const counts = countByStatus(repo.servers);
            const isExpanded = expanded === repo.name;
            return (
              <div key={repo.name} className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
                <button
                  onClick={() => setExpanded(isExpanded ? null : repo.name)}
                  className="w-full flex items-center justify-between p-4 hover:bg-gray-50 dark:hover:bg-gray-750"
                >
                  <div className="flex items-center gap-3">
                    {repoStatusIcon(repo.status)}
                    <div className="text-left">
                      <div className="font-medium text-gray-900 dark:text-white">{repo.name}</div>
                      <div className="text-xs text-gray-500 dark:text-gray-400">{repo.path}</div>
                    </div>
                  </div>
                  <div className="flex items-center gap-3 text-xs">
                    {counts.running > 0 && <span className="text-green-500">{counts.running} running</span>}
                    {counts.error > 0 && <span className="text-red-500">{counts.error} error</span>}
                    {counts.stopped > 0 && <span className="text-gray-400">{counts.stopped} stopped</span>}
                    <span className="text-gray-400 font-medium">{repo.servers.length} servers</span>
                  </div>
                </button>
                {isExpanded && (
                  <div className="border-t border-gray-200 dark:border-gray-700 divide-y divide-gray-100 dark:divide-gray-700">
                    {repo.servers.map((s) => (
                      <div key={s.name} className="flex items-center justify-between px-4 py-3 pl-12">
                        <div className="flex items-center gap-3">
                          <Cpu className="w-4 h-4 text-gray-400" />
                          <div>
                            <div className="flex items-center gap-2">
                              <span className="text-sm font-medium text-gray-900 dark:text-white">{s.name}</span>
                              <span className={`text-xs px-1.5 py-0.5 rounded-full ${
                                s.type === 'builtin' ? 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400' : 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400'
                              }`}>{s.type}</span>
                              <span className="text-xs text-gray-500">{s.description}</span>
                            </div>
                          </div>
                        </div>
                        <div className="flex items-center gap-2">
                          {statusIcon(s.status)}
                          <span className="text-xs text-gray-500 mr-2">{s.status}</span>
                          {s.status === 'running' ? (
                            <button onClick={() => toggleServer(s.name, 'stop')} className="p-1 text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 rounded">
                              <Square className="w-3.5 h-3.5" />
                            </button>
                          ) : (
                            <button onClick={() => toggleServer(s.name, 'start')} className="p-1 text-green-500 hover:bg-green-50 dark:hover:bg-green-900/20 rounded">
                              <Play className="w-3.5 h-3.5" />
                            </button>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}

export default MultiRepoViewInner;
