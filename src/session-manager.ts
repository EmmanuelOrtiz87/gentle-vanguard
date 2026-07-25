#!/usr/bin/env node
import * as fs from 'fs';
import * as path from 'path';
import { spawnSync } from 'child_process';

interface CliArgs {
  mode: string;
  timezone: string;
  quiet: boolean;
}

function parseArgs(): CliArgs {
  const args = process.argv.slice(2);
  const result: CliArgs = { mode: 'AutoStart', timezone: '', quiet: false };
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--mode' || args[i] === '-Mode') {
      result.mode = args[++i] || 'AutoStart';
    } else if (args[i] === '--timezone' || args[i] === '-TimeZone') {
      result.timezone = args[++i] || '';
    } else if (args[i] === '--quiet' || args[i] === '-Quiet') {
      result.quiet = true;
    }
  }
  return result;
}

const ROOT = path.resolve(process.cwd());
const TARGET_TS = path.join(ROOT, 'src', 'session-cleanup-start.ts');
const TARGET_PS1 = path.join(ROOT, 'scripts', 'utilities', 'session', 'session-cleanup-start.ps1');

function run(): void {
  const { mode, timezone, quiet } = parseArgs();

  const npxArgs: string[] = ['tsx', TARGET_TS];
  if (mode) { npxArgs.push('-Mode', mode); }
  if (timezone) { npxArgs.push('-TimeZone', timezone); }
  if (quiet) { npxArgs.push('-Quiet'); }

  if (fs.existsSync(TARGET_TS)) {
    const result = spawnSync('npx', npxArgs, { stdio: 'inherit', cwd: ROOT, shell: true });
    process.exit(result.status ?? 0);
  } else if (fs.existsSync(TARGET_PS1)) {
    // Check for TS equivalent in src/ to avoid PS1 proxy chain
    const tsBasename = path.basename(TARGET_PS1, '.ps1') + '.ts';
    const tsEquivalent = path.join(ROOT, 'src', tsBasename);
    if (fs.existsSync(tsEquivalent)) {
      // Call session-manager.ts directly — TS proxies like session-start-optimized.ts
      // already delegate here, so going through them would create a circular call.
      const directArgs: string[] = ['tsx', 'src/session-manager.ts'];
      if (mode) { directArgs.push('--mode', mode); }
      if (timezone) { directArgs.push('--timezone', timezone); }
      if (quiet) { directArgs.push('--quiet'); }
      const result = spawnSync('npx', directArgs, { stdio: 'inherit', cwd: ROOT, shell: true });
      process.exit(result.status ?? 0);
    }
    const psArgs: string[] = [];
    if (mode) { psArgs.push('-Mode', mode); }
    if (timezone) { psArgs.push('-TimeZone', timezone); }
    if (quiet) { psArgs.push('-Quiet'); }
    const result = spawnSync('powershell', ['-File', TARGET_PS1, ...psArgs], { stdio: 'inherit', cwd: ROOT, shell: true });
    process.exit(result.status ?? 0);
  } else {
    console.warn(`[session-manager] target not found: ${TARGET_TS} or ${TARGET_PS1}`);

  }
}

run();
