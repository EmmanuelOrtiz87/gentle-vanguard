import { useEffect, useMemo, useState } from 'react';
import {
  Activity,
  AlertTriangle,
  BookOpen,
  Braces,
  CheckCircle2,
  Download,
  FileCode2,
  FileText,
  FileType2,
  History,
  KeyRound,
  Loader2,
  Network,
  RefreshCw,
  Search,
  Settings,
  ShieldCheck,
} from 'lucide-react';
import type { AnalyticsReport, ConnectionForm, ConnectionStatus } from './types';

interface ReportListItem {
  id: string;
  createdAt: string;
  mode: string;
  summary: string;
  input: string;
}

const emptyForm: ConnectionForm = {
  siteUrl: '',
  email: '',
  apiToken: '',
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
  const [activeSection, setActiveSection] = useState<'conexion' | 'analisis' | 'reporte' | 'evidencia'>('conexion');

  const loadStatus = async () => {
    const next = await readJson<ConnectionStatus>('/api/connection/status');
    setStatus(next);
  };

  const loadHistory = async () => {
    const next = await readJson<{ reports: ReportListItem[] }>('/api/reports?limit=5');
    setHistory(next.reports);
  };

  useEffect(() => {
    void loadStatus().catch((error) => setMessage(error.message));
    void loadHistory().catch(() => undefined);
  }, []);

  // Scroll-spy para el stepper de la cabecera
  useEffect(() => {
    const ids: Array<'conexion' | 'analisis' | 'reporte' | 'evidencia'> = [
      'conexion',
      'analisis',
      'reporte',
      'evidencia',
    ];
    const elements = ids
      .map((id) => ({ id, node: document.getElementById(id) }))
      .filter((entry): entry is { id: typeof ids[number]; node: HTMLElement } => Boolean(entry.node));
    if (elements.length === 0) return;
    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((entry) => entry.isIntersecting)
          .sort((a, b) => b.intersectionRatio - a.intersectionRatio);
        if (visible[0]?.target) {
          const match = elements.find((entry) => entry.node === visible[0].target);
          if (match) setActiveSection(match.id);
        }
      },
      { rootMargin: '-30% 0px -50% 0px', threshold: [0, 0.25, 0.5, 0.75, 1] },
    );
    for (const entry of elements) observer.observe(entry.node);
    return () => observer.disconnect();
  }, [report]);

  const scrollToSection = (id: 'conexion' | 'analisis' | 'reporte' | 'evidencia') => {
    const node = document.getElementById(id);
    if (node) {
      node.scrollIntoView({ behavior: 'smooth', block: 'start' });
      setActiveSection(id);
    }
  };

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
      setMessage('Conexion guardada y verificada.');
    } catch (error) {
      setMessage(error instanceof Error ? error.message : String(error));
    } finally {
      setBusy(false);
    }
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
      `/api/reports/${encodeURIComponent(report.id)}/export?format=${format}`,
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
              Gentle<span>Vanguard</span> <small>Analytics</small>
            </span>
          </div>
          <nav className="main-nav" aria-label="Secciones">
            <button
              type="button"
              className={activeSection === 'conexion' ? 'active' : ''}
              onClick={() => scrollToSection('conexion')}
            >
              <span className="step">1</span>
              Conexion
            </button>
            <button
              type="button"
              className={activeSection === 'analisis' ? 'active' : ''}
              onClick={() => scrollToSection('analisis')}
            >
              <span className="step">2</span>
              Analisis
            </button>
            <button
              type="button"
              className={activeSection === 'reporte' ? 'active' : ''}
              onClick={() => scrollToSection('reporte')}
            >
              <span className="step">3</span>
              Reporte
            </button>
            <button
              type="button"
              className={activeSection === 'evidencia' ? 'active' : ''}
              onClick={() => scrollToSection('evidencia')}
            >
              <span className="step">4</span>
              Evidencia
            </button>
          </nav>
          <div className={`system-state ${statusTone}`}>
            <span />
            {statusTone === 'ready'
              ? 'Atlassian listo'
              : statusTone === 'partial'
                ? 'Conexion parcial'
                : 'Sin conexion'}
          </div>
        </div>
      </header>

      <main className="app-shell">
      <section className="workspace-grid">
        <aside className="left-rail">
          <section className="panel compact" id="conexion">
            <div className="panel-heading">
              <KeyRound className="icon" />
              <div>
                <h2>Conexion Atlassian</h2>
                <p>
                  {connected
                    ? 'Credenciales cargadas para esta ejecucion local.'
                    : 'Configura la conexion una sola vez para operar.'}
                </p>
              </div>
            </div>

            {connected && !editingConnection ? (
              <div className="connection-summary">
                <div>
                  <span>Site</span>
                  <strong>{status?.siteUrl || 'Atlassian Cloud'}</strong>
                </div>
                <div>
                  <span>Bitbucket</span>
                  <strong>{status?.bitbucketWorkspace || 'Workspace no definido'}</strong>
                </div>
                <div className="connection-actions">
                  <button className="secondary-action" onClick={() => void loadStatus()} disabled={busy}>
                    <RefreshCw className={busy ? 'spin' : ''} />
                    Revalidar
                  </button>
                  <button className="secondary-action" onClick={() => setEditingConnection(true)}>
                    <Settings />
                    Editar
                  </button>
                </div>
              </div>
            ) : (
              <form onSubmit={(event) => void saveConnection(event)}>
                <label>
                  Site URL
                  <input
                    value={form.siteUrl}
                    onChange={(event) => setForm({ ...form, siteUrl: event.target.value })}
                    placeholder="https://tu-dominio.atlassian.net"
                    autoComplete="url"
                  />
                </label>
                <label>
                  Email
                  <input
                    value={form.email}
                    onChange={(event) => setForm({ ...form, email: event.target.value })}
                    placeholder="nombre@empresa.com"
                    autoComplete="username"
                  />
                </label>
                <label>
                  API token
                  <input
                    value={form.apiToken}
                    onChange={(event) => setForm({ ...form, apiToken: event.target.value })}
                    placeholder="Token Atlassian"
                    type="password"
                    autoComplete="current-password"
                  />
                </label>
                <label>
                  Bitbucket workspace
                  <input
                    value={form.bitbucketWorkspace}
                    onChange={(event) => setForm({ ...form, bitbucketWorkspace: event.target.value })}
                    placeholder="workspace-slug"
                  />
                </label>
                <button className="primary-action" type="submit" disabled={busy}>
                  {busy ? <Loader2 className="spin" /> : <ShieldCheck />}
                  Guardar y probar
                </button>
              </form>
            )}
          </section>

          <section className="panel compact">
            <div className="panel-heading">
                <Activity className="icon" />
              <div>
                <h2>Estado</h2>
                <p>{connected ? 'Sesion operativa sin exponer credenciales.' : 'Pendiente de conexion.'}</p>
              </div>
            </div>
            <ServiceLine label="Jira" service={status?.jira} />
            <ServiceLine label="Confluence" service={status?.confluence} />
            <ServiceLine label="Bitbucket" service={status?.bitbucket} />
          </section>

          <section className="panel compact" id="historial">
            <div className="panel-heading">
              <History className="icon" />
              <div>
                <h2>Historial</h2>
                <p>Ultimos 5 reportes persistidos en Nexus, listos para retomar.</p>
              </div>
            </div>
            {history.length === 0 ? (
              <p className="history-empty">Sin reportes todavia.</p>
            ) : (
              <ul className="history-list">
                {history.map((item) => (
                  <li key={item.id}>
                    <button
                      className={report?.id === item.id ? 'active' : ''}
                      onClick={() => void openReport(item.id)}
                      disabled={busy}
                      title={item.input.slice(0, 120)}
                    >
                      <span className="history-title">{item.summary || item.id}</span>
                      <span className="history-meta">
                        {item.mode} · {new Date(item.createdAt).toLocaleString()}
                      </span>
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </section>
        </aside>

        <section className="main-column">
          <section className="analysis-board" id="analisis">
            <div className="board-toolbar">
              <div className="mode-switch" role="tablist" aria-label="Modo de analisis">
                <button className={mode === 'url' ? 'active' : ''} onClick={() => setMode('url')}>
                  <Network />
                  URL
                </button>
                <button className={mode === 'request' ? 'active' : ''} onClick={() => setMode('request')}>
                  <BookOpen />
                  Pedido
                </button>
              </div>
              <div className="export-wrap">
                <button
                  className="secondary-action"
                  disabled={!report}
                  onClick={() => setExportOpen((open) => !open)}
                  title="Exportar reporte"
                >
                  <Download />
                  Exportar
                </button>
                {exportOpen && report && (
                  <div className="export-menu" role="menu">
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
              placeholder={
                mode === 'url'
                  ? 'Pega una URL de Jira, Confluence, Bitbucket, PR o repositorio...'
                  : 'Pega el pedido funcional o tecnico para analizar impacto, frentes, roles y estimacion...'
              }
            />

            {message && (
              <div className="notice">
                <AlertTriangle />
                {message}
              </div>
            )}

            <button className="primary-action analyze" disabled={!canAnalyze} onClick={() => void analyze()}>
              {busy ? <Loader2 className="spin" /> : <Search />}
              Analizar
            </button>
          </section>

          {report ? <ReportView report={report} /> : <EmptyReport />}
        </section>
      </section>
    </main>
    </>
  );
}

function ServiceLine({ label, service }: { label: string; service?: { ok: boolean; message: string } }) {
  return (
    <div className="service-line">
      {service?.ok ? <CheckCircle2 className="ok" /> : <AlertTriangle className="warn" />}
      <span>{label}</span>
      <strong>{service?.message || 'Pendiente'}</strong>
    </div>
  );
}

function EmptyReport() {
  return (
    <section className="report-empty">
      <Braces />
      <h2>Listo para interpretar una iniciativa</h2>
      <p>
        El primer analisis va a recuperar evidencia, detectar frentes de impacto y producir una
        respuesta tecnica lista para evolucionar.
      </p>
    </section>
  );
}

function ReportView({ report }: { report: AnalyticsReport }) {
  return (
    <section className="report" id="reporte">
      <div className="report-header">
        <div>
          <span className="eyebrow">Reporte {report.id}</span>
          <h2>{report.summary}</h2>
        </div>
        <time>{new Date(report.createdAt).toLocaleString()}</time>
      </div>

      <div className="metric-strip">
        <Metric label="Complejidad" value={report.complexity.level} />
        <Metric label="Delivery" value={`${report.estimate.deliveryHours}h`} />
        <Metric label="QA" value={`${report.estimate.qaHours}h`} />
        <Metric label="Confianza" value={report.estimate.confidence} />
      </div>

      <ReportSection title="Estado actual" items={report.currentState} />
      <ReportSection title="Solucion propuesta" items={report.proposedSolution} />
      <section className="report-section">
        <h3>Frentes involucrados</h3>
        <ul className="fronts-list">
          {report.impactedFronts.map((front) => (
            <li key={front}>{front}</li>
          ))}
        </ul>
      </section>
      <ReportSection title="Roles" items={report.roles} />
      <ReportSection title="Escenarios QA" items={report.qaScenarios} />
      <ReportSection title="Proximas acciones" items={report.nextActions} />

      <div className="diagram-grid">
        <pre>{report.diagrams.current}</pre>
        <pre>{report.diagrams.proposed}</pre>
      </div>

      <section className="evidence-list" id="evidencia">
        <h3>Evidencia</h3>
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
