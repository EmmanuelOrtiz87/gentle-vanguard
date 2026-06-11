import { useEffect, useState } from 'react';
import { Activity, Clock, AlertCircle, GitBranch } from 'lucide-react';

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

export function TracingDashboard() {
  const [traces, setTraces] = useState<Trace[]>([]);
  const [stats, setStats] = useState<TraceStats>({
    totalTraces: 0,
    avgDuration: 0,
    errorRate: 0,
    activeSpans: 0,
  });
  const [selectedTrace, setSelectedTrace] = useState<Trace | null>(null);

  useEffect(() => {
    // Load traces from file
    const loadTraces = async () => {
      try {
        const response = await fetch('/api/traces');
        const data = await response.json();
        setTraces(data.traces || []);
        setStats(data.stats || stats);
      } catch {
        // Use mock data if API not available
        const mockTraces: Trace[] = [
          {
            traceId: 'abc123',
            spanId: 'span001',
            name: 'skill-execution',
            startTime: Date.now() - 5000,
            endTime: Date.now() - 4800,
            duration: 200,
            status: 'completed',
            attributes: { skill: 'react-skill', agent: 'DEV' },
          },
          {
            traceId: 'abc124',
            spanId: 'span002',
            name: 'mcp-tool-call',
            startTime: Date.now() - 3000,
            status: 'running',
            attributes: { tool: 'list_skills' },
          },
        ];
        setTraces(mockTraces);
        setStats({
          totalTraces: 156,
          avgDuration: 245,
          errorRate: 0.02,
          activeSpans: 3,
        });
      }
    };

    void loadTraces();
    const interval = setInterval(loadTraces, 5000);
    return () => clearInterval(interval);
  }, []);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'text-green-500';
      case 'running': return 'text-blue-500';
      case 'error': return 'text-red-500';
      default: return 'text-gray-500';
    }
  };

  return (
    <div className="space-y-6">
      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="metric-label">Total Traces</p>
              <p className="metric-value">{stats.totalTraces}</p>
            </div>
            <Activity className="w-8 h-8 text-blue-500" />
          </div>
        </div>
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="metric-label">Avg Duration</p>
              <p className="metric-value">{stats.avgDuration}ms</p>
            </div>
            <Clock className="w-8 h-8 text-yellow-500" />
          </div>
        </div>
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="metric-label">Error Rate</p>
              <p className="metric-value">{(stats.errorRate * 100).toFixed(1)}%</p>
            </div>
            <AlertCircle className="w-8 h-8 text-red-500" />
          </div>
        </div>
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="metric-label">Active Spans</p>
              <p className="metric-value">{stats.activeSpans}</p>
            </div>
            <GitBranch className="w-8 h-8 text-green-500" />
          </div>
        </div>
      </div>

      {/* Traces Table */}
      <div className="card">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          Recent Traces
        </h3>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-200 dark:border-gray-700">
                <th className="text-left py-2 px-4 text-sm font-medium text-gray-500">Trace ID</th>
                <th className="text-left py-2 px-4 text-sm font-medium text-gray-500">Name</th>
                <th className="text-left py-2 px-4 text-sm font-medium text-gray-500">Status</th>
                <th className="text-left py-2 px-4 text-sm font-medium text-gray-500">Duration</th>
                <th className="text-left py-2 px-4 text-sm font-medium text-gray-500">Date/Time (ART)</th>
                <th className="text-left py-2 px-4 text-sm font-medium text-gray-500">Attributes</th>
              </tr>
            </thead>
            <tbody>
              {traces.map((trace) => (
                <tr
                  key={trace.spanId}
                  className="border-b border-gray-100 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-gray-800 cursor-pointer"
                  onClick={() => setSelectedTrace(trace)}
                >
                  <td className="py-2 px-4 text-sm font-mono text-gray-600 dark:text-gray-400">
                    {trace.traceId.substring(0, 8)}...
                  </td>
                  <td className="py-2 px-4 text-sm text-gray-900 dark:text-white">{trace.name}</td>
                  <td className="py-2 px-4">
                    <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(trace.status)}`}>
                      {trace.status}
                    </span>
                  </td>
                  <td className="py-2 px-4 text-sm text-gray-600 dark:text-gray-400">
                    {trace.duration ? `${trace.duration}ms` : '-'}
                  </td>
                  <td className="py-2 px-4 text-sm text-gray-600 dark:text-gray-400">
                    {new Date(trace.startTime).toLocaleString('es-AR', { timeZone: 'America/Argentina/Buenos_Aires' })}
                  </td>
                  <td className="py-2 px-4 text-sm text-gray-600 dark:text-gray-400">
                    {Object.entries(trace.attributes).map(([k, v]) => `${k}=${v}`).join(', ')}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Trace Detail */}
      {selectedTrace && (
        <div className="card">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            Trace Detail: {selectedTrace.name}
          </h3>
          <div className="space-y-2 text-sm">
            <p><strong>Trace ID:</strong> {selectedTrace.traceId}</p>
            <p><strong>Span ID:</strong> {selectedTrace.spanId}</p>
            <p><strong>Parent Span:</strong> {selectedTrace.parentSpanId || 'None'}</p>
            <p><strong>Status:</strong> {selectedTrace.status}</p>
            <p><strong>Duration:</strong> {selectedTrace.duration}ms</p>
            <p><strong>Start Time:</strong> {new Date(selectedTrace.startTime).toLocaleString('es-AR', { timeZone: 'America/Argentina/Buenos_Aires' })}</p>
            <div>
              <strong>Attributes:</strong>
              <pre className="mt-2 p-2 bg-gray-100 dark:bg-gray-800 rounded text-xs">
                {JSON.stringify(selectedTrace.attributes, null, 2)}
              </pre>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default TracingDashboard;
