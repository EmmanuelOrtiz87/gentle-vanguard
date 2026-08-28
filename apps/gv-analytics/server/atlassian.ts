import type {
  AnalyticsReport,
  AnalysisEvidence,
  ConnectionForm,
  ConnectionStatus,
} from '../src/types';
import { loadConnection, saveConnection, type StoredConnection } from './vault';
import { enrichWithLLM } from './llm';

interface AtlassianRequestOptions {
  path: string;
  service: 'jira' | 'confluence' | 'bitbucket';
  query?: Record<string, string>;
}

function cleanSiteUrl(siteUrl: string): string {
  const parsed = new URL(siteUrl);
  parsed.pathname = '';
  parsed.search = '';
  parsed.hash = '';
  return parsed.toString().replace(/\/$/, '');
}

/**
 * Selects the correct credential per service:
 * - Jira + Confluence share the same Atlassian API token (`apiToken`).
 * - Bitbucket uses a separate token (`bitbucketApiToken`), falling back to
 *   `apiToken` for backward-compat with vaults saved before the split.
 */
function tokenFor(connection: StoredConnection, service: 'jira' | 'confluence' | 'bitbucket'): string {
  if (service === 'bitbucket') {
    return connection.bitbucketApiToken || connection.apiToken;
  }
  return connection.apiToken;
}

function authHeader(connection: StoredConnection, service: 'jira' | 'confluence' | 'bitbucket'): string {
  // OAuth bearer if available, otherwise Basic auth with email + per-service token.
  if (connection.oauth?.accessToken) {
    return `Bearer ${connection.oauth.accessToken}`;
  }
  return `Basic ${Buffer.from(`${connection.email}:${tokenFor(connection, service)}`).toString('base64')}`;
}

async function atlassianFetch(connection: StoredConnection, options: AtlassianRequestOptions) {
  const base =
    options.service === 'bitbucket'
      ? 'https://api.bitbucket.org/2.0'
      : cleanSiteUrl(connection.siteUrl);
  const url = new URL(`${base}${options.path}`);
  for (const [key, value] of Object.entries(options.query || {})) {
    url.searchParams.set(key, value);
  }
  const response = await fetch(url, {
    headers: {
      Accept: 'application/json',
      Authorization: authHeader(connection, options.service),
    },
  });
  if (!response.ok) {
    throw new Error(`${options.service} HTTP ${response.status}`);
  }
  return response.json() as Promise<unknown>;
}

async function atlassianTextFetch(connection: StoredConnection, options: AtlassianRequestOptions) {
  const base =
    options.service === 'bitbucket'
      ? 'https://api.bitbucket.org/2.0'
      : cleanSiteUrl(connection.siteUrl);
  const url = new URL(`${base}${options.path}`);
  for (const [key, value] of Object.entries(options.query || {})) {
    url.searchParams.set(key, value);
  }
  const response = await fetch(url, {
    headers: {
      Accept: 'text/plain, application/json',
      Authorization: authHeader(connection, options.service),
    },
  });
  if (!response.ok) {
    throw new Error(`${options.service} HTTP ${response.status}`);
  }
  return response.text();
}

async function testService(connection: StoredConnection, service: 'jira' | 'confluence' | 'bitbucket') {
  try {
    if (service === 'jira') {
      await atlassianFetch(connection, { service, path: '/rest/api/3/myself' });
    } else if (service === 'confluence') {
      await atlassianFetch(connection, { service, path: '/wiki/api/v2/spaces', query: { limit: '1' } });
    } else if (connection.bitbucketWorkspace) {
      await atlassianFetch(connection, {
        service,
        path: `/repositories/${encodeURIComponent(connection.bitbucketWorkspace)}`,
        query: { pagelen: '1' },
      });
    } else {
      return { ok: false, message: 'Workspace pendiente' };
    }
    return { ok: true, message: 'OK' };
  } catch (error) {
    return { ok: false, message: error instanceof Error ? error.message : String(error) };
  }
}

/** Masks a secret for display, showing only the last 4 chars (never the raw value). */
function maskSecret(secret?: string): string | undefined {
  if (!secret) return undefined;
  const tail = secret.slice(-4);
  return `••••${tail}`;
}

export async function getConnectionStatus(): Promise<ConnectionStatus> {
  const connection = loadConnection();
  if (!connection) {
    return {
      configured: false,
      jira: { ok: false, message: 'Pendiente' },
      confluence: { ok: false, message: 'Pendiente' },
      bitbucket: { ok: false, message: 'Pendiente' },
    };
  }
  const [jira, confluence, bitbucket] = await Promise.all([
    testService(connection, 'jira'),
    testService(connection, 'confluence'),
    testService(connection, 'bitbucket'),
  ]);
  return {
    configured: true,
    jira,
    confluence,
    bitbucket,
    siteUrl: connection.siteUrl,
    email: connection.email,
    bitbucketWorkspace: connection.bitbucketWorkspace,
    updatedAt: connection.updatedAt,
    apiTokenSet: Boolean(connection.apiToken),
    apiTokenMasked: maskSecret(connection.apiToken),
    bitbucketApiTokenSet: Boolean(connection.bitbucketApiToken),
    bitbucketApiTokenMasked: maskSecret(connection.bitbucketApiToken),
  };
}

/** Builds a StoredConnection from a form, keeping existing tokens when a field is left blank. */
function buildConnection(form: ConnectionForm): StoredConnection {
  const existing = loadConnection();
  const apiToken = form.apiToken.trim() || existing?.apiToken || '';
  if (!form.siteUrl || !form.email || !apiToken) {
    throw new Error('Site URL, email y API token son obligatorios.');
  }
  return {
    siteUrl: cleanSiteUrl(form.siteUrl),
    email: form.email.trim(),
    apiToken,
    bitbucketApiToken: form.bitbucketApiToken?.trim() || existing?.bitbucketApiToken || undefined,
    bitbucketWorkspace: form.bitbucketWorkspace.trim(),
    updatedAt: new Date().toISOString(),
  };
}

export async function configureConnection(form: ConnectionForm): Promise<ConnectionStatus> {
  saveConnection(buildConnection(form));
  return getConnectionStatus();
}

/** Tests the provided credentials WITHOUT persisting them to the vault. */
export async function testConnectionForm(form: ConnectionForm): Promise<ConnectionStatus> {
  const connection = buildConnection(form);
  const [jira, confluence, bitbucket] = await Promise.all([
    testService(connection, 'jira'),
    testService(connection, 'confluence'),
    testService(connection, 'bitbucket'),
  ]);
  return {
    configured: true,
    jira,
    confluence,
    bitbucket,
    siteUrl: connection.siteUrl,
    email: connection.email,
    bitbucketWorkspace: connection.bitbucketWorkspace,
    apiTokenSet: Boolean(connection.apiToken),
    apiTokenMasked: maskSecret(connection.apiToken),
    bitbucketApiTokenSet: Boolean(connection.bitbucketApiToken),
    bitbucketApiTokenMasked: maskSecret(connection.bitbucketApiToken),
  };
}

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === 'object' ? (value as Record<string, unknown>) : {};
}

function asString(value: unknown): string {
  return typeof value === 'string' ? value : '';
}

function deepText(value: unknown): string {
  if (value == null) return '';
  if (typeof value === 'string') return value;
  if (typeof value === 'number' || typeof value === 'boolean') return String(value);
  if (Array.isArray(value)) return value.map(deepText).filter(Boolean).join(' ');
  if (typeof value === 'object') {
    const record = value as Record<string, unknown>;
    return Object.values(record).map(deepText).filter(Boolean).join(' ');
  }
  return '';
}

function extractJiraKey(input: string): string | null {
  const match = input.match(/\b[A-Z][A-Z0-9]+-\d+\b/);
  return match ? match[0] : null;
}

function extractConfluencePageId(input: string): string | null {
  const direct = input.match(/\/pages\/(\d+)\b/i);
  if (direct) return direct[1];
  try {
    const url = new URL(input);
    return url.searchParams.get('pageId');
  } catch {
    return null;
  }
}

function extractBitbucketParts(input: string):
  | { workspace: string; repo: string; pullRequestId?: string }
  | null {
  try {
    const url = new URL(input);
    if (!/bitbucket\.org$/i.test(url.hostname)) return null;
    const parts = url.pathname.split('/').filter(Boolean);
    if (parts.length < 2) return null;
    const pullRequestIndex = parts.findIndex((part) => part === 'pull-requests' || part === 'pullrequests');
    return {
      workspace: parts[0],
      repo: parts[1],
      pullRequestId: pullRequestIndex >= 0 ? parts[pullRequestIndex + 1] : undefined,
    };
  } catch {
    return null;
  }
}

async function gatherJiraEvidence(
  connection: StoredConnection,
  input: string,
): Promise<{ evidence: AnalysisEvidence[]; text: string[] }> {
  const key = extractJiraKey(input);
  if (!key) return { evidence: [], text: [] };
  const issue = asRecord(
    await atlassianFetch(connection, {
      service: 'jira',
      path: `/rest/api/3/issue/${encodeURIComponent(key)}`,
      query: { expand: 'names,renderedFields,changelog' },
    }),
  );
  const fields = asRecord(issue.fields);
  const title = `${key} ${asString(fields.summary)}`.trim();
  const description = deepText(fields.description || fields.renderedFields).slice(0, 1800);
  const comments = asRecord(fields.comment);
  const commentText = Array.isArray(comments.comments)
    ? comments.comments.map((comment) => deepText(asRecord(comment).body)).join('\n')
    : '';
  const url = `${connection.siteUrl}/browse/${key}`;

  const relatedEvidence = await collectJiraRelatedEvidence(connection, key, fields);
  const relatedText = relatedEvidence.map((item) => `${item.title}: ${item.detail.slice(0, 400)}`);

  return {
    evidence: [
      {
        source: 'jira',
        title,
        url,
        detail: [
          description,
          commentText,
          asString(fields.status) ? `Estado: ${deepText(fields.status)}` : '',
        ]
          .filter(Boolean)
          .join('\n')
          .slice(0, 2400),
      },
      ...relatedEvidence,
    ],
    text: [title, description, commentText, ...relatedText],
  };
}

async function collectJiraRelatedEvidence(
  connection: StoredConnection,
  key: string,
  fields: Record<string, unknown>,
): Promise<AnalysisEvidence[]> {
  const evidence: AnalysisEvidence[] = [];

  const links = Array.isArray(fields.issuelinks) ? fields.issuelinks : [];
  for (const link of links.slice(0, 6)) {
    const record = asRecord(link);
    const inward = asRecord(record.inwardIssue);
    const outward = asRecord(record.outwardIssue);
    const target = asString(inward.key) ? inward : outward;
    if (!asString(target.key)) continue;
    evidence.push({
      source: 'jira',
      title: `Vinculado ${asString(target.key)} ${asString(asRecord(target.fields).summary)}`.trim(),
      url: `${connection.siteUrl}/browse/${asString(target.key)}`,
      detail: `Relacion: ${asString(record.type && asRecord(record.type).inward) || 'link'}. Estado: ${deepText(asRecord(target.fields).status) || 'n/d'}.`,
    });
  }

  try {
    const search = asRecord(
      await atlassianFetch(connection, {
        service: 'confluence',
        path: '/wiki/rest/api/content/search',
        query: { cql: `type = page AND text ~ "${key}"`, limit: '3' },
      }),
    );
    const pages = Array.isArray(search.results) ? search.results : [];
    for (const page of pages) {
      const record = asRecord(page);
      evidence.push({
        source: 'confluence',
        title: `Doc relacionada: ${asString(record.title)}`,
        url: `${connection.siteUrl}/wiki${asString(record._links && asRecord(record._links).webui)}`,
        detail: 'Pagina de Confluence que menciona el ticket analizado.',
      });
    }
  } catch {
    // Related docs are best-effort; silent skip keeps the main report stable.
  }

  return evidence;
}

async function gatherConfluenceEvidence(
  connection: StoredConnection,
  input: string,
): Promise<{ evidence: AnalysisEvidence[]; text: string[] }> {
  const pageId = extractConfluencePageId(input);
  if (!pageId) return { evidence: [], text: [] };
  const page = asRecord(
    await atlassianFetch(connection, {
      service: 'confluence',
      path: `/wiki/api/v2/pages/${encodeURIComponent(pageId)}`,
      query: { 'body-format': 'atlas_doc_format' },
    }),
  );
  const title = asString(page.title) || `Confluence page ${pageId}`;
  const body = deepText(asRecord(page.body)).slice(0, 2400);
  const url = `${connection.siteUrl}/wiki/pages/${pageId}`;
  return {
    evidence: [{ source: 'confluence', title, url, detail: body || 'Pagina recuperada.' }],
    text: [title, body],
  };
}

async function gatherBitbucketEvidence(
  connection: StoredConnection,
  input: string,
): Promise<{ evidence: AnalysisEvidence[]; text: string[] }> {
  const parts = extractBitbucketParts(input);
  if (!parts) return { evidence: [], text: [] };
  const repo = asRecord(
    await atlassianFetch(connection, {
      service: 'bitbucket',
      path: `/repositories/${encodeURIComponent(parts.workspace)}/${encodeURIComponent(parts.repo)}`,
    }),
  );
  const evidence: AnalysisEvidence[] = [
    {
      source: 'bitbucket',
      title: `Repo ${asString(repo.full_name) || `${parts.workspace}/${parts.repo}`}`,
      url: `https://bitbucket.org/${parts.workspace}/${parts.repo}`,
      detail: [
        asString(repo.description),
        `SCM: ${asString(repo.scm) || 'unknown'}`,
        `Language: ${asString(repo.language) || 'unknown'}`,
      ]
        .filter(Boolean)
        .join('\n'),
    },
  ];
  const text = [asString(repo.description), asString(repo.language)];

  if (parts.pullRequestId) {
    const pullRequest = asRecord(
      await atlassianFetch(connection, {
        service: 'bitbucket',
        path: `/repositories/${encodeURIComponent(parts.workspace)}/${encodeURIComponent(parts.repo)}/pullrequests/${encodeURIComponent(parts.pullRequestId)}`,
      }),
    );
    const diff = await atlassianTextFetch(connection, {
      service: 'bitbucket',
      path: `/repositories/${encodeURIComponent(parts.workspace)}/${encodeURIComponent(parts.repo)}/pullrequests/${encodeURIComponent(parts.pullRequestId)}/diff`,
    }).catch((error) => `Diff no disponible: ${error instanceof Error ? error.message : String(error)}`);
    const title = `PR #${parts.pullRequestId} ${asString(pullRequest.title)}`.trim();
    const detail = [deepText(pullRequest.description), diff.slice(0, 2200)]
      .filter(Boolean)
      .join('\n');
    evidence.push({
      source: 'bitbucket',
      title,
      url: `https://bitbucket.org/${parts.workspace}/${parts.repo}/pull-requests/${parts.pullRequestId}`,
      detail,
    });
    text.push(title, detail);
  }

  return { evidence, text };
}

async function gatherAtlassianEvidence(
  input: string,
): Promise<{ evidence: AnalysisEvidence[]; text: string[] }> {
  const connection = loadConnection();
  if (!connection || !/^https?:\/\//i.test(input)) return { evidence: [], text: [] };
  const collectors = await Promise.allSettled([
    gatherJiraEvidence(connection, input),
    gatherConfluenceEvidence(connection, input),
    gatherBitbucketEvidence(connection, input),
  ]);
  const evidence: AnalysisEvidence[] = [];
  const text: string[] = [];
  for (const result of collectors) {
    if (result.status === 'fulfilled') {
      evidence.push(...result.value.evidence);
      text.push(...result.value.text);
    } else {
      evidence.push({
        source: 'stack',
        title: 'Recupero Atlassian parcial',
        detail: result.reason instanceof Error ? result.reason.message : String(result.reason),
      });
    }
  }
  return { evidence, text };
}

function detectFronts(text: string): string[] {
  const catalog: Array<[string, RegExp]> = [
    ['Frontend', /front|ui|pantalla|react|angular|web|portal/i],
    ['Backend', /back|api|servicio|endpoint|java|node|microservicio/i],
    ['Magento', /magento|catalog|checkout|cart/i],
    ['Billing', /billing|factur|invoice|cobro/i],
    ['PNL', /pnl|profit|loss|rentabilidad/i],
    ['Themis', /themis|fraud|risk|riesgo/i],
    ['Toolbox', /toolbox|operador|admin/i],
    ['Dataservice', /data service|dataservice|etl|dataset|query/i],
    ['CloudOps', /cloudops|cloud|infra|kubernetes|aws|azure|gcp/i],
    ['DevOps', /devops|pipeline|deploy|ci|cd|release/i],
    ['Payment Engine', /payment|pago|tarjeta|gateway|processor/i],
    ['QA', /qa|test|prueba|regresion|escenario/i],
  ];
  const matches = catalog.filter(([, pattern]) => pattern.test(text)).map(([name]) => name);
  return matches.length > 0 ? matches : ['BA', 'SAD', 'DEV', 'QA'];
}

function buildEvidence(input: string, linkedTitle?: string): AnalysisEvidence[] {
  return [
    {
      source: 'input',
      title: linkedTitle || 'Entrada del usuario',
      url: /^https?:\/\//i.test(input) ? input : undefined,
      detail: input.slice(0, 280),
    },
    {
      source: 'stack',
      title: 'Analisis inicial local',
      detail:
        'El motor preserva evidencia, supuestos y estimacion para retomar el trabajo sin recalentar contexto.',
    },
  ];
}

export function requireConnection(): StoredConnection {
  const connection = loadConnection();
  if (!connection) {
    throw new Error('Conexion Atlassian no configurada. Configurala desde la app antes de usar esta herramienta.');
  }
  return connection;
}

export async function fetchJiraIssue(keyOrUrl: string): Promise<string> {
  const connection = requireConnection();
  const key = extractJiraKey(keyOrUrl);
  if (!key) throw new Error('No se detecto una clave de Jira (ej: PROJ-123).');
  const issue = asRecord(
    await atlassianFetch(connection, {
      service: 'jira',
      path: `/rest/api/3/issue/${encodeURIComponent(key)}`,
      query: { expand: 'renderedFields' },
    }),
  );
  const fields = asRecord(issue.fields);
  const comments = asRecord(fields.comment);
  const commentText = Array.isArray(comments.comments)
    ? comments.comments.map((comment) => deepText(asRecord(comment).body)).join('\n')
    : '';
  return [
    `Issue: ${key} — ${asString(fields.summary)}`,
    `URL: ${connection.siteUrl}/browse/${key}`,
    `Estado: ${deepText(fields.status) || 'n/d'} · Prioridad: ${deepText(fields.priority) || 'n/d'}`,
    `Assignee: ${deepText(fields.assignee) || 'sin asignar'} · Reporter: ${deepText(fields.reporter) || 'n/d'}`,
    `Labels: ${Array.isArray(fields.labels) ? fields.labels.join(', ') : 'n/d'}`,
    '',
    '--- Descripcion ---',
    deepText(fields.description || fields.renderedFields),
    '',
    '--- Comentarios ---',
    commentText || 'Sin comentarios.',
  ].join('\n');
}

export async function fetchConfluencePage(pageIdOrUrl: string): Promise<string> {
  const connection = requireConnection();
  const pageId = extractConfluencePageId(pageIdOrUrl) || (/^\d+$/.test(pageIdOrUrl.trim()) ? pageIdOrUrl.trim() : null);
  if (!pageId) throw new Error('No se detecto un pageId de Confluence.');
  const page = asRecord(
    await atlassianFetch(connection, {
      service: 'confluence',
      path: `/wiki/api/v2/pages/${encodeURIComponent(pageId)}`,
      query: { 'body-format': 'atlas_doc_format' },
    }),
  );
  return [
    `Pagina: ${asString(page.title) || pageId}`,
    `URL: ${connection.siteUrl}/wiki/pages/${pageId}`,
    '',
    deepText(asRecord(page.body)),
  ].join('\n');
}

export async function fetchBitbucketPullRequest(workspace: string, repo: string, prId: string): Promise<string> {
  const connection = requireConnection();
  const pullRequest = asRecord(
    await atlassianFetch(connection, {
      service: 'bitbucket',
      path: `/repositories/${encodeURIComponent(workspace)}/${encodeURIComponent(repo)}/pullrequests/${encodeURIComponent(prId)}`,
    }),
  );
  const diff = await atlassianTextFetch(connection, {
    service: 'bitbucket',
    path: `/repositories/${encodeURIComponent(workspace)}/${encodeURIComponent(repo)}/pullrequests/${encodeURIComponent(prId)}/diff`,
  }).catch(() => '');
  return [
    `PR #${prId}: ${asString(pullRequest.title)}`,
    `URL: https://bitbucket.org/${workspace}/${repo}/pull-requests/${prId}`,
    `Estado: ${asString(pullRequest.state)} · Autor: ${asString(asRecord(pullRequest.author).display_name) || 'n/d'}`,
    '',
    '--- Descripcion ---',
    deepText(pullRequest.description) || 'Sin descripcion.',
    '',
    '--- Diff ---',
    diff.slice(0, 6000) || 'Diff no disponible.',
  ].join('\n');
}

export async function searchEvidence(query: string): Promise<AnalysisEvidence[]> {
  const connection = requireConnection();
  const trimmed = query.trim();
  if (!trimmed) throw new Error('La busqueda necesita un termino.');
  const evidence: AnalysisEvidence[] = [];
  const results = await Promise.allSettled([
    atlassianFetch(connection, {
      service: 'jira',
      path: '/rest/api/3/search',
      query: { jql: `text ~ "${trimmed.replace(/"/g, '')}" ORDER BY updated DESC`, maxResults: '5', fields: 'summary,status' },
    }),
    atlassianFetch(connection, {
      service: 'confluence',
      path: '/wiki/rest/api/content/search',
      query: { cql: `type = page AND text ~ "${trimmed.replace(/"/g, '')}"`, limit: '5' },
    }),
  ]);
  if (results[0].status === 'fulfilled') {
    const issues = asRecord(results[0].value);
    for (const item of (Array.isArray(issues.issues) ? issues.issues : []) as unknown[]) {
      const record = asRecord(item);
      const fields = asRecord(record.fields);
      evidence.push({
        source: 'jira',
        title: `${asString(record.key)} ${asString(fields.summary)}`.trim(),
        url: `${connection.siteUrl}/browse/${asString(record.key)}`,
        detail: `Estado: ${deepText(fields.status) || 'n/d'}.`,
      });
    }
  }
  if (results[1].status === 'fulfilled') {
    const pages = asRecord(results[1].value);
    for (const item of (Array.isArray(pages.results) ? pages.results : []) as unknown[]) {
      const record = asRecord(item);
      evidence.push({
        source: 'confluence',
        title: asString(record.title),
        url: `${connection.siteUrl}/wiki${asString(asRecord(record._links).webui)}`,
        detail: 'Pagina de Confluence que coincide con la busqueda.',
      });
    }
  }
  if (evidence.length === 0) {
    evidence.push({
      source: 'stack',
      title: 'Sin resultados',
      detail: `No se encontro contenido para "${trimmed}" o los servicios no respondieron.`,
    });
  }
  return evidence;
}

export async function analyzeInput(mode: 'url' | 'request', input: string): Promise<AnalyticsReport> {  if (!input.trim()) throw new Error('El analisis necesita una URL o texto de pedido.');

  const remote = await gatherAtlassianEvidence(input);
  const evidence = [...buildEvidence(input), ...remote.evidence];
  const hasRemoteEvidence = remote.evidence.some((item) => item.source !== 'stack');

  // Try the LLM path first. Falls back to the heuristic below on any error
  // so the app never goes dark when the model is unreachable.
  const evidenceCorpus = remote.text.join('\n\n').trim();
  const llm = await enrichWithLLM(input, evidenceCorpus).catch((error) => ({
    analysis: null,
    cached: false,
    durationMs: 0,
    source: 'fallback' as const,
    error: error instanceof Error ? error.message : String(error),
  }));

  if (llm.analysis) {
    const a = llm.analysis;
    return {
      id: `GVA-${Date.now().toString(36).toUpperCase()}`,
      createdAt: new Date().toISOString(),
      mode,
      input,
      summary: a.summary,
      currentState: a.currentState.length > 0 ? a.currentState : [
        hasRemoteEvidence
          ? 'Se recupero evidencia real desde Atlassian para complementar la lectura local.'
          : 'Se detecto la entrada y se preparo una interpretacion local.',
      ],
      proposedSolution: a.proposedSolution.length > 0 ? a.proposedSolution : [
        'Normalizar la entrada como caso de analisis trazable.',
        'Relacionar ticket, documentacion y codigo antes de estimar.',
      ],
      impactedFronts: a.impactedFronts.length > 0 ? a.impactedFronts : detectFronts(evidenceCorpus),
      roles: a.roles.length > 0 ? a.roles : ['Business Analyst', 'Developer', 'QA Analyst', 'Tech Lead'],
      complexity: {
        level: a.complexity.level,
        rationale: a.complexity.rationale || 'Complejidad estimada por el agente BA a partir de la evidencia.',
      },
      estimate: {
        discoveryHours: Math.max(4, Math.round(a.estimate.deliveryHours * 0.2)),
        deliveryHours: a.estimate.deliveryHours,
        qaHours: a.estimate.qaHours,
        confidence: a.estimate.confidence,
      },
      qaScenarios: a.qaScenarios,
      diagrams: {
        current: a.diagrams.current || 'Sin diagrama actual (evidencia insuficiente).',
        proposed: a.diagrams.proposed || 'Sin diagrama propuesto (evidencia insuficiente).',
      },
      evidence,
      nextActions: a.nextActions.length > 0 ? a.nextActions : [
        'Validar la lectura con el PO y el equipo tecnico.',
        'Cargar credenciales Atlassian o una URL reconocible si la evidencia es pobre.',
      ],
      llmSource: llm.source,
      llmDurationMs: llm.durationMs,
      llmCached: llm.cached,
      llmNotes: a.notes,
    };
  }

  // Heuristic fallback.
  const analysisCorpus = [input, ...remote.text].join('\n');
  const fronts = detectFronts(analysisCorpus);
  const complexityLevel = fronts.length >= 6 ? 'high' : fronts.length >= 3 ? 'medium' : 'low';
  const deliveryHours = complexityLevel === 'high' ? 64 : complexityLevel === 'medium' ? 32 : 16;
  const qaHours = Math.ceil(deliveryHours * 0.45);

  return {
    id: `GVA-${Date.now().toString(36).toUpperCase()}`,
    createdAt: new Date().toISOString(),
    mode,
    input,
    summary:
      mode === 'url'
        ? 'Analisis inicial de recurso Atlassian'
        : 'Analisis inicial de requerimiento',
    currentState: [
      hasRemoteEvidence
        ? 'Se recupero evidencia real desde Atlassian para complementar la lectura local.'
        : 'Se detecto la entrada y se preparo una interpretacion local.',
      hasRemoteEvidence
        ? 'La evidencia recuperada queda enlazada al reporte para auditoria y continuidad.'
        : 'La recuperacion profunda de Jira, Confluence y Bitbucket requiere credenciales validas o una URL reconocible.',
      'El reporte preserva evidencia y supuestos para que otro agente pueda continuar sin recalentar contexto.',
    ],
    proposedSolution: [
      'Normalizar la entrada como caso de analisis trazable.',
      'Relacionar ticket, documentacion y codigo antes de estimar o proponer implementacion.',
      'Generar documentacion y diagramas actual/propuesto con evidencia enlazada.',
    ],
    impactedFronts: fronts,
    roles: ['Business Analyst', 'Solution Architect', 'Developer', 'QA Analyst', 'Tech Lead'],
    complexity: {
      level: complexityLevel,
      rationale: `La complejidad se infiere por cantidad de frentes detectados: ${fronts.join(', ')}.`,
    },
    estimate: {
      discoveryHours: complexityLevel === 'high' ? 12 : complexityLevel === 'medium' ? 8 : 4,
      deliveryHours,
      qaHours,
      confidence: 'low',
    },
    qaScenarios: [
      'Validar camino feliz end-to-end.',
      'Validar escenarios de error, permisos y datos incompletos.',
      'Ejecutar regresion sobre frentes impactados.',
      'Confirmar criterios de aceptacion contra el ticket fuente.',
    ],
    diagrams: {
      current: 'URL/Ticket -> Lectura manual -> Interpretacion dispersa -> Estimacion',
      proposed:
        'URL/Ticket -> MCP Atlassian -> Evidencia normalizada -> Agentes GV -> Reporte/Diagramas/Export',
    },
    evidence,
    nextActions: [
      hasRemoteEvidence
        ? 'Ampliar busqueda relacionada: issues vinculados, paginas hijas, PRs y repos candidatos.'
        : 'Configurar credenciales Atlassian o pegar una URL reconocible para recuperar evidencia real.',
      'Conectar el pipeline de agentes BA/SAD/DEV/QA/DOC mediante el model router.',
    ],
    llmSource: 'heuristic',
    llmDurationMs: llm.durationMs,
    llmNotes: llm.error,
  };
}
