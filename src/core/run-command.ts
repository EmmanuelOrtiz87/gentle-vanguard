#!/usr/bin/env node
/**
 * run-command.ts — Centralized command execution wrapper.
 *
 * Ensures ALL child processes in the stack:
 * 1. Use `windowsHide: true` (no flashing cmd windows on Windows)
 * 2. Use direct argv arrays instead of shell strings (no cmd.exe wrapping)
 * 3. Have consistent timeout handling
 * 4. Have consistent stdio configuration
 *
 * Usage:
 *   import { run, runSync } from './core/run-command.js';
 *
 *   // Async spawn (non-blocking)
 *   const child = run('npx', ['tsx', 'script.ts', '--arg'], { cwd: '/path' });
 *
 *   // Sync spawn (blocking)
 *   const result = runSync('npx', ['tsx', 'script.ts', '--arg']);
 *   console.log(result.stdout, result.stderr, result.status);
 *
 *   // Shell fallback (when you MUST use shell)
 *   const result = runSyncShell('npx tsx script.ts --arg');
 */

import { spawn, spawnSync, type SpawnOptions, type SpawnSyncOptions, type ChildProcess } from 'child_process';

// ─── Types ────────────────────────────────────────────────────────────

export interface RunSyncResult {
  stdout: string;
  stderr: string;
  status: number | null;
  error: Error | null;
  signal: string | null;
}

export interface RunOptions {
  cwd?: string;
  timeout?: number;
  env?: Record<string, string | undefined>;
  stdio?: SpawnOptions['stdio'];
  maxBuffer?: number;
}

// ─── Defaults ─────────────────────────────────────────────────────────

const DEFAULT_OPTIONS: SpawnOptions = {
  windowsHide: true,     // CRITICAL: no flashing cmd windows on Windows
  stdio: 'pipe',         // capture output by default
};

const DEFAULT_SYNC_OPTIONS: SpawnSyncOptions = {
  windowsHide: true,     // CRITICAL: no flashing cmd windows on Windows
  stdio: 'pipe',         // capture output by default
  encoding: 'utf-8' as const,
  maxBuffer: 1024 * 1024, // 1MB default
};

// ─── Async spawn ──────────────────────────────────────────────────────

/**
 * Spawn a child process with windowsHide:true enforced.
 * Use direct argv array — no shell wrapping.
 *
 * @param command - The command to run (e.g. 'npx', 'node', 'git')
 * @param args - Array of arguments (e.g. ['tsx', 'script.ts'])
 * @param options - Optional spawn options
 * @returns ChildProcess instance
 */
export function run(
  command: string,
  args: string[] = [],
  options: RunOptions = {},
): ChildProcess {
  const spawnOpts: SpawnOptions = {
    ...DEFAULT_OPTIONS,
    cwd: options.cwd ?? process.cwd(),
    timeout: options.timeout,
    env: options.env ? { ...process.env, ...options.env } : undefined,
    stdio: options.stdio ?? 'pipe',
  };

  return spawn(command, args, spawnOpts);
}

// ─── Sync spawn ───────────────────────────────────────────────────────

/**
 * Spawn a child process synchronously with windowsHide:true enforced.
 * Use direct argv array — no shell wrapping.
 *
 * @param command - The command to run (e.g. 'npx', 'node', 'git')
 * @param args - Array of arguments (e.g. ['tsx', 'script.ts'])
 * @param options - Optional spawn options
 * @returns RunSyncResult with stdout, stderr, status, error
 */
export function runSync(
  command: string,
  args: string[] = [],
  options: RunOptions = {},
): RunSyncResult {
  const spawnOpts: SpawnSyncOptions = {
    ...DEFAULT_SYNC_OPTIONS,
    cwd: options.cwd ?? process.cwd(),
    timeout: options.timeout,
    env: options.env ? { ...process.env, ...options.env } : undefined,
    stdio: options.stdio ?? 'pipe',
    maxBuffer: options.maxBuffer ?? 1024 * 1024,
  };

  try {
    const result = spawnSync(command, args, spawnOpts);
    return {
      stdout: (result.stdout ?? '') as string,
      stderr: (result.stderr ?? '') as string,
      status: result.status,
      error: result.error ?? null,
      signal: result.signal,
    };
  } catch (err) {
    return {
      stdout: '',
      stderr: '',
      status: null,
      error: err instanceof Error ? err : new Error(String(err)),
      signal: null,
    };
  }
}

// ─── Shell fallback (only when necessary) ─────────────────────────────

/**
 * Run a command via shell with windowsHide:true.
 * USE ONLY when you need shell features (pipes, globs, redirects).
 * Prefer run()/runSync() with direct argv arrays.
 */
export function runSyncShell(
  command: string,
  options: RunOptions = {},
): RunSyncResult {
  const isWindows = process.platform === 'win32';
  const shellCmd = isWindows ? process.env.ComSpec || 'cmd.exe' : '/bin/sh';
  const shellArgs = isWindows ? ['/d', '/s', '/c', command] : ['-c', command];

  const spawnOpts: SpawnSyncOptions = {
    ...DEFAULT_SYNC_OPTIONS,
    cwd: options.cwd ?? process.cwd(),
    timeout: options.timeout,
    env: options.env ? { ...process.env, ...options.env } : undefined,
    stdio: options.stdio ?? 'pipe',
    maxBuffer: options.maxBuffer ?? 1024 * 1024,
    windowsHide: true,
  };

  try {
    const result = spawnSync(shellCmd, shellArgs, spawnOpts);
    return {
      stdout: (result.stdout ?? '') as string,
      stderr: (result.stderr ?? '') as string,
      status: result.status,
      error: result.error ?? null,
      signal: result.signal,
    };
  } catch (err) {
    return {
      stdout: '',
      stderr: '',
      status: null,
      error: err instanceof Error ? err : new Error(String(err)),
      signal: null,
    };
  }
}

// ─── Windows-specific: npx wrapper ────────────────────────────────────

/**
 * Run npx with tsx (the most common pattern in the stack).
 * Automatically handles npx.cmd vs npx on Windows.
 */
export function runNpxTsx(
  script: string,
  scriptArgs: string[] = [],
  options: RunOptions = {},
): ChildProcess {
  const isWindows = process.platform === 'win32';
  const npxCmd = isWindows ? 'npx.cmd' : 'npx';
  return run(npxCmd, ['tsx', script, ...scriptArgs], options);
}

/**
 * Run npx with tsx synchronously.
 */
export function runNpxTsxSync(
  script: string,
  scriptArgs: string[] = [],
  options: RunOptions = {},
): RunSyncResult {
  const isWindows = process.platform === 'win32';
  const npxCmd = isWindows ? 'npx.cmd' : 'npx';
  return runSync(npxCmd, ['tsx', script, ...scriptArgs], options);
}
