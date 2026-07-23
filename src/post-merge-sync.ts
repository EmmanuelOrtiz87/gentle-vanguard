#!/usr/bin/env node

import { execSync } from 'child_process';
import { existsSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

function main(): void {
  const repoRoot = resolve(__dirname, '..');

  console.log('[INFO] Running post-merge sync...');

  const validatorTs = resolve(repoRoot, 'src', 'cross-workspace-validator.ts');
  const validatorPs1 = resolve(repoRoot, 'scripts/monitoring/cross-workspace-validator.ps1');
  if (existsSync(validatorTs)) {
    execSync(`npx tsx "${validatorTs}" --fix`, { stdio: 'inherit' });
  } else if (existsSync(validatorPs1)) {
    execSync(`powershell -File "${validatorPs1}" -Fix`, { stdio: 'inherit' });
  }

  try {
    const version = execSync('engram --version', { encoding: 'utf8', stdio: 'pipe' }).trim();
    if (/Update available/i.test(version)) {
      console.log('[WARN] Engram update available');
    }
  } catch {
    // engram CLI not available
  }

  console.log('[OK] Post-merge sync completed');
  process.exit(0);
}

main();
