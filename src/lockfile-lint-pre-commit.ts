#!/usr/bin/env node

import { existsSync, readFileSync } from 'fs';
import { pathToFileURL } from 'url';
import { spawnSync } from 'child_process';

interface LockfilePackages {
  [key: string]: {
    version?: string;
    resolved?: string;
    integrity?: string;
  };
}

interface LockfileData {
  lockfileVersion: number;
  requires: boolean;
  packages: LockfilePackages;
  [key: string]: unknown;
}

const REQUIRED_FIELDS: (keyof LockfileData)[] = ['lockfileVersion', 'requires', 'packages'];
const VERSION_RE = /^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?(\+[a-zA-Z0-9.]+)?$/;

function parseArgs(): { lockfilePath: string; verbose: boolean } {
  const args = process.argv.slice(2);
  let lockfilePath = 'package-lock.json';
  let verbose = false;
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--lockfile-path' && args[i + 1]) {
      lockfilePath = args[i + 1];
      i++;
    } else if (args[i] === '--verbose' || args[i] === '-v') {
      verbose = true;
    }
  }
  return { lockfilePath, verbose };
}

function main(): number {
  const { lockfilePath, verbose } = parseArgs();
  const cwd = process.cwd();

  const stagedRaw = spawnSync('git', ['diff', '--cached', '--name-only'], {
    cwd,
    encoding: 'utf-8',
    windowsHide: true,
  });
  const stagedFiles = (stagedRaw.stdout || '').split('\n').map((s) => s.trim()).filter(Boolean);

  if (!stagedFiles.includes(lockfilePath)) {
    if (verbose) {
      console.log(`[lockfile-lint] ${lockfilePath} not staged, skipping validation`);
    }
    return 0;
  }

  if (!existsSync(lockfilePath)) {
    console.log(`[lockfile-lint] ${lockfilePath} not found, skipping validation`);
    return 0;
  }

  console.log(`[lockfile-lint] Validating ${lockfilePath}...`);

  let lock: LockfileData;
  try {
    const content = readFileSync(lockfilePath, 'utf-8');
    lock = JSON.parse(content) as LockfileData;
    console.log(`[OK] JSON structure valid`);
  } catch (err) {
    console.log(`[ERROR] Invalid JSON in lockfile: ${err}`);
    console.log(`\nTo fix:`);
    console.log(`  1. Inspect the file: code ${lockfilePath}`);
    console.log(`  2. Fix JSON syntax errors`);
    console.log(`  3. Regenerate if corrupted: rm ${lockfilePath} && npm install`);
    return 1;
  }

  const missingFields = REQUIRED_FIELDS.filter((field) => !(field in lock));
  if (missingFields.length > 0) {
    console.log(`[ERROR] Missing required fields: ${missingFields.join(', ')}`);
    console.log(`\nTo fix:`);
    console.log(`  Run: npm install  (to regenerate valid lockfile)`);
    return 1;
  }

  console.log(`[OK] Required fields present (lockfileVersion=${lock.lockfileVersion})`);

  if (Object.keys(lock.packages).length === 0) {
    console.log(`[WARNING] packages object is empty`);
    console.log(`  This might indicate a corrupted lockfile`);
  }

  const issues: string[] = [];

  const invalidVersions = Object.entries(lock.packages).filter(
    ([, pkg]) => pkg.version && !VERSION_RE.test(pkg.version),
  );
  if (invalidVersions.length > 0) {
    issues.push('Invalid version format detected');
  }

  const missingIntegrity = Object.entries(lock.packages).filter(
    ([, pkg]) => pkg.resolved && !pkg.integrity,
  ).length;
  if (missingIntegrity > 0) {
    issues.push(`${missingIntegrity} packages missing integrity hashes`);
  }

  if (issues.length > 0) {
    console.log(`[WARNING] Potential lockfile issues detected:`);
    for (const issue of issues) {
      console.log(`  - ${issue}`);
    }
    console.log(`\nConsider regenerating: npm ci && npm install --save-exact`);
  }

  if (lock.lockfileVersion < 2) {
    console.log(`[WARNING] lockfileVersion ${lock.lockfileVersion} is outdated`);
    console.log(`  Recommend updating to v3+: npm install`);
  }

  console.log(`[OK] Lockfile validation passed`);
  return 0;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  process.exit(main());
}

export { main as lockfileLintPreCommit };
