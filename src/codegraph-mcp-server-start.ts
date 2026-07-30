#!/usr/bin/env node

/**
 * Start CodeGraph MCP Server
 * Inicia el servidor MCP de CodeGraph en background para disponibilidad inmediata
 */

import { spawn } from 'child_process';
import { existsSync, writeFileSync, readFileSync } from 'fs';
import { join } from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const PID_FILE = join(process.cwd(), '.runtime', 'codegraph-mcp-server.pid');

function log(message: string) {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${message}`);
}

function findCodeGraph(): string {
  // Try to find codegraph in common locations
  const isWindows = process.platform === 'win32';
  
  // Try which/where first
  try {
    const cmd = isWindows ? 'where codegraph' : 'which codegraph';
    const output = execSync(cmd, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
    const path = output.split('\n')[0].trim();
    if (existsSync(path)) {
      log(`[INFO] Found codegraph at: ${path}`);
      return path;
    }
  } catch {
    // Fallback to common paths
  }
  
  // Common installation paths
  const searchPaths = isWindows ? [
    join(process.env.USERPROFILE || '', 'go', 'bin', 'codegraph.exe'),
    join(process.env.USERPROFILE || '', 'bin', 'codegraph.exe'),
    join(process.env.LOCALAPPDATA || '', 'Microsoft', 'WindowsApps', 'codegraph.exe'),
    'C:\\Program Files\\codegraph\\codegraph.exe',
    'C:\\ProgramData\\chocolatey\\bin\\codegraph.exe',
    'codegraph', // fallback to PATH
  ] : [
    join(process.env.HOME || '', 'go', 'bin', 'codegraph'),
    join(process.env.HOME || '', '.local', 'bin', 'codegraph'),
    '/usr/local/bin/codegraph',
    '/usr/bin/codegraph',
    'codegraph', // fallback to PATH
  ];
  
  for (const path of searchPaths) {
    if (path === 'codegraph' || existsSync(path)) {
      return path;
    }
  }
  
  // Last resort: try PATH
  return 'codegraph';
}

function isServerRunning(): boolean {
  if (!existsSync(PID_FILE)) return false;
  
  try {
    const pid = parseInt(readFileSync(PID_FILE, 'utf-8').trim(), 10);
    if (isNaN(pid)) return false;
    
    // Check if process exists (Windows compatible)
    try {
      process.kill(pid, 0);
      return true;
    } catch {
      return false;
    }
  } catch {
    return false;
  }
}

function startCodeGraphServer(): Promise<void> {
  return new Promise((resolve, reject) => {
    if (isServerRunning()) {
      log('[OK] CodeGraph MCP server is already running');
      resolve();
      return;
    }

    log('[INFO] Starting CodeGraph MCP server...');
    
    const codegraphPath = findCodeGraph();
    log(`[INFO] Using codegraph: ${codegraphPath}`);
    
    // Spawn codegraph serve --mcp in detached mode
    const child = spawn(codegraphPath, ['serve', '--mcp'], {
      detached: true,
      stdio: ['ignore', 'pipe', 'pipe'],
      windowsHide: true,
      shell: true, // Use shell to resolve PATH
    });

    // Write PID file
    writeFileSync(PID_FILE, child.pid?.toString() || '');

    // Give it time to start
    setTimeout(() => {
      if (child.pid) {
        log(`[OK] CodeGraph MCP server started (PID: ${child.pid})`);
        // Unref so parent can exit
        child.unref();
        resolve();
      } else {
        reject(new Error('CodeGraph process did not start'));
      }
    }, 3000);

    // Handle errors after start
    child.on('error', (err) => {
      log(`[ERROR] Failed to start CodeGraph: ${err.message}`);
      // Don't reject here; we already resolved
    });

    child.stderr?.on('data', (data) => {
      const msg = data.toString().trim();
      if (msg) log(`[CodeGraph:err] ${msg}`);
    });

    child.stdout?.on('data', (data) => {
      const msg = data.toString().trim();
      if (msg) log(`[CodeGraph] ${msg}`);
    });
  });
}

async function main() {
  try {
    await startCodeGraphServer();
    process.exit(0);
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    log(`[FAIL] ${msg}`);
    process.exit(1);
  }
}

// Check if this is the main module
const __filename = fileURLToPath(import.meta.url);
const isMainModule = process.argv[1] && __filename === process.argv[1];

if (isMainModule) {
  void main();
}

export { startCodeGraphServer, isServerRunning, findCodeGraph };
