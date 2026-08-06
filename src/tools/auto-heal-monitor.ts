#!/usr/bin/env node
/**
 * auto-heal-monitor.ts — Automatic service healing monitor
 *
 * Monitors critical services and auto-heals when they fail:
 * - Dashboard WebSocket Server (port 8080)
 * - Dashboard Dev Server (port 5173) 
 * - MCP Server
 * - Database connections
 *
 * Usage:
 *   npx tsx src/tools/auto-heal-monitor.ts
 *   npx tsx src/tools/auto-heal-monitor.ts --daemon
 *   npx tsx src/tools/auto-heal-monitor.ts --status
 */

import { spawn, execSync } from 'child_process';
import { existsSync, readFileSync, writeFileSync, mkdirSync } from 'fs';
import { join, resolve } from 'path';
import { runSync } from '../core/run-command.js';

const ROOT = resolve(process.cwd());
const STATE_FILE = join(ROOT, '.runtime', 'auto-heal-state.json');
const LOG_FILE = join(ROOT, '.runtime', 'auto-heal.log');

interface ServiceHealth {
  name: string;
  port?: number;
  check: () => boolean;
  restart: () => boolean;
  cooldownMs: number;
  lastRestart?: number;
  restartCount: number;
}

interface HealState {
  services: Record<string, { restarts: number; lastRestart: string }>;
  lastRun: string;
}

function log(msg: string, level: 'info' | 'warn' | 'error' | 'success' = 'info'): void {
  const timestamp = new Date().toISOString();
  const prefix = { info: '[INFO]', warn: '[WARN]', error: '[ERR]', success: '[OK]' }[level];
  const line = `[${timestamp}] ${prefix} ${msg}`;
  console.log(line);
  
  // Append to log file
  try {
    const existing = existsSync(LOG_FILE) ? readFileSync(LOG_FILE, 'utf-8') : '';
    writeFileSync(LOG_FILE, existing + line + '\n');
  } catch {}
}

function loadState(): HealState {
  try {
    if (existsSync(STATE_FILE)) {
      return JSON.parse(readFileSync(STATE_FILE, 'utf-8'));
    }
  } catch {}
  return { services: {}, lastRun: new Date().toISOString() };
}

function saveState(state: HealState): void {
  try {
    mkdirSync(join(ROOT, '.runtime'), { recursive: true });
    writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
  } catch {}
}

// Service checks
function isPortListening(port: number): boolean {
  try {
    const result = runSync('netstat', ['-ano'], { timeout: 3000 });
    return result.stdout.includes(`:${port}`);
  } catch {
    return false;
  }
}

function isProcessRunning(name: string): boolean {
  try {
    const result = runSync('tasklist', ['/fi', `imagename eq ${name}`], { timeout: 3000 });
    return result.stdout.toLowerCase().includes(name.toLowerCase());
  } catch {
    return false;
  }
}

// Service definitions
const services: Map<string, ServiceHealth> = new Map([
  ['dashboard-ws', {
    name: 'Dashboard WebSocket',
    port: 8080,
    check: () => isPortListening(8080),
    restart: () => {
      try {
        // Kill existing process on port
        execSync('Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }', { shell: 'powershell' });
      } catch {}
      
      // Restart
      try {
        const proc = spawn('npx', ['tsx', 'src/dashboard-ws-autostart.ts'], {
          cwd: ROOT,
          detached: true,
          stdio: 'ignore',
          windowsHide: true,
        });
        proc.unref();
        
        // Wait for port
        for (let i = 0; i < 10; i++) {
          if (isPortListening(8080)) return true;
          setTimeout(() => {}, 1000);
        }
      } catch {}
      return false;
    },
    cooldownMs: 30000,
    restartCount: 0,
  }],
  ['dashboard-dev', {
    name: 'Dashboard Dev',
    port: 5173,
    check: () => isPortListening(5173),
    restart: () => {
      try {
        // Kill existing
        execSync('Get-NetTCPConnection -LocalPort 5173 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }', { shell: 'powershell' });
      } catch {}
      
      try {
        const proc = spawn('npm', ['run', 'dev'], {
          cwd: join(ROOT, 'apps', 'web-dashboard'),
          detached: true,
          stdio: 'ignore',
          windowsHide: true,
        });
        proc.unref();
        
        for (let i = 0; i < 15; i++) {
          if (isPortListening(5173)) return true;
          setTimeout(() => {}, 1000);
        }
      } catch {}
      return false;
    },
    cooldownMs: 30000,
    restartCount: 0,
  }],
  ['mcp-server', {
    name: 'MCP Server',
    check: () => existsSync(join(ROOT, 'dist', 'scripts', 'mcp', 'skill-server.js')),
    restart: () => {
      try {
        // Just verify it exists and compiles - MCP is spawned per-session
        execSync('npm run build:mcp', { cwd: ROOT, timeout: 30000 });
        return existsSync(join(ROOT, 'dist', 'scripts', 'mcp', 'skill-server.js'));
      } catch {
        return false;
      }
    },
    cooldownMs: 60000,
    restartCount: 0,
  }],
]);

async function healServices(): Promise<void> {
  const state = loadState();
  let healed = false;
  
  for (const [id, service] of services) {
    const healthy = service.check();
    
    if (!healthy) {
      log(`${service.name} is DOWN`, 'warn');
      
      // Check cooldown
      const serviceState = state.services[id] || { restarts: 0, lastRestart: '1970-01-01' };
      const lastRestart = new Date(serviceState.lastRestart).getTime();
      const now = Date.now();
      
      if (now - lastRestart < service.cooldownMs) {
        log(`${service.name} in cooldown (${Math.round((service.cooldownMs - (now - lastRestart)) / 1000)}s)`, 'info');
        continue;
      }
      
      // Check max restarts
      if (serviceState.restarts >= 5) {
        log(`${service.name} exceeded max restarts (5), manual intervention required`, 'error');
        continue;
      }
      
      log(`Attempting to restart ${service.name}...`, 'info');
      
      if (service.restart()) {
        log(`${service.name} restarted successfully`, 'success');
        serviceState.restarts++;
        serviceState.lastRestart = new Date().toISOString();
        state.services[id] = serviceState;
        healed = true;
      } else {
        log(`Failed to restart ${service.name}`, 'error');
      }
    } else {
      // Reset restart count on successful health check
      if (state.services[id]) {
        state.services[id].restarts = 0;
      }
    }
  }
  
  state.lastRun = new Date().toISOString();
  saveState(state);
  
  if (healed) {
    log('Heal cycle completed with restarts', 'success');
  } else {
    log('All services healthy', 'info');
  }
}

function printStatus(): void {
  const state = loadState();
  
  console.log('\n=== Auto-Heal Monitor Status ===\n');
  
  for (const [id, service] of services) {
    const healthy = service.check();
    const serviceState = state.services[id] || { restarts: 0, lastRestart: 'never' };
    
    console.log(`${healthy ? '✅' : '❌'} ${service.name}`);
    console.log(`   Port: ${service.port || 'N/A'}`);
    console.log(`   Restarts: ${serviceState.restarts}`);
    console.log(`   Last restart: ${serviceState.lastRestart}`);
    console.log();
  }
  
  console.log(`Last run: ${state.lastRun}`);
  console.log(`Log file: ${LOG_FILE}`);
}

async function daemonMode(): Promise<void> {
  log('Auto-Heal Monitor started in daemon mode', 'success');
  log('Monitoring every 30 seconds...', 'info');
  
  while (true) {
    await healServices();
    await new Promise(r => setTimeout(r, 30000)); // 30 second interval
  }
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  
  if (args.includes('--status')) {
    printStatus();
    return;
  }
  
  if (args.includes('--daemon')) {
    await daemonMode();
    return;
  }
  
  // Single run mode
  console.log('🔧 Gentle-Vanguard Auto-Heal Monitor\n');
  await healServices();
  printStatus();
}

main().catch(e => {
  console.error('Fatal error:', e);
  process.exit(1);
});
