#!/usr/bin/env node

import { readFileSync, existsSync, readdirSync, writeFileSync, statSync } from 'fs';
import { join, resolve, basename } from 'path';
import { spawn, execSync } from 'child_process';
import { createConnection } from 'net';

const ROOT = resolve(process.cwd());
const RUNTIME_DIR = join(ROOT, '.runtime');
const SESSION_DIR = join(ROOT, '.session');

interface CheckResult {
  component: string;
  check: string;
  status: 'PASS' | 'WARN' | 'FAIL' | 'SKIP';
  detail: string;
  action: string;
  timestamp: string;
}

const results: CheckResult[] = [];
let quiet = false;
let exitCode = 0;

function addResult(
  component: string,
  check: string,
  status: CheckResult['status'],
  detail: string,
  action = 'ok',
  critical = false,
) {
  results.push({
    component,
    check,
    status,
    detail,
    action,
    timestamp: new Date().toISOString(),
  });
  if (!quiet || status !== 'PASS') {
    const icons: Record<string, string> = { PASS: '  ', WARN: '  ', FAIL: '  ', SKIP: '  ' };
    console.log(
      `${icons[status]}[${component}] ${check}: ${status}${detail ? ' - ' + detail : ''}`,
    );
  }
  if (status === 'FAIL' && critical) exitCode++;
}

function getFileAgeHours(filePath: string): number {
  try {
    const stats = statSync(filePath);
    return (Date.now() - stats.mtimeMs) / (1000 * 60 * 60);
  } catch {
    return -1;
  }
}

function testPort(port: number): Promise<boolean> {
  return new Promise((resolve) => {
    const sock = createConnection(port, '127.0.0.1', () => {
      sock.destroy();
      resolve(true);
    });
    sock.on('error', () => resolve(false));
    sock.setTimeout(3000);
    sock.on('timeout', () => {
      sock.destroy();
      resolve(false);
    });
  });
}

function testHttp(url: string): Promise<boolean> {
  return new Promise((resolve) => {
    const client = createConnection(parseInt(new URL(url).port, 10) || 8080, '127.0.0.1', () => {
      client.write(
        `GET ${new URL(url).pathname} HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n`,
      );
    });
    let data = '';
    client.on('data', (chunk: Buffer) => {
      data += chunk.toString();
    });
    client.on('end', () =>
      resolve(
        data.includes('200 OK') || data.includes('HTTP/1.1 200') || data.includes('HTTP/1.0 200'),
      ),
    );
    client.on('error', () => resolve(false));
    client.setTimeout(5000);
    client.on('timeout', () => {
      client.destroy();
      resolve(false);
    });
  });
}

function fileExists(p: string): boolean {
  return existsSync(p);
}

function readJson(p: string): any {
  return JSON.parse(readFileSync(p, 'utf-8'));
}

function payloadFileOk(
  component: string,
  label: string,
  filePath: string,
  onFailAction = 'manual',
  critical = false,
): boolean {
  if (!fileExists(filePath)) {
    addResult(component, label, 'WARN', 'Not found', onFailAction);
    return false;
  }
  if (filePath.endsWith('.json')) {
    try {
      readJson(filePath);
      addResult(component, label, 'PASS', '', 'ok');
      return true;
    } catch {
      addResult(component, label, 'FAIL', 'Invalid JSON', onFailAction, critical);
      return false;
    }
  } else {
    addResult(component, label, 'PASS', '', 'ok');
    return true;
  }
}

// ─── Component: Dashboard WS ────────────────────────────────────────────────

async function checkDashboardWs() {
  if (!quiet) console.log('  [Dashboard WS] Checking...');

  let wsPort = 8080;
  const portsFile = join(RUNTIME_DIR, 'dashboard-ports.json');
  if (fileExists(portsFile)) {
    try {
      const ports = readJson(portsFile);
      wsPort = ports.wsPort || 8080;
    } catch {
      addResult('dashboard-ws', 'ports.json', 'FAIL', 'Invalid JSON', 'verify');
    }
  }

  const httpOk = await testHttp(`http://127.0.0.1:${wsPort}/api/metrics`);
  const running = await testPort(wsPort);

  if (httpOk) {
    addResult('dashboard-ws', `HTTP API (port ${wsPort})`, 'PASS', 'Responding', 'ok');
  } else if (running) {
    addResult(
      'dashboard-ws',
      `HTTP API (port ${wsPort})`,
      'WARN',
      'Port open but HTTP not responding',
      'verify',
    );
  } else {
    addResult('dashboard-ws', `HTTP API (port ${wsPort})`, 'FAIL', 'Not responding', 'restart');
  }

  const wPidFile = join(RUNTIME_DIR, 'dashboard-ws-watchdog.pid');
  if (fileExists(wPidFile)) {
    const watchdogPid = readFileSync(wPidFile, 'utf-8').trim();
    try {
      process.kill(parseInt(watchdogPid, 10), 0);
      addResult('dashboard-ws', 'watchdog process', 'PASS', `PID ${watchdogPid} running`, 'ok');
    } catch {
      addResult(
        'dashboard-ws',
        'watchdog process',
        'FAIL',
        `PID ${watchdogPid} not running`,
        'restart',
      );
    }
  } else if (httpOk || running) {
    addResult('dashboard-ws', 'watchdog process', 'PASS', 'WS running standalone', 'ok');
  } else {
    addResult('dashboard-ws', 'watchdog process', 'WARN', 'WS down and no watchdog', 'start');
  }

  const pidFile = join(RUNTIME_DIR, 'dashboard-ws.pid');
  if (fileExists(pidFile)) {
    const wsPid = readFileSync(pidFile, 'utf-8').trim();
    try {
      process.kill(parseInt(wsPid, 10), 0);
      addResult('dashboard-ws', 'WS server process', 'PASS', `PID ${wsPid} running`, 'ok');
    } catch {
      addResult('dashboard-ws', 'WS server process', 'FAIL', `PID ${wsPid} not running`, 'restart');
    }
  } else {
    addResult('dashboard-ws', 'WS server process', 'WARN', 'No PID file', 'start');
  }

  addResult(
    'dashboard-ws',
    'build (dist/index.html)',
    fileExists(join(ROOT, 'apps/web-dashboard/dist/index.html')) ? 'PASS' : 'FAIL',
    '',
    'ok',
  );
}

// ─── Component: CodeGraph ───────────────────────────────────────────────────

async function checkCodeGraph() {
  if (!quiet) console.log('  [CodeGraph] Checking...');

  const cgDir = join(ROOT, '.codegraph');
  const indexOk = fileExists(join(cgDir, 'codegraph.db'));
  addResult('codegraph', 'index database', indexOk ? 'PASS' : 'FAIL', '', 'rebuild');

  addResult('codegraph', 'server process', 'PASS', 'Not running (MCP mode — expected)', 'verify');
}

// ─── Component: ML Embeddings ────────────────────────────────────────────────

async function checkMlEmbeddings() {
  if (!quiet) console.log('  [ML Embeddings] Checking...');

  const mlIndex = join(ROOT, '.atl/skill-embeddings.json');
  const mlDir = join(ROOT, '.atl/ml-embeddings');

  const ageH = getFileAgeHours(mlIndex);
  if (ageH === -1) {
    addResult('ml-embeddings', 'skill-embeddings.json', 'FAIL', 'Not found', 'rebuild');
  } else if (ageH > 48) {
    addResult(
      'ml-embeddings',
      'skill-embeddings.json freshness',
      'WARN',
      `Stale: ${ageH.toFixed(1)} hours`,
      'rebuild',
    );
  } else {
    addResult(
      'ml-embeddings',
      'skill-embeddings.json freshness',
      'PASS',
      `${ageH.toFixed(1)} hours`,
      'ok',
    );
  }

  if (fileExists(mlDir)) {
    const files = readdirSync(mlDir, { recursive: true }).filter((f) =>
      statSync(join(mlDir, f as string)).isFile(),
    );
    const fc = files.length;
    addResult(
      'ml-embeddings',
      'embedding files',
      fc > 0 ? 'PASS' : 'WARN',
      `${fc} files`,
      'rebuild',
    );
  } else {
    addResult('ml-embeddings', 'embedding directory', 'FAIL', 'Not found', 'rebuild');
  }

  const scripts = [
    'scripts/utilities/agents/AUTO-DELEGATION/skill-embedder.ps1',
    'scripts/utilities/agents/AUTO-DELEGATION/ml-router.ps1',
  ];
  for (const s of scripts) {
    const name = basename(s);
    addResult('ml-embeddings', name, fileExists(join(ROOT, s)) ? 'PASS' : 'FAIL', '', 'manual');
  }

  if (fileExists(mlIndex)) {
    try {
      const idx = readJson(mlIndex);
      const cnt = Object.keys(idx).length;
      addResult('ml-embeddings', 'index parseable', 'PASS', `${cnt} skills`, 'ok');
    } catch {
      addResult('ml-embeddings', 'index parseable', 'FAIL', 'Parse error', 'rebuild', true);
    }
  }
}

// ─── Component: Engram ───────────────────────────────────────────────────────

async function checkEngram() {
  if (!quiet) console.log('  [Engram] Checking...');

  const ragReindex = join(ROOT, 'scripts/utilities/memory/ENGRAM-RAG/engram-rag-reindex.ps1');
  addResult('engram', 'reindex script', fileExists(ragReindex) ? 'PASS' : 'FAIL', '', 'manual');

  const ragLog = join(ROOT, '.atl/rag-reindex.log');
  if (fileExists(ragLog)) {
    const logAge = getFileAgeHours(ragLog);
    addResult(
      'engram',
      'reindex freshness',
      logAge <= 48 ? 'PASS' : 'WARN',
      `${logAge.toFixed(1)} hours`,
      'reindex',
    );

    const content = readFileSync(ragLog, 'utf-8');
    const tailLines = content.trim().split('\n').slice(-3).join('\n');
    if (/error|fail|exception/i.test(tailLines)) {
      addResult('engram', 'reindex errors', 'WARN', 'Errors in last run', 'verify');
    }
  } else {
    addResult('engram', 'reindex log', 'WARN', 'Not found', 'reindex');
  }

  const userProfile = process.env.USERPROFILE || process.env.HOME || '';
  const engramDir = join(userProfile, '.engram');
  addResult('engram', 'engram directory', fileExists(engramDir) ? 'PASS' : 'FAIL', '', 'manual');

  const engramBin = join(
    userProfile,
    'bin',
    process.platform === 'win32' ? 'engram.exe' : 'engram',
  );
  const engramCmd = fileExists(engramBin) ? engramBin : 'engram';
  try {
    const output = execSync(`"${engramCmd}" doctor --json`, {
      encoding: 'utf-8',
      timeout: 10000,
      shell: process.env.COMSPEC || 'cmd.exe',
    });
    const ok = /"status"\s*:\s*"ok"/.test(output);
    addResult('engram', 'doctor', ok ? 'PASS' : 'WARN', `Healthy=${ok}`, 'verify');
  } catch (e: any) {
    const output = ((e.stdout || '') + (e.stderr || '')).toString();
    const ok = /"status"\s*:\s*"ok"/.test(output);
    addResult(
      'engram',
      'doctor',
      ok ? 'PASS' : 'FAIL',
      ok ? 'Healthy (stderr)' : 'Not accessible',
      ok ? 'verify' : 'manual',
      !ok,
    );
  }
}

// ─── Component: MCP ─────────────────────────────────────────────────────────

async function checkMcp() {
  if (!quiet) console.log('  [MCP] Checking...');

  payloadFileOk('mcp', 'skill-server.js', join(ROOT, 'dist/scripts/mcp/skill-server.js'), 'build');
  payloadFileOk('mcp', 'skill-server.ts', join(ROOT, 'scripts/mcp/skill-server.ts'), 'manual');
  payloadFileOk('mcp', 'mcp-bridge.ps1', join(ROOT, 'scripts/mcp-bridge/mcp-bridge.ps1'), 'manual');
  payloadFileOk(
    'mcp',
    'mcp-bridge.ts (dashboard)',
    join(ROOT, 'apps/web-dashboard/server/mcp-bridge.ts'),
    'manual',
  );

  const mcpConfigs = [
    'config/skill-mcp.json',
    'config/mcp-bridge.json',
    'config/mcp-config.sd.json',
  ];
  const found = mcpConfigs.filter((c) => fileExists(join(ROOT, c))).length;
  addResult(
    'mcp',
    'config files',
    found === mcpConfigs.length ? 'PASS' : 'WARN',
    `${found} of ${mcpConfigs.length}`,
    'verify',
  );

  const bridgePs1 = join(ROOT, 'scripts/mcp-bridge/mcp-bridge.ps1');
  if (fileExists(bridgePs1)) {
    try {
      const output = execSync(`pwsh -NoProfile -File "${bridgePs1}" -Action verify 2>&1`, {
        encoding: 'utf-8',
        timeout: 10000,
      });
      const healthOk = /OK|PASS|healthy|Bridge status: OK|^True$/.test(output);
      addResult('mcp', 'bridge health', healthOk ? 'PASS' : 'WARN', '', 'verify');
    } catch {
      addResult('mcp', 'bridge health', 'WARN', 'Not accessible', 'verify');
    }
  } else {
    addResult('mcp', 'bridge health', 'WARN', 'Script not found', 'verify');
  }

  payloadFileOk('mcp', 'mcp-registry.json', join(ROOT, 'config/mcp-registry.json'), 'config');
  payloadFileOk(
    'mcp',
    'mcp-manager.ps1',
    join(ROOT, 'scripts/utilities/MCP/mcp-manager.ps1'),
    'manual',
  );
  payloadFileOk(
    'mcp',
    'mcp-gateway.ps1',
    join(ROOT, 'scripts/utilities/MCP/mcp-gateway.ps1'),
    'manual',
  );
  payloadFileOk(
    'mcp',
    'mcp-gateway-api.ts (dashboard)',
    join(ROOT, 'apps/web-dashboard/server/mcp-gateway-api.ts'),
    'manual',
  );
  payloadFileOk('mcp', 'mcp-templates.json', join(ROOT, 'config/mcp-templates.json'), 'config');
}

// ─── Component: Session Pipeline ────────────────────────────────────────────

async function checkSessionPipeline() {
  if (!quiet) console.log('  [Session] Checking...');

  const scripts = [
    'scripts/utilities/session-start-optimized.ps1',
    'scripts/utilities/session-manager.ps1',
    'scripts/utilities/pre-process-input.ps1',
    'scripts/utilities/session/session-start-optimized.ps1',
    'scripts/utilities/session/session-cleanup-start.ps1',
  ];
  for (const s of scripts) {
    const name = basename(s);
    addResult('session', name, fileExists(join(ROOT, s)) ? 'PASS' : 'FAIL', '', 'manual');
  }

  addResult(
    'session',
    'autostart config',
    fileExists(join(ROOT, 'config/session-autostart.config.json')) ? 'PASS' : 'FAIL',
    '',
    'manual',
  );
}

// ─── Component: Git Hooks ───────────────────────────────────────────────────

async function checkHooks() {
  if (!quiet) console.log('  [Hooks] Checking...');

  addResult(
    'hooks',
    '.lefthook.yml',
    fileExists(join(ROOT, '.lefthook.yml')) ? 'PASS' : 'FAIL',
    '',
    'manual',
  );

  try {
    execSync('lefthook validate 2>&1', { encoding: 'utf-8', timeout: 10000 });
    addResult('hooks', 'lefthook validate', 'PASS', '', 'manual');
  } catch {
    addResult('hooks', 'lefthook validate', 'FAIL', 'Not installed or invalid', 'manual');
  }
}

// ─── Component: Configs ─────────────────────────────────────────────────────

async function checkConfigs() {
  if (!quiet) console.log('  [Configs] Checking...');

  const configs = [
    'config/orchestrator.json',
    'config/auto-delegation.json',
    'config/session-autostart.config.json',
    'config/security-policy.json',
    'config/trusted-users-policy.json',
    'config/security-privacy.json',
    'config/sre-error-budgets.json',
    'config/dashboard-alerts.json',
    'opencode.json',
    'renovate.json',
  ];
  for (const cfg of configs) {
    payloadFileOk('configs', cfg, join(ROOT, cfg), 'fix', true);
  }
}

// ─── Component: Tool Configs ────────────────────────────────────────────────

async function checkToolConfigs() {
  if (!quiet) console.log('  [Tool Configs] Checking...');

  const files = [
    'CLAUDE.md',
    'AGENTS.md',
    '.clinerules',
    '.cursorrules',
    'SECURITY.md',
    '.nvmrc',
    '.node-version',
  ];
  for (const f of files) {
    addResult('tool-configs', f, fileExists(join(ROOT, f)) ? 'PASS' : 'WARN', '', 'manual');
  }

  const windsurfCfg = join(ROOT, '.windsurf/config.json');
  if (fileExists(windsurfCfg)) {
    payloadFileOk('tool-configs', '.windsurf/config.json', windsurfCfg, 'fix');
  } else {
    addResult('tool-configs', '.windsurf/config.json', 'WARN', 'Not found', 'manual');
  }
}

// ─── Component: Security ────────────────────────────────────────────────────

async function checkSecurity() {
  if (!quiet) console.log('  [Security] Checking...');

  const secFiles = [
    'config/owner-auth.json.enc',
    'config/owner-auth.json.integrity',
    'scripts/security/privacy-gateway.ps1',
    'scripts/security/security-orchestrator.ps1',
    'SECURITY.md',
    '.github/CODEOWNERS',
    '.github/dependabot.yml',
  ];
  for (const f of secFiles) {
    addResult('security', f, fileExists(join(ROOT, f)) ? 'PASS' : 'WARN', '', 'manual');
  }
}

// ─── Component: Cloud Connectors ────────────────────────────────────────────

async function checkCloudConnectors() {
  if (!quiet) console.log('  [Cloud Connectors] Checking...');

  const cloudMetrics = join(SESSION_DIR, 'cloud-metrics.json');
  if (fileExists(cloudMetrics)) {
    try {
      const data = readJson(cloudMetrics);
      const execs = (data.executions || []).length;
      const successCount = (data.executions || []).filter((e: any) => e.success).length;
      const successRate = execs > 0 ? ((successCount / execs) * 100).toFixed(1) : '100';
      addResult(
        'cloud-connectors',
        'metrics file',
        'PASS',
        `${execs} executions, ${successRate}% success`,
        'ok',
      );
    } catch {
      addResult('cloud-connectors', 'metrics file', 'WARN', 'Corrupted', 'verify');
    }
  } else {
    addResult('cloud-connectors', 'metrics file', 'WARN', 'No cloud metrics yet', 'ok');
  }

  const hybridMetrics = join(SESSION_DIR, 'hybrid-metrics.json');
  if (fileExists(hybridMetrics)) {
    addResult(
      'cloud-connectors',
      'hybrid metrics',
      'PASS',
      'Hybrid routing history available',
      'ok',
    );
  } else {
    addResult('cloud-connectors', 'hybrid metrics', 'WARN', 'No hybrid routing yet', 'ok');
  }

  const delegators = ['aws-delegator.ps1', 'azure-delegator.ps1', 'hybrid-executor.ps1'];
  const missingCount = delegators.filter(
    (d) => !fileExists(join(ROOT, `scripts/utilities/ops/CLOUD-CONNECTORS/${d}`)),
  ).length;
  if (missingCount === 0) {
    addResult('cloud-connectors', 'delegator scripts', 'PASS', 'All 3 scripts present', 'ok');
  } else {
    addResult(
      'cloud-connectors',
      'delegator scripts',
      'FAIL',
      `Missing ${missingCount} delegator script(s)`,
      'verify',
    );
  }
}

// ─── Component: Tracing ──────────────────────────────────────────────────────

async function checkTracing() {
  if (!quiet) console.log('  [Tracing] Checking...');

  const telemetryDir = join(ROOT, '.telemetry');
  const tracesDir = join(telemetryDir, 'traces');
  const metricsDir = join(telemetryDir, 'metrics');

  if (fileExists(tracesDir)) {
    const traceFiles = readdirSync(tracesDir).filter((f) => f.endsWith('.jsonl')).length;
    addResult('tracing', 'trace files', 'PASS', `${traceFiles} trace file(s)`, 'ok');
  } else {
    addResult('tracing', 'trace files', 'WARN', 'No traces directory', 'ok');
  }

  if (fileExists(metricsDir)) {
    const promFile = join(metricsDir, 'prometheus-metrics.prom');
    if (fileExists(promFile)) {
      const age = getFileAgeHours(promFile);
      const status: CheckResult['status'] = age < 24 ? 'PASS' : age < 72 ? 'WARN' : 'FAIL';
      addResult(
        'tracing',
        'prometheus metrics',
        status,
        `last export ${age.toFixed(1)} hrs ago`,
        'ok',
      );
    } else {
      addResult('tracing', 'prometheus metrics', 'WARN', 'No prometheus export', 'ok');
    }
  } else {
    addResult('tracing', 'metrics directory', 'WARN', 'Not initialized', 'ok');
  }

  addResult(
    'tracing',
    'instrumentation script',
    fileExists(join(ROOT, 'scripts/utilities/ops/TRACING/tracing-instrument.ps1'))
      ? 'PASS'
      : 'FAIL',
    '',
    'verify',
  );
}

// ─── Component: State Persistence ────────────────────────────────────────────

async function checkStatePersistence() {
  if (!quiet) console.log('  [State Persistence] Checking...');

  const checkpointDir = join(SESSION_DIR, 'checkpoints');
  const manifestDir = join(SESSION_DIR, 'manifests');
  const snapshotDir = join(SESSION_DIR, 'snapshots');

  if (fileExists(checkpointDir)) {
    const ckpts = readdirSync(checkpointDir).filter((f) =>
      statSync(join(checkpointDir, f)).isDirectory(),
    ).length;
    addResult('state-persistence', 'checkpoints', 'PASS', `${ckpts} checkpoint(s)`, 'ok');
    const dirs = readdirSync(checkpointDir)
      .filter((f) => statSync(join(checkpointDir, f)).isDirectory())
      .map((f) => ({ name: f, mtime: statSync(join(checkpointDir, f)).mtimeMs }))
      .sort((a, b) => b.mtime - a.mtime);
    if (dirs.length > 0) {
      const latestAge = (Date.now() - dirs[0].mtime) / (1000 * 60 * 60);
      if (latestAge > 72) {
        addResult(
          'state-persistence',
          'latest checkpoint',
          'WARN',
          `${latestAge.toFixed(1)}hrs old`,
          'verify',
        );
      }
    }
  } else {
    addResult('state-persistence', 'checkpoints', 'WARN', 'No checkpoints directory', 'ok');
  }

  if (fileExists(manifestDir)) {
    const manifests = readdirSync(manifestDir).filter((f) => f.endsWith('.json')).length;
    addResult('state-persistence', 'manifests', 'PASS', `${manifests} manifest(s)`, 'ok');
  } else {
    addResult('state-persistence', 'manifests', 'WARN', 'No manifests', 'ok');
  }

  if (fileExists(snapshotDir)) {
    const snaps = readdirSync(snapshotDir).filter((f) => f.endsWith('.json')).length;
    addResult('state-persistence', 'snapshots', 'PASS', `${snaps} snapshot(s)`, 'ok');
  } else {
    addResult('state-persistence', 'snapshots', 'WARN', 'No snapshots', 'ok');
  }

  const ckptMgr = join(ROOT, 'scripts/utilities/ops/STATE-PERSISTENCE/checkpoint-manager.ps1');
  const rollbackOrch = join(
    ROOT,
    'scripts/utilities/ops/STATE-PERSISTENCE/rollback-orchestrator.ps1',
  );
  const snapMgr = join(ROOT, 'scripts/utilities/ops/STATE-PERSISTENCE/snapshot-manager.ps1');
  const allScripts = fileExists(ckptMgr) && fileExists(rollbackOrch) && fileExists(snapMgr);
  addResult(
    'state-persistence',
    'scripts',
    allScripts ? 'PASS' : 'FAIL',
    allScripts ? 'All 3 scripts present' : 'Missing scripts',
    'verify',
  );
}

// ─── Component: Audit Pipeline ───────────────────────────────────────────────

async function checkAuditPipeline() {
  if (!quiet) console.log('  [Audit Pipeline] Checking...');

  const auditDir = join(SESSION_DIR, 'audit');
  const logDir = join(auditDir, 'logs');
  const indexFile = join(auditDir, 'index.json');

  if (fileExists(logDir)) {
    const logFiles = readdirSync(logDir).filter((f) => f.endsWith('.jsonl'));
    let totalEvents = 0;
    for (const f of logFiles) {
      const content = readFileSync(join(logDir, f), 'utf-8').trim();
      if (content) totalEvents += content.split('\n').length;
    }
    addResult(
      'audit',
      'log files',
      'PASS',
      `${logFiles.length} file(s), ${totalEvents} events`,
      'ok',
    );
  } else {
    addResult('audit', 'log files', 'WARN', 'No audit logs yet', 'ok');
  }

  if (fileExists(indexFile)) {
    addResult('audit', 'index', 'PASS', 'Available', 'ok');
  } else {
    addResult('audit', 'index', 'WARN', 'No index', 'ok');
  }

  addResult(
    'audit',
    'pipeline script',
    fileExists(join(ROOT, 'scripts/security/audit-pipeline.ps1')) ? 'PASS' : 'FAIL',
    '',
    'verify',
  );

  const rbacPath = join(ROOT, 'config/rbac-policy.json');
  const cspPath = join(ROOT, 'config/security-csp.json');
  const secConfigs = fileExists(rbacPath) && fileExists(cspPath);
  addResult(
    'audit',
    'security configs',
    secConfigs ? 'PASS' : 'FAIL',
    secConfigs ? 'RBAC + CSP present' : 'Missing configs',
    'verify',
  );
}

// ─── Component: Governance ──────────────────────────────────────────────────

async function checkGovernance() {
  if (!quiet) console.log('  [Governance] Checking...');

  const govFiles = [
    'rules/NORMATIVAS-PERFORMANCE.md',
    'rules/SDD-STRICT-TDD.md',
    'rules/PER-PHASE-MODEL-ROUTING.md',
    'openspec/config.yaml',
    'rules/NORMATIVA-PNPM-SECURITY.md',
  ];
  for (const f of govFiles) {
    addResult('governance', f, fileExists(join(ROOT, f)) ? 'PASS' : 'WARN', '', 'manual');
  }

  // Pester check removed — all checks migrated to TypeScript, no PowerShell tests remain
}

// ─── Rebuild Actions ────────────────────────────────────────────────────────

async function rebuildMlEmbeddings() {
  if (!quiet) console.log('  [Rebuild] ML Embeddings...');
  const skillEmbedder = join(ROOT, 'scripts/utilities/agents/AUTO-DELEGATION/skill-embedder.ps1');
  if (fileExists(skillEmbedder)) {
    try {
      execSync(`pwsh -NoProfile -File "${skillEmbedder}" 2>&1`, {
        encoding: 'utf-8',
        timeout: 60000,
      });
      addResult('ml-embeddings', 'rebuild', 'PASS', 'Completed', 'ok');
    } catch (e: any) {
      addResult('ml-embeddings', 'rebuild', 'FAIL', `Error: ${e.message}`, 'manual', true);
    }
  } else {
    addResult('ml-embeddings', 'rebuild', 'SKIP', 'Not found', 'manual');
  }
}

async function reindexEngramRag() {
  if (!quiet) console.log('  [Rebuild] Engram RAG...');
  const ragReindex = join(ROOT, 'scripts/utilities/memory/ENGRAM-RAG/engram-rag-reindex.ps1');
  if (fileExists(ragReindex)) {
    try {
      execSync(`pwsh -NoProfile -File "${ragReindex}" 2>&1`, { encoding: 'utf-8', timeout: 60000 });
      addResult('engram', 'reindex', 'PASS', 'Completed', 'ok');
    } catch (e: any) {
      addResult('engram', 'reindex', 'FAIL', `Error: ${e.message}`, 'manual', true);
    }
  } else {
    addResult('engram', 'reindex', 'SKIP', 'Not found', 'manual');
  }
}

// ─── Auto-Heal ──────────────────────────────────────────────────────────────

async function autoHeal() {
  if (!quiet) console.log('\n  -- Auto-Heal Phase --');

  const needsRestart = results.filter((r) => r.action === 'restart' && r.status !== 'PASS');
  const needsStart = results.filter((r) => r.action === 'start' && r.status !== 'PASS');

  let healed = 0;
  let failed = 0;

  if (needsRestart.length === 0 && needsStart.length === 0) {
    if (!quiet) console.log('  No components need healing');
    return;
  }

  // Dashboard WS server restart
  const dashFail = [...needsRestart, ...needsStart].filter((r) => r.component === 'dashboard-ws');
  if (dashFail.length > 0) {
    let wsPort = 8080;
    const portsFile = join(RUNTIME_DIR, 'dashboard-ports.json');
    if (fileExists(portsFile)) {
      try {
        const ports = readJson(portsFile);
        wsPort = ports.wsPort || 8080;
      } catch {}
    }

    const wsRunning = await testPort(wsPort);
    const wsAutostart = join(ROOT, 'scripts/utilities/dashboard/dashboard-ws-autostart.ps1');

    if (wsRunning) {
      if (!quiet)
        console.log(`  [Heal] WS alive on port ${wsPort}, no action needed (watchdog optional)`);
      addResult('dashboard-ws', 'autoheal', 'PASS', 'WS alive, watchdog skipped', 'ok');
      healed++;
    } else if (fileExists(wsAutostart)) {
      if (!quiet) console.log('  [Heal] Restarting Dashboard WS server...');
      try {
        const child = spawn('pwsh', ['-NoProfile', '-File', wsAutostart, '-Quiet'], {
          cwd: ROOT,
          stdio: 'ignore',
          detached: true,
          windowsHide: true,
        });
        child.unref();
        await new Promise((resolve) => setTimeout(resolve, 5000));
        if (child.exitCode === null) {
          addResult('dashboard-ws', 'autoheal', 'PASS', `Restarted PID ${child.pid}`, 'ok');
          healed++;
        } else {
          addResult('dashboard-ws', 'autoheal', 'FAIL', 'Restart failed', 'manual', true);
          failed++;
        }
      } catch (e: any) {
        addResult('dashboard-ws', 'autoheal', 'FAIL', `Error: ${e.message}`, 'manual', true);
        failed++;
      }
    } else {
      if (!quiet) console.log('    dashboard-ws-autostart.ps1 not found');
      failed++;
    }
  }

  // CodeGraph server restart
  const cgFail = needsRestart.filter((r) => r.component === 'codegraph');
  if (cgFail.length > 0) {
    if (!quiet) console.log('  [Heal] Restarting CodeGraph serve...');
    try {
      const child = spawn('npx.cmd', ['codegraph', 'serve', '--mcp'], {
        cwd: ROOT,
        stdio: 'ignore',
        detached: true,
        windowsHide: true,
      });
      child.unref();
      await new Promise((resolve) => setTimeout(resolve, 3000));
      if (child.exitCode === null) {
        addResult('codegraph', 'autoheal', 'PASS', `Restarted PID ${child.pid}`, 'ok');
        healed++;
      } else {
        failed++;
      }
    } catch {
      failed++;
    }
  }

  if (!quiet) console.log(`  Healed: ${healed} | Failed: ${failed}`);
}

// ─── Summary ────────────────────────────────────────────────────────────────

function generateReport(outputPath?: string) {
  const pass = results.filter((r) => r.status === 'PASS').length;
  const warn = results.filter((r) => r.status === 'WARN').length;
  const fail = results.filter((r) => r.status === 'FAIL').length;
  const skip = results.filter((r) => r.status === 'SKIP').length;
  const total = results.length;

  const byComponentMap = new Map<
    string,
    { pass: number; warn: number; fail: number; skip: number }
  >();
  for (const r of results) {
    if (!byComponentMap.has(r.component))
      byComponentMap.set(r.component, { pass: 0, warn: 0, fail: 0, skip: 0 });
    const c = byComponentMap.get(r.component)!;
    c[r.status.toLowerCase() as keyof typeof c]++;
  }
  const byComponent = Array.from(byComponentMap.entries()).map(([name, counts]) => ({
    component: name,
    status: counts.fail > 0 ? 'ISSUES' : ('OK' as const),
    fails: counts.fail,
    pass: counts.pass,
    warn: counts.warn,
    skip: counts.skip,
  }));

  const report = {
    watchtowerVersion: '2.0.0',
    timestamp: new Date().toISOString(),
    summary: { pass, warn, fail, skip, total },
    byComponent,
    findings: results,
  };

  console.log(`\n=======================================`);
  console.log(`  PASS: ${pass} | WARN: ${warn} | FAIL: ${fail} | SKIP: ${skip} | Total: ${total}`);

  for (const c of byComponent) {
    const icon = c.status === 'OK' ? '  ' : '  ';
    console.log(`    ${icon}${c.component}: ${c.status}`);
  }

  if (outputPath) {
    writeFileSync(outputPath, JSON.stringify(report, null, 2), 'utf-8');
    console.log(`  Report: ${outputPath}`);
  }

  console.log(`=======================================`);

  return report;
}

// ─── Main ───────────────────────────────────────────────────────────────────

function parseArgs() {
  const args = process.argv.slice(2);
  const flags: Record<string, string | boolean | number> = {};

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '-Action' || args[i] === '--action') {
      flags.action = (args[++i] || 'health').toLowerCase();
    } else if (args[i] === '-Quiet' || args[i] === '--quiet') {
      flags.quiet = true;
    } else if (args[i] === '-OutputFile' || args[i] === '--output') {
      flags.output = args[++i];
    } else if (args[i] === '-Interval' || args[i] === '--interval') {
      flags.interval = parseInt(args[++i], 10) || 60;
    } else if (args[i] === '-Force' || args[i] === '--force') {
      flags.force = true;
    }
  }

  return {
    action: (flags.action as string) || 'health',
    quiet: !!flags.quiet,
    output: flags.output as string | undefined,
    interval: (flags.interval as number) || 60,
    force: !!flags.force,
  };
}

async function runAllChecks() {
  await checkDashboardWs();
  await checkCodeGraph();
  await checkMlEmbeddings();
  await checkEngram();
  await checkMcp();
  await checkSessionPipeline();
  await checkHooks();
  await checkConfigs();
  await checkToolConfigs();
  await checkSecurity();
  await checkCloudConnectors();
  await checkTracing();
  await checkStatePersistence();
  await checkAuditPipeline();
  await checkGovernance();
}

async function main() {
  const opts = parseArgs();
  quiet = opts.quiet;

  console.log(`===============================================`);
  console.log(` [MW] Maintenance Watchtower (v2.0.0)`);
  console.log(`    Action: ${opts.action} | Force: ${opts.force} | Interval: ${opts.interval}s`);
  console.log(`===============================================`);

  switch (opts.action) {
    case 'health':
      await runAllChecks();
      generateReport(opts.output);
      break;

    case 'rebuild':
      await runAllChecks();
      if (!quiet) console.log('\n  -- Auto-Rebuild Phase --');
      {
        const needsRebuild = results.filter(
          (r) => ['rebuild', 'reindex'].includes(r.action) && r.status !== 'PASS',
        );
        if (needsRebuild.length === 0 && !opts.force) {
          if (!quiet) console.log('  Everything fresh');
        } else {
          if (opts.force && !quiet) console.log('  Force rebuild');
          else if (!quiet) console.log(`  ${needsRebuild.length} component(s) need rebuild`);
          if (
            opts.force ||
            results.some(
              (r) =>
                r.component === 'ml-embeddings' && r.action === 'rebuild' && r.status !== 'PASS',
            )
          ) {
            await rebuildMlEmbeddings();
          }
          if (
            opts.force ||
            results.some(
              (r) => r.component === 'engram' && r.action === 'reindex' && r.status !== 'PASS',
            )
          ) {
            await reindexEngramRag();
          }
        }
      }
      generateReport(opts.output);
      break;

    case 'autoheal':
      await runAllChecks();
      await autoHeal();
      generateReport(opts.output);
      break;

    case 'all':
      await runAllChecks();
      await autoHeal();
      if (!quiet) console.log('\n  -- Rebuild Phase --');
      if (
        opts.force ||
        results.some(
          (r) => r.component === 'ml-embeddings' && r.action === 'rebuild' && r.status !== 'PASS',
        )
      ) {
        await rebuildMlEmbeddings();
      }
      if (
        opts.force ||
        results.some(
          (r) => r.component === 'engram' && r.action === 'reindex' && r.status !== 'PASS',
        )
      ) {
        await reindexEngramRag();
      }
      generateReport(opts.output);
      break;

    case 'continuous':
      if (!quiet) console.log(`Continuous mode: Interval=${opts.interval}s (Ctrl+C to stop)`);
      let cycle = 0;
      const loop = async () => {
        cycle++;
        if (!quiet) console.log(`\n=== Cycle ${cycle} (${new Date().toLocaleTimeString()}) ===`);
        results.length = 0;
        await runAllChecks();
        await autoHeal();
        generateReport();
        if (!quiet) console.log(`  Next cycle in ${opts.interval}s...`);
        setTimeout(loop, opts.interval * 1000);
      };
      loop();
      break;

    case 'report':
      await runAllChecks();
      generateReport(opts.output);
      break;

    default:
      console.error(`Unknown action: ${opts.action}`);
      process.exit(1);
  }

  if (opts.action !== 'continuous') {
    console.log(`===============================================`);
  }

  if (exitCode > 0) process.exit(Math.min(exitCode, 255));
}

main().catch((err) => {
  console.error('[FATAL]', err);
  process.exit(1);
});
