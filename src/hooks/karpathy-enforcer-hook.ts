#!/usr/bin/env node

import { spawnSync } from 'child_process';
import { join, resolve } from 'path';
import { fileURLToPath, pathToFileURL } from 'url';

const __dirname = fileURLToPath(new URL('.', import.meta.url));

function resolveRepoRoot(): string {
  const result = spawnSync('git', ['rev-parse', '--show-toplevel'], {
    encoding: 'utf-8',
    windowsHide: true,
  });
  return result.stdout?.trim() || resolve(__dirname, '..', '..');
}

function main(): number {
  const repoRoot = resolveRepoRoot();
  const handlerScript = join(repoRoot, 'scripts', 'utilities', 'utils', 'resilience-handler.ps1');

  const scriptBlock = `& '${join(repoRoot, 'scripts', 'adaptive', 'auto-norm-enforcer.ps1').replace(/\\/g, '\\\\')}' -Trigger karpathy`;

  const result = spawnSync(
    'powershell.exe',
    [
      '-NoProfile',
      '-ExecutionPolicy', 'Bypass',
      '-Command',
      `& '${handlerScript}' -ScriptBlock { ${scriptBlock} } -TimeoutSeconds 30 -OperationName karpathy-enforcer -FallbackAction warn_skip`,
    ],
    { encoding: 'utf-8', windowsHide: true, stdio: 'inherit' }
  );

  return result.status ?? 0;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  process.exit(main());
}

export { main as karpathyEnforcerHook };
