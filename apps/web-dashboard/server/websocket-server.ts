import { WebSocketServer, WebSocket } from 'ws';
import { createServer, IncomingMessage, ServerResponse } from 'http';
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'fs';
import { join, resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { getBridge } from './mcp-bridge.js';
import { getStateBridge } from './shared-state-bridge.js';
import type {
  AgentSession,
  AgentMessage,
  AgentToolCall,
  AgentMessage as AgentMessageType,
} from '../src/types/agent.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = resolve(__dirname);
const ROOT = resolve(__dirname, '../../..');
const STATS_PATH = join(ROOT, '.atl', 'skill-stats.json');
const REGISTRY_PATH = join(ROOT, '.atl', 'skill-registry.md');
const SESSIONS_HISTORY_PATH = join(ROOT, '.event-bus', 'sessions-history.json');

const PORT = parseInt(process.env.WS_PORT || '8080', 10);
const server = createServer(handleRequest);
const wss = new WebSocketServer({ server });

const clients = new Set<WebSocket>();
const agentSubscriptions = new Map<string, Set<WebSocket>>();
const sessions = new Map<string, AgentSession>();
let bridgeReady = false;

function loadStats() {
  try {
    const content = readFileSync(STATS_PATH, 'utf-8');
    return JSON.parse(content);
  } catch {
    return { totalCalls: 0, callsByTool: {}, callsBySkill: {}, lastCall: null };
  }
}

function countSkills() {
  try {
    const content = readFileSync(REGISTRY_PATH, 'utf-8');
    const lines = content.split('\n');
    let count = 0;
    const byAgent: Record<string, number> = {};

    for (const line of lines) {
      const match = line.match(/^\|\s*([^|]+)\|\s*([^|]+)\|/);
      if (match && match[1].trim() !== 'Agent') {
        const agent = match[1].trim();
        byAgent[agent] = (byAgent[agent] || 0) + 1;
        count++;
      }
    }

    return { total: count, byAgent };
  } catch {
    return { total: 0, byAgent: {} };
  }
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
  const stats = loadStats();
  const skills = countSkills();
  const topSkills = Object.entries(stats.callsBySkill || {})
    .sort(([, a], [, b]) => b - a)
    .slice(0, 5)
    .map(([name]) => name);

  return {
    timestamp: new Date().toISOString(),
    tokens: {
      used: 15000 + Math.floor(Math.random() * 500),
      limit: 30000,
      cost: 0.45 + Math.random() * 0.02,
    },
    sessions: {
      total: 42 + Math.floor(Math.random() * 5),
      active: 3 + Math.floor(Math.random() * 2),
      today: 5,
    },
    git: {
      commits: 128 + Math.floor(Math.random() * 10),
      prsMerged: 15,
      contributors: 4,
    },
    health: {
      status: Math.random() > 0.1 ? 'healthy' : 'degraded',
      routing: 0.95 + Math.random() * 0.04,
    },
    mcp: {
      skills: {
        total: skills.total,
        byAgent: skills.byAgent,
        recentlyUsed: topSkills,
      },
      calls: {
        total: stats.totalCalls || 0,
        byTool: stats.callsByTool || {},
        bySkill: stats.callsBySkill || {},
        lastCall: stats.lastCall,
      },
      performance: {
        avgResponseTime: 150 + Math.floor(Math.random() * 50),
        errorRate: Math.random() * 0.02,
      },
    },
  };
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
    res.end(JSON.stringify({ type: 'mcp', data: { skills: countSkills(), calls: loadStats() } }));
    return;
  }

  if (url.pathname === '/api/health') {
    res.writeHead(200, headers);
    res.end(JSON.stringify({ status: 'ok', uptime: process.uptime(), connections: clients.size }));
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
    const bridge = getStateBridge();
    res.end(JSON.stringify({ events: [] }));
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

  res.writeHead(404, headers);
  res.end(JSON.stringify({ error: 'Not found' }));
}

// --- WebSocket ---

wss.on('connection', (ws: WebSocket) => {
  console.log('[WS] Client connected');
  clients.add(ws);
  ws.send(JSON.stringify({ type: 'metrics', data: generateMetrics() }));
  ws.send(JSON.stringify({ type: 'bridge_status', connected: bridgeReady }));

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
    for (const [, subs] of agentSubscriptions) {
      subs.delete(ws);
    }
  });
});

setInterval(() => {
  const msg = JSON.stringify({ type: 'metrics', data: generateMetrics() });
  clients.forEach((c) => c.readyState === WebSocket.OPEN && c.send(msg));
}, 5000);

// --- Start ---

async function start() {
  loadSessions();
  try {
    const mcpBridge = getBridge();
    await mcpBridge.start();
    bridgeReady = true;
    console.log(`[MCP] Bridge connected — ${mcpBridge.tools.length} tools available`);
  } catch (err) {
    console.warn('[MCP] Bridge not available (MCP server not running)');
    bridgeReady = false;
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

server.listen(PORT, () => {
  console.log(`[WS] Server on port ${PORT}`);
  start();
  initSharedState();
});
