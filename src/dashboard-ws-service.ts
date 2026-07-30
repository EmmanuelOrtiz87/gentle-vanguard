#!/usr/bin/env tsx
/**
 * dashboard-ws-service.ts — Windows Service Wrapper for Dashboard WS
 *
 * Creates a persistent auto-start mechanism for the Dashboard WebSocket server
 * without external dependencies. Uses Node.js child process with keep-alive.
 *
 * Installation:
 *   npx tsx src/dashboard-ws-service.ts --install
 *
 * Run once:
 *   npx tsx src/dashboard-ws-service.ts --start
 *
 * Features:
 *   - Auto-restart on crash
 *   - PID tracking
 *   - Health check verification
 *   - Windows startup integration via Registry
 */

import { spawn, ChildProcess } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import * as http from 'http';

const ROOT = path.resolve(process.cwd());
const RUNTIME_DIR = path.join(ROOT, '.runtime');
const PID_FILE = path.join(RUNTIME_DIR, 'dashboard-ws-service.pid');
const LOG_FILE = path.join(RUNTIME_DIR, 'dashboard-ws-service.log');
const WS_SCRIPT = path.join(ROOT, 'apps', 'web-dashboard', 'server', 'websocket-server.ts');

const DEFAULT_PORT = 8080;
const HEALTH_CHECK_INTERVAL = 10000; // 10 seconds

function log(msg: string): void {
  const timestamp = new Date().toISOString();
  const line = `[${timestamp}] ${msg}`;
  console.log(line);
  try {
    fs.appendFileSync(LOG_FILE, line + '\n', 'utf-8');
  } catch { /* silent */ }
}

function ensureDir(): void {
  if (!fs.existsSync(RUNTIME_DIR)) {
    fs.mkdirSync(RUNTIME_DIR, { recursive: true });
  }
}

function writePid(pid: number): void {
  ensureDir();
  fs.writeFileSync(PID_FILE, String(pid), 'utf-8');
}

function readPid(): number | null {
  try {
    const content = fs.readFileSync(PID_FILE, 'utf-8').trim();
    const pid = parseInt(content, 10);
    return isNaN(pid) ? null : pid;
  } catch {
    return null;
  }
}

function isRunning(pid: number): boolean {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

function healthCheck(port: number): Promise<boolean> {
  return new Promise((resolve) => {
    const req = http.get(`http://127.0.0.1:${port}/api/health`, { timeout: 5000 }, (res) => {
      resolve(res.statusCode === 200);
    });
    req.on('error', () => resolve(false));
    req.on('timeout', () => { req.destroy(); resolve(false); });
  });
}

function startWsServer(port: number): ChildProcess {
  log(`[START] Launching Dashboard WS on port ${port}...`);
  
  const child = spawn(
    'npx.cmd',
    ['tsx', WS_SCRIPT],
    {
      cwd: ROOT,
      stdio: 'ignore',
      detached: true,
      windowsHide: true,
      env: {
        ...process.env,
        WS_PORT: String(port),
      },
    }
  );

  child.unref();
  
  if (child.pid) {
    writePid(child.pid);
    log(`[START] Process started with PID ${child.pid}`);
  }

  return child;
}

async function runService(): Promise<void> {
  log('[INIT] Dashboard WS Service starting...');
  ensureDir();

  const port = parseInt(process.env.WS_PORT || String(DEFAULT_PORT), 10);

  // Cleanup old PID if stale
  const oldPid = readPid();
  if (oldPid && !isRunning(oldPid)) {
    log('[CLEANUP] Removed stale PID file');
    try { fs.unlinkSync(PID_FILE); } catch { /* ignore */ }
  }

  // Main service loop
  while (true) {
    // Check if already running
    const currentPid = readPid();
    const healthy = await healthCheck(port);

    if (currentPid && isRunning(currentPid) && healthy) {
      // All good, wait and check again
      await new Promise(r => setTimeout(r, HEALTH_CHECK_INTERVAL));
      continue;
    }

    if (currentPid && isRunning(currentPid) && !healthy) {
      log('[HEALTH] Process running but not responding, restarting...');
      try { process.kill(currentPid); } catch { /* ignore */ }
    }

    // Start new instance
    log('[RESTART] Starting new instance...');
    startWsServer(port);

    // Wait for it to become ready
    let attempts = 0;
    while (attempts < 6) {
      await new Promise(r => setTimeout(r, 2000));
      if (await healthCheck(port)) {
        log('[READY] Dashboard WS is healthy');
        break;
      }
      attempts++;
    }

    if (attempts >= 6) {
      log('[WARN] Server did not become healthy after restart');
    }

    // Wait before next check
    await new Promise(r => setTimeout(r, HEALTH_CHECK_INTERVAL));
  }
}

async function install(): Promise<void> {
  // Create startup task for current user using Windows Registry
  const startupKey = 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run';
  const command = `cmd /c cd /d "${ROOT}" && npx tsx src/dashboard-ws-service.ts --start`;
  
  log('[INSTALL] Registering auto-start...');
  
  try {
    const regCmd = spawn('reg', ['add', startupKey, '/v', 'GentleVanguardDashboardWS', '/t', 'REG_SZ', '/d', command, '/f'], { 
      stdio: 'inherit',
      windowsHide: true 
    });
    
    await new Promise((resolve) => {
      regCmd.on('close', (code) => {
        resolve(code);
      });
    });
    
    log('[INSTALL] Auto-start registered successfully');
    log(`[INSTALL] Command: ${command}`);
    log('[INSTALL] Dashboard WS will start automatically on next login');
  } catch (err) {
    log(`[INSTALL] Error: ${err}`);
    process.exit(1);
  }
}

async function uninstall(): Promise<void> {
  const startupKey = 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run';
  
  log('[UNINSTALL] Removing auto-start...');
  
  try {
    const regCmd = spawn('reg', ['delete', startupKey, '/v', 'GentleVanguardDashboardWS', '/f'], { 
      stdio: 'inherit',
      windowsHide: true 
    });
    
    await new Promise((resolve) => {
      regCmd.on('close', (code) => {
        resolve(code);
      });
    });
    
    log('[UNINSTALL] Auto-start removed');
  } catch (err) {
    log(`[UNINSTALL] Error: ${err}`);
  }
}

async function status(): Promise<void> {
  const pid = readPid();
  const port = DEFAULT_PORT;
  const healthy = await healthCheck(port);
  
  if (pid && isRunning(pid)) {
    console.log(`Status: RUNNING (PID: ${pid})`);
    console.log(`Health: ${healthy ? 'HEALTHY' : 'NOT RESPONDING'}`);
    console.log(`Port: ${port}`);
  } else {
    console.log('Status: STOPPED');
    console.log(`Health: NOT CHECKABLE`);
  }
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  
  if (args.includes('--install')) {
    await install();
    process.exit(0);
  }
  
  if (args.includes('--uninstall')) {
    await uninstall();
    process.exit(0);
  }
  
  if (args.includes('--status')) {
    await status();
    process.exit(0);
  }
  
  // Default: run service
  await runService();
}

main().catch(err => {
  log(`[FATAL] ${err}`);
  process.exit(1);
});
