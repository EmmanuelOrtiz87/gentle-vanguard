import { useEffect, useMemo, useState } from 'react';
import {
  Activity,
  AlertTriangle,
  BookOpen,
  Braces,
  CheckCircle2,
  Copy,
  Download,
  FileCode2,
  FileText,
  FileType2,
  History,
  KeyRound,
  Loader2,
  Moon,
  Network,
  RefreshCw,
  Search,
  Settings,
  ShieldCheck,
  Sun,
} from 'lucide-react';
import type { AnalyticsReport, ConnectionForm, ConnectionStatus, OAuthStatus } from './types';
import { useT, LocaleSwitcher } from './i18n';

interface ReportListItem {
  id: string;
  createdAt: string;
  mode: string;
  summary: string;
  input: string;
}

interface TemplateInfo {
  id: string;
  label: string;
  description: string;
}

const emptyForm: ConnectionForm = {
  siteUrl: '',
  email: '',
  apiToken: '',
  bitbucketApiToken: '',
  bitbucketWorkspace: '',
};

async function readJson<T>(url: string, init?: RequestInit): Promise<T> {
  const response = await fetch(url, {
    ...init,
    headers: { 'Content-Type': 'application/json', ...(init?.headers || {}) },
  });
  const body = await response.json();
  if (!response.ok) {
    throw new Error(body.error || `HTTP ${response.status}`);
  }
  return body as T;
}

export function App() {
  const { tt } = useT();
  const [status, setStatus] = useState<ConnectionStatus | null>(null);
  const [form, setForm] = useState<ConnectionForm>(emptyForm);
  const [input, setInput] = useState('');
  const [mode, setMode] = useState<'url' | 'request'>('url');
  const [report, setReport] = useState<AnalyticsReport | null>(null);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [editingConnection, setEditingConnection] = useState(false);
  const [history, setHistory] = useState<ReportListItem[]>([]);
  const [exportOpen, setExportOpen] = useState(false);
  const [view, setView] = useState<'operacion' | 'configuracion' | 'historial'>('operacion');
  const [theme, setTheme] = useState<'dark' | 'light'>(() => {
    if (typeof window === 'undefined') return 'dark';
    const stored = window.localStorage.getItem('gv-analytics-theme');
    return stored === 'light' ? 'light' : 'dark';
  });
  const [testing, setTesting] = useState(false);
  const [testResult, setTestResult] = useState<ConnectionStatus | null>(null);
  const [oauth, setOauth] = useState<OAuthStatus | null>(null);
  const [oauthBusy, setOauthBusy] = useState(false);
  const [templates, setTemplates] = useState<TemplateInfo[]>([]);
  const [template, setTemplate] = useState('sdd');

  const loadStatus = async () => {
    const next = await readJson<ConnectionStatus>('/api/connection/status');
    setStatus(next);
  };

  const loadOauthStatus = async () => {
    try {
      const next = await readJson<OAuthStatus>('/api/oauth/status');
      setOauth(next);
    } catch (error) {
      setOauth(null);
    }
  };

  const startOauth = async () => {
    setOauthBusy(true);
    setMessage(null);
    try {
      const next = await readJson<{ url: string; state: string }>('/api/oauth/start', { method: 'POST' });
      window.open(next.url, '_blank', 'noopener');
      setMessage(tt('conn.oauthOpened'));
    } catch (error) {
      setMessage(error instanceof Error ? error.message : String(error));
    } finally {
      setOauthBusy(false);
    }
  };

  const disconnectOauth = async () => {
    setOauthBusy(true);
    setMessage(null);
    try {
      await readJson<{ ok: boolean }>('/api/oauth/disconnect', { method: 'POST' });
      await loadOauthStatus();
      setMessage(tt('conn.oauthRemoved'));
    } catch (error) {
      setMessage(error instanceof Error ? error.message : String(error));
    } finally {
      setOauthBusy(false);
    }
  };

  const loadHistory = async () => {
    const next = await readJson<{ reports: ReportListItem[] }>('/api/reports?limit=5');
    setHistory(next.reports);
  };

  useEffect(() => {
    void loadStatus().catch((error) => setMessage(error.message));
    void loadHistory().catch(() => undefined);
    void loadOauthStatus().catch(() => undefined);
    void readJson<{ templates: TemplateInfo[] }>('/api/templates')
      .then((next) => setTemplates(next.templates))
      .catch(() => undefined);
  }, []);

  useEffect(() => {
    if (typeof document === 'undefined') return;
    document.documentElement.dataset.theme = theme;
    try {
      window.localStorage.setItem('gv-analytics-theme', theme);
    } catch {
      /* localStorage may be disabled */
    }
  }, [theme]);

  const connected = Boolean(status?.configured);
  const canAnalyze = input.trim().length > 3 && !busy;

  const statusTone = useMemo(() => {
    if (!status?.configured) return 'pending';
    if (status.jira.ok && status.confluence.ok && status.bitbucket.ok) return 'ready';
    return 'partial';
  }, [status]);

  const saveConnection = async (event: React.FormEvent) => {
    event.preventDefault();
    setBusy(true);
    setMessage(null);
    try {
      const next = await readJson<ConnectionStatus>('/api/connection', {
        method: 'POST',
        body: JSON.stringify(form),
      });
      setStatus(next);
      setForm(emptyForm);
      setEditingConnection(false);
      setTestResult(null);
      setMessage(tt('conn.saved'));
    } catch (error) {
      setMessage(error instanceof Error ? error.message : String(error));
    } finally {
      setBusy(false);
    }
  };

  const testConnection = async () => {
    setTesting(true);
    setTestResult(null);
    setMessage(null);
    try {
      // Test-only endpoint: validates the credentials WITHOUT persisting them.
      const next = await readJson<ConnectionStatus>('/api/connection/test', {
        method: 'POST',
        body: JSON.stringify(form),
      });
      setTestResult(next);
      const allOk = next.jira.ok && next.confluence.ok && next.bitbucket.ok;
      setMessage(allOk ? tt('conn.validAll') : tt('conn.partial'));
    } catch (error) {
      setMessage(error instanceof Error ? error.message : String(error));
    } finally {
      setTesting(false);
    }
  };

  // Prefill the edit form from the currently stored connection (tokens stay masked).
  const editConnection = () => {
    setForm({
      siteUrl: status?.siteUrl || '',
      email: status?.email || '',
      apiToken: '',
      bitbucketApiToken: '',
      bitbucketWorkspace: status?.bitbucketWorkspace || '',
    });
    setEditingConnection(true);
    setTestResult(null);
  };

  const analyze = async () => {
    setBusy(true);
    setMessage(null);
    try {
      const next = await readJson<AnalyticsReport>('/api/analyze', {
        method: 'POST',
        body: JSON.stringify({ mode, input }),
      });
      setReport(next);
      void loadHistory().catch(() => undefined);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : String(error));
    } finally {
      setBusy(false);
    }
  };

  const openReport = async (id: string) => {
    setBusy(true);
    setMessage(null);
    try {
      setReport(await readJson<AnalyticsReport>(`/api/reports/${encodeURIComponent(id)}`));
    } catch (error) {
      setMessage(error instanceof Error ? error.message : String(error));
    } finally {
      setBusy(false);
    }
  };

  const exportReport = (format: 'md' | 'html' | 'docx' | 'pdf') => {
    if (!report) return;
    setExportOpen(false);
    window.open(
      `/api/reports/${encodeURIComponent(report.id)}/export?format=${format}&template=${encodeURIComponent(template)}`,
      '_blank',
      'noopener',
    );
  };

  return (
    <>
      <div className="grid-bg" />
      <div className="glow-a" />
      <div className="glow-b" />
      <header className="topbar">
        <div className="topbar-inner">
          <div className="brand">
            <img src="/logo.svg" alt="Gentle-Vanguard" />
            <span className="name">
              Gentle<span>Vanguard</span> <small>{tt('brand.analytics')}</small>
            </span>
          </div>
          <nav className="main-nav view-tabs" aria-label={tt('nav.sections')}>
            <button
              type="button"
              className={view === 'operacion' ? 'active' : ''}
              onClick={() => setView('operacion')}
            >
              <Network />
              {tt('nav.operation')}
            </button>
            <button
              type="button"
              className={view === 'configuracion' ? 'active' : ''}
              onClick={() => setView('configuracion')}
            >
              <Settings />
              {tt('nav.config')}
            </button>
            <button
              type="button"
              className={view === 'historial' ? 'active' : ''}
              onClick={() => setView('historial')}
            >
              <History />
              {tt('nav.history')}
            </button>
          </nav>
          <div className={`system-state ${statusTone}`}>
            <span />
            {statusTone === 'ready'
              ? tt('state.ready')
              : statusTone === 'partial'
                ? tt('state.partial')
                : tt('state.none')}
          </div>
          <LocaleSwitcher />
          <button
            type="button"
            className="theme-toggle"
            onClick={() => setTheme((t) => (t === 'dark' ? 'light' : 'dark'))}
            title={theme === 'dark' ? tt('theme.toLight') : tt('theme.toDark')}
            aria-label={tt('theme.toggle')}
          >
            {theme === 'dark' ? <Sun /> : <Moon />}
          </button>
        </div>
      </header>

      <main className="app-shell">
        {view === 'operacion' && (
          <section className="workspace-grid">
            <section className="main-column">
              <section className="analysis-board">
                <div className="board-toolbar">
                  <div className="mode-switch" role="tablist" aria-label={tt('analysis.mode')}>
                    <button className={mode === 'url' ? 'active' : ''} onClick={() => setMode('url')}>
                      <Network />
                      {tt('analysis.url')}
                    </button>
                    <button className={mode === 'request' ? 'active' : ''} onClick={() => setMode('request')}>
                      <BookOpen />
                      {tt('analysis.request')}
                    </button>
                  </div>
                  <div className="export-wrap">
                    <button
                      className="secondary-action"
                      disabled={!report}
                      onClick={() => setExportOpen((open) => !open)}
                      title={tt('analysis.export')}
                    >
                      <Download />
                      {tt('analysis.export')}
                    </button>
                    {exportOpen && report && (
                      <div className="export-menu" role="menu">
                        <div className="export-template">
                          <label htmlFor="export-template">{tt('analysis.template')}</label>
                          <select
                            id="export-template"
                            value={template}
                            onChange={(event) => setTemplate(event.target.value)}
                          >
                            {templates.map((t) => (
                              <option key={t.id} value={t.id}>
                                {t.label}
                              </option>
                            ))}
                          </select>
                          <p className="export-template-desc">
                            {templates.find((t) => t.id === template)?.description}
                          </p>
                        </div>
                        <button role="menuitem" onClick={() => exportReport('pdf')}>
                          <FileText />
                          PDF
                        </button>
                        <button role="menuitem" onClick={() => exportReport('docx')}>
                          <FileType2 />
                          DOCX
                        </button>
                        <button role="menuitem" onClick={() => exportReport('html')}>
                          <Braces />
                          HTML
                        </button>
                        <button role="menuitem" onClick={() => exportReport('md')}>
                          <FileCode2 />
                          Markdown
                        </button>
                      </div>
                    )}
                  </div>
                </div>

                <textarea
                  value={input}
                  onChange={(event) => setInput(event.target.value)}
                  placeholder={mode === 'url' ? tt('analysis.urlPlaceholder') : tt('analysis.requestPlaceholder')}
                />

                {message && (
                  <div className="notice">
                    <AlertTriangle />
                    {message}
                  </div>
                )}

                <button className="primary-action analyze" disabled={!canAnalyze} onClick={() => void analyze()}>
                  {busy ? <Loader2 className="spin" /> : <Search />}
                  {tt('analysis.run')}
                </button>
              </section>

              {report ? <ReportView report={report} /> : <EmptyReport />}
            </section>
          </section>
        )}

        {view === 'configuracion' && (
          <ConfigView
            connected={connected}
            status={status}
            form={form}
            setForm={setForm}
            editingConnection={editingConnection}
            setEditingConnection={setEditingConnection}
            busy={busy}
            testing={testing}
            testResult={testResult}
            oauth={oauth}
            oauthBusy={oauthBusy}
            onSave={saveConnection}
            onTest={testConnection}
            onEdit={editConnection}
            onRevalidate={loadStatus}
            onOauthConnect={startOauth}
            onOauthDisconnect={disconnectOauth}
          />
        )}

        {view === 'historial' && (
          <HistoryView
            history={history}
            activeId={report?.id}
            busy={busy}
            onOpen={openReport}
          />
        )}
      </main>
    </>
  );
}

interface ConfigViewProps {
  connected: boolean;
  status: ConnectionStatus | null;
  form: ConnectionForm;
  setForm: React.Dispatch<React.SetStateAction<ConnectionForm>>;
  editingConnection: boolean;
  setEditingConnection: React.Dispatch<React.SetStateAction<boolean>>;
  busy: boolean;
  testing: boolean;
  testResult: ConnectionStatus | null;
  oauth: OAuthStatus | null;
  oauthBusy: boolean;
  onSave: (event: React.FormEvent) => Promise<void>;
  onTest: () => Promise<void>;
  onEdit: () => void;
  onRevalidate: () => Promise<void>;
  onOauthConnect: () => Promise<void>;
  onOauthDisconnect: () => Promise<void>;
}

function ConfigView({
  connected,
  status,
  form,
  setForm,
  editingConnection,
  setEditingConnection,
  busy,
  testing,
  testResult,
  oauth,
  oauthBusy,
  onSave,
  onTest,
  onEdit,
  onRevalidate,
  onOauthConnect,
  onOauthDisconnect,
}: ConfigViewProps) {
  const { tt } = useT();
  return (
    <section className="workspace-grid config-grid">
      <section className="panel compact">
        <div className="panel-heading">
          <KeyRound className="icon" />
          <div>
            <h2>{tt('conn.title')}</h2>
            <p>{connected ? tt('conn.loaded') : tt('conn.configure')}</p>
          </div>
        </div>

        {connected && !editingConnection ? (
          <div className="connection-summary">
            <div>
              <span>{tt('conn.site')}</span>
              <strong>{status?.siteUrl || 'Atlassian Cloud'}</strong>
            </div>
            <div>
              <span>{tt('conn.bitbucket')}</span>
              <strong>{status?.bitbucketWorkspace || tt('conn.workspaceUndefined')}</strong>
            </div>
            <div className="connection-actions">
              <button className="secondary-action" onClick={() => void onRevalidate()} disabled={busy}>
                <RefreshCw className={busy ? 'spin' : ''} />
                {tt('conn.revalidate')}
              </button>
              <button className="secondary-action" onClick={onEdit}>
                <Settings />
                {tt('conn.edit')}
              </button>
            </div>
            {oauth ? (
              <OAuthCard
                oauth={oauth}
                busy={oauthBusy}
                onConnect={() => void onOauthConnect()}
                onDisconnect={() => void onOauthDisconnect()}
              />
            ) : null}
          </div>
        ) : (
          <form onSubmit={(event) => void onSave(event)}>
            <label>
              {tt('conn.siteUrl')} <span className="required" title={tt('conn.requiredHint')}>*</span>
              <input
                value={form.siteUrl}
                onChange={(event) => setForm({ ...form, siteUrl: event.target.value })}
                placeholder="https://tu-dominio.atlassian.net"
                autoComplete="url"
              />
            </label>
            <label>
              {tt('conn.email')} <span className="required" title={tt('conn.requiredHint')}>*</span>
              <input
                value={form.email}
                onChange={(event) => setForm({ ...form, email: event.target.value })}
                placeholder="nombre@empresa.com"
                autoComplete="username"
              />
            </label>

            <fieldset className="token-group">
              <legend>
                {tt('conn.apiToken')} <span className="required" title={tt('conn.requiredHint')}>*</span>
              </legend>
              <p className="field-hint">{tt('conn.tokenHint')}</p>
              {status?.apiTokenSet ? (
                <p className="token-loaded-hint">
                  {tt('conn.tokenLoaded').replace('{masked}', status.apiTokenMasked || '')} · {tt('conn.keepExisting')}
                </p>
              ) : null}
              <input
                value={form.apiToken}
                onChange={(event) => setForm({ ...form, apiToken: event.target.value })}
                placeholder="Token Atlassian (Jira + Confluence)"
                type="password"
                autoComplete="current-password"
              />
            </fieldset>

            <fieldset className="token-group">
              <legend>{tt('conn.bitbucketApiToken')}</legend>
              <p className="field-hint">{tt('conn.bitbucketTokenHint')}</p>
              {status?.bitbucketApiTokenSet ? (
                <p className="token-loaded-hint">
                  {tt('conn.tokenLoaded').replace('{masked}', status.bitbucketApiTokenMasked || '')} · {tt('conn.keepExisting')}
                </p>
              ) : null}
              <input
                value={form.bitbucketApiToken}
                onChange={(event) => setForm({ ...form, bitbucketApiToken: event.target.value })}
                placeholder="App Password de Bitbucket"
                type="password"
                autoComplete="current-password"
              />
              <label className="sub-field">
                {tt('conn.bitbucketWorkspace')}
                <input
                  value={form.bitbucketWorkspace}
                  onChange={(event) => setForm({ ...form, bitbucketWorkspace: event.target.value })}
                  placeholder="workspace-slug"
                />
              </label>
            </fieldset>

            <div className="connection-actions">
              <button
                className="secondary-action"
                type="button"
                onClick={() => void onTest()}
                disabled={testing || !form.siteUrl || !form.email || !form.apiToken}
                title={tt('conn.test')}
              >
                {testing ? <Loader2 className="spin" /> : <Search />}
                {tt('conn.test')}
              </button>
              <button className="primary-action" type="submit" disabled={busy}>
                {busy ? <Loader2 className="spin" /> : <ShieldCheck />}
                {tt('conn.saveAndTest')}
              </button>
            </div>
            {testResult ? (
              <div className="test-result">
                <ServiceLine label="Jira" service={testResult.jira} />
                <ServiceLine label="Confluence" service={testResult.confluence} />
                <ServiceLine label="Bitbucket" service={testResult.bitbucket} />
              </div>
            ) : null}
          </form>
        )}
      </section>

      <section className="panel compact">
        <div className="panel-heading">
          <Activity className="icon" />
          <div>
            <h2>{tt('status.title')}</h2>
            <p>{connected ? tt('status.operational') : tt('status.pending')}</p>
          </div>
        </div>
        <ServiceLine label="Jira" service={status?.jira} />
        <ServiceLine label="Confluence" service={status?.confluence} />
        <ServiceLine label="Bitbucket" service={status?.bitbucket} />
      </section>
    </section>
  );
}

interface HistoryViewProps {
  history: ReportListItem[];
  activeId?: string;
  busy: boolean;
  onOpen: (id: string) => Promise<void>;
}

function HistoryView({ history, activeId, busy, onOpen }: HistoryViewProps) {
  const { tt } = useT();
  const [query, setQuery] = useState('');
  const [modeFilter, setModeFilter] = useState('');

  const modes = useMemo(() => Array.from(new Set(history.map((item) => item.mode))), [history]);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return history.filter((item) => {
      if (modeFilter && item.mode !== modeFilter) return false;
      if (!q) return true;
      return (
        item.summary.toLowerCase().includes(q) ||
        item.id.toLowerCase().includes(q) ||
        item.input.toLowerCase().includes(q)
      );
    });
  }, [history, query, modeFilter]);

  return (
    <section className="history-view">
      <div className="panel-heading history-heading">
        <History className="icon" />
        <div>
          <h2>{tt('history.title')}</h2>
          <p>{tt('history.subtitle')}</p>
        </div>
      </div>

      <div className="history-filters">
        <input
          className="history-search"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder={tt('history.search')}
          aria-label={tt('history.search')}
        />
        <select
          className="history-mode-filter"
          value={modeFilter}
          onChange={(event) => setModeFilter(event.target.value)}
          aria-label={tt('history.columnMode')}
        >
          <option value="">{tt('history.columnMode')} — {tt('history.columnMode')}</option>
          {modes.map((m) => (
            <option key={m} value={m}>
              {m}
            </option>
          ))}
        </select>
      </div>

      {history.length === 0 ? (
        <p className="history-empty">{tt('history.empty')}</p>
      ) : filtered.length === 0 ? (
        <p className="history-empty">{tt('history.noResults')}</p>
      ) : (
        <div className="history-table-wrap">
          <table className="history-table">
            <thead>
              <tr>
                <th>{tt('history.columnDate')}</th>
                <th>{tt('history.columnTime')}</th>
                <th>{tt('history.columnTitle')}</th>
                <th>{tt('history.columnMode')}</th>
                <th>{tt('history.columnId')}</th>
                <th aria-label={tt('history.open')} />
              </tr>
            </thead>
            <tbody>
              {filtered.map((item) => {
                const date = new Date(item.createdAt);
                return (
                  <tr key={item.id} className={activeId === item.id ? 'active' : ''}>
                    <td>{date.toLocaleDateString()}</td>
                    <td>{date.toLocaleTimeString()}</td>
                    <td className="history-title-cell" title={item.input.slice(0, 200)}>
                      {item.summary || item.id}
                    </td>
                    <td>
                      <span className="history-mode-badge">{item.mode}</span>
                    </td>
                    <td className="history-id-cell">{item.id}</td>
                    <td>
                      <button
                        className="secondary-action history-open"
                        onClick={() => void onOpen(item.id)}
                        disabled={busy}
                        title={tt('history.open')}
                      >
                        <Search />
                        {tt('history.open')}
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}

function ServiceLine({ label, service }: { label: string; service?: { ok: boolean; message: string } }) {
  const { tt } = useT();
  return (
    <div className="service-line">
      {service?.ok ? <CheckCircle2 className="ok" /> : <AlertTriangle className="warn" />}
      <span>{label}</span>
      <strong>{service?.message || tt('status.pendingShort')}</strong>
    </div>
  );
}

function EmptyReport() {
  const { tt } = useT();
  return (
    <section className="report-empty">
      <Braces />
      <h2>{tt('report.emptyTitle')}</h2>
      <p>{tt('report.emptyBody')}</p>
    </section>
  );
}

function ReportView({ report }: { report: AnalyticsReport }) {
  const { tt } = useT();
  return (
    <section className="report" id="reporte">
      <div className="report-header">
        <div>
          <span className="eyebrow">{tt('report.label')} {report.id}</span>
          <h2>{report.summary}</h2>
        </div>
        <time>{new Date(report.createdAt).toLocaleString()}</time>
      </div>

      <div className="metric-strip">
        <Metric label={tt('report.complexity')} value={report.complexity.level} />
        <Metric label={tt('report.delivery')} value={`${report.estimate.deliveryHours}h`} />
        <Metric label={tt('report.qa')} value={`${report.estimate.qaHours}h`} />
        <Metric label={tt('report.confidence')} value={report.estimate.confidence} />
      </div>

      <LLMProvenance report={report} />

      <ReportSection title={tt('report.currentState')} items={report.currentState} />
      <ReportSection title={tt('report.proposedSolution')} items={report.proposedSolution} />
      <section className="report-section">
        <h3>{tt('report.fronts')}</h3>
        <ul className="fronts-list">
          {report.impactedFronts.map((front) => (
            <li key={front}>{front}</li>
          ))}
        </ul>
      </section>
      <ReportSection title={tt('report.roles')} items={report.roles} />
      <ReportSection title={tt('report.qaScenarios')} items={report.qaScenarios} />
      <ReportSection title={tt('report.nextActions')} items={report.nextActions} />

      <div className="diagram-grid">
        <DiagramBlock label={tt('report.currentState')} content={report.diagrams.current} />
        <DiagramBlock label={tt('report.proposedState')} content={report.diagrams.proposed} />
      </div>

      <section className="evidence-list" id="evidencia">
        <h3>{tt('report.evidence')}</h3>
        {report.evidence.map((item) => (
          <article key={`${item.source}-${item.title}-${item.url || item.detail}`}>
            <strong>{item.source}</strong>
            <span>{item.title}</span>
            <p>{item.detail}</p>
            {item.url && <a href={item.url}>{item.url}</a>}
          </article>
        ))}
      </section>
    </section>
  );
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div className="metric">
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}

function OAuthCard({
  oauth,
  busy,
  onConnect,
  onDisconnect,
}: {
  oauth: OAuthStatus;
  busy: boolean;
  onConnect: () => void;
  onDisconnect: () => void;
}) {
  const { tt } = useT();
  return (
    <div className="oauth-card">
      <div className="oauth-heading">
        <span>{tt('oauth.title')}</span>
        <em className={oauth.connected ? 'oauth-on' : 'oauth-off'}>
          {oauth.connected ? tt('oauth.connected') : oauth.configured ? tt('oauth.ready') : tt('oauth.notConfigured')}
        </em>
      </div>
      {oauth.connected ? (
        <>
          {typeof oauth.expiresAt === 'number' ? (
            <p className="oauth-detail">
              {tt('oauth.expires')} {new Date(oauth.expiresAt).toLocaleString()}
            </p>
          ) : null}
          <div className="connection-actions">
            <button className="secondary-action" onClick={onDisconnect} disabled={busy}>
              {tt('oauth.disconnect')}
            </button>
          </div>
        </>
      ) : (
        <>
          <p className="oauth-detail">
            {tt('oauth.callback')} <code>{oauth.redirectUri}</code>
          </p>
          <p className="oauth-detail">
            {tt('oauth.scopes')} <code>{oauth.scopes.join(' ')}</code>
          </p>
          {!oauth.configured ? (
            <p className="oauth-detail muted">{tt('oauth.configureHint')}</p>
          ) : null}
          <div className="connection-actions">
            <button
              className="primary-action"
              onClick={onConnect}
              disabled={busy || !oauth.configured}
              title={tt('oauth.connect')}
            >
              {busy ? <Loader2 className="spin" /> : <ShieldCheck />}
              {tt('oauth.connect')}
            </button>
          </div>
        </>
      )}
    </div>
  );
}

function LLMProvenance({ report }: { report: AnalyticsReport }) {
  const { tt } = useT();
  const source = report.llmSource ?? 'heuristic';
  const labelMap: Record<typeof source, string> = {
    agent: tt('llm.agent'),
    cache: tt('llm.cache'),
    fallback: tt('llm.fallback'),
    heuristic: tt('llm.heuristic'),
  };
  const detail =
    typeof report.llmDurationMs === 'number'
      ? `${(report.llmDurationMs / 1000).toFixed(1)}s`
      : 'n/d';
  return (
    <div className={`llm-badge llm-${source}`}>
      <strong>{labelMap[source]}</strong>
      <span>{detail}</span>
      {report.llmNotes ? <em>{report.llmNotes}</em> : null}
    </div>
  );
}

interface MermaidGlobal {
  initialize: (cfg: unknown) => void;
  render: (id: string, code: string) => Promise<{ svg: string }>;
}

async function loadMermaid(): Promise<MermaidGlobal | null> {
  for (let attempt = 0; attempt < 40; attempt += 1) {
    const candidate = (globalThis as { mermaid?: MermaidGlobal }).mermaid;
    if (candidate && typeof candidate.render === 'function') return candidate;
    await new Promise((r) => setTimeout(r, 250));
  }
  return null;
}

function DiagramBlock({ label, content }: { label: string; content: string }) {
  const { tt } = useT();
  const [copied, setCopied] = useState(false);
  const [mermaidHtml, setMermaidHtml] = useState<string | null>(null);
  const [mermaidError, setMermaidError] = useState<string | null>(null);
  const text = content || tt('report.noContent');
  const isMermaid = /^\s*(```\s*)?(mermaid|graph|sequenceDiagram|flowchart|classDiagram|stateDiagram|erDiagram|gantt|pie|journey)/im.test(
    text,
  );

  useEffect(() => {
    let cancelled = false;
    if (!isMermaid) {
      setMermaidHtml(null);
      setMermaidError(null);
      return () => undefined;
    }
    const renderMermaid = async () => {
      try {
        const mermaid = await loadMermaid();
        if (!mermaid) throw new Error('Mermaid no cargo (offline o CDN bloqueado)');
        mermaid.initialize({ startOnLoad: false, theme: 'dark', securityLevel: 'loose' });
        const { svg } = await mermaid.render(
          `m-${Math.random().toString(36).slice(2, 8)}`,
          text.replace(/^```(?:mermaid)?\s*|```$/g, '').trim(),
        );
        if (!cancelled) {
          setMermaidHtml(svg);
          setMermaidError(null);
        }
      } catch (error) {
        if (!cancelled) {
          setMermaidHtml(null);
          setMermaidError(error instanceof Error ? error.message : String(error));
        }
      }
    };
    void renderMermaid();
    return () => {
      cancelled = true;
    };
  }, [text, isMermaid]);

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      setCopied(false);
    }
  };

  return (
    <div className="diagram-block">
      <div className="diagram-heading">
        <span>
          {label}
          {isMermaid ? <em className="mermaid-tag">mermaid</em> : null}
        </span>
        <button type="button" onClick={() => void copy()} title={tt('report.copy')}>
          <Copy />
          {copied ? tt('report.copied') : tt('report.copy')}
        </button>
      </div>
      {mermaidHtml ? (
        <div className="mermaid-render" dangerouslySetInnerHTML={{ __html: mermaidHtml }} />
      ) : (
        <pre>
          {text}
          {isMermaid && mermaidError ? (
            <span className="mermaid-fallback"> ({tt('report.mermaidRender')} {mermaidError})</span>
          ) : null}
        </pre>
      )}
    </div>
  );
}

function ReportSection({ title, items }: { title: string; items: string[] }) {
  return (
    <section className="report-section">
      <h3>{title}</h3>
      <ul>
        {items.map((item) => (
          <li key={item}>{item}</li>
        ))}
      </ul>
    </section>
  );
}
