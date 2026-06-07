import { Activity } from 'lucide-react';
import { useLiveTraces } from '../hooks/useLiveTraces';

export function LiveTraceFeed() {
  const traces = useLiveTraces();

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
      <div className="flex items-center gap-2 mb-3">
        <Activity className="w-4 h-4 text-blue-500" />
        <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300">Trazas en vivo</h3>
        {traces.length > 0 && (
          <span className="ml-auto text-xs text-gray-400">{traces.length} activa(s)</span>
        )}
      </div>
      {traces.length === 0 ? (
        <p className="text-xs text-gray-400">Esperando actividad de agentes...</p>
      ) : (
        <div className="space-y-1.5">
          {traces.map((t) => (
            <div key={t.id} className="flex items-center gap-2 px-2 py-1 rounded bg-blue-50 dark:bg-blue-900/10 text-xs">
              <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
              <span className="font-mono text-gray-600 dark:text-gray-400 truncate min-w-0 flex-1">{t.id}</span>
              <span className="text-gray-500">{t.turnCount} turnos</span>
              <span className="text-gray-400 ml-auto">{t.model}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
