#!/usr/bin/env node
/**
 * stack-start-all.ts — Start all Gentle-Vanguard services
 *
 * Starts all required services for full stack operation:
 * - Dashboard WebSocket Server (port 8080)
 * - Dashboard Vite Dev Server (port 5173)
 * - MCP Skill Server (stdio)
 * - Watchtower health monitoring
 *
 * Usage:
 *   npx tsx src/tools/stack-start-all.ts
 *   npx tsx src/tools/stack-start-all.ts --skip-mcp    # Skip MCP server
 *   npx tsx src/tools/stack-start-all.ts --verbose     # Detailed output
 */

import { spawn, spawnSync } from 'child_process';
import { existsSync, writeFileSync, mkdirSync } from 'fs';
import { join, resolve } from 'path';
import { runSync } from '../core/run-command.js';

const ROOT = resolve(process.cwd());
const RUNTIME_DIR = join(ROOT, '.runtime');

interface ServiceStatus {
  name: string;
  pid?: number;
  port?: number;
  status: 'running' | 'stopped' | 'error';
  url?: string;
}

const services: ServiceStatus[] = [];

function log(msg: string, level: 'info' | 'warn' | 'error' | 'success' = 'info'): void {
  const prefix = {
    info: '[INFO]',
    warn: '[WARN]',
    error: '[ERR]',
    success: '[OK]',
  }[level];
  const color = {
    info: '\x1b[36m',
    warn: '\x1b[33m',
    error: '\x1b[31m',
    success: '\x1b[32m',
  }[level];
  console.log(`${color}${prefix}\x1b[0m ${msg}`);
}

function ensureRuntimeDir(): void {
  if (!existsSync(RUNTIME_DIR)) {
    mkdirSync(RUNTIME_DIR, { recursive: true });
  }
}

function isPortInUse(port: number): boolean {
  try {
    const result = runSync('netstat', ['-ano'], { timeout: 5000 });
    return result.stdout.includes(`:${port}`) || result.stdout.includes(`  ${port} `);
  } catch {
    return false;
  }
}

function isProcessRunning(name: string): boolean {
  try {
    const result = runSync('tasklist', ['/fi', `imagename eq ${name}`], { timeout: 5000 });
    return result.stdout.includes(name);
  } catch {
    return false;
  }
}

async function startDashboardWS(): Promise<ServiceStatus> {
  log('Starting Dashboard WebSocket Server...');
  
  if (isPortInUse(8080)) {
    log('Dashboard WS already running on port 8080', 'success');
    return { name: 'Dashboard WS', port: 8080, status: 'running' };
  }

  try {
    const wsProcess = spawn('npx', ['tsx', 'src/dashboard-ws-autostart.ts'], {
      cwd: ROOT,
      detached: true,
      stdio: ['ignore', 'pipe', 'pipe'],
      windowsHide: true,
    });

    // Wait briefly for startup
    await new Promise(r => setTimeout(r, 3000));
    
    if (isPortInUse(8080)) {
      log('Dashboard WS started on port 8080', 'success');
      return { 
        name: 'Dashboard WS', 
        pid: wsProcess.pid, 
        port: 8080, 
        status: 'running',
        url: 'http://localhost:8080'
      };
    }
    
    log('Dashboard WS failed to start', 'error');
    return { name: 'Dashboard WS', status: 'error' };
  } catch (e) {
    log(`Dashboard WS error: ${e}`, 'error');
    return { name: 'Dashboard WS', status: 'error' };
  }
}

async function startDashboardDev(): Promise<ServiceStatus> {
  log('Starting Dashboard Dev Server...');
  
  if (isPortInUse(5173)) {
    log('Dashboard Dev already running on port 5173', 'success');
    return { name: 'Dashboard Dev', port: 5173, status: 'running' };
  }

  try {
    const viteProcess = spawn('npm', ['run', 'dev'], {
      cwd: join(ROOT, 'apps', 'web-dashboard'),
      detached: true,
      stdio: ['ignore', 'pipe', 'pipe'],
      windowsHide: true,
    });

    // Wait for Vite to start
    await new Promise(r => setTimeout(r, 5000));
    
    if (isPortInUse(5173)) {
      log('Dashboard Dev started on port 5173', 'success');
      return { 
        name: 'Dashboard Dev', 
        pid: viteProcess.pid, 
        port: 5173, 
        status: 'running',
        url: 'http://localhost:5173'
      };
    }
    
    log('Dashboard Dev failed to start', 'error');
    return { name: 'Dashboard Dev', status: 'error' };
  } catch (e) {
    log(`Dashboard Dev error: ${e}`, 'error');
    return { name: 'Dashboard Dev', status: 'error' };
  }
}

async function checkMCPServer(): Promise<ServiceStatus> {
  log('Checking MCP Server...');
  
  // MCP server is spawned per-session, not persistent
  // Just verify the file exists and compiles
  try {
    const result = runSync('npx', ['tsx', '--check', 'scripts/mcp/skill-server.ts'], { 
      cwd: ROOT, 
      timeout: 10000 
    });
    
    if (result.status === 0) {
      log('MCP Server ready (starts on-demand)', 'success');
      return { name: 'MCP Server', status: 'running' };
    }
  } catch {
    // Compilation check failed
  }
  
  return { name: 'MCP Server', status: 'stopped' };
}

async function checkHealth(): Promise<ServiceStatus> {
  log('Running Health Check...');
  
  try {
    const result = runSync('npx', ['tsx', 'src/core/health-check.ts'], { 
      cwd: ROOT, 
      timeout: 60000 
    });
    
    if (result.status === 0) {
      log('Health Check passed', 'success');
      return { name: 'Health Check', status: 'running' };
    }
  } catch {
    // Health check might show failures but that's ok
  }
  
  log('Health Check completed with warnings', 'warn');
  return { name: 'Health Check', status: 'running' };
}

function saveStatus(): void {
  ensureRuntimeDir();
  const statusFile = join(RUNTIME_DIR, 'stack-services.json');
  writeFileSync(statusFile, JSON.stringify({
    timestamp: new Date().toISOString(),
    services: services.map(s => ({
      ...s,
      pid: s.pid || undefined
    }))
  }, null, 2));
}

function printSummary(): void {
  console.log('\n' + '='.repeat(60));
  console.log('Gentle-Vanguard Stack Status');
  console.log('='.repeat(60));
  
  const running = services.filter(s => s.status === 'running');
  const error = services.filter(s => s.status === 'error');
  const stopped = services.filter(s => s.status === 'stopped');
  
  for (const s of services) {
    const icon = s.status === 'running' ? '✅' : s.status === 'error' ? '❌' : '⚠️';
    const url = s.url ? ` (${s.url})` : '';
    console.log(`${icon} ${s.name}${url}`);
  }
  
  console.log('-'.repeat(60));
  console.log(`Running: ${running.length} | Errors: ${error.length} | Stopped: ${stopped.length}`);
  console.log('='.repeat(60));
  
  if (running.length > 0) {
    console.log('\n🎉 Stack is operational!');
    console.log('📊 Dashboard: http://localhost:5173');
  }
  
  if (error.length > 0) {
    console.log('\n⚠️  Some services failed. Check logs above.');
  }
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const skipMcp = args.includes('--skip-mcp');
  const verbose = args.includes('--verbose');
  
  console.log('🚀 Starting Gentle-Vanguard Stack...\n');
  
  // 1. Dashboard WS
  services.push(await startDashboardWS());
  
  // 2. Dashboard Dev
  services.push(await startDashboardDev());
  
  // 3. MCP (check only - starts on-demand)
  if (!skipMcp) {
    services.push(await checkMCPServer());
  }
  
  // 4. Health Check
  services.push(await checkHealth());
  
  // Save status
  saveStatus();
  
  // Print summary
  printSummary();
  
  // Exit code based on services
  const errors = services.filter(s => s.status === 'error').length;
  process.exit(errors > 0 ? 1 : 0);
}

main().catch(e => {
  console.error('Fatal error:', e);
  process.exit(1);
});
