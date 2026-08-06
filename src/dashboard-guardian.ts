#!/usr/bin/env node
/**
 * Dashboard Health Guardian
 * Monitorea y recupera el dashboard WebSocket automáticamente
 *
 * Usage: npx tsx src/dashboard-guardian.ts [--daemon]
 */

import { spawn } from 'child_process';
import { runSyncShell, runNpxTsxSync } from './core/run-command.js';
import { existsSync } from 'fs';
import { join } from 'path';

const ROOT = process.cwd();
const PORT = 8080;
const CHECK_INTERVAL = 10000; // 10 seconds
const MAX_RETRIES = 5;

function isDashboardRunning(): boolean {
  try {
    // Check HTTP endpoint
    const result = runSyncShell(
      `curl -s -o nul -w "%{http_code}" http://localhost:${PORT}/health`,
      {
        timeout: 3000,
        stdio: ['pipe', 'pipe', 'pipe'],
      },
    ).stdout;
    return result.trim() === '200';
  } catch {
    return false;
  }
}

function getPids(): { watchdog: number | null; ws: number | null } {
  try {
    const watchdogFile = join(ROOT, '.runtime', 'dashboard-ws-watchdog.pid');
    const wsFile = join(ROOT, '.runtime', 'dashboard-ws.pid');

    let watchdog: number | null = null;
    let ws: number | null = null;

    if (existsSync(watchdogFile)) {
      watchdog = parseInt(require('fs').readFileSync(watchdogFile, 'utf-8').trim());
    }
    if (existsSync(wsFile)) {
      ws = parseInt(require('fs').readFileSync(wsFile, 'utf-8').trim());
    }

    return { watchdog, ws };
  } catch {
    return { watchdog: null, ws: null };
  }
}

async function restartDashboard(): Promise<boolean> {
  console.log('[GUARDIAN] Dashboard unhealthy, restarting...');

  try {
    // Stop any existing processes
    try {
      runNpxTsxSync('src/dashboard-stop.ts', [], { timeout: 10000 });
    } catch {
      // Ignore errors
    }

    // Wait for processes to die
    await new Promise((r) => setTimeout(r, 2000));

    // Start new instance
    const child = spawn('npx', ['tsx', 'src/dashboard-ws-autostart.ts'], {
      detached: true,
      stdio: 'ignore',
      windowsHide: true,
    });

    child.unref();

    // Wait for startup
    await new Promise((r) => setTimeout(r, 5000));

    return isDashboardRunning();
  } catch (e) {
    console.error('[GUARDIAN] Restart failed:', e);
    return false;
  }
}

async function main() {
  const daemon = process.argv.includes('--daemon');

  console.log('[GUARDIAN] Dashboard Health Guardian');
  console.log(`[GUARDIAN] Monitoring port ${PORT} ${daemon ? '(daemon mode)' : ''}`);

  if (!daemon) {
    // Single check
    const healthy = isDashboardRunning();
    console.log(`[GUARDIAN] Dashboard status: ${healthy ? 'HEALTHY' : 'UNHEALTHY'}`);

    if (!healthy) {
      const success = await restartDashboard();
      console.log(`[GUARDIAN] Restart ${success ? 'succeeded' : 'failed'}`);
    }
    return;
  }

  // Daemon mode
  let consecutiveFailures = 0;

  while (consecutiveFailures < MAX_RETRIES) {
    const healthy = isDashboardRunning();
    const pids = getPids();

    if (!healthy) {
      console.log(
        `[GUARDIAN] ${new Date().toISOString()}: Unhealthy (PID: WS=${pids.ws}, WD=${pids.watchdog})`,
      );

      const success = await restartDashboard();
      if (!success) {
        consecutiveFailures++;
        console.log(`[GUARDIAN] Failure ${consecutiveFailures}/${MAX_RETRIES}`);
      } else {
        consecutiveFailures = 0;
        console.log('[GUARDIAN] Dashboard restored');
      }
    } else {
      if (consecutiveFailures > 0) {
        console.log('[GUARDIAN] Dashboard healthy again');
        consecutiveFailures = 0;
      }
    }

    await new Promise((r) => setTimeout(r, CHECK_INTERVAL));
  }

  console.error('[GUARDIAN] Max retries exceeded. Giving up.');
  process.exit(1);
}

if (import.meta.url === new URL(import.meta.url).href) {
  void main();
}

export { isDashboardRunning, restartDashboard };
