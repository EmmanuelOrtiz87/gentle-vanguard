import { WebSocketServer, WebSocket } from 'ws';
import { createServer, IncomingMessage, ServerResponse } from 'http';
import { readFileSync, writeFileSync, existsSync, mkdirSync, watch } from 'fs';
import { join, dirname } from 'path';
import { getBridge } from './mcp-bridge.js';
import { getStateBridge } from './shared-state-bridge.js';
import { getGlobalHealth } from './global-health-api.js';
import {
  getListings,
  getListing,
  createListing,
  addReview,
  incrementDownloads,
  validateSkillStructure,
  getSkillContent,
} from './marketplace-api.js';
import { getRealMetrics, getTraces } from './real-data.js';
import { runValidations } from './validations.js';
import { ROOT, readJson, countSkills } from './shared.js';
import type {
  AgentSession,
  AgentMessage,
  AgentToolCall,
  AgentMessage as AgentMessageType,
} from '../src/types/agent.js';

const STATS_PATH = join(ROOT, '.atl', 'skill-stats.json');
const REGISTRY_PATH = join(ROOT, '.atl', 'skill-registry.md');
const SESSIONS_HISTORY_PATH = join(ROOT, '.event-bus', 'sessions-history.json');

const PORT = parseInt(process.env.WS_PORT || '8080', 10);
const server = createServer(handleRequest);
const wss = new WebSocketServer({ server });

const clients = new Set<WebSocket>();
const agentSubscriptions = new Map<string, Set<WebSocket>>();
const sessions = new Map<string, AgentSession>();
const connPerIp = new Map<string, number>();
const MAX_CONN_PER_IP = 5;
let bridgeReady = false;
let bridgeToolCount = 0;

function loadStats() {
  const content = readJson<{
    totalCalls: number;
    callsByTool: Record<string, number>;
    callsBySkill: Record<string, number>;
    lastCall: string | null;
  }>(STATS_PATH);
  return content || { totalCalls: 0, callsByTool: {}, callsBySkill: {}, lastCall: null };
}

function saveSessions(): void {
  try {
    const dir = dirname(SESSIONS_HISTORY_PATH);
    if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
    const list = Array.from(sessions.values()).map((s) => ({
      id: s.id,
      agent: s.agent,
      status: s.status,
      messageCount: s.messages.length,
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
      messages: s.messages,
    }));
    writeFileSync(SESSIONS_HISTORY_PATH, JSON.stringify(list, null, 2), 'utf-8');
  } catch {
    /* persistence best-effort */
  }
}

function loadSessions(): void {
  try {
    if (!existsSync(SESSIONS_HISTORY_PATH)) return;
    const content = readFileSync(SESSIONS_HISTORY_PATH, 'utf-8');
    const list: AgentSession[] = JSON.parse(content);
    for (const s of list) {
      if (!sessions.has(s.id)) sessions.set(s.id, s);
    }
    console.log(`[HISTORY] Loaded ${list.length} sessions from disk`);
  } catch {
    /* best-effort */
  }
}

function generateMetrics() {
  const real = getRealMetrics();
  return { ...real, globalHealth: getGlobalHealth() };
}

// --- Agent Session Management ---

function createSession(agent: string): AgentSession {
  const session: AgentSession = {
    id: `sess-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
    agent,
    status: 'idle',
    messages: [],
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  sessions.set(session.id, session);
  return session;
}

function addMessage(sessionId: string, msg: AgentMessage): void {
  const session = sessions.get(sessionId);
  if (session) {
    session.messages.push(msg);
    session.updatedAt = new Date().toISOString();
    saveSessions();
  }
}

function broadcastToSession(sessionId: string, payload: Record<string, unknown>): void {
  const subs = agentSubscriptions.get(sessionId);
  if (!subs) return;
  const msg = JSON.stringify(payload);
  for (const ws of subs) {
    if (ws.readyState === WebSocket.OPEN) ws.send(msg);
  }
}

async function handleAgentCommand(ws: WebSocket, msg: Record<string, unknown>): Promise<void> {
  const { action, sessionId, agent, skill, params } = msg as Record<string, string>;

  if (action === 'create_session') {
    const session = createSession(agent || 'DEV');
    subscribeToAgentSession(ws, session.id);
    ws.send(JSON.stringify({ type: 'agent_session_created', session }));
    return;
  }

  if (!sessionId) {
    ws.send(JSON.stringify({ type: 'error', error: 'sessionId required' }));
    return;
  }

  const session = sessions.get(sessionId as string);
  if (!session) {
    ws.send(JSON.stringify({ type: 'error', error: 'Session not found' }));
    return;
  }

  if (action === 'subscribe') {
    subscribeToAgentSession(ws, sessionId as string);
    ws.send(JSON.stringify({ type: 'subscribed', sessionId }));
    return;
  }

  if (action === 'list_sessions') {
    const list = Array.from(sessions.values()).map((s) => ({
      id: s.id,
      agent: s.agent,
      status: s.status,
      messageCount: s.messages.length,
      updatedAt: s.updatedAt,
    }));
    ws.send(JSON.stringify({ type: 'agent_sessions', sessions: list }));
    return;
  }

  if (action === 'list_history') {
    ws.send(JSON.stringify({ type: 'agent_history', sessions: Array.from(sessions.values()) }));
    return;
  }

  if (action === 'get_session') {
    ws.send(JSON.stringify({ type: 'agent_session', session }));
    return;
  }

  if (action === 'list_tools') {
    const bridge = getBridge();
    ws.send(
      JSON.stringify({ type: 'agent_tools', tools: bridge.tools, connected: bridge.connected }),
    );
    return;
  }

  if (action === 'execute_skill') {
    executeSkillAndStream(ws, session, skill as string, params as Record<string, unknown>);
    return;
  }

  if (action === 'emit_event') {
    const eventMsg = msg as { event?: string; payload?: Record<string, unknown> };
    if (eventMsg.event) {
      getStateBridge().emitEvent(eventMsg.event, eventMsg.payload || {});
    }
    return;
  }

  if (action === 'hitl_response') {
    const hitlResponse = msg as Record<string, unknown>;
    session.status = 'active';
    broadcastToSession(session.id, {
      type: 'hitl_resolved',
      requestId: hitlResponse.requestId,
      response: hitlResponse.response,
    });
    return;
  }

  if (action === 'send_message') {
    const userMsg: AgentMessage = {
      id: `msg-${Date.now()}`,
      agent: session.agent,
      role: 'user',
      content: (msg as Record<string, string>).message || '',
      timestamp: new Date().toISOString(),
    };
    addMessage(session.id, userMsg);
    broadcastToSession(session.id, { type: 'agent_message', message: userMsg });

    const assistantMsg: AgentMessage = {
      id: `msg-${Date.now()}-1`,
      agent: session.agent,
      role: 'assistant',
      content: `Procesando solicitud en agente ${session.agent}...`,
      timestamp: new Date().toISOString(),
      streaming: true,
    };
    addMessage(session.id, assistantMsg);
    broadcastToSession(session.id, { type: 'agent_message', message: assistantMsg });

    const text = (msg as Record<string, string>).message?.toLowerCase() || '';
    const needsHITL =
      text.includes('approve') ||
      text.includes('confirm') ||
      text.includes('delegate') ||
      text.includes('revisar');

    if (needsHITL) {
      session.status = 'awaiting_input';
      const hitlRequest = {
        id: `hitl-${Date.now()}`,
        type: 'confirmation' as const,
        title: 'Human-in-the-Loop Required',
        description: `Agent ${session.agent} requires your approval before proceeding.`,
        agent: session.agent,
        context: { input: text, session: session.id },
      };
      broadcastToSession(session.id, { type: 'hitl_request', hitlRequest });
    } else {
      setTimeout(() => {
        assistantMsg.streaming = false;
        assistantMsg.content = `Solicitud procesada por agente ${session.agent}. La respuesta sería generada aquí en producción.`;
        broadcastToSession(session.id, { type: 'agent_message', message: assistantMsg });
        broadcastToSession(session.id, { type: 'agent_stream_done', messageId: assistantMsg.id });
      }, 1500);
    }
    return;
  }
}

function subscribeToAgentSession(ws: WebSocket, sessionId: string): void {
  if (!agentSubscriptions.has(sessionId)) {
    agentSubscriptions.set(sessionId, new Set());
  }
  agentSubscriptions.get(sessionId)!.add(ws);
}

async function executeSkillAndStream(
  ws: WebSocket,
  session: AgentSession,
  skillName: string,
  params?: Record<string, unknown>,
): Promise<void> {
  session.status = 'active';

  const toolCall: AgentToolCall = {
    id: `tc-${Date.now()}`,
    tool: 'execute_skill',
    args: { name: skillName, ...params },
    status: 'running',
    startedAt: new Date().toISOString(),
  };

  const msg: AgentMessage = {
    id: `msg-${Date.now()}`,
    agent: session.agent,
    role: 'assistant',
    content: `Ejecutando skill "${skillName}"...`,
    timestamp: new Date().toISOString(),
    streaming: true,
    toolCalls: [toolCall],
  };
  addMessage(session.id, msg);
  broadcastToSession(session.id, { type: 'agent_message', message: msg });

  try {
    const bridge = getBridge();
    if (!bridge.connected) {
      throw new Error('MCP bridge not connected');
    }

    const result = await bridge.callTool('execute_skill', { name: skillName, params });

    msg.streaming = false;
    msg.content = `Skill "${skillName}" ejecutado exitosamente.`;
    toolCall.status = 'completed';
    toolCall.result = JSON.stringify(result);
    toolCall.completedAt = new Date().toISOString();

    broadcastToSession(session.id, { type: 'agent_message', message: msg });
    broadcastToSession(session.id, { type: 'agent_stream_done', messageId: msg.id });
  } catch (err) {
    msg.streaming = false;
    msg.content = `Error ejecutando skill "${skillName}": ${err instanceof Error ? err.message : String(err)}`;
    toolCall.status = 'error';
    toolCall.error = err instanceof Error ? err.message : String(err);
    toolCall.completedAt = new Date().toISOString();

    broadcastToSession(session.id, { type: 'agent_message', message: msg });
    broadcastToSession(session.id, { type: 'agent_stream_done', messageId: msg.id });
  }

  session.status = 'idle';
}

// --- HTTP Handlers ---

function handleRequest(req: IncomingMessage, res: ServerResponse) {
  const url = new URL(req.url || '/', `http://${req.headers.host}`);
  const headers = { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' };

  if (req.method === 'OPTIONS') {
    res.writeHead(204, { ...headers, 'Access-Control-Allow-Methods': 'GET, OPTIONS' });
    res.end();
    return;
  }

  if (url.pathname === '/api/metrics') {
    res.writeHead(200, headers);
    res.end(JSON.stringify({ type: 'metrics', data: generateMetrics() }));
    return;
  }

  if (url.pathname === '/api/mcp/metrics') {
    res.writeHead(200, headers);
    res.end(
      JSON.stringify({
        type: 'mcp',
        data: { skills: countSkills(REGISTRY_PATH), calls: loadStats() },
      }),
    );
    return;
  }

  if (url.pathname === '/api/health') {
    res.writeHead(200, headers);
    res.end(JSON.stringify({ status: 'ok', uptime: process.uptime(), connections: clients.size }));
    return;
  }

  if (url.pathname === '/api/traces') {
    res.writeHead(200, headers);
    res.end(JSON.stringify(getTraces()));
    return;
  }

  if (url.pathname === '/api/health/global') {
    res.writeHead(200, headers);
    res.end(JSON.stringify(getGlobalHealth()));
    return;
  }

  if (url.pathname === '/api/agent/tools') {
    const bridge = getBridge();
    res.writeHead(200, headers);
    res.end(JSON.stringify({ tools: bridge.tools, connected: bridge.connected }));
    return;
  }

  if (url.pathname === '/api/agent/sessions') {
    const list = Array.from(sessions.values()).map((s) => ({
      id: s.id,
      agent: s.agent,
      status: s.status,
      messageCount: s.messages.length,
      updatedAt: s.updatedAt,
    }));
    res.writeHead(200, headers);
    res.end(JSON.stringify({ sessions: list }));
    return;
  }

  if (url.pathname === '/api/state/events') {
    res.writeHead(200, headers);
    try {
      const historyPath = join(ROOT, '.event-bus', 'history.json');
      if (existsSync(historyPath)) {
        const history = JSON.parse(readFileSync(historyPath, 'utf-8'));
        res.end(JSON.stringify({ events: history.events || [] }));
      } else {
        res.end(JSON.stringify({ events: [] }));
      }
    } catch {
      res.end(JSON.stringify({ events: [] }));
    }
    return;
  }

  if (url.pathname === '/api/state/tasks') {
    res.writeHead(200, headers);
    const bridge = getStateBridge();
    res.end(JSON.stringify({ tasks: bridge.tasks }));
    return;
  }

  if (url.pathname === '/api/state/emit' && req.method === 'POST') {
    let body = '';
    req.on('data', (chunk) => {
      body += chunk;
    });
    req.on('end', () => {
      try {
        const { event, payload } = JSON.parse(body);
        if (event) {
          getStateBridge().emitEvent(event, payload || {});
          res.writeHead(200, headers);
          res.end(JSON.stringify({ ok: true }));
        } else {
          res.writeHead(400, headers);
          res.end(JSON.stringify({ error: 'event field required' }));
        }
      } catch {
        res.writeHead(400, headers);
        res.end(JSON.stringify({ error: 'Invalid JSON' }));
      }
    });
    return;
  }

  if (url.pathname.startsWith('/api/agent/session/')) {
    const sessionId = url.pathname.split('/').pop();
    const session = sessionId ? sessions.get(sessionId) : undefined;
    if (!session) {
      res.writeHead(404, headers);
      res.end(JSON.stringify({ error: 'Session not found' }));
      return;
    }
    res.writeHead(200, headers);
    res.end(JSON.stringify({ session }));
    return;
  }

  // --- Marketplace Routes ---

  if (url.pathname === '/api/marketplace' && req.method === 'GET') {
    const listings = getListings();
    res.writeHead(200, headers);
    res.end(JSON.stringify({ success: true, data: listings, total: listings.length }));
    return;
  }

  if (url.pathname === '/api/marketplace' && req.method === 'POST') {
    let body = '';
    req.on('data', (chunk) => {
      body += chunk;
    });
    req.on('end', () => {
      try {
        const payload = JSON.parse(body);
        const missingFields: string[] = [];
        if (!payload.name) missingFields.push('name');
        if (!payload.description) missingFields.push('description');
        if (!payload.author) missingFields.push('author');
        if (!payload.skillContent) missingFields.push('skillContent');

        if (missingFields.length > 0) {
          res.writeHead(400, headers);
          res.end(
            JSON.stringify({
              success: false,
              error: `Missing required fields: ${missingFields.join(', ')}`,
            }),
          );
          return;
        }

        const validation = validateSkillStructure(payload.skillContent);
        if (!validation.valid) {
          res.writeHead(400, headers);
          res.end(
            JSON.stringify({
              success: false,
              error: 'Skill structure validation failed',
              details: validation.errors,
            }),
          );
          return;
        }

        const listing = createListing({
          name: payload.name,
          description: payload.description,
          author: payload.author,
          version: payload.version,
          tags: payload.tags,
          triggers: payload.triggers,
          agentType: payload.agentType,
          skillContent: payload.skillContent,
        });
        res.writeHead(201, headers);
        res.end(
          JSON.stringify({
            success: true,
            data: listing,
            message: `Skill '${payload.name}' created successfully`,
          }),
        );
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Failed to create listing';
        const status = message.includes('already exists') ? 409 : 500;
        res.writeHead(status, headers);
        res.end(JSON.stringify({ success: false, error: message }));
      }
    });
    return;
  }

  if (url.pathname === '/api/marketplace/validate/structure' && req.method === 'POST') {
    let body = '';
    req.on('data', (chunk) => {
      body += chunk;
    });
    req.on('end', () => {
      try {
        const { skillContent } = JSON.parse(body);
        if (!skillContent) {
          res.writeHead(400, headers);
          res.end(
            JSON.stringify({ success: false, error: 'Missing required field: skillContent' }),
          );
          return;
        }
        const result = validateSkillStructure(skillContent);
        res.writeHead(200, headers);
        res.end(JSON.stringify({ success: true, data: result }));
      } catch {
        res.writeHead(400, headers);
        res.end(JSON.stringify({ success: false, error: 'Invalid JSON' }));
      }
    });
    return;
  }

  // Match /api/marketplace/:id/review and /api/marketplace/:id/download
  const marketplaceMatch = url.pathname.match(
    /^\/api\/marketplace\/([^/]+)(?:\/(review|download))?$/,
  );
  if (marketplaceMatch) {
    const listingId = marketplaceMatch[1];
    const action = marketplaceMatch[2];

    if (!action && req.method === 'GET') {
      const listing = getListing(listingId);
      if (!listing) {
        res.writeHead(404, headers);
        res.end(JSON.stringify({ success: false, error: 'Listing not found' }));
        return;
      }
      const content = listing.skillPath ? getSkillContent(listing.skillPath) : null;
      res.writeHead(200, headers);
      res.end(JSON.stringify({ success: true, data: { ...listing, content } }));
      return;
    }

    if (action === 'review' && req.method === 'POST') {
      let body = '';
      req.on('data', (chunk) => {
        body += chunk;
      });
      req.on('end', () => {
        try {
          const { user, rating, comment } = JSON.parse(body);
          if (!user || rating == null || !comment) {
            res.writeHead(400, headers);
            res.end(
              JSON.stringify({
                success: false,
                error: 'Missing required fields: user, rating, comment',
              }),
            );
            return;
          }
          if (typeof rating !== 'number' || rating < 1 || rating > 5) {
            res.writeHead(400, headers);
            res.end(
              JSON.stringify({ success: false, error: 'Rating must be a number between 1 and 5' }),
            );
            return;
          }
          const review = addReview(listingId, { user, rating, comment });
          res.writeHead(201, headers);
          res.end(JSON.stringify({ success: true, data: review }));
        } catch {
          res.writeHead(400, headers);
          res.end(JSON.stringify({ success: false, error: 'Invalid JSON' }));
        }
      });
      return;
    }

    if (action === 'download' && req.method === 'POST') {
      const downloads = incrementDownloads(listingId);
      res.writeHead(200, headers);
      res.end(JSON.stringify({ success: true, data: { id: listingId, downloads } }));
      return;
    }

    res.writeHead(404, headers);
    res.end(JSON.stringify({ success: false, error: 'Route not found' }));
    return;
  }

  res.writeHead(404, headers);
  res.end(JSON.stringify({ error: 'Not found' }));
}

// --- WebSocket ---

wss.on('connection', (ws: WebSocket, req: IncomingMessage) => {
  const ip =
    (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() ||
    req.socket.remoteAddress ||
    'unknown';
  const current = connPerIp.get(ip) || 0;
  if (current >= MAX_CONN_PER_IP) {
    console.log(`[WS] Blocked excessive connection from ${ip} (${current})`);
    ws.close(1013, 'Too many connections');
    return;
  }
  connPerIp.set(ip, current + 1);
  console.log(`[WS] Client connected (${ip}, conns: ${current + 1})`);
  clients.add(ws);
  ws.send(JSON.stringify({ type: 'metrics', data: generateMetrics() }));
  ws.send(JSON.stringify({ type: 'bridge_status', connected: bridgeReady }));

  // Send current state to newly connected client
  const stateBridge = getStateBridge();
  ws.send(JSON.stringify({ type: 'state_tasks', tasks: stateBridge.tasks }));
  try {
    const historyPath = join(ROOT, '.event-bus', 'history.json');
    if (existsSync(historyPath)) {
      const history = JSON.parse(readFileSync(historyPath, 'utf-8'));
      ws.send(
        JSON.stringify({ type: 'state_history', events: (history.events || []).slice(0, 20) }),
      );
    }
  } catch (e) {
    console.warn('[WS] Failed to send state history to new client:', (e as Error).message);
  }

  ws.on('message', (raw: Buffer | string) => {
    try {
      const parsed = JSON.parse(raw.toString());

      if (parsed.type === 'ping') {
        ws.send(JSON.stringify({ type: 'pong' }));
        return;
      }

      if (parsed.type === 'agent') {
        handleAgentCommand(ws, parsed);
        return;
      }
    } catch {
      // Ignore invalid messages
    }
  });

  ws.on('close', () => {
    clients.delete(ws);
    const prev = connPerIp.get(ip) || 1;
    if (prev <= 1) connPerIp.delete(ip);
    else connPerIp.set(ip, prev - 1);
    for (const [, subs] of agentSubscriptions) {
      subs.delete(ws);
    }
  });
});

let prevMetrics: Record<string, unknown> | null = null;

function broadcastValidations(): void {
  const validations = runValidations(bridgeReady, bridgeToolCount, clients.size);
  const msg = JSON.stringify({ type: 'validations', data: validations });
  clients.forEach((c) => c.readyState === WebSocket.OPEN && c.send(msg));
}

setInterval(() => {
  const metrics = generateMetrics();
  const msg = JSON.stringify({ type: 'metrics', data: metrics });
  clients.forEach((c) => c.readyState === WebSocket.OPEN && c.send(msg));
  broadcastValidations();

  if (prevMetrics) {
    const prev = prevMetrics as Record<string, any>;
    const curr = metrics as Record<string, any>;
    const currTokens = curr?.tokens?.used || 0;
    const prevTokens = prev?.tokens?.used || 0;
    const currSessions = curr?.sessions?.total || 0;
    const prevSessions = prev?.sessions?.total || 0;
    const currActive = curr?.sessions?.active || 0;
    const prevActive = prev?.sessions?.active || 0;
    const currEvents = curr?.events?.length || 0;
    const prevEvents = prev?.events?.length || 0;

    const notifications: Array<{
      type: string;
      message: string;
      severity: string;
      timestamp: string;
    }> = [];

    if (currTokens > prevTokens) {
      const delta = currTokens - prevTokens;
      notifications.push({
        type: 'token_usage',
        message: `+${delta} tokens (${(currTokens / 1000).toFixed(1)}K total)`,
        severity: 'info',
        timestamp: curr.timestamp,
      });
    }
    if (currSessions > prevSessions) {
      notifications.push({
        type: 'session_created',
        message: `Nueva sesión creada (${currSessions} total)`,
        severity: 'info',
        timestamp: curr.timestamp,
      });
    }
    if (currActive !== prevActive) {
      notifications.push({
        type: 'session_status',
        message: `Sesiones activas: ${prevActive} → ${currActive}`,
        severity: currActive > prevActive ? 'info' : 'warning',
        timestamp: curr.timestamp,
      });
    }
    if (currEvents > prevEvents) {
      const delta = currEvents - prevEvents;
      notifications.push({
        type: 'new_events',
        message: `${delta} nuevo(s) evento(s) en timeline`,
        severity: 'info',
        timestamp: curr.timestamp,
      });
    }

    if (notifications.length > 0) {
      const note = JSON.stringify({ type: 'notification', notifications });
      clients.forEach((c) => c.readyState === WebSocket.OPEN && c.send(note));
    }
  }

  prevMetrics = metrics;
}, 5000);

// Auto-refresh token.json cada 5 minutos
setInterval(() => {
  refreshTokenMetrics();
  console.log('[METRICS] token.json auto-refreshed (5min cycle)');
}, 300000);

// File watcher en .runtime/metrics/ — broadcast inmediato ante cambios reales
const METRICS_WATCH_DIR = join(ROOT, '.runtime', 'metrics');
if (existsSync(METRICS_WATCH_DIR)) {
  try {
    let watchTimer: ReturnType<typeof setTimeout> | null = null;
    const DEBOUNCE_MS = 200;
    watch(METRICS_WATCH_DIR, (eventType, filename) => {
      if (!filename || !filename.endsWith('.json')) return;
      if (watchTimer) clearTimeout(watchTimer);
      watchTimer = setTimeout(() => {
        const metrics = generateMetrics();
        const msg = JSON.stringify({ type: 'metrics', data: metrics });
        clients.forEach((c) => c.readyState === WebSocket.OPEN && c.send(msg));
        console.log(`[WATCH] metrics file changed: ${filename} → broadcast`);
      }, DEBOUNCE_MS);
    });
    console.log('[WATCH] .runtime/metrics/ watcher started');
  } catch (err) {
    console.warn('[WATCH] Could not start metrics watcher:', (err as Error).message);
  }
}

// --- Start ---

function refreshTokenMetrics(): void {
  const consolidatedPath = join(ROOT, '.runtime', 'metrics', 'consolidated.json');
  const tokenPath = join(ROOT, '.runtime', 'metrics', 'token.json');
  const tokenDir = dirname(tokenPath);
  if (!existsSync(tokenDir)) mkdirSync(tokenDir, { recursive: true });
  try {
    let usedToday = 0,
      budget = 1000000;
    if (existsSync(consolidatedPath)) {
      const c = JSON.parse(readFileSync(consolidatedPath, 'utf-8'));
      usedToday = c?.token?.usedToday || 0;
      budget = c?.token?.budget || 1000000;
    }
    writeFileSync(
      tokenPath,
      JSON.stringify(
        {
          usedToday,
          budget,
          estCost: 0,
          pct: budget > 0 ? (usedToday / budget) * 100 : 0,
          _refreshedAt: new Date().toISOString(),
        },
        null,
        2,
      ),
    );
    console.log('[METRICS] token.json refreshed');
  } catch (e) {
    console.warn('[METRICS] Could not refresh token.json:', (e as Error).message);
  }
}

async function start() {
  loadSessions();
  refreshTokenMetrics();
  try {
    const mcpBridge = getBridge();
    await mcpBridge.start();
    bridgeReady = true;
    bridgeToolCount = mcpBridge.tools.length;
    console.log(`[MCP] Bridge connected — ${bridgeToolCount} tools available`);
  } catch (err) {
    console.warn('[MCP] Bridge not available (MCP server not running)');
    bridgeReady = false;
    bridgeToolCount = 0;
  }
}

function initSharedState(): void {
  const stateBridge = getStateBridge();
  stateBridge.on('history_update', (events: unknown) => {
    const msg = JSON.stringify({ type: 'state_history', events });
    clients.forEach((c) => c.readyState === WebSocket.OPEN && c.send(msg));
  });
  stateBridge.on('task_update', (tasks: unknown) => {
    const msg = JSON.stringify({ type: 'state_tasks', tasks });
    clients.forEach((c) => c.readyState === WebSocket.OPEN && c.send(msg));
  });
  stateBridge.on('event', (evt: unknown) => {
    const msg = JSON.stringify({ type: 'state_event', event: evt });
    clients.forEach((c) => c.readyState === WebSocket.OPEN && c.send(msg));
  });
  stateBridge.start();
  console.log('[STATE] Shared State Bridge started');
}

function startTraceWatcher(): void {
  const ctxDir = join(ROOT, '.session', 'context-log');
  if (!existsSync(ctxDir)) {
    mkdirSync(ctxDir, { recursive: true });
  }
  try {
    watch(ctxDir, { recursive: true }, (eventType, filename) => {
      if (!filename || !filename.endsWith('.state.json')) return;
      const statePath = join(ctxDir, filename);
      try {
        const state = JSON.parse(readFileSync(statePath, 'utf-8'));
        const msg = JSON.stringify({
          type: 'trace_update',
          session: { id: state.sessionId || filename.split(/[\\/]/)[0], state },
        });
        clients.forEach((c) => c.readyState === WebSocket.OPEN && c.send(msg));
      } catch (e) {
        console.warn('[TRACE] Error parsing state file:', filename, (e as Error).message);
      }
    });
    console.log('[TRACE] Context-log watcher started');
  } catch (err) {
    console.warn('[TRACE] File watcher not available:', (err as Error).message);
  }
}

server.listen(PORT, () => {
  console.log(`[WS] Server on port ${PORT}`);
  start();
  initSharedState();
  startTraceWatcher();
});

// --- Graceful Shutdown ---

function shutdown(signal: string) {
  console.log(`[SHUTDOWN] Received ${signal}, closing gracefully...`);
  const bridge = getBridge();
  bridge.stop().catch(() => {});
  getStateBridge().stop();
  wss.close(() => {
    console.log('[SHUTDOWN] WebSocket server closed');
  });
  server.close(() => {
    console.log('[SHUTDOWN] HTTP server closed');
    process.exit(0);
  });
  setTimeout(() => {
    console.warn('[SHUTDOWN] Forced exit after timeout');
    process.exit(1);
  }, 5000);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
