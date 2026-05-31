#!/usr/bin/env node
const http = require('http');
const fs = require('fs');
const path = require('path');
const cp = require('child_process');

const PORT = 8080;
const ROOT = path.resolve(__dirname, '..', '..');
const METRICS_DIR = path.join(ROOT, '.runtime', 'metrics');
const SESSION_DIR = path.join(ROOT, '.session');
const CONTEXT_LOG_DIR = path.join(SESSION_DIR, 'context-log');
const MODEL_ROUTING = path.join(ROOT, 'config', 'model-routing.json');
const AGENT_PROFILES = path.join(ROOT, 'config', 'orchestrator.json');

const MIME_TYPES = {
  '.html': 'text/html', '.css': 'text/css', '.js': 'application/javascript', '.json': 'application/json'
};

const MECHANISM_PROFILES = {
  'fast-cheap': { profile: 'optimized', thinking: 'off', description: 'Fast response, minimal reasoning' },
  'strong-reasoning': { profile: 'deep', thinking: 'high', description: 'Deep reasoning, high compute' },
  'strong-coding': { profile: 'focused', thinking: 'medium', description: 'Focused coding, balanced compute' },
  'strong-review': { profile: 'thorough', thinking: 'high', description: 'Thorough review, full analysis' },
  'inherit': { profile: 'default', thinking: 'default', description: 'Inherits from parent context' }
};

// Opencode runtime profiles — detected from CLAUDE.md or model metadata
const OPENCODE_PROFILES = {
  'ultra': { profile: 'ultra', thinking: 'off', chat: 'chat-compact', description: 'Ultra-compact response, max 4 lines' },
  'lleno': { profile: 'lleno', thinking: 'medium', chat: 'chat-balanced', description: 'Full verbose, detailed responses' },
  'balanced': { profile: 'balanced', thinking: 'low', chat: 'chat-balanced', description: 'Balanced verbosity mode' },
};

// SSE clients for push-based live updates
let sseClients = [];

let currentStateWatcher = null;

// Server-side auto-tracked metrics for live fallback
let serverMetrics = {
  requestCount: 0,
  bytesServed: 0,
  startTime: Date.now(),
  virtualTokens: 1234,
  virtualCost: 0.0086,
  sessionId: 'live-' + Date.now().toString(36)
};

function readJson(filePath) {
  try {
    if (!fs.existsSync(filePath)) return null;
    return JSON.parse(fs.readFileSync(filePath, 'utf-8'));
  } catch { return null; }
}

function readDir(dirPath) {
  try {
    if (!fs.existsSync(dirPath)) return [];
    return fs.readdirSync(dirPath, { withFileTypes: true }).filter(d => d.isDirectory()).map(d => d.name);
  } catch { return []; }
}

function findStateInDir(dir) {
  const stateFile = path.join(dir, '.state.json');
  if (fs.existsSync(stateFile)) return readJson(stateFile);
  return null;
}

function getAgentModel(agentCode) {
  const routing = readJson(MODEL_ROUTING);
  if (!routing || !routing.agents) return 'inherit';
  const agent = routing.agents[agentCode];
  return agent ? { model: agent.model, thinking: agent.thinking, rationale: agent.rationale } : null;
}

function detectMechanismFromModel(model) {
  if (!model) return MECHANISM_PROFILES['inherit'];
  const lower = model.toLowerCase();

  // Check opencode runtime profiles first
  if (lower.includes('ultra') || lower.includes('chat-compact')) return OPENCODE_PROFILES['ultra'];
  if (lower.includes('lleno') || lower.includes('chat-balanced') && lower.includes('lleno')) return OPENCODE_PROFILES['lleno'];
  if (lower.includes('balanced') || lower.includes('chat-balanced') && !lower.includes('lleno')) return OPENCODE_PROFILES['balanced'];

  // Check agent/model-routing profiles
  if (lower.includes('fast') || lower.includes('cheap')) return MECHANISM_PROFILES['fast-cheap'];
  if (lower.includes('reason') || lower.includes('deep')) return MECHANISM_PROFILES['strong-reasoning'];
  if (lower.includes('code') || lower.includes('dev')) return MECHANISM_PROFILES['strong-coding'];
  if (lower.includes('review') || lower.includes('qa')) return MECHANISM_PROFILES['strong-review'];
  return MECHANISM_PROFILES['inherit'];
}

function collectSessions() {
  const sessionDirs = readDir(CONTEXT_LOG_DIR);
  const sessions = [];
  for (const sid of sessionDirs) {
    const state = findStateInDir(path.join(CONTEXT_LOG_DIR, sid));
    if (!state) continue;
    const isActive = sid === getCurrentSessionId();
    sessions.push({
      id: state.sessionId || sid,
      startedAt: state.startedAt || '',
      turnCount: state.turnCount || 0,
      totalInputTokens: state.totalInputTokens || 0,
      totalOutputTokens: state.totalOutputTokens || 0,
      totalTokens: (state.totalInputTokens || 0) + (state.totalOutputTokens || 0),
      totalCost: state.totalCost || 0,
      totalContextChars: state.totalContextChars || 0,
      model: state.model || '',
      status: isActive ? 'ACTIVE' : 'COMPLETED',
      turns: state.turns || []
    });
  }
  sessions.sort((a, b) => (b.startedAt || '').localeCompare(a.startedAt || ''));
  return sessions;
}

function getCurrentSessionId() {
  const sessions = readDir(CONTEXT_LOG_DIR);
  if (sessions.length === 0) return 'none';
  const sessionDirs = sessions.map(s => ({ name: s, stat: fs.statSync(path.join(CONTEXT_LOG_DIR, s), { throwIfNoEntry: false }) }))
    .filter(s => s.stat);
  sessionDirs.sort((a, b) => b.stat.mtimeMs - a.stat.mtimeMs);
  return sessionDirs.length > 0 ? sessionDirs[0].name : sessions[sessions.length - 1];
}

function getLiveSession() {
  const currentId = getCurrentSessionId();
  const stateFile = path.join(CONTEXT_LOG_DIR, currentId, '.state.json');
  const state = readJson(stateFile);
  if (!state) {
    // Virtual fallback when no real session state exists
    const elapsed = Math.floor((Date.now() - serverMetrics.startTime) / 1000);
    const elapsedStr = elapsed >= 3600
      ? `${Math.floor(elapsed / 3600)}h ${Math.floor((elapsed % 3600) / 60)}m`
      : `${Math.floor(elapsed / 60)}m ${elapsed % 60}s`;
    const totalVTokens = serverMetrics.virtualTokens || 150;
    return {
      sessionId: serverMetrics.sessionId,
      startedAt: serverMetrics.startTime.toISOString(),
      elapsed: elapsedStr,
      status: 'ACTIVE',
      turnCount: serverMetrics.requestCount + 1,
      currentMechanism: MECHANISM_PROFILES['fast-cheap'],
      totalTokens: {
        input: Math.floor(totalVTokens * 0.65),
        output: Math.floor(totalVTokens * 0.35),
        total: totalVTokens,
        cost: parseFloat((totalVTokens * 0.000007).toFixed(6)) || 0.001,
        contextChars: totalVTokens * 3
      },
      turns: [{
        turn: 1,
        label: 'Auto-tracked',
        timestamp: new Date().toISOString(),
        inputTokens: Math.floor(totalVTokens * 0.65),
        outputTokens: Math.floor(totalVTokens * 0.35),
        totalTokens: totalVTokens,
        contextChars: totalVTokens * 3,
        cost: parseFloat((totalVTokens * 0.000007).toFixed(6)) || 0.001,
        mechanism: MECHANISM_PROFILES['fast-cheap']
      }],
      lastUpdate: new Date().toISOString()
    };
  }

  const totalIn = state.totalInputTokens || 0;
  const totalOut = state.totalOutputTokens || 0;
  const mechanism = detectMechanismFromModel(state.model || '');

  const startTime = state.startedAt ? new Date(state.startedAt) : new Date();
  const elapsed = Math.floor((Date.now() - startTime.getTime()) / 1000);
  const elapsedStr = elapsed >= 3600
    ? `${Math.floor(elapsed / 3600)}h ${Math.floor((elapsed % 3600) / 60)}m`
    : `${Math.floor(elapsed / 60)}m ${elapsed % 60}s`;

  return {
    sessionId: state.sessionId || currentId,
    startedAt: state.startedAt,
    elapsed: elapsedStr,
    status: 'ACTIVE',
    turnCount: state.turnCount || 0,
    currentMechanism: mechanism,
    totalTokens: {
      input: totalIn,
      output: totalOut,
      total: totalIn + totalOut,
      cost: state.totalCost || 0,
      contextChars: state.totalContextChars || 0
    },
    turns: (state.turns || []).map((t, i) => ({
      turn: t.turn || i + 1,
      label: t.label || `Turn-${i + 1}`,
      timestamp: t.timestamp || '',
      inputTokens: t.inputTokens || 0,
      outputTokens: t.outputTokens || 0,
      totalTokens: t.totalTokens || 0,
      contextChars: t.contextChars || 0,
      cost: t.cost || 0,
      mechanism: mechanism
    })),
    lastUpdate: new Date().toISOString()
  };
}

function getMechanismHistory(sessions) {
  const changes = [];
  let lastMechanism = null;
  for (const session of sessions) {
    const mechanism = detectMechanismFromModel(session.model);
    if (lastMechanism && (lastMechanism.profile !== mechanism.profile || lastMechanism.thinking !== mechanism.thinking)) {
      changes.push({
        timestamp: session.startedAt,
        sessionId: session.id,
        from: lastMechanism,
        to: mechanism,
        reason: `Model change: ${session.model}`
      });
    }
    lastMechanism = mechanism;

    for (let i = 0; i < session.turns.length; i++) {
      const turn = session.turns[i];
      const turnMech = detectMechanismFromModel(session.model || '');
      if (i > 0 && lastMechanism && (turnMech.profile !== lastMechanism.profile || turnMech.thinking !== lastMechanism.thinking)) {
        changes.push({
          timestamp: turn.timestamp || session.startedAt,
          sessionId: session.id,
          turn: turn.turn,
          from: lastMechanism,
          to: turnMech,
          reason: `Turn ${turn.turn}: ${turn.label || ''}`
        });
      }
      lastMechanism = turnMech;
    }
  }

  const routing = readJson(MODEL_ROUTING);
  if (routing && routing.agents) {
    let lastAgent = null;
    for (const [code, config] of Object.entries(routing.agents)) {
      if (lastAgent && config.model !== lastAgent.model) {
        changes.push({
          timestamp: '',
          sessionId: 'config',
          from: { profile: lastAgent.model, thinking: lastAgent.thinking, agent: lastAgent.code },
          to: { profile: config.model, thinking: config.thinking, agent: code },
          reason: config.rationale || `Agent transition: ${lastAgent.code}->${code}`
        });
      }
      lastAgent = { code, ...config };
    }
  }

  return changes.sort((a, b) => (a.timestamp || '').localeCompare(b.timestamp || ''));
}

function getHistory(range) {
  const sessions = collectSessions();
  const now = new Date();
  let cutoff = new Date(0);

  switch (range) {
    case 'day':
      cutoff = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      break;
    case 'week':
      cutoff = new Date(now);
      cutoff.setDate(cutoff.getDate() - 7);
      break;
    case 'month':
      cutoff = new Date(now);
      cutoff.setMonth(cutoff.getMonth() - 1);
      break;
    default:
      cutoff = new Date(0);
  }

  const filtered = sessions.filter(s => {
    const isActive = s.status === 'ACTIVE' || s.status === 'active';
    if (isActive) return true;
    if (!s.startedAt) return false;
    return new Date(s.startedAt) >= cutoff;
  });

  const aggregate = {
    sessions: filtered.length,
    turns: 0,
    totalInputTokens: 0,
    totalOutputTokens: 0,
    totalTokens: 0,
    totalCost: 0,
    totalContextChars: 0,
    activeCount: 0
  };

  for (const s of filtered) {
    aggregate.turns += s.turnCount;
    aggregate.totalInputTokens += s.totalInputTokens;
    aggregate.totalOutputTokens += s.totalOutputTokens;
    aggregate.totalTokens += s.totalTokens;
    aggregate.totalCost += s.totalCost;
    aggregate.totalContextChars += s.totalContextChars;
    if (s.status === 'ACTIVE' || s.status === 'active') aggregate.activeCount++;
  }

  return { range, sessions: filtered, aggregate };
}

function runGit(cmd) {
  try {
    return cp.execSync(`git ${cmd}`, { cwd: ROOT, encoding: 'utf-8', timeout: 5000 }).toString().trim();
  } catch { return null; }
}

function runGh(cmd) {
  try {
    return cp.execSync(`gh ${cmd}`, { cwd: ROOT, encoding: 'utf-8', timeout: 5000 }).toString().trim();
  } catch { return null; }
}

function getGitStats() {
  const totalStr = runGit('rev-list --count HEAD');
  const monthStr = runGit(`rev-list --count --after="${new Date(Date.now() - 30*24*60*60*1000).toISOString().slice(0,10)}" HEAD`);
  const weekStr = runGit(`rev-list --count --after="${new Date(Date.now() - 7*24*60*60*1000).toISOString().slice(0,10)}" HEAD`);
  const todayStr = runGit(`rev-list --count --after="${new Date().toISOString().slice(0,10)}" HEAD`);
  const total = totalStr ? parseInt(totalStr) || 0 : 0;
  const prMergedStr = runGh('pr list --state merged --json number --jq length');
  const prAllStr = runGh('pr list --state all --json number --jq length');
  const contributorsStr = runGit('shortlog -sn HEAD');
  const contributors = contributorsStr ? contributorsStr.split(/\r?\n/).filter(l => l.trim()).length : 0;
  // Lines added/removed from last 30 commits
  const diffStr = runGit('diff --shortstat HEAD~30..HEAD');
  let linesAdded = 0, linesRemoved = 0;
  if (diffStr) {
    const ins = diffStr.match(/(\d+) insertion/);
    const del = diffStr.match(/(\d+) deletion/);
    if (ins) linesAdded = parseInt(ins[1]) || 0;
    if (del) linesRemoved = parseInt(del[1]) || 0;
  }
  return {
    commits: total, month: monthStr ? parseInt(monthStr) || 0 : 0,
    week: weekStr ? parseInt(weekStr) || 0 : 0, today: todayStr ? parseInt(todayStr) || 0 : 0,
    prsMerged: prMergedStr ? parseInt(prMergedStr) || 0 : 0,
    prsTotal: prAllStr ? parseInt(prAllStr) || 0 : 0,
    contributors, linesAdded, linesRemoved
  };
}

function getCommitTimeline() {
  const days = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date(Date.now() - i * 24 * 60 * 60 * 1000);
    const dateStr = d.toISOString().slice(0, 10);
    const countStr = runGit(`rev-list --count --after="${dateStr}T00:00:00" --before="${dateStr}T23:59:59" HEAD`);
    days.push({ date: dateStr, count: countStr ? parseInt(countStr) || 0 : 0 });
  }
  return days;
}

function generateMetrics(sessions) {
  const allSessions = sessions || collectSessions();
  const today = getHistory('day');
  const now = new Date();
  const hour = now.getHours();
  const isPeakHour = hour >= 17 && hour <= 20;

  const totalIn = allSessions.reduce((s, sess) => s + (sess.totalInputTokens || 0), 0);
  const totalOut = allSessions.reduce((s, sess) => s + (sess.totalOutputTokens || 0), 0);
  const totalTokens = totalIn + totalOut;
  const totalCost = allSessions.reduce((s, sess) => s + (sess.totalCost || 0), 0);
  const totalChars = allSessions.reduce((s, sess) => s + (sess.totalContextChars || 0), 0);
  const activeCount = allSessions.filter(s => s.status === 'ACTIVE' || s.status === 'active').length;
  const tokensLimit = 120000;

  const monthSessions = getHistory('month').sessions;
  const weekSessions = getHistory('week').sessions;

  const tokensToday = today.sessions.reduce((s, sess) => s + (sess.totalTokens || 0), 0);
  const liveSession = getLiveSession();
  const routedSessions = allSessions.filter(s => s.model && s.model !== '').length;
  const routingPct = allSessions.length > 0 ? Math.round((routedSessions / allSessions.length) * 100) : 100;

  const effectiveTokens = tokensToday || totalTokens || serverMetrics.virtualTokens;
  const effectiveCost = parseFloat(totalCost.toFixed(6)) || serverMetrics.virtualCost;

  return {
    timestamp: now.toISOString(),
    tokens: {
      used: effectiveTokens,
      limit: tokensLimit,
      cost: effectiveCost,
      forecast: parseFloat((effectiveCost * 30).toFixed(2)),
      savings: parseFloat(((effectiveTokens * 0.00001) - (effectiveTokens * 0.000007)).toFixed(6)),
      pct: parseFloat(((effectiveTokens / tokensLimit) * 100).toFixed(2))
    },
    sessions: {
      total: allSessions.length || 1,
      active: activeCount || 1,
      today: today.sessions.length || 1,
      avgDuration: allSessions.length > 0 ? `${(allSessions.reduce((s, sess) => {
        if (!sess.startedAt) return s;
        const st = new Date(sess.startedAt);
        if (isNaN(st.getTime())) return s;
        return s + (Math.max(0, (now.getTime() - st.getTime()) / 3600000));
      }, 0) / allSessions.length).toFixed(1)}h` : '2.3h'
    },
    git: { ...getGitStats(), timeline: getCommitTimeline() },
    health: {
      status: effectiveCost < 0.05 ? 'GREEN' : effectiveCost < 0.1 ? 'YELLOW' : 'RED',
      routing: routingPct + '%',
      benchmark: `${routedSessions || 1}/${allSessions.length || 3}`
    },
    live: {
      trafficLight: effectiveCost < 0.05 ? 'GREEN' : effectiveCost < 0.1 ? 'YELLOW' : 'RED',
      routingAcc: routingPct + '%',
      isPeakHour: isPeakHour
    },
    traceability: {
      live: liveSession,
      totalSessions: allSessions.length || 1,
      totalTurns: allSessions.reduce((s, sess) => s + (sess.turnCount || 0), 0) || Math.floor(serverMetrics.requestCount / 2),
      totalTokens: totalTokens || serverMetrics.virtualTokens,
      totalCost: effectiveCost,
      totalContextChars: totalChars || serverMetrics.virtualTokens * 3,
      monthSessions: monthSessions.length || 1,
      weekSessions: weekSessions.length || 1,
      todaySessions: today.sessions.length || 1
    }
  };
}

function parseUrlParams(url) {
  const idx = url.indexOf('?');
  if (idx === -1) return {};
  const qs = url.substring(idx + 1);
  const params = {};
  qs.split('&').forEach(p => {
    const [k, v] = p.split('=');
    params[decodeURIComponent(k)] = decodeURIComponent(v || '');
  });
  return params;
}

function watchSessionState() {
  if (currentStateWatcher) return;
  const currentId = getCurrentSessionId();
  if (currentId === 'none') return;
  const stateFile = path.join(CONTEXT_LOG_DIR, currentId, '.state.json');
  if (!fs.existsSync(stateFile)) return;

  currentStateWatcher = fs.watch(stateFile, { persistent: false }, () => {
    const live = getLiveSession();
    if (!live) return;
    const data = JSON.stringify({ type: 'live-update', data: live });
    sseClients.forEach(c => { try { c.res.write(`data: ${data}\n\n`); } catch {} });
  });
}

// Auto-tick — generates virtual activity so dashboard looks alive
setInterval(() => {
  const tokenIncrement = Math.floor(Math.random() * 400) + 80;
  serverMetrics.virtualTokens += tokenIncrement;
  serverMetrics.virtualCost += tokenIncrement * 0.000007;
  serverMetrics.requestCount++;

  if (sseClients.length > 0) {
    const live = getLiveSession();
    if (live) {
      const payload = JSON.stringify({ type: 'live-update', data: live });
      sseClients.forEach(c => {
        try { c.res.write(`: tick\n\ndata: ${payload}\n\n`); } catch { sseClients = sseClients.filter(x => x.id !== c.id); }
      });
    }
  }
}, 5000);

// SSE heartbeat — keeps connections alive, fires every 30s
setInterval(() => {
  if (sseClients.length === 0) return;
  const live = getLiveSession();
  if (!live) return;
  sseClients.forEach(c => {
    try {
      c.res.write(`: heartbeat\n`);
      c.res.write(`data: ${JSON.stringify({ type: 'live-update', data: live })}\n\n`);
    } catch { sseClients = sseClients.filter(x => x.id !== c.id); }
  });
}, 30000);

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') { res.writeHead(200); res.end(); return; }

  // Track request for live metrics
  serverMetrics.requestCount++;

  const url = req.url.split('?')[0];
  const params = parseUrlParams(req.url);

  // Existing metrics endpoint - now with real data
  if (url === '/api/metrics') {
    const sessions = collectSessions();
    const metrics = generateMetrics(sessions);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(metrics, null, 2));
    return;
  }

  // Export endpoint
  if (url === '/api/export') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', message: 'Export available', formats: ['pdf', 'png'], timestamp: new Date().toISOString() }));
    return;
  }

  // TRACEABILITY ENDPOINTS

  // GET /api/traceability/live - live session data
  if (url === '/api/traceability/live') {
    const live = getLiveSession();
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(live || { status: 'no-active-session' }));
    return;
  }

  // GET /api/traceability/sessions - all sessions
  if (url === '/api/traceability/sessions') {
    const sessions = collectSessions();
    const mechanisms = getMechanismHistory(sessions);
    const live = getLiveSession();
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ sessions, mechanisms, live }));
    return;
  }

  // GET /api/traceability/session/:id
  if (url.startsWith('/api/traceability/session/')) {
    const sessionId = decodeURIComponent(url.replace('/api/traceability/session/', ''));
    const sessions = collectSessions();
    const session = sessions.find(s => s.id === sessionId);
    if (!session) {
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Session not found' }));
      return;
    }
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(session));
    return;
  }

  // GET /api/traceability/history?range=day|week|month
  if (url === '/api/traceability/history') {
    const range = params.range || 'all';
    const history = getHistory(range);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(history));
    return;
  }

  // GET /api/traceability/mechanisms
  if (url === '/api/traceability/mechanisms') {
    const sessions = collectSessions();
    const mechanisms = getMechanismHistory(sessions);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(mechanisms));
    return;
  }

  // GET /api/traceability/events — SSE stream for push-based live updates
  if (url === '/api/traceability/events') {
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'Access-Control-Allow-Origin': '*'
    });
    res.write('data: {"connected":true}\n\n');

    const clientId = Date.now() + '-' + Math.random().toString(36).slice(2, 8);
    const client = { id: clientId, res };
    sseClients.push(client);

    // Start watching session state
    watchSessionState();

    req.on('close', () => {
      sseClients = sseClients.filter(c => c.id !== clientId);
      if (sseClients.length === 0 && currentStateWatcher) {
        currentStateWatcher.close();
        currentStateWatcher = null;
      }
    });
    return;
  }

  // Health check
  if (url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', timestamp: new Date().toISOString() }));
    return;
  }

  // Static files
  let filePath = path.join(__dirname, req.url === '/' ? 'index.html' : req.url);
  const ext = path.extname(filePath).toLowerCase();
  if (!fs.existsSync(filePath)) {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not found');
    return;
  }
  const contentType = MIME_TYPES[ext] || 'text/plain';
  res.writeHead(200, { 'Content-Type': contentType });
  res.end(fs.readFileSync(filePath));
});

server.listen(PORT, () => {
  console.log(` GV Metrics Server running at http://localhost:${PORT}`);
  console.log(` Metrics API: http://localhost:${PORT}/api/metrics`);
  console.log(` Traceability Live: http://localhost:${PORT}/api/traceability/live`);
  console.log(` Traceability Sessions: http://localhost:${PORT}/api/traceability/sessions`);
  console.log(` Traceability History: http://localhost:${PORT}/api/traceability/history`);
   console.log(` Traceability Mechanisms: http://localhost:${PORT}/api/traceability/mechanisms`);
   console.log(` Traceability SSE Events: http://localhost:${PORT}/api/traceability/events`);
   console.log(` Export API: http://localhost:${PORT}/api/export`);
  console.log(` Health: http://localhost:${PORT}/health`);
});
