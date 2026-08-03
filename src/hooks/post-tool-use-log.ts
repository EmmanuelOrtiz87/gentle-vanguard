#!/usr/bin/env node

import { existsSync } from 'fs';
import { join } from 'path';
import { spawnSync } from 'child_process';
import { fileURLToPath, pathToFileURL } from 'url';

const __dirname = fileURLToPath(new URL('.', import.meta.url));

interface ToolUseArgs {
  toolName: string;
  toolArgs: string;
  inputSummary: string;
  outputSummary: string;
}

function parseArgs(): ToolUseArgs {
  const args = process.argv.slice(2);
  return {
    toolName: args[0] ?? '',
    toolArgs: args[1] ?? '',
    inputSummary: args[2] ?? '',
    outputSummary: args[3] ?? '',
  };
}

function main(): number {
  const repoRoot = join(__dirname, '..', '..');
  const { toolName, toolArgs, inputSummary, outputSummary } = parseArgs();

  const autoScript = join(repoRoot, 'scripts', 'utilities', 'TOKEN', 'token-usage-auto.ps1');
  const enrichScript = join(repoRoot, 'scripts', 'utilities', 'FINE-TUNING', 'session-enrich.ps1');

  if (!existsSync(autoScript)) {
    return 0;
  }

  const ctxChars = toolArgs ? Math.max(1, Math.floor(toolArgs.length * 1.5)) : 0;
  const turnLabel = toolName ? `tool:${toolName}` : 'auto-hook';

  spawnSync(
    'powershell.exe',
    [
      '-NoProfile',
      '-ExecutionPolicy', 'Bypass',
      '-File', autoScript,
      '-InputTokens', '0',
      '-OutputTokens', '0',
      '-ContextChars', String(ctxChars),
      '-TurnLabel', turnLabel,
      '-InputSummary', inputSummary,
      '-OutputSummary', outputSummary,
      '-Model', 'auto-detected',
    ],
    { encoding: 'utf-8', windowsHide: true, stdio: 'inherit' }
  );

  if (existsSync(enrichScript) && (inputSummary || outputSummary)) {
    spawnSync(
      'powershell.exe',
      [
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', enrichScript,
        '-TurnLabel', turnLabel,
        '-InputSummary', inputSummary,
        '-OutputSummary', outputSummary,
        '-Silent',
      ],
      { encoding: 'utf-8', windowsHide: true, stdio: 'inherit' }
    );
  }

  return 0;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  process.exit(main());
}

export { main as postToolUseLog };
