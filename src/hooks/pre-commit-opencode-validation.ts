#!/usr/bin/env node

import { existsSync, readFileSync } from 'fs';
import { join } from 'path';
import { spawnSync } from 'child_process';
import { pathToFileURL } from 'url';

const LOG_COLORS: Record<string, string> = {
  Success: '32',
  Error: '31',
  Warning: '33',
  Info: '36',
};

function writeLog(message: string, level: string = 'Info'): void {
  const color = LOG_COLORS[level] ?? '37';
  console.log(`\x1b[${color}m[${level}] ${message}\x1b[0m`);
}

function execGit(args: string[], cwd: string = process.cwd()): string {
  const result = spawnSync('git', args, { cwd, encoding: 'utf-8', windowsHide: true });
  return result.stdout?.trim() ?? '';
}

function tryParseJson(filePath: string): Record<string, unknown> | null {
  try {
    return JSON.parse(readFileSync(filePath, 'utf-8')) as Record<string, unknown>;
  } catch {
    return null;
  }
}

function testJsonSchema(jsonPath: string, schemaPath: string): boolean {
  if (!existsSync(jsonPath)) {
    writeLog(`File not found: ${jsonPath}`, 'Error');
    return false;
  }
  if (!existsSync(schemaPath)) {
    writeLog(`Schema not found: ${schemaPath}`, 'Error');
    return false;
  }

  const json = tryParseJson(jsonPath);
  if (!json) {
    writeLog(`Invalid JSON: ${jsonPath}`, 'Error');
    return false;
  }

  const schema = tryParseJson(schemaPath);
  if (!schema) {
    writeLog(`Invalid schema: ${schemaPath}`, 'Error');
    return false;
  }

  const requiredFields = schema.required as string[] | undefined;
  if (requiredFields) {
    for (const field of requiredFields) {
      if (!(field in json)) {
        writeLog(`Required field missing: ${field}`, 'Error');
        return false;
      }
    }
  }

  const provider = json.provider as Record<string, unknown> | undefined;
  if (!provider) {
    writeLog('provider is required', 'Error');
    return false;
  }

  const anthropic = provider.anthropic as Record<string, unknown> | undefined;
  if (!anthropic) {
    writeLog('provider.anthropic is required', 'Error');
    return false;
  }

  if (!anthropic.enabled || !anthropic.model) {
    writeLog('provider.anthropic.enabled and model are required', 'Error');
    return false;
  }

  writeLog('JSON schema validation passed', 'Success');
  return true;
}

function testNormativas(jsonPath: string, gitRoot: string): boolean {
  const normativasPath = join(gitRoot, 'docs', 'reference', 'NORMATIVAS-ORQUESTADOR.md');
  if (!existsSync(normativasPath)) {
    writeLog('NORMATIVAS-ORQUESTADOR.md not found, skipping', 'Warning');
    return true;
  }

  try {
    const json = tryParseJson(jsonPath);
    if (!json) {
      writeLog(`Invalid JSON: ${jsonPath}`, 'Error');
      return false;
    }

    const normativas = readFileSync(normativasPath, 'utf-8');

    const requiredSections = ['Objetivo', 'Ubicación', 'Contenido', 'Decisiones'];
    for (const section of requiredSections) {
      const sectionRe = new RegExp(`##\\s*${section}`);
      if (!sectionRe.test(normativas)) {
        writeLog(`Missing section in NORMATIVAS: ${section}`, 'Warning');
      }
    }

    writeLog('Normativas check completed', 'Success');
    return true;
  } catch (err) {
    writeLog(`Error checking normativas: ${err}`, 'Warning');
    return true;
  }
}

function main(): number {
  const verbose = process.argv.includes('--verbose') || process.argv.includes('-v');
  const cwd = process.cwd();

  const gitRoot = execGit(['rev-parse', '--show-toplevel'], cwd);
  if (!gitRoot) {
    writeLog('Not in a git repository', 'Warning');
    return 0;
  }

  const stagedRaw = execGit(['diff', '--cached', '--name-only', '--diff-filter=ACM'], gitRoot);
  if (!stagedRaw) return 0;

  const stagedFiles = stagedRaw.split('\n').filter(Boolean);
  const configFiles = stagedFiles.filter(
    (f) => f.endsWith('.json') && /(config|opencode)/.test(f)
  );

  if (configFiles.length === 0) {
    writeLog('No configuration changes', 'Success');
    return 0;
  }

  writeLog(`Configuration files to validate: ${configFiles.length}`, 'Info');

  if (verbose) {
    for (const file of configFiles) {
      writeLog(`  ${file}`, 'Info');
    }
  }

  let hasErrors = false;

  for (const file of configFiles) {
    writeLog(`Validating: ${file}`, 'Info');

    const json = tryParseJson(file);
    if (!json) {
      writeLog(`  Invalid JSON in ${file}`, 'Error');
      hasErrors = true;
      continue;
    }
    writeLog('  Valid JSON', 'Success');

    const schemaFile = file.replace(/\.json$/, '.schema.json');
    if (existsSync(schemaFile)) {
      writeLog('  Validating against schema...', 'Info');
      if (!testJsonSchema(file, schemaFile)) {
        hasErrors = true;
      }
    }

    if (/opencode|config/.test(file)) {
      writeLog('  Checking normativas...', 'Info');
      if (!testNormativas(file, gitRoot)) {
        hasErrors = true;
      }
    }
  }

  if (hasErrors) {
    writeLog('Configuration validation failed', 'Error');
    return 1;
  }

  writeLog('All configuration validations passed', 'Success');
  return 0;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  process.exit(main());
}

export { main as preCommitOpencodeValidation };
