#!/usr/bin/env node

import { execSync } from 'child_process';
import { existsSync } from 'fs';
import { join, dirname, resolve } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

interface HashlineSnapshotHookArgs {
  quiet: boolean;
}

function parseArgs(): HashlineSnapshotHookArgs {
  const args = process.argv.slice(2);
  return { quiet: args.includes('--quiet') || args.includes('-q') };
}

function main(): void {
  const args = parseArgs();

  let changed: string;
  try {
    changed = execSync('git diff --name-only HEAD~1 HEAD', { encoding: 'utf8', stdio: 'pipe' }).trim();
  } catch {
    return;
  }

  if (!changed) return;

  const lines = changed.split('\n');
  for (const rawPath of lines) {
    const p = rawPath.trim();
    if (p && existsSync(p)) {
      const hashlineScript = join(resolve(__dirname, '..'), 'src', 'hashline.ts');
      const quietFlag = args.quiet ? '--quiet' : '';
      try {
        execSync(`npx tsx ${hashlineScript} --action update --path "${p}" ${quietFlag}`, { stdio: 'pipe' });
      } catch {
        // silently continue on error
      }
    }
  }
}

main();
