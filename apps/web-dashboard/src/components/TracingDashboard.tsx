import { useEffect, useState } from 'react';
import {
  Activity,
  Clock,
  AlertCircle,
  GitBranch,
  Search,
  ChevronDown,
  ChevronUp,
  ChevronLeft,
  ChevronRight,
  Download,
  ThumbsUp,
  ThumbsDown,
} from 'lucide-react';
import { readCached, writeCached } from '../lib/offlineCache';
import { useT } from '../hooks/useLocale';

const TRACES_CACHE_KEY = 'traces';

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

function TraceWaterfall({
  trace,
  allTraces,
  onFocus,
}: {
  trace: Trace;
  allTraces: Trace[];
  onFocus?: () => void;
}) {
  const { tt } = useT();
  const children = allTraces.filter((t) => t.parentSpanId === trace.spanId);
  const maxDuration = Math.max(...allTraces.map((t) => t.duration || 0), 1);
  const hasChildren = children.length > 0;
  const [expanded, setExpanded] = useState(true);

  const barWidth = trace.duration ? Math.max((trace.duration / maxDuration) * 100, 2) : 0;
  const barColor =
    trace.status === 'error'
      ? 'bg-red-500'
      : trace.status === 'running'
        ? 'bg-blue-400 animate-pulse'
        : 'bg-emerald-500';

  return (
    <div className="select-none">
      <div className="flex items-center gap-2 py-1.5 px-2 hover:bg-gray-50 dark:hover:bg-gray-800 rounded group">
        <button
          onClick={() => setExpanded(!expanded)}
          className={`p-0.5 rounded hover:bg-gray-200 dark:hover:bg-gray-700 ${hasChildren ? '' : 'invisible'}`}
        >
          {expanded ? (
            <ChevronDown className="w-3 h-3 text-gray-400" />
          ) : (
            <ChevronUp className="w-3 h-3 text-gray-400" />
          )}
        </button>
        <div className="flex items-center gap-1.5 min-w-[180px]">
          <span
            className={`w-1.5 h-1.5 rounded-full ${trace.status === 'completed' ? 'bg-green-500' : trace.status === 'running' ? 'bg-blue-500' : 'bg-red-500'}`}
          />
          <span
            className="text-xs font-mono text-gray-700 dark:text-gray-300 truncate cursor-pointer hover:text-blue-600 dark:hover:text-blue-400 hover:underline"
            title={tt('ui.focus_trace')}
            onClick={(e) => {
              e.stopPropagation();
              onFocus?.();
            }}
          >
            {trace.name}
          </span>
        </div>
        <div className="flex-1 h-4 bg-gray-100 dark:bg-gray-700 rounded overflow-hidden min-w-[100px]">
          <div
            className={`h-full ${barColor} rounded transition-all duration-300`}
            style={{ width: `${barWidth}%` }}
          />
        </div>
        <span className="text-xs text-gray-500 dark:text-gray-400 w-16 text-right tabular-nums">
          {trace.duration ? `${trace.duration}ms` : '-'}
        </span>
        <span className="text-xs text-gray-400 dark:text-gray-500 w-12 text-right">
          {trace.attributes.model || '—'}
        </span>
      </div>
      {expanded && hasChildren && (
        <div className="ml-4 border-l-2 border-gray-200 dark:border-gray-700 pl-2">
          {children.map((child) => (
            <TraceWaterfall key={child.spanId} trace={child} allTraces={allTraces} />
          ))}
        </div>
      )}
    </div>
  );
}

function TraceDetail({ trace, allTraces }: { trace: Trace; allTraces: Trace[] }) {
  const children = allTraces.filter((t) => t.parentSpanId === trace.spanId);
  return (
    <div className="space-y-4">
      <div className="card">
        <h3 className="text-base font-semibold text-gray-900 dark:text-white mb-3">{trace.name}</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
          <div>
            <p className="text-xs text-gray-500">Trace ID</p>
            <p className="font-mono text-gray-800 dark:text-gray-200">{trace.traceId}</p>
          </div>
          <div>
            <p className="text-xs text-gray-500">Span ID</p>
            <p className="font-mono text-gray-800 dark:text-gray-200">{trace.spanId}</p>
          </div>
          <div>
            <p className="text-xs text-gray-500">Duration</p>
            <p className="font-mono text-gray-800 dark:text-gray-200">{trace.duration}ms</p>
          </div>
          <div>
            <p className="text-xs text-gray-500">Status</p>
            <span
              className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                trace.status === 'completed'
                  ? 'text-green-700 bg-green-50 dark:text-green-300 dark:bg-green-900/20'
                  : trace.status === 'error'
                    ? 'text-red-700 bg-red-50 dark:text-red-300 dark:bg-red-900/20'
                    : 'text-blue-700 bg-blue-50 dark:text-blue-300 dark:bg-blue-900/20'
              }`}
            >
              {trace.status}
            </span>
          </div>
        </div>
        <div className="mt-3 grid grid-cols-2 gap-2 text-sm">
          {Object.entries(trace.attributes).map(([k, v]) => (
            <div key={k} className="flex gap-1">
              <span className="text-gray-500 font-medium">{k}:</span>
              <span className="text-gray-800 dark:text-gray-200 truncate">{v}</span>
            </div>
          ))}
        </div>
      </div>
      {children.length > 0 && (
        <div className="card">
          <h4 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">
            Child Spans ({children.length})
          </h4>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 dark:border-gray-700">
                  <th className="text-left py-2 px-3 text-xs font-medium text-gray-500">Name</th>
                  <th className="text-right py-2 px-3 text-xs font-medium text-gray-500">
                    Duration
                  </th>
                  <th className="text-right py-2 px-3 text-xs font-medium text-gray-500">Input</th>
                  <th className="text-right py-2 px-3 text-xs font-medium text-gray-500">Output</th>
                  <th className="text-right py-2 px-3 text-xs font-medium text-gray-500">Cost</th>
                </tr>
              </thead>
              <tbody>
                {children.map((c) => (
                  <tr key={c.spanId} className="border-b border-gray-100 dark:border-gray-800">
                    <td className="py-2 px-3 text-gray-800 dark:text-gray-200 font-mono text-xs">
                      {c.name}
                    </td>
                    <td className="py-2 px-3 text-right text-gray-600 dark:text-gray-400">
                      {c.duration}ms
                    </td>
                    <td className="py-2 px-3 text-right text-gray-600 dark:text-gray-400">
                      {c.attributes.inputTokens}
                    </td>
                    <td className="py-2 px-3 text-right text-gray-600 dark:text-gray-400">
                      {c.attributes.outputTokens}
                    </td>
                    <td className="py-2 px-3 text-right text-gray-600 dark:text-gray-400">
                      ${parseFloat(c.attributes.cost || '0').toFixed(4)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}

function FeedbackButtons({ traceId, spanId }: { traceId: string; spanId: string }) {
  const [sent, setSent] = useState<'up' | 'down' | null>(null);
  const sendFeedback = async (type: 'up' | 'down') => {
    setSent(type);
    try {
      await fetch('/api/feedback', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ traceId, spanId, type }),
      });
    } catch {
      /* best-effort */
    }
  };
  return (
    <div className="flex items-center gap-1 ml-2 opacity-0 group-hover:opacity-100 transition-opacity">
      <button
        onClick={() => sendFeedback('up')}
        className={`p-1 rounded hover:bg-green-100 dark:hover:bg-green-900/30 ${sent === 'up' ? 'text-green-500' : 'text-gray-400'}`}
      >
        <ThumbsUp className="w-3 h-3" />
      </button>
      <button
        onClick={() => sendFeedback('down')}
        className={`p-1 rounded hover:bg-red-100 dark:hover:bg-red-900/30 ${sent === 'down' ? 'text-red-500' : 'text-gray-400'}`}
      >
        <ThumbsDown className="w-3 h-3" />
      </button>
    </div>
  );
}

export function TracingDashboard() {
  const { tt } = useT();
  const [traces, setTraces] = useState<Trace[]>([]);
  const [stats, setStats] = useState<TraceStats>({
    totalTraces: 0,
    avgDuration: 0,
    errorRate: 0,
    activeSpans: 0,
  });
  const [selectedTrace, setSelectedTrace] = useState<Trace | null>(null);
  const [search, setSearch] = useState('');
  const [filterModel, setFilterModel] = useState('');
  const [tablePage, setTablePage] = useState(0);
  const [wfPage, setWfPage] = useState(0);
  const [range, setRange] = useState<'all' | '1h' | '24h' | '7d'>('all');
  const [focusId, setFocusId] = useState<string | null>(null);
  const [lastUpdate, setLastUpdate] = useState<Date | null>(null);
  const [offline, setOffline] = useState(false);

  useEffect(() => {
    const loadTraces = async () => {
      try {
        const qs = range === 'all' ? '' : `?range=${range}`;
        const response = await fetch(`/api/traces${qs}`);
        const data = await response.json();
        setTraces(data.traces || []);
        setStats(data.stats || stats);
        writeCached(TRACES_CACHE_KEY, { traces: data.traces || [], stats: data.stats || stats });
        setOffline(false);
        setLastUpdate(new Date());
      } catch {
        const cached = readCached<{ traces: Trace[]; stats: TraceStats }>(TRACES_CACHE_KEY);
        if (cached?.data) {
          setTraces(cached.data.traces || []);
          setStats(cached.data.stats || stats);
          setOffline(true);
        }
      }
    };
    void loadTraces();
    const interval = setInterval(loadTraces, 5000);
    return () => clearInterval(interval);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [range]);

  const exportCsv = () => {
    const header = 'name,status,duration_ms,model,input_tokens,output_tokens,cost,start_time';
    const lines = recentSpans.map((t) =>
      [
        `"${t.name.replace(/"/g, '""')}"`,
        t.status,
        t.duration ?? '',
        t.attributes.model || '',
        t.attributes.inputTokens,
        t.attributes.outputTokens,
        t.attributes.cost,
        new Date(t.startTime).toISOString(),
      ].join(','),
    );
    const blob = new Blob([[header, ...lines].join('\n')], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `traces-${new Date().toISOString().slice(0, 19).replace(/[:T]/g, '-')}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const rootTraces = traces.filter((t) => !t.parentSpanId || t.parentSpanId === t.traceId);
  const models = [...new Set(traces.map((t) => t.attributes.model).filter(Boolean))];

  const matchesFilters = (t: Trace) => {
    if (
      search &&
      !t.name.toLowerCase().includes(search.toLowerCase()) &&
      !t.traceId.toLowerCase().includes(search.toLowerCase())
    )
      return false;
    if (filterModel && t.attributes.model !== filterModel) return false;
    return true;
  };

  const filteredRoots = rootTraces.filter(matchesFilters);

  // Recent spans table: newest first, filtered, paginated (10/page).
  const recentSpans = traces
    .filter(matchesFilters)
    .sort((a, b) => b.startTime - a.startTime);
  const TABLE_PAGE_SIZE = 10;
  const tablePages = Math.max(1, Math.ceil(recentSpans.length / TABLE_PAGE_SIZE));
  const safeTablePage = Math.min(tablePage, tablePages - 1);
  const tableRows = recentSpans.slice(
    safeTablePage * TABLE_PAGE_SIZE,
    (safeTablePage + 1) * TABLE_PAGE_SIZE,
  );

  // Waterfall: same filters, paginated roots (10/page). Focus mode drills into one trace subtree.
  const focusRoot = focusId ? (filteredRoots.find((t) => t.spanId === focusId) ?? null) : null;
  const focusSet = focusRoot
    ? [focusRoot, ...traces.filter((t) => t.traceId === focusRoot.traceId && t.parentSpanId)]
    : [];
  const WF_PAGE_SIZE = 10;
  const wfPages = Math.max(1, Math.ceil(filteredRoots.length / WF_PAGE_SIZE));
  const safeWfPage = Math.min(wfPage, wfPages - 1);
  const wfRows = focusRoot
    ? [focusRoot]
    : filteredRoots.slice(safeWfPage * WF_PAGE_SIZE, (safeWfPage + 1) * WF_PAGE_SIZE);
  const filtersActive = Boolean(search || filterModel);

  return (
    <div className="max-w-7xl mx-auto px-4 py-8 space-y-6">
      {offline && (
        <div className="bg-amber-50 dark:bg-amber-900/30 border border-amber-200 dark:border-amber-800 rounded-lg px-4 py-2 text-sm text-amber-700 dark:text-amber-300">
          Offline mode — showing cached traces (server unavailable)
        </div>
      )}
      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="card">
          <div className="flex items-center justify-between">
            <div title={tt('ui.tip_total_traces')}>
              <p className="metric-label">{tt('ui.total_traces')}</p>
              <p className="metric-value">{stats.totalTraces}</p>
            </div>
            <Activity className="w-8 h-8 text-blue-500" />
          </div>
        </div>
        <div className="card">
          <div className="flex items-center justify-between">
            <div title={tt('ui.tip_avg_duration')}>
              <p className="metric-label">{tt('ui.avg_duration')}</p>
              <p className="metric-value">{stats.avgDuration}ms</p>
            </div>
            <Clock className="w-8 h-8 text-yellow-500" />
          </div>
        </div>
        <div className="card">
          <div className="flex items-center justify-between">
            <div title={tt('ui.tip_error_rate')}>
              <p className="metric-label">{tt('ui.error_rate')}</p>
              <p className="metric-value">{(stats.errorRate * 100).toFixed(1)}%</p>
            </div>
            <AlertCircle className="w-8 h-8 text-red-500" />
          </div>
        </div>
        <div className="card">
          <div className="flex items-center justify-between">
            <div title={tt('ui.tip_active_spans')}>
              <p className="metric-label">{tt('ui.active_spans')}</p>
              <p className="metric-value">{stats.activeSpans}</p>
            </div>
            <GitBranch className="w-8 h-8 text-green-500" />
          </div>
        </div>
      </div>

      {/* Waterfall View */}
      <div className="card">
        <div className="flex items-start justify-between mb-1">
          <div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
              {tt('ui.trace_waterfall')}
            </h3>
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5 max-w-2xl">
              {tt('ui.waterfall_subtitle')}
            </p>
          </div>
          <div className="flex items-center gap-3 shrink-0 ml-4">
            <div className="relative">
              <Search className="w-3.5 h-3.5 absolute left-2.5 top-1/2 -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder={tt('ui.search_traces')}
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pl-7 pr-3 py-1.5 text-xs border border-gray-200 dark:border-gray-700 rounded bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 w-40"
              />
            </div>
            {models.length > 0 && (
              <select
                value={filterModel}
                onChange={(e) => setFilterModel(e.target.value)}
                className="px-2 py-1.5 text-xs border border-gray-200 dark:border-gray-700 rounded bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100"
              >
                <option value="">{tt('ui.all_models')}</option>
                {models.map((m) => (
                  <option key={m} value={m}>
                    {m || '—'}
                  </option>
                ))}
              </select>
            )}
            <select
              value={range}
              onChange={(e) => {
                setRange(e.target.value as typeof range);
                setWfPage(0);
                setTablePage(0);
              }}
              className="px-2 py-1.5 text-xs border border-gray-200 dark:border-gray-700 rounded bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100"
              title={tt('ui.tip_range')}
            >
              <option value="all">{tt('ui.range_all')}</option>
              <option value="1h">{tt('ui.range_1h')}</option>
              <option value="24h">{tt('ui.range_24h')}</option>
              <option value="7d">{tt('ui.range_7d')}</option>
            </select>
            <button
              onClick={exportCsv}
              disabled={recentSpans.length === 0}
              className="flex items-center gap-1 px-2 py-1.5 text-xs border border-gray-200 dark:border-gray-700 rounded hover:bg-gray-100 dark:hover:bg-gray-700 disabled:opacity-40 disabled:cursor-not-allowed text-gray-600 dark:text-gray-300"
              title={tt('ui.export_csv')}
            >
              <Download className="w-3 h-3" />
              CSV
            </button>
          </div>
        </div>

        {/* Filter status bar */}
        <div className="flex items-center justify-between mb-2 text-xs">
          <span className="text-gray-500 dark:text-gray-400">
            {focusRoot
              ? tt('ui.focused_on').replace('{name}', focusRoot.name)
              : tt('ui.showing_of')
                  .replace('{shown}', String(filteredRoots.length))
                  .replace('{total}', String(rootTraces.length))}
          </span>
          <span className="flex items-center gap-2">
            {offline ? (
              <span className="text-amber-600 dark:text-amber-400 flex items-center gap-1">
                <span className="w-1.5 h-1.5 rounded-full bg-amber-500" />
                {tt('ui.offline_cached')}
              </span>
            ) : (
              lastUpdate && (
                <span className="text-green-600 dark:text-green-400 flex items-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse" />
                  {tt('ui.live_updated')} {lastUpdate.toLocaleTimeString()}
                </span>
              )
            )}
            {filtersActive && (
              <button
                onClick={() => {
                  setSearch('');
                  setFilterModel('');
                  setWfPage(0);
                  setTablePage(0);
                }}
                className="text-blue-600 dark:text-blue-400 hover:underline flex items-center gap-1"
              >
                <AlertCircle className="w-3 h-3" />
                {tt('ui.clear_filters')}
              </button>
            )}
          </span>
        </div>

        {traces.length === 0 ? (
          <div className="text-center py-12 text-gray-400">
            <Activity className="w-10 h-10 mx-auto mb-3 opacity-50" />
            <p className="text-sm">{tt('ui.no_traces')}</p>
            <p className="text-xs text-gray-500 mt-1">
              {tt('ui.traces_source')}
            </p>
          </div>
        ) : filteredRoots.length === 0 ? (
          <div className="text-center py-8 text-gray-400">
            <Search className="w-8 h-8 mx-auto mb-2 opacity-40" />
            <p className="text-sm">{tt('ui.no_matches')}</p>
          </div>
        ) : (
          <>
            {/* Legend */}
            <div className="flex flex-wrap items-center gap-x-4 gap-y-1 pb-2 text-[11px] text-gray-500 dark:text-gray-400">
              <span className="flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-green-500" />
                {tt('ui.legend_completed')}
              </span>
              <span className="flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-blue-500 animate-pulse" />
                {tt('ui.legend_running')}
              </span>
              <span className="flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-red-500" />
                {tt('ui.legend_error')}
              </span>
              <span className="italic">— {tt('ui.legend_bar')}</span>
            </div>
            {/* Waterfall header */}
            <div className="flex items-center gap-2 pb-2 border-b border-gray-200 dark:border-gray-700 mb-1 text-xs text-gray-500 font-medium">
              <div className="w-[22px]" />
              <div className="min-w-[180px]" title={tt('ui.tip_name')}>{tt('ui.col_name')}</div>
              <div className="flex-1" title={tt('ui.tip_timeline')}>{tt('ui.col_timeline')}</div>
              <div className="w-16 text-right" title={tt('ui.tip_duration_wf')}>{tt('ui.duration')}</div>
              <div className="w-12 text-right" title={tt('ui.tip_model')}>{tt('ui.model')}</div>
              <div className="w-16" />
            </div>
            <div className="divide-y divide-gray-100 dark:divide-gray-800">
              {focusRoot && (
                <button
                  onClick={() => setFocusId(null)}
                  className="text-xs text-blue-600 dark:text-blue-400 hover:underline flex items-center gap-1 mb-2"
                >
                  <ChevronLeft className="w-3 h-3" />
                  {tt('ui.back_overview')}
                </button>
              )}
              {wfRows.map((t) => (
                <div key={t.spanId} className="group">
                  <div
                    className="flex items-center cursor-pointer"
                    onClick={() => setSelectedTrace(selectedTrace?.spanId === t.spanId ? null : t)}
                  >
                    <TraceWaterfall
                      trace={t}
                      allTraces={focusRoot ? focusSet : traces}
                      onFocus={() => setFocusId(t.spanId)}
                    />
                    <FeedbackButtons traceId={t.traceId} spanId={t.spanId} />
                  </div>
                  {selectedTrace?.spanId === t.spanId && (
                    <div className="ml-6 mb-3">
                      <TraceDetail trace={t} allTraces={traces} />
                    </div>
                  )}
                </div>
              ))}
            </div>
            {!focusRoot && wfPages > 1 && (
              <div className="flex items-center justify-between mt-3 pt-3 border-t border-gray-100 dark:border-gray-800">
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  {safeWfPage * WF_PAGE_SIZE + 1}–{Math.min((safeWfPage + 1) * WF_PAGE_SIZE, filteredRoots.length)}{' '}
                  {tt('ui.of')} {filteredRoots.length}
                </p>
                <div className="flex items-center gap-1">
                  <button
                    onClick={() => setWfPage(Math.max(0, safeWfPage - 1))}
                    disabled={safeWfPage === 0}
                    className="p-1.5 rounded hover:bg-gray-100 dark:hover:bg-gray-700 disabled:opacity-30 disabled:cursor-not-allowed"
                    aria-label={tt('ui.previous_page')}
                  >
                    <ChevronLeft className="w-4 h-4 text-gray-600 dark:text-gray-300" />
                  </button>
                  <span className="text-xs text-gray-600 dark:text-gray-300 tabular-nums px-2">
                    {safeWfPage + 1} / {wfPages}
                  </span>
                  <button
                    onClick={() => setWfPage(Math.min(wfPages - 1, safeWfPage + 1))}
                    disabled={safeWfPage >= wfPages - 1}
                    className="p-1.5 rounded hover:bg-gray-100 dark:hover:bg-gray-700 disabled:opacity-30 disabled:cursor-not-allowed"
                    aria-label={tt('ui.next_page')}
                  >
                    <ChevronRight className="w-4 h-4 text-gray-600 dark:text-gray-300" />
                  </button>
                </div>
              </div>
            )}
          </>
        )}
      </div>

      {/* Recent spans table */}
      <div className="card">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
            {tt('ui.recent_spans')}
          </h3>
          <span className="text-xs text-gray-500">
            {recentSpans.length} {tt('ui.total')}
          </span>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-200 dark:border-gray-700">
                <th className="text-left py-2 px-4 text-sm font-medium text-gray-500">{tt('ui.name')}</th>
                <th className="text-left py-2 px-4 text-sm font-medium text-gray-500">{tt('ui.status')}</th>
                <th className="text-right py-2 px-4 text-sm font-medium text-gray-500">{tt('ui.duration')}</th>
                <th className="text-left py-2 px-4 text-sm font-medium text-gray-500">{tt('ui.model')}</th>
                <th className="text-right py-2 px-4 text-sm font-medium text-gray-500">{tt('ui.tokens')}</th>
                <th className="text-right py-2 px-4 text-sm font-medium text-gray-500">{tt('ui.cost')}</th>
                <th className="text-left py-2 px-4 text-sm font-medium text-gray-500">{tt('ui.started')}</th>
              </tr>
            </thead>
            <tbody>
              {tableRows.map((t) => {
                const ageMin = Math.round((Date.now() - t.startTime) / 60000);
                const rel =
                  ageMin < 1
                    ? tt('ui.just_now')
                    : ageMin < 60
                      ? `${ageMin} ${tt('ui.min_ago')}`
                      : ageMin < 1440
                        ? tt('ui.hours_ago').replace('{n}', String(Math.floor(ageMin / 60)))
                        : tt('ui.days_ago').replace('{n}', String(Math.floor(ageMin / 1440)));
                return (
                  <tr
                    key={t.spanId}
                    className="border-b border-gray-100 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-gray-800 cursor-pointer"
                    onClick={() => setSelectedTrace(t)}
                  >
                    <td className="py-2 px-4 text-sm text-gray-900 dark:text-white">{t.name}</td>
                    <td className="py-2 px-4">
                      <span
                        className={`inline-flex px-2 py-1 rounded-full text-xs font-medium ${
                          t.status === 'completed'
                            ? 'text-green-700 bg-green-50 dark:text-green-300 dark:bg-green-900/20'
                            : t.status === 'running'
                              ? 'text-blue-700 bg-blue-50 dark:text-blue-300 dark:bg-blue-900/20'
                              : 'text-red-700 bg-red-50 dark:text-red-300 dark:bg-red-900/20'
                        }`}
                      >
                        {t.status}
                      </span>
                    </td>
                    <td className="py-2 px-4 text-sm text-right text-gray-600 dark:text-gray-400 tabular-nums">
                      {t.duration ? `${t.duration}ms` : '-'}
                    </td>
                    <td className="py-2 px-4 text-sm text-gray-600 dark:text-gray-400">
                      {t.attributes.model || '-'}
                    </td>
                    <td className="py-2 px-4 text-sm text-right text-gray-600 dark:text-gray-400 tabular-nums">
                      {(Number(t.attributes.inputTokens) || 0) + (Number(t.attributes.outputTokens) || 0)}
                    </td>
                    <td className="py-2 px-4 text-sm text-right text-gray-600 dark:text-gray-400 tabular-nums">
                      ${parseFloat(t.attributes.cost || '0').toFixed(4)}
                    </td>
                    <td
                      className="py-2 px-4 text-sm whitespace-nowrap"
                      title={new Date(t.startTime).toLocaleString()}
                    >
                      <span className={`font-medium ${ageMin < 5 ? 'text-green-600 dark:text-green-400' : 'text-gray-600 dark:text-gray-400'}`}>
                        {rel}
                      </span>
                      <span className="block text-xs text-gray-400">
                        {new Date(t.startTime).toLocaleTimeString()}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
        {tablePages > 1 && (
          <div className="flex items-center justify-between mt-4 pt-3 border-t border-gray-100 dark:border-gray-800">
            <p className="text-xs text-gray-500 dark:text-gray-400">
              {safeTablePage * TABLE_PAGE_SIZE + 1}–{Math.min((safeTablePage + 1) * TABLE_PAGE_SIZE, recentSpans.length)}{' '}
              {tt('ui.of')} {recentSpans.length}
            </p>
            <div className="flex items-center gap-1">
              <button
                onClick={() => setTablePage(Math.max(0, safeTablePage - 1))}
                disabled={safeTablePage === 0}
                className="p-1.5 rounded hover:bg-gray-100 dark:hover:bg-gray-700 disabled:opacity-30 disabled:cursor-not-allowed"
                aria-label={tt('ui.previous_page')}
              >
                <ChevronLeft className="w-4 h-4 text-gray-600 dark:text-gray-300" />
              </button>
              <span className="text-xs text-gray-600 dark:text-gray-300 tabular-nums px-2">
                {safeTablePage + 1} / {tablePages}
              </span>
              <button
                onClick={() => setTablePage(Math.min(tablePages - 1, safeTablePage + 1))}
                disabled={safeTablePage >= tablePages - 1}
                className="p-1.5 rounded hover:bg-gray-100 dark:hover:bg-gray-700 disabled:opacity-30 disabled:cursor-not-allowed"
                aria-label={tt('ui.next_page')}
              >
                <ChevronRight className="w-4 h-4 text-gray-600 dark:text-gray-300" />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default TracingDashboard;
