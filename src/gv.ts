#!/usr/bin/env node
/**
 * Gentle-Vanguard Unified CLI (gv.ts)
 * 
 * UNIFICA todas las herramientas en un solo comando:
 * - session: Gestión de sesiones (start, stop, status)
 * - dashboard: Control del dashboard (start, stop, restart, status)
 * - cleanup: Limpieza de procesos zombie
 * - fix: Reparación de referencias PS1
 * - health: Verificación de salud
 * - status: Estado completo del stack
 * 
 * Usage: npx tsx src/gv.ts <command> [options]
 */

import { run, runSync, runSyncShell, runNpxTsxSync } from './core/run-command.js';
import { existsSync, readFileSync, writeFileSync, unlinkSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';

const ROOT = process.cwd();
const RUNTIME_DIR = join(ROOT, '.runtime');
const SESSION_FILE = join(ROOT, '.session', '.active-session.json');

// Unified interface
interface CommandResult {
  success: boolean;
  message: string;
  data?: any;
}

// ============================================
// SESSION MANAGEMENT
// ============================================

function getSessionState(): { active: boolean; id?: string; lastActivity?: string; reason?: string } {
  try {
    if (!existsSync(SESSION_FILE)) {
      return { active: false, reason: 'No session state file' };
    }

    const state = JSON.parse(readFileSync(SESSION_FILE, 'utf-8'));
    const lastActivity = new Date(state.lastActivity).getTime();
    
    if (Date.now() - lastActivity > 30 * 60 * 1000) {
      return { active: false, reason: 'Session expired (>30min)' };
    }
    
    try {
      process.kill(state.pid, 0);
    } catch {
      return { active: false, reason: 'Process not running' };
    }
    
    return { active: true, id: state.id, lastActivity: state.lastActivity };
  } catch {
    return { active: false, reason: 'Invalid state' };
  }
}

function createSession(id: string): void {
  const sessionDir = dirname(SESSION_FILE);
  if (!existsSync(sessionDir)) {
    mkdirSync(sessionDir, { recursive: true });
  }
  
  const state = {
    id,
    pid: process.pid,
    startedAt: new Date().toISOString(),
    lastActivity: new Date().toISOString(),
  };
  writeFileSync(SESSION_FILE, JSON.stringify(state, null, 2));
}

function touchSession(): void {
  try {
    if (existsSync(SESSION_FILE)) {
      const state = JSON.parse(readFileSync(SESSION_FILE, 'utf-8'));
      state.lastActivity = new Date().toISOString();
      writeFileSync(SESSION_FILE, JSON.stringify(state, null, 2));
    }
  } catch {}
}

function cmdSession(args: string[]): CommandResult {
  const subcmd = args[0] || 'status';
  
  switch (subcmd) {
    case 'start': {
      const state = getSessionState();
      if (state.active) {
        touchSession();
        return { success: true, message: `Session ${state.id} already active (touched)` };
      }
      
      console.log('[GV] Cleaning zombie processes...');
      cmdCleanup([]);
      
      console.log('[GV] Starting session...');
      try {
        runSync('npm', ['run', 'session:autostart:detached'], { 
          cwd: ROOT,
          stdio: process.env.DEBUG ? 'inherit' : 'pipe'
        });
        createSession(`session-${Date.now()}`);
        return { success: true, message: 'Session started' };
      } catch (e) {
        return { success: false, message: `Failed to start: ${e}` };
      }
    }
    
    case 'stop': {
      try {
        cmdCleanup([]);
        if (existsSync(SESSION_FILE)) {
          unlinkSync(SESSION_FILE);
        }
        return { success: true, message: 'Session stopped' };
      } catch (e) {
        return { success: false, message: `Failed: ${e}` };
      }
    }
    
    case 'status':
    default: {
      const state = getSessionState();
      if (state.active) {
        return { success: true, message: `Session ${state.id} active since ${state.lastActivity}` };
      }
      return { success: false, message: `No active session: ${state.reason}` };
    }
  }
}

// ============================================
// DASHBOARD MANAGEMENT
// ============================================

function isDashboardRunning(): boolean {
  try {
    runSync('curl', ['-s', 'http://localhost:8080/health'], { 
      timeout: 2000,
      stdio: 'pipe'
    });
    return true;
  } catch {
    return false;
  }
}

function cmdDashboard(args: string[]): CommandResult {
  const subcmd = args[0] || 'status';
  
  switch (subcmd) {
    case 'start': {
      if (isDashboardRunning()) {
        return { success: true, message: 'Dashboard already running on http://localhost:5173' };
      }
      
      console.log('[GV] Cleaning zombie processes...');
      cmdCleanup([]);
      
      try {
        console.log('[GV] Starting dashboard...');
        const child = run('npx', ['tsx', 'src/dashboard-start.ts'], {
          detached: true,
          stdio: 'ignore',
          windowsHide: true,
          cwd: ROOT,
        });
        child.unref();
        
        // Wait for startup
        let attempts = 0;
        const maxAttempts = 10;
        const check = () => {
          if (isDashboardRunning() || attempts >= maxAttempts) {
            return;
          }
          attempts++;
          setTimeout(check, 1000);
        };
        check();
        
        return { success: true, message: 'Dashboard starting on http://localhost:5173' };
      } catch (e) {
        return { success: false, message: `Failed: ${e}` };
      }
    }
    
    case 'stop': {
      try {
        runNpxTsxSync('src/dashboard-stop.ts', [], { cwd: ROOT, stdio: 'pipe' });
        return { success: true, message: 'Dashboard stopped' };
      } catch (e) {
        return { success: false, message: `Failed: ${e}` };
      }
    }
    
    case 'restart': {
      cmdDashboard(['stop']);
      setTimeout(() => cmdDashboard(['start']), 2000);
      return { success: true, message: 'Dashboard restarting...' };
    }
    
    case 'status':
    default: {
      const running = isDashboardRunning();
      return { 
        success: running, 
        message: running 
          ? 'Dashboard running: http://localhost:5173 (WS: 8080)' 
          : 'Dashboard not running'
      };
    }
  }
}

// ============================================
// CLEANUP
// ============================================

function cmdCleanup(_args: string[]): CommandResult {
  let killed = 0;
  const ports = [8080, 5173, 3000];
  
  // Use native Windows netstat (NO PowerShell)
  for (const port of ports) {
    try {
      const output = runSyncShell(
        `netstat -ano | findstr :${port}`,
        {}
      ).stdout;
      
      const lines = output.split('\n').filter(line => line.includes('LISTENING'));
      
      for (const line of lines) {
        const parts = line.trim().split(/\s+/);
        const pid = parts[parts.length - 1];
        
        if (pid && !isNaN(parseInt(pid)) && parseInt(pid) !== process.pid) {
          try {
            runSyncShell(`taskkill /F /T /PID ${pid}`, { 
              stdio: 'pipe' 
            });
            console.log(`[GV] Killed PID ${pid} on port ${port}`);
            killed++;
          } catch {}
        }
      }
    } catch {}
  }
  
  // Clean stale files
  const files = [
    join(RUNTIME_DIR, 'dashboard-ws.pid'),
    join(RUNTIME_DIR, 'dashboard-ws-watchdog.pid'),
    join(RUNTIME_DIR, 'dashboard-vite.pid'),
  ];
  
  let cleaned = 0;
  for (const file of files) {
    try {
      if (existsSync(file)) {
        unlinkSync(file);
        cleaned++;
      }
    } catch {}
  }
  
  return { success: true, message: `Cleaned: ${killed} processes, ${cleaned} files` };
}

// ============================================
// HEALTH CHECK
// ============================================

function cmdHealth(_args: string[]): CommandResult {
  try {
    runSync('npm', ['run', 'watchtower:health'], { 
      cwd: ROOT,
      stdio: process.env.DEBUG ? 'inherit' : 'pipe'
    });
    return { success: true, message: 'Health check executed' };
  } catch {
    return { success: false, message: 'Health check failed' };
  }
}

// ============================================
// STATUS (Complete Stack Overview)
// ============================================

function cmdStatus(_args: string[]): CommandResult {
  const session = getSessionState();
  const dashboard = isDashboardRunning();
  
  const status = {
    timestamp: new Date().toISOString(),
    session: session.active ? 'active' : 'inactive',
    sessionId: session.id,
    dashboard: dashboard ? 'running' : 'stopped',
    dashboardUrl: dashboard ? 'http://localhost:5173' : null,
    wsApi: dashboard ? 'http://localhost:8080' : null,
  };
  
  console.log('╔════════════════════════════════════════════════════════╗');
  console.log('║         GENTLE-VANGUARD STACK STATUS                   ║');
  console.log('╠════════════════════════════════════════════════════════╣');
  console.log(`║  Session:    ${status.session.padEnd(38)} ║`);
  if (status.sessionId) {
    console.log(`║  Session ID: ${status.sessionId.padEnd(38)} ║`);
  }
  console.log(`║  Dashboard: ${status.dashboard.padEnd(38)} ║`);
  if (status.dashboardUrl) {
    console.log(`║  Web UI:     ${status.dashboardUrl.padEnd(38)} ║`);
    console.log(`║  WS API:     ${(status.wsApi ?? '').padEnd(38)} ║`);
  }
  console.log('╚════════════════════════════════════════════════════════╝');
  
  return { success: true, message: 'Status displayed', data: status };
}

// ============================================
// FIX PS1 REFERENCES
// ============================================

function cmdFix(args: string[]): CommandResult {
  const dryRun = args.includes('--dry-run');
  
  console.log(`[GV] Fixing PS1 references${dryRun ? ' (dry-run)' : ''}...`);
  
  try {
    const mode = args.includes('--configs') ? 'src/auto-ps1-fixer-configs.ts' : 'src/auto-ps1-fixer.ts';
    const cmd = dryRun ? `npx tsx ${mode} --dry-run` : `npx tsx ${mode}`;
    
    runSyncShell(cmd, { 
      cwd: ROOT,
      stdio: 'inherit'
    });
    
    return { success: true, message: 'Fix completed' };
  } catch (e) {
    return { success: false, message: `Fix failed: ${e}` };
  }
}

// ============================================
// HELP
// ============================================

function cmdHelp(): CommandResult {
  console.log(`
Gentle-Vanguard Unified CLI (gv.ts)

USAGE:
  npx tsx src/gv.ts <command> [options]

COMMANDS:
  session [start|stop|status]     Manage session lifecycle
  dashboard [start|stop|restart|status]  Control dashboard
  cleanup                         Kill zombie processes
  health                          Run health check
  status                          Show complete stack status
  fix [--configs] [--dry-run]      Fix PS1 references
  help                            Show this help

EXAMPLES:
  npx tsx src/gv.ts session start
  npx tsx src/gv.ts dashboard start
  npx tsx src/gv.ts status
  npx tsx src/gv.ts cleanup

OPTIMIZATIONS:
  ✅ Session reuse (saves 40K tokens)
  ✅ Zombie cleanup (prevents port conflicts)
  ✅ Unified interface (no duplicate scripts)
  ✅ Smart detection (only starts what's needed)
`);
  return { success: true, message: 'Help displayed' };
}

// ============================================
// MAIN
// ============================================

const command = process.argv[2] || 'status';
const args = process.argv.slice(3);

const commands: Record<string, (args: string[]) => CommandResult> = {
  session: cmdSession,
  dashboard: cmdDashboard,
  cleanup: cmdCleanup,
  health: cmdHealth,
  status: cmdStatus,
  fix: cmdFix,
  help: cmdHelp,
};

const handler = commands[command] || cmdStatus;
const result = handler(args);

process.exit(result.success ? 0 : 1);
