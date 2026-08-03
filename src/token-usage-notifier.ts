#!/usr/bin/env node
import * as fs from 'fs';
import * as path from 'path';
import { spawnSync } from 'child_process';

interface CliArgs {
  action: string;
  quiet: boolean;
}

function parseArgs(): CliArgs {
  const args = process.argv.slice(2);
  const result: CliArgs = { action: 'init', quiet: false };
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--action' || args[i] === '-Action') {
      result.action = args[++i] || 'init';
    } else if (args[i] === '--quiet' || args[i] === '-Quiet') {
      result.quiet = true;
    }
  }
  return result;
}

const ROOT = path.resolve(process.cwd());
const SCRIPT_DIR = path.join(ROOT, 'scripts', 'utilities');
const TARGET = path.join(SCRIPT_DIR, 'token', 'token-metrics-store.ps1');

function run(): void {
  const { action, quiet } = parseArgs();

  if (fs.existsSync(TARGET)) {
    const psArgs: string[] = ['-File', TARGET, '-Action', action];
    if (quiet) { psArgs.push('-Quiet'); }
    const result = spawnSync('powershell', psArgs, { stdio: 'inherit', cwd: ROOT, shell: true });
    process.exit(result.status ?? 0);
  } else {
    console.warn(`[token-usage-notifier] target not found: ${TARGET}`);
    process.exit(1);
  }
}

run();
