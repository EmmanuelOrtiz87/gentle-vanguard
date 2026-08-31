import { useCallback, useEffect, useState } from 'react';
import { ExternalLink, Power, RefreshCw } from 'lucide-react';
import { apiFetch } from '../lib/api';
import { useT } from '../hooks/useLocale';

type AppStatus = 'running' | 'stopped' | 'partial';
interface AppProcess {
  name: string;
  pid: number | null;
  port: number;
  alive: boolean;
}
interface AppInfo {
  id: string;
  name: string;
  description: string;
  status: AppStatus;
  url: string;
  processes: AppProcess[];
}

const statusClasses: Record<AppStatus, string> = {
  running: 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300',
  stopped: 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300',
  partial: 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300',
};

export default function AppsControlPanel() {
  const { tt } = useT();
  const [apps, setApps] = useState<AppInfo[]>([]);
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      const response = await apiFetch('/api/apps');
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      setApps((await response.json()) as AppInfo[]);
      setError(null);
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : tt('ui.apps_load_error'));
    }
  }, [tt]);

  useEffect(() => {
    void load();
    const timer = window.setInterval(() => void load(), 5000);
    return () => window.clearInterval(timer);
  }, [load]);

  const toggle = async (app: AppInfo) => {
    if (app.id === 'dashboard') return;
    const action = app.status === 'running' ? 'stop' : 'start';
    if (action === 'stop' && !window.confirm(tt('ui.apps_stop_confirm'))) return;
    setBusy(app.id);
    setError(null);
    try {
      const response = await apiFetch(`/api/apps/${encodeURIComponent(app.id)}/${action}`, {
        method: 'POST',
      });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      await response.json();
      await load();
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : tt('ui.apps_action_error'));
    } finally {
      setBusy(null);
    }
  };

  return (
    <section className="max-w-7xl mx-auto px-4 py-8" aria-labelledby="apps-title">
      <div className="flex items-start justify-between mb-6">
        <div>
          <h1 id="apps-title" className="text-2xl font-bold text-gray-900 dark:text-white">
            {tt('ui.apps_title')}
          </h1>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">{tt('ui.apps_subtitle')}</p>
        </div>
        <button
          onClick={() => void load()}
          className="p-2 rounded-lg border border-gray-300 dark:border-gray-600"
          aria-label={tt('ui.apps_refresh')}
        >
          <RefreshCw className="w-4 h-4" />
        </button>
      </div>
      {error && (
        <p className="mb-4 rounded border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {error}
        </p>
      )}
      <div className="grid gap-4 md:grid-cols-2">
        {apps.map((app) => (
          <article
            key={app.id}
            className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-5"
          >
            <div className="flex items-start justify-between gap-3">
              <div>
                <h2 className="font-semibold text-gray-900 dark:text-white">{app.name}</h2>
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">{app.description}</p>
              </div>
              <span
                className={`rounded-full px-2.5 py-1 text-xs font-medium ${statusClasses[app.status]}`}
              >
                {tt(`ui.apps_status_${app.status}`)}
              </span>
            </div>
            <div className="mt-4 space-y-1 text-xs text-gray-500 dark:text-gray-400">
              {app.processes.map((processInfo) => (
                <div key={processInfo.name} className="flex justify-between">
                  <span>{processInfo.name}</span>
                  <span>
                    {processInfo.alive
                      ? `PID ${processInfo.pid ?? '—'} · ${tt('ui.apps_port')} ${processInfo.port}`
                      : `${tt('ui.apps_port')} ${processInfo.port} · ${tt('ui.apps_offline')}`}
                  </span>
                </div>
              ))}
            </div>
            <div className="mt-5 flex gap-2">
              <button
                onClick={() => void toggle(app)}
                disabled={app.id === 'dashboard' || busy === app.id}
                className="inline-flex items-center gap-2 rounded bg-blue-600 px-3 py-2 text-sm text-white disabled:cursor-not-allowed disabled:opacity-50"
              >
                <Power className="w-4 h-4" />
                {app.status === 'running' ? tt('ui.apps_power_off') : tt('ui.apps_power_on')}
              </button>
              <button
                onClick={() => window.open(app.url, '_blank', 'noopener,noreferrer')}
                className="inline-flex items-center gap-2 rounded border border-gray-300 px-3 py-2 text-sm dark:border-gray-600"
              >
                <ExternalLink className="w-4 h-4" />
                {tt('ui.apps_open')}
              </button>
            </div>
            {app.id === 'dashboard' && (
              <p className="mt-2 text-xs text-gray-400">{tt('ui.apps_self_managed')}</p>
            )}
          </article>
        ))}
      </div>
    </section>
  );
}
