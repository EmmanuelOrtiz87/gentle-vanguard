#!/usr/bin/env node

import * as fs from 'fs';
import * as path from 'path';
import { execSync, spawnSync } from 'child_process';
import * as net from 'net';

const ROOT = process.cwd();
let quiet = false;
let exitCode = 0;

function writeCheck(name: string, passed: boolean, detail?: string) {
  if (!quiet || !passed) {
    const icon = passed ? '\x1b[32m[PASS]\x1b[0m' : '\x1b[31m[FAIL]\x1b[0m';
    console.log(`${icon} ${name}`);
    if (detail) console.log(`       \x1b[90m${detail}\x1b[0m`);
  }
  if (!passed) exitCode++;
}

function header(title: string) {
  console.log(`\n\x1b[36m=== ${title} ===\x1b[0m`);
}

function exists(...parts: string[]) {
  return fs.existsSync(path.resolve(ROOT, ...parts));
}

function readJson(...parts: string[]) {
  return JSON.parse(fs.readFileSync(path.resolve(ROOT, ...parts), 'utf-8'));
}

async function tcpCheck(port: number, host = '127.0.0.1', timeoutMs = 2000): Promise<boolean> {
  return new Promise((resolve) => {
    const sock = new net.Socket();
    sock.setTimeout(timeoutMs);
    sock.on('connect', () => {
      sock.destroy();
      resolve(true);
    });
    sock.on('error', () => {
      sock.destroy();
      resolve(false);
    });
    sock.on('timeout', () => {
      sock.destroy();
      resolve(false);
    });
    sock.connect(port, host);
  });
}

// ---- 14 checks ----

function checkMCP() {
  header('MCP Server');
  const mcpJs = path.resolve(ROOT, 'dist/scripts/mcp/skill-server.js');
  const mcpTs = path.resolve(ROOT, 'scripts/mcp/skill-server.ts');

  writeCheck('MCP JS exists', fs.existsSync(mcpJs), 'dist/scripts/mcp/skill-server.js');
  writeCheck('MCP TS exists', fs.existsSync(mcpTs), 'scripts/mcp/skill-server.ts');
  if (!fs.existsSync(mcpJs)) return;

  try {
    const r = spawnSync('pnpm', ['tsc', '--noEmit'], { cwd: ROOT, stdio: 'pipe', timeout: 60000 });
    writeCheck('MCP TS compiles clean', r.status === 0);
  } catch {
    writeCheck('MCP TS compiles clean', false);
  }

  try {
    const input = JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'tools/list', params: {} });
    const r = spawnSync('node', [mcpJs], {
      input,
      stdio: ['pipe', 'pipe', 'pipe'],
      timeout: 10000,
      maxBuffer: 1024 * 1024,
    });
    const stdout = (r.stdout || '').toString();
    const stderr = (r.stderr || '').toString();
    const allOutput = stdout + '\n' + stderr;
    const lines = allOutput.split('\n').filter((l) => l.trim());
    let toolsCount = 0;
    for (const line of lines) {
      try {
        const parsed = JSON.parse(line);
        const tools = parsed.result?.tools || [];
        toolsCount = tools.length;
        if (toolsCount > 0) break;
      } catch {
        /* skip non-JSON lines */
      }
    }
    writeCheck('MCP tools/list responds', toolsCount > 0, `${toolsCount} tools`);
  } catch (e: any) {
    writeCheck('MCP tools/list responds', false, e.message);
  }
}

function checkTeamMode() {
  header('Team Mode');
  const script = path.resolve(ROOT, 'scripts/team-mode/team-orchestrator.ps1');
  writeCheck(
    'Team Mode script exists',
    fs.existsSync(script),
    'scripts/team-mode/team-orchestrator.ps1',
  );
  if (!fs.existsSync(script)) return;
  try {
    const r = spawnSync(
      'pwsh',
      ['-File', script, '-Task', 'health check', '-MaxParallel', '1', '-TimeoutSeconds', '5'],
      { cwd: ROOT, stdio: 'pipe', timeout: 15000 },
    );
    writeCheck('Team Mode dry-run passes', r.status === 0);
  } catch {
    writeCheck('Team Mode dry-run passes', false);
  }
}

function checkSessionRef() {
  header('Session Reference System');
  writeCheck(
    'Session Ref script exists',
    exists('scripts/utilities/session/session-reference-system.ps1'),
  );
}

function checkSkillFactory() {
  header('Skill Factory');
  writeCheck('Skill Factory exists', exists('scripts/utilities/skill-factory/skill-factory.ps1'));
  writeCheck('Skill registry exists', exists('.atl', 'skill-registry.md'));
  const regPath = path.resolve(ROOT, '.atl/skill-registry.md');
  if (fs.existsSync(regPath)) {
    const lines = fs.readFileSync(regPath, 'utf-8').split('\n').length;
    writeCheck('Registry has entries', lines > 5, `${lines} lines`);
  }
}

function checkSDD() {
  header('SDD Pipeline');
  const script = path.resolve(ROOT, 'scripts/sdd-pipeline/sdd-pipeline.ps1');
  writeCheck('SDD Pipeline exists', fs.existsSync(script));
  if (!fs.existsSync(script)) return;
  try {
    const r = spawnSync(
      'pwsh',
      ['-File', script, '-Feature', 'health-check', '-Description', 'Health check', '-DryRun'],
      { cwd: ROOT, stdio: 'pipe', timeout: 15000 },
    );
    writeCheck('SDD Pipeline dry-run passes', r.status === 0);
  } catch {
    writeCheck('SDD Pipeline dry-run passes', false);
  }
}

function checkPnpm() {
  header('pnpm Security');
  writeCheck('pnpm-lock.yaml exists', exists('pnpm-lock.yaml'));
  writeCheck('pnpm security normativa exists', exists('rules/NORMATIVA-PNPM-SECURITY.md'));
  try {
    const v = execSync('pnpm --version', { cwd: ROOT, stdio: 'pipe', timeout: 10000 })
      .toString()
      .trim();
    writeCheck('pnpm installed', true, `v${v}`);
  } catch {
    writeCheck('pnpm installed', false);
  }
}

function checkLefthook() {
  header('Lefthook Hooks');
  const candidates = ['.lefthook.yml', 'config/lefthook.yml'];
  let found = false;
  for (const f of candidates) {
    if (exists(f)) {
      writeCheck('lefthook config', true, f);
      found = true;
      break;
    }
  }
  if (!found) writeCheck('lefthook config', false);
}

function checkOptimizationStack() {
  header('Optimization Stack');
  const script = path.resolve(ROOT, 'scripts/validation/verify-optimization-stack.ps1');
  if (!fs.existsSync(script)) {
    writeCheck('verify-optimization-stack.ps1 exists', false);
    return;
  }
  try {
    const r = spawnSync('pwsh', ['-File', script, '-Quiet'], {
      cwd: ROOT,
      stdio: 'pipe',
      timeout: 15000,
    });
    writeCheck('Optimization stack (8 rules)', r.status === 0);
  } catch {
    writeCheck('Optimization stack (8 rules)', false);
  }
}

function checkGateGuard() {
  header('GateGuard');
  const script = path.resolve(ROOT, 'scripts/gateguard/gateguard-mcp.ps1');
  writeCheck(
    'GateGuard script exists',
    fs.existsSync(script),
    'scripts/gateguard/gateguard-mcp.ps1',
  );
  if (!fs.existsSync(script)) return;
  try {
    const r = spawnSync('pwsh', ['-File', script, '-Server', 'codegraph'], {
      cwd: ROOT,
      stdio: 'pipe',
      timeout: 15000,
    });
    const output = r.stdout.toString().trim();
    const jsonMatch = output.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      const detail = `server=${parsed.Status} latency=${parsed.LatencyMs}ms`;
      writeCheck('GateGuard responds', true, detail);
    } else {
      writeCheck('GateGuard responds', false, 'No JSON response found');
    }
  } catch (e: any) {
    writeCheck('GateGuard responds', false, e.message);
  }
}

function checkMlEmbeddings() {
  header('ML Embeddings (Auto-Delegation)');
  writeCheck('ml-index.json exists', exists('.atl', 'ml-index.json'), '.atl/ml-index.json');
  writeCheck(
    'skill-embedder.ps1 exists',
    exists('scripts/ml', 'skill-embedder.ps1'),
    'scripts/ml/skill-embedder.ps1',
  );
  writeCheck(
    'ml-router.ps1 exists',
    exists('scripts/ml', 'ml-router.ps1'),
    'scripts/ml/ml-router.ps1',
  );
  const mlIndex = path.resolve(ROOT, '.atl/ml-index.json');
  if (fs.existsSync(mlIndex)) {
    try {
      const data = readJson('.atl', 'ml-index.json');
      const cnt = Object.keys(data).length;
      writeCheck('ml-index parseable', true, `${cnt} skills indexed`);
    } catch {
      writeCheck('ml-index parseable', false);
    }
    const stat = fs.statSync(mlIndex);
    const ageHours = (Date.now() - stat.mtimeMs) / (1000 * 60 * 60);
    writeCheck('ml-index fresh (<48h)', ageHours <= 48, `${ageHours.toFixed(1)} hours old`);
  }
}

async function checkEngramRag() {
  header('Engram RAG Index');
  writeCheck(
    'engram-rag-reindex.ps1 exists',
    exists('scripts/utilities/memory/ENGRAM-RAG/engram-rag-reindex.ps1'),
  );
  try {
    const output = execSync('engram doctor --json', {
      cwd: ROOT,
      stdio: 'pipe',
      timeout: 15000,
    }).toString();
    const healthy = output.includes('"status":"ok"') || output.includes('"ok"');
    writeCheck('engram doctor', healthy);
  } catch {
    writeCheck('engram doctor', false, 'Not accessible');
  }
}

async function checkDashboardV3() {
  header('Dashboard v3');
  const dashboardDir = path.resolve(ROOT, 'apps/web-dashboard');
  writeCheck('apps/web-dashboard exists', fs.existsSync(dashboardDir));
  const portOpen = await tcpCheck(5173);
  writeCheck('dashboard dev server (port 5173)', portOpen);
}

function checkMcpBridge() {
  header('MCP Bridge');
  writeCheck(
    'mcp-bridge.ps1 exists',
    exists('scripts/mcp-bridge/mcp-bridge.ps1'),
    'scripts/mcp-bridge/mcp-bridge.ps1',
  );
  writeCheck(
    'tms-mcp-bridge.ps1 exists',
    exists('scripts/tms-mcp-bridge.ps1'),
    'scripts/tms-mcp-bridge.ps1',
  );
  const configs = ['config/skill-mcp.json', 'config/mcp-bridge.json'];
  const found = configs.filter((c) => exists(c)).length;
  writeCheck('MCP configs present', found === configs.length, `${found} of ${configs.length}`);
}

function checkCostTracking() {
  header('Cost Tracking');
  const configPath = path.resolve(ROOT, 'config/model-router.json');
  if (!fs.existsSync(configPath)) {
    writeCheck('model-router.json exists', false);
    return;
  }
  writeCheck('model-router.json exists', true);
  try {
    const config = readJson('config/model-router.json');
    writeCheck('costTracking section present', config.costTracking !== undefined);
    writeCheck(
      'routingPolicy section present',
      config.routingPolicy?.fastCheapToStrongReasoning !== undefined,
    );
  } catch (e: any) {
    writeCheck('costTracking section present', false, e.message);
    writeCheck('routingPolicy section present', false);
  }
}

// ---- dispatch map ----

const checkMap: Record<string, () => void | Promise<void>> = {
  mcp: checkMCP,
  team: checkTeamMode,
  session: checkSessionRef,
  factory: checkSkillFactory,
  sdd: checkSDD,
  pnpm: checkPnpm,
  lefthook: checkLefthook,
  optimization: checkOptimizationStack,
  gateguard: checkGateGuard,
  costtracking: checkCostTracking,
  ml: checkMlEmbeddings,
  rag: checkEngramRag,
  dashboard: checkDashboardV3,
  mcpbridge: checkMcpBridge,
};

// ---- main ----

async function main() {
  const args = process.argv.slice(2);
  let components: string[] = [];

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--quiet':
      case '-q':
        quiet = true;
        break;
      case '--component':
      case '-c':
        if (i + 1 < args.length) {
          components.push(...args[++i].split(',').map((s) => s.trim()));
        }
        break;
      default:
        if (!args[i].startsWith('-')) components.push(args[i]);
        break;
    }
  }

  if (components.length === 0 || components.includes('all')) {
    components = Object.keys(checkMap);
  }

  for (const comp of components) {
    const fn = checkMap[comp];
    if (fn) {
      const result = fn();
      if (result instanceof Promise) await result;
    } else {
      console.error(`\x1b[33mUnknown component: ${comp}\x1b[0m`);
      exitCode++;
    }
  }

  console.log(`\n\x1b[36m=== Health Check Complete ===\x1b[0m`);
  const ok = exitCode === 0;
  console.log(
    `${ok ? '\x1b[32m' : '\x1b[31m'}Status: ${ok ? 'ALL PASS' : `${exitCode} FAILURES`}\x1b[0m`,
  );
  process.exit(exitCode);
}

main().catch((e) => {
  console.error('\x1b[31mFATAL:\x1b[0m', e.message);
  process.exit(1);
});
