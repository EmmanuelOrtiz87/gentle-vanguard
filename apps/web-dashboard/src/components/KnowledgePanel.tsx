import { useState, useCallback } from 'react';
import { Search, BookOpen, Activity, MessageSquare, Camera, ChevronDown, ChevronUp } from 'lucide-react';

interface KnowledgeResult {
  source: string;
  id: string;
  title: string;
  content: string;
  timestamp: string;
  relevance: number;
}

const SOURCE_ICONS: Record<string, typeof BookOpen> = {
  events: Activity,
  traces: Activity,
  feedback: MessageSquare,
  checkpoints: Camera,
};

const SOURCE_COLORS: Record<string, string> = {
  events: 'bg-cyan-100 text-cyan-700 dark:bg-cyan-900/30 dark:text-cyan-400',
  traces: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400',
  feedback: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
  checkpoints: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400',
};

function KnowledgePanelInner() {
  const [query, setQuery] = useState('');
  const [sources, setSources] = useState(['events', 'traces', 'feedback', 'checkpoints']);
  const [results, setResults] = useState<KnowledgeResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [expanded, setExpanded] = useState<string | null>(null);
  const [searched, setSearched] = useState(false);

  const toggleSource = (src: string) => {
    setSources((prev) => prev.includes(src) ? prev.filter((s) => s !== src) : [...prev, src]);
  };

  const search = useCallback(async () => {
    if (!query.trim()) return;
    setLoading(true);
    setSearched(true);
    try {
      const res = await fetch(`/api/knowledge?q=${encodeURIComponent(query)}&sources=${sources.join(',')}&limit=20`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const msg = await res.json();
      setResults(msg.data?.results || []);
    } catch {
      setResults([]);
    }
    setLoading(false);
  }, [query, sources]);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') void search();
  };

  return (
    <div className="max-w-5xl mx-auto px-4 py-8">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Knowledge Base</h1>
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
          Unified search across events, traces, feedback, and checkpoints
        </p>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4 mb-4">
        <div className="flex items-center gap-2 mb-3">
          <Search className="w-5 h-5 text-gray-400" />
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Search knowledge base..."
            className="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md text-sm bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
          <button
            onClick={search}
            disabled={loading || !query.trim()}
            className="px-4 py-2 bg-blue-600 text-white rounded-md text-sm font-medium hover:bg-blue-700 disabled:opacity-50"
          >
            {loading ? 'Searching...' : 'Search'}
          </button>
        </div>
        <div className="flex flex-wrap gap-2">
          {['events', 'traces', 'feedback', 'checkpoints'].map((src) => {
            const Icon = SOURCE_ICONS[src] || BookOpen;
            return (
              <button
                key={src}
                onClick={() => toggleSource(src)}
                className={`flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium border ${
                  sources.includes(src)
                    ? 'bg-blue-50 text-blue-700 border-blue-200 dark:bg-blue-900/20 dark:text-blue-400 dark:border-blue-800'
                    : 'bg-gray-50 text-gray-500 border-gray-200 dark:bg-gray-700 dark:text-gray-400 dark:border-gray-600'
                }`}
              >
                <Icon className="w-3 h-3" />
                {src}
              </button>
            );
          })}
        </div>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
        {loading ? (
          <div className="p-8 text-center text-gray-500">Searching...</div>
        ) : !searched ? (
          <div className="p-8 text-center text-gray-500">
            <BookOpen className="w-12 h-12 mx-auto mb-3 opacity-50" />
            <p>Enter a query to search the knowledge base.</p>
          </div>
        ) : results.length === 0 ? (
          <div className="p-8 text-center text-gray-500">No results found.</div>
        ) : (
          <div className="divide-y divide-gray-200 dark:divide-gray-700">
            {results.map((r, i) => {
              const isExpanded = expanded === `${r.source}-${i}`;
              const colorClass = SOURCE_COLORS[r.source] || 'bg-gray-100 text-gray-700';
              return (
                <div key={`${r.source}-${r.id}-${i}`} className="p-4">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-2 mb-1">
                      <span className={`text-xs px-1.5 py-0.5 rounded-full font-medium ${colorClass}`}>
                        {r.source.toUpperCase()}
                      </span>
                      <span className="font-medium text-gray-900 dark:text-white text-sm">{r.title}</span>
                      <span className="text-xs text-gray-400">{r.timestamp}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="text-xs text-gray-400">{Math.round(r.relevance * 100)}%</span>
                      <button
                        onClick={() => setExpanded(isExpanded ? null : `${r.source}-${i}`)}
                        className="text-gray-400 hover:text-gray-600"
                      >
                        {isExpanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
                      </button>
                    </div>
                  </div>
                  <p className="text-xs text-gray-500 dark:text-gray-400 mt-1 line-clamp-2">{r.content}</p>
                  {isExpanded && (
                    <pre className="mt-2 p-2 bg-gray-50 dark:bg-gray-900 rounded text-xs text-gray-600 dark:text-gray-400 overflow-x-auto whitespace-pre-wrap">
                      {JSON.stringify(r, null, 2)}
                    </pre>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}

export default KnowledgePanelInner;
