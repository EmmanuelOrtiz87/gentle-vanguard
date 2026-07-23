#!/usr/bin/env node

import { spawnSync } from 'child_process';
import { resolve } from 'path';
import { pathToFileURL } from 'url';

interface PrivacyGatewayResponse {
  status: string;
  sanitized?: string;
}

function parseArgs(): { input: string; workspaceRoot: string } {
  const args = process.argv.slice(2);
  let input = '';
  let workspaceRoot = '.';

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--input':
        input = args[++i] ?? '';
        break;
      case '--workspace-root':
        workspaceRoot = args[++i] ?? '.';
        break;
    }
  }

  if (!input) {
    console.error('--input is required');
    process.exit(1);
  }

  return { input, workspaceRoot };
}

function applyPrivacyGateway(input: string, workspaceRoot: string): string | null {
  const gatewayPath = resolve(workspaceRoot, 'src/privacy-gateway.ts');
  try {
    const result = spawnSync('npx', ['tsx', gatewayPath, '--text', input, '--as-json'], {
      encoding: 'utf-8',
      stdio: 'pipe',
      timeout: 15000,
      cwd: workspaceRoot,
    });

    if (result.status !== 0 || !result.stdout?.trim()) return null;

    const parsed: PrivacyGatewayResponse = JSON.parse(result.stdout.trim());
    if (parsed.status !== 'OK') return null;
    return parsed.sanitized ?? null;
  } catch {
    return null;
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const { input, workspaceRoot } = parseArgs();

  const sanitized = applyPrivacyGateway(input, workspaceRoot);

  if (sanitized !== null) {
    console.log(sanitized);
  } else {
    console.log(input);
  }
}
