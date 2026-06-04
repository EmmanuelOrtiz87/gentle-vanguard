import { WebSocketServer, WebSocket } from 'ws';
import { createServer, IncomingMessage, ServerResponse } from 'http';
import { readFileSync } from 'fs';
import { join, resolve } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = resolve(__dirname);
const ROOT = resolve(__dirname, '../../..');
const STATS_PATH = join(ROOT, '.atl', 'skill-stats.json');
const REGISTRY_PATH = join(ROOT, '.atl', 'skill-registry.md');

const PORT = parseInt(process.env.WS_PORT || '8080', 10);
const server = createServer(handleRequest);
const wss = new WebSocketServer({ server });

const clients = new Set<WebSocket>();

// Load real stats from MCP
function loadStats() {
  try {
    const content = readFileSync(STATS_PATH, 'utf-8');
    return JSON.parse(content);
  } catch {
    return { totalCalls: 0, callsByTool: {}, callsBySkill: {}, lastCall: null };
  }
}

// Count skills from registry
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

function generateMetrics() {
  const stats = loadStats();
  const skills = countSkills();

  // Calculate top skills
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

  res.writeHead(404, headers);
  res.end(JSON.stringify({ error: 'Not found' }));
}

wss.on('connection', (ws: WebSocket) => {
  console.log('[WS] Client connected');
  clients.add(ws);
  ws.send(JSON.stringify({ type: 'metrics', data: generateMetrics() }));

  ws.on('message', (msg: string) => {
    try {
      const parsed = JSON.parse(msg.toString());
      if (parsed.type === 'ping') ws.send(JSON.stringify({ type: 'pong' }));
    } catch {
      // Ignore invalid messages
    }
  });

  ws.on('close', () => clients.delete(ws));
});

setInterval(() => {
  const msg = JSON.stringify({ type: 'metrics', data: generateMetrics() });
  clients.forEach((c) => c.readyState === WebSocket.OPEN && c.send(msg));
}, 5000);

server.listen(PORT, () => console.log(`[WS] Server on port ${PORT}`));
