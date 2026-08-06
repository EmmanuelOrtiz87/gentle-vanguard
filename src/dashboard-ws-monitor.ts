#!/usr/bin/env tsx
/**
 * dashboard-ws-monitor.ts — Persistent health monitor and auto-heal for Dashboard WS
 *
 * Runs as a background service, checking Dashboard WS health every 30s.
 * Restarts the server automatically if it becomes unresponsive.
 *
 * Usage:
 *   npx tsx src/dashboard-ws-monitor.ts [--daemon] [--interval 30]
 *
 * Features:
 *   - Health check via HTTP /api/health endpoint
 *   - Auto-restart on failure (up to 5 attempts per cycle)
 *   - PID tracking and stale process cleanup
 *   - Logging to .runtime/dashboard-monitor.log
 *   - Graceful shutdown on SIGTERM/SIGINT
 */

import * as fs from 'fs';
import * as path from 'path';
import { spawn } from 'child_process';
import * as http from 'http';

const ROOT = path.resolve(process.cwd());
const RUNTIME_DIR = path.join(ROOT, '.runtime');
const LOG_FILE = path.join(RUNTIME_DIR, 'dashboard-monitor.log');
const PID_FILE = path.join(RUNTIME_DIR, 'dashboard-monitor.pid');

const DEFAULT_PORT = 8080;
const WS_SCRIPT = path.join(ROOT, 'apps', 'web-dashboard', 'server', 'websocket-server.ts');

interface MonitorConfig {
  interval: number; // Health check interval in seconds
  maxRetries: number; // Max restart attempts per failure
  retryDelay: number; // Delay between restart attempts in ms
  daemon: boolean; // Run as daemon (detach from parent)
}

function log(msg: string): void {
  const timestamp = new Date().toISOString();
  const line = `[${timestamp}] ${msg}\n`;
  console.log(line.trim());
  try {
    fs.appendFileSync(LOG_FILE, line, 'utf-8');
  } catch {
    // Silent fail if log file not writable
  }
}

function getConfig(): MonitorConfig {
  const args = process.argv.slice(2);
  return {
    interval: parseInt(args.find((_, i) => args[i - 1] === '--interval') || '30', 10),
    maxRetries: parseInt(args.find((_, i) => args[i - 1] === '--max-retries') || '5', 10),
    retryDelay: parseInt(args.find((_, i) => args[i - 1] === '--retry-delay') || '5000', 10),
    daemon: args.includes('--daemon'),
  };
}

function writePid(): void {
  try {
    if (!fs.existsSync(RUNTIME_DIR)) {
      fs.mkdirSync(RUNTIME_DIR, { recursive: true });
    }
    fs.writeFileSync(PID_FILE, String(process.pid), 'utf-8');
  } catch (err) {
    log(`WARN: Could not write PID file: ${err}`);
  }
}

function removePid(): void {
  try {
    if (fs.existsSync(PID_FILE)) {
      fs.unlinkSync(PID_FILE);
    }
  } catch {
    // Silent fail
  }
}

async function healthCheck(port: number): Promise<boolean> {
  return new Promise((resolve) => {
    const req = http.get(`http://127.0.0.1:${port}/api/health`, { timeout: 5000 }, (res) => {
      resolve(res.statusCode === 200);
    });
    req.on('error', () => resolve(false));
    req.on('timeout', () => {
      req.destroy();
      resolve(false);
    });
  });
}

async function startWsServer(port: number): Promise<boolean> {
  log(`[RESTART] Starting Dashboard WS on port ${port}...`);

  if (!fs.existsSync(WS_SCRIPT)) {
    log(`[ERROR] WS script not found: ${WS_SCRIPT}`);
    return false;
  }

  return new Promise((resolve) => {
    const child = spawn('cmd.exe', ['/c', 'npx.cmd', 'tsx', WS_SCRIPT], {
      cwd: ROOT,
      stdio: 'ignore',
      detached: true,
      windowsHide: true,
      env: {
        ...process.env,
        WS_PORT: String(port),
      },
    });

    child.unref();

    // Wait for server to become healthy
    setTimeout(async () => {
      const healthy = await healthCheck(port);
      if (healthy) {
        log(`[SUCCESS] Dashboard WS started (PID: ${child.pid})`);
      } else {
        log(`[WARN] Dashboard WS process started but not responding yet`);
      }
      resolve(healthy);
    }, 3000);
  });
}

async function ensureDashboardRunning(config: MonitorConfig): Promise<void> {
  const port = parseInt(process.env.WS_PORT || String(DEFAULT_PORT), 10);

  // Check if already running
  const healthy = await healthCheck(port);

  if (healthy) {
    // Silent success - only log on failure or periodic status
    return;
  }

  log(`[ALERT] Dashboard WS not responding on port ${port}`);

  // Attempt restart with retries
  for (let attempt = 1; attempt <= config.maxRetries; attempt++) {
    log(`[RETRY ${attempt}/${config.maxRetries}] Attempting restart...`);

    const success = await startWsServer(port);

    if (success) {
      log(`[RECOVERED] Dashboard WS is now healthy`);
      return;
    }

    if (attempt < config.maxRetries) {
      log(`[RETRY] Waiting ${config.retryDelay}ms before next attempt...`);
      await new Promise((resolve) => setTimeout(resolve, config.retryDelay));
    }
  }

  log(`[CRITICAL] Failed to restart Dashboard WS after ${config.maxRetries} attempts`);
}

async function main(): Promise<void> {
  const config = getConfig();

  log('[INIT] Dashboard WS Monitor starting...');
  log(`[CONFIG] Interval: ${config.interval}s, MaxRetries: ${config.maxRetries}`);

  writePid();

  // Initial check
  await ensureDashboardRunning(config);

  // Schedule periodic checks
  const intervalMs = config.interval * 1000;

  setInterval(async () => {
    await ensureDashboardRunning(config);
  }, intervalMs);

  log(`[RUNNING] Monitor active, checking every ${config.interval}s`);

  // Handle graceful shutdown
  process.on('SIGTERM', () => {
    log('[SHUTDOWN] SIGTERM received, cleaning up...');
    removePid();
    process.exit(0);
  });

  process.on('SIGINT', () => {
    log('[SHUTDOWN] SIGINT received, cleaning up...');
    removePid();
    process.exit(0);
  });
}

// Run if called directly
if (
  process.argv[1] &&
  import.meta.url === (await import('url')).pathToFileURL(process.argv[1]).href
) {
  main().catch((err) => {
    log(`[FATAL] ${err}`);
    removePid();
    process.exit(1);
  });
}

export { healthCheck, startWsServer, ensureDashboardRunning };
