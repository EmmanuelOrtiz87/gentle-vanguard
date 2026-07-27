#!/usr/bin/env node
/**
 * Pre-Process Input Pipeline
 *
 * Chains input transformations before submission:
 * 1. Privacy Gateway — PII/secret sanitization
 * 2. Prompt Compression — token optimization (skill-aware + budget-aware)
 *
 * Usage:
 *   npx tsx src/pre-process-input.ts --input "prompt text" [--skill react-19]
 *   npx tsx src/pre-process-input.ts --input "..." --workspace-root . --skill security-skill
 */

import { resolve } from 'path';
import { pathToFileURL } from 'url';
import { compressPrompt } from './prompt-compression.js';
import { runNpxTsxSync } from './core/run-command.js';

interface PrivacyGatewayResponse {
  status: string;
  sanitized?: string;
}

interface ParsedArgs {
  input: string;
  workspaceRoot: string;
  skill: string;
  skipCompression: boolean;
  json: boolean;
}

function parseArgs(): ParsedArgs {
  const args = process.argv.slice(2);
  let input = '';
  let workspaceRoot = '.';
  let skill = '';
  let skipCompression = false;
  let json = false;

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--input':
        input = args[++i] ?? '';
        break;
      case '--workspace-root':
        workspaceRoot = args[++i] ?? '.';
        break;
      case '--skill':
        skill = args[++i] ?? '';
        break;
      case '--skip-compression':
        skipCompression = true;
        break;
      case '--json':
        json = true;
        break;
    }
  }

  if (!input) {
    console.error('--input is required');
    process.exit(1);
  }

  return { input, workspaceRoot, skill, skipCompression, json };
}

function applyPrivacyGateway(input: string, workspaceRoot: string): string | null {
  const gatewayPath = resolve(workspaceRoot, 'src/privacy-gateway.ts');
  try {
    const result = runNpxTsxSync(gatewayPath, ['--text', input, '--as-json'], {
      cwd: workspaceRoot,
      timeout: 15000,
    });

    if (result.status !== 0 || !result.stdout?.trim()) return null;

    const parsed: PrivacyGatewayResponse = JSON.parse(result.stdout.trim());
    if (parsed.status !== 'OK') return null;
    return parsed.sanitized ?? null;
  } catch {
    return null;
  }
}

function applyPromptCompression(input: string, skill: string): string {
  try {
    const effectiveSkill = skill || 'default';
    const result = compressPrompt(input, effectiveSkill);

    if (!result.compressed || result.compressed.trim().length === 0) {
      return input; // fallback: return original if compression yielded empty
    }

    // Only return compressed if it's actually smaller
    if (result.compressed.length < input.length) {
      return result.compressed;
    }
    return input;
  } catch {
    return input; // fallback: return original on error
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const { input, workspaceRoot, skill, skipCompression, json } = parseArgs();
  let output = input;

  // Stage 1: Privacy Gateway
  const sanitized = applyPrivacyGateway(input, workspaceRoot);
  if (sanitized !== null) {
    output = sanitized;
  }

  // Stage 2: Prompt Compression
  if (!skipCompression) {
    output = applyPromptCompression(output, skill);
  }

  if (json) {
    console.log(JSON.stringify({
      status: 'ok',
      originalLength: input.length,
      outputLength: output.length,
      compressed: output.length < input.length,
      output,
    }));
  } else {
    console.log(output);
  }
}
