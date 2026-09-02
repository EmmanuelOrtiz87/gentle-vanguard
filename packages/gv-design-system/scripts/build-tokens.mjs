#!/usr/bin/env node
/**
 * Legacy entry point — delegates to the canonical token builder.
 *
 * The real implementation lives in src/cli/build-tokens.ts (validate + generate
 * css/ts/tailwind/figma from src/tokens/tokens.json). This wrapper is kept so
 * existing `node scripts/build-tokens.mjs` invocations keep working; it never
 * regenerates artifacts itself (the previous inline generator emitted invalid
 * tokens like `--gv-$schema` and an invalid dist/tokens.ts interface block).
 */

import { spawnSync } from 'node:child_process';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const CLI = join(__dirname, '..', 'src', 'cli', 'build-tokens.ts');

const result = spawnSync(
  process.execPath,
  ['--import', 'tsx', CLI],
  { stdio: 'inherit', windowsHide: true, cwd: join(__dirname, '..') }
);

process.exit(result.status ?? 1);
