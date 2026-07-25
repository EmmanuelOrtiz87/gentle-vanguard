#!/usr/bin/env node

import * as fs from 'fs';
import * as path from 'path';
import { spawnSync } from 'child_process';
import * as net from 'net';
import { getEffectiveProcessTimeout, getExternalApiTimeouts } from './timeout-config';

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
    sock.on('connect', () => { sock.destroy(); resolve(true); });
    sock.on('error', () => { sock.destroy(); resolve(false); });
    sock.on('timeout', () => { sock.destroy(); resolve(false); });
    sock.connect(port, host);
  });
}

/** Try to run a TS script via npx tsx if it exists. */
function tryRunTs(tsPath: string, args: string[] = []): { status: number; stdout: string } {
  const fullPath = path.resolve(ROOT, tsPath);
  if (!fs.existsSync(fullPath)) {
    return { status: -1, stdout: '' };
  }
  try {
    const r = spawnSync('npx', ['tsx', tsPath, ...args], {
      cwd: ROOT,
      stdio: 'pipe',
      timeout: getEffectiveProcessTimeout('health_check'),
      shell: true,
    });
    return { status: r.status ?? -1, stdout: (r.stdout ?? '').toString() };
  } catch {
    return { status: -1, stdout: '' };
  }
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
    const r = spawnSync('pnpm', ['tsc', '--noEmit'], { cwd: ROOT, stdio: 'pipe', timeout: getEffectiveProcessTimeout('tsc') });
    writeCheck('MCP TS compiles clean', r.status === 0);
  } catch {
    writeCheck('MCP TS compiles clean', false);
  }
  try {
    const input = JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'tools/list', params: {} });
    const r = spawnSync('node', [mcpJs], { input, stdio: ['pipe', 'pipe', 'pipe'], timeout: getEffectiveProcessTimeout('default'), maxBuffer: 1024 * 1024 });
    const allOutput = ((r.stdout || '').toString()) + '\n' + ((r.stderr || '').toString());
    const lines = allOutput.split('\n').filter((l) => l.trim());
    let toolsCount = 0;
    for (const line of lines) {
      try { const parsed = JSON.parse(line); const tools = parsed.result?.tools || []; toolsCount = tools.length; if (toolsCount > 0) break; } catch { /* skip */ }
    }
    writeCheck('MCP tools/list responds', toolsCount > 0, `${toolsCount} tools`);
  } catch (e: unknown) {
    writeCheck('MCP tools/list responds', false, e instanceof Error ? e.message : String(e));
  }
}

function checkTeamMode() {
  header('Team Mode');
  // TS equivalent
  const tsScript = 'src/team-orchestrator.ts';
  writeCheck('Team Orchestrator (TS)', exists(tsScript), tsScript);
  if (exists(tsScript)) {
    const r = tryRunTs(tsScript, ['--task', 'health-check']);
    writeCheck('Team orchestrator responds', r.status === 0);
  }
}

function checkSessionRef() {
  header('Session Reference System');
  writeCheck('Session Ref (TS)', exists('src/session-reference-system.ts'), 'src/session-reference-system.ts');
}

function checkSkillFactory() {
  header('Skill Factory');
  writeCheck('Skill Factory (TS)', exists('src/skills/skill-factory.ts'), 'src/skills/skill-factory.ts');
  writeCheck('Skill registry exists', exists('.atl', 'skill-registry.md'));
  const regPath = path.resolve(ROOT, '.atl/skill-registry.md');
  if (fs.existsSync(regPath)) {
    const lines = fs.readFileSync(regPath, 'utf-8').split('\n').length;
    writeCheck('Registry has entries', lines > 5, `${lines} lines`);
  }
}

function checkSDD() {
  header('SDD Pipeline');
  writeCheck('SDD Pipeline (TS)', exists('src/sdd-pipeline.ts'), 'src/sdd-pipeline.ts');
}

function checkPnpm() {
  header('pnpm Security');
  writeCheck('pnpm-lock.yaml exists', exists('pnpm-lock.yaml'));
  writeCheck('pnpm security normativa exists', exists('rules/NORMATIVA-PNPM-SECURITY.md'));
  try {
    const r = spawnSync('pnpm', ['--version'], { cwd: ROOT, stdio: 'pipe', timeout: getEffectiveProcessTimeout('pnpm') });
    const v = (r.stdout?.toString() ?? '').trim();
    writeCheck('pnpm installed', r.status === 0, `v${v}`);
  } catch {
    writeCheck('pnpm installed', false);
  }
}

function checkLefthook() {
  header('Lefthook Hooks');
  const candidates = ['.lefthook.yml', 'config/lefthook.yml'];
  let found = false;
  for (const f of candidates) {
    if (exists(f)) { writeCheck('lefthook config', true, f); found = true; break; }
  }
  if (!found) writeCheck('lefthook config', false);
}

function checkOptimizationStack() {
  header('Optimization Stack');
  // No dedicated TS equivalent — check cross-workspace-validator as proxy
  writeCheck('Cross-workspace validator (TS)', exists('src/cross-workspace-validator.ts'), 'src/cross-workspace-validator.ts');
}

function checkGateGuard() {
  header('GateGuard');
  writeCheck('GateGuard (TS)', exists('src/gateguard-mcp.ts'), 'src/gateguard-mcp.ts');
  if (exists('src/gateguard-mcp.ts')) {
    const r = tryRunTs('src/gateguard-mcp.ts', ['--server', 'codegraph']);
    if (r.status === 0) {
      const output = r.stdout.trim();
      const jsonMatch = output.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        try {
          const parsed = JSON.parse(jsonMatch[0]);
          writeCheck('GateGuard responds', true, `server=${parsed.Status || parsed.status} latency=${parsed.LatencyMs || '?'}ms`);
        } catch {
          writeCheck('GateGuard responds', true, 'responded');
        }
      } else {
        writeCheck('GateGuard responds', true, 'responded');
      }
    } else {
      writeCheck('GateGuard responds', false, 'TS execution failed');
    }
  }
}

function checkMlEmbeddings() {
  header('ML Embeddings (Auto-Delegation)');
  // Check both ml-index.json and skill-embeddings.json
  const mlIndexPath = path.resolve(ROOT, '.atl/ml-index.json');
  const skillEmbeddingsPath = path.resolve(ROOT, '.atl/skill-embeddings.json');
  
  const hasMlIndex = fs.existsSync(mlIndexPath);
  const hasSkillEmbeddings = fs.existsSync(skillEmbeddingsPath);
  
  writeCheck('ml-index.json exists', hasMlIndex, '.atl/ml-index.json');
  writeCheck('skill-embeddings.json exists', hasSkillEmbeddings, '.atl/skill-embeddings.json');
  writeCheck('skill-embedder.ts exists', exists('src/skills/skill-embedder.ts'), 'src/skills/skill-embedder.ts');
  writeCheck('ml-router.ts exists', exists('src/ml-router.ts'), 'src/ml-router.ts');
  
  // Use skill-embeddings.json as primary source if available
  const primaryPath = hasSkillEmbeddings ? skillEmbeddingsPath : mlIndexPath;
  if (fs.existsSync(primaryPath)) {
    try { 
      const data = JSON.parse(fs.readFileSync(primaryPath, 'utf-8')); 
      const cnt = Object.keys(data).length; 
      writeCheck('embeddings parseable', true, `${cnt} skills indexed`); 
    } catch { 
      writeCheck('embeddings parseable', false); 
    }
    const stat = fs.statSync(primaryPath);
    const ageHours = (Date.now() - stat.mtimeMs) / (1000 * 60 * 60);
    writeCheck('embeddings fresh (<48h)', ageHours <= 48, `${ageHours.toFixed(1)} hours old`);
  }
}

async function checkEngramRag() {
  header('Engram RAG Index');
  writeCheck('engram-rag-reindex.ts exists', exists('src/engram-rag-reindex.ts'), 'src/engram-rag-reindex.ts');
  try {
    const r = spawnSync('engram', ['doctor', '--json'], { cwd: ROOT, stdio: 'pipe', timeout: getExternalApiTimeouts()?.engram_operation_ms ?? 15000 });
    const output = (r.stdout?.toString() ?? '') + (r.stderr?.toString() ?? '');
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
  writeCheck('mcp-bridge.ts exists', exists('src/mcp-bridge.ts'), 'src/mcp-bridge.ts');
  const configs = ['config/skill-mcp.json', 'config/mcp-bridge.json'];
  const found = configs.filter((c) => exists(c)).length;
  writeCheck('MCP configs present', found === configs.length, `${found} of ${configs.length}`);
}

function checkCostTracking() {
  header('Cost Tracking');
  const configPath = path.resolve(ROOT, 'config/model-router.json');
  if (!fs.existsSync(configPath)) { writeCheck('model-router.json exists', false); return; }
  writeCheck('model-router.json exists', true);
  try {
    const config = readJson('config/model-router.json');
    writeCheck('costTracking section present', config.costTracking !== undefined);
    writeCheck('routingPolicy section present', config.routingPolicy?.fastCheapToStrongReasoning !== undefined);
  } catch (e: unknown) {
    writeCheck('costTracking section present', false, e instanceof Error ? e.message : String(e));
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
      case '--quiet': case '-q': quiet = true; break;
      case '--component': case '-c':
        if (i + 1 < args.length) components.push(...args[++i].split(',').map((s) => s.trim()));
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
    if (fn) { const result = fn(); if (result instanceof Promise) await result; }
    else { console.error(`\x1b[33mUnknown component: ${comp}\x1b[0m`); exitCode++; }
  }

  console.log(`\n\x1b[36m=== Health Check Complete ===\x1b[0m`);
  const ok = exitCode === 0;
  console.log(`${ok ? '\x1b[32m' : '\x1b[31m'}Status: ${ok ? 'ALL PASS' : `${exitCode} FAILURES`}\x1b[0m`);
  process.exit(exitCode);
}

main().catch((e) => {
  console.error('\x1b[31mFATAL:\x1b[0m', e.message);
  process.exit(1);
});
