#!/usr/bin/env node

import { runSync } from './core/run-command.js';
import { existsSync, mkdirSync, rmSync, writeFileSync } from 'fs';
import { join, resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

interface EngramRagReindexArgs {
  project: string;
  exportFile: string;
}

function parseArgs(): EngramRagReindexArgs {
  const raw = process.argv.slice(2);
  return {
    project: extractArg(raw, '--project') || '',
    exportFile: extractArg(raw, '--export-file') || '',
  };
}

function extractArg(args: string[], name: string): string | undefined {
  const idx = args.indexOf(name);
  if (idx !== -1 && idx + 1 < args.length) return args[idx + 1];
  return undefined;
}

function findRepoRoot(dir: string): string {
  const envDir = process.env.GENTLE_VANGUARD_BASE_DIR;
  if (envDir && existsSync(envDir)) return envDir;
  let current = resolve(dir);
  while (current) {
    if (existsSync(join(current, 'config', 'orchestrator.json'))) return current;
    const parent = resolve(current, '..');
    if (parent === current) break;
    current = parent;
  }
  return dir;
}

function log(m: string, _c = 'Cyan'): void {
  console.log(`[ENGRAM-RAG-REINDEX] ${m}`);
}

function main(): void {
  const args = parseArgs();
  const repoRoot = findRepoRoot(__dirname);
  const indexDir = join(repoRoot, '.session', 'engram-rag');
  const indexFile = join(indexDir, 'vector-index.json');
  const metaFile = join(indexDir, 'index-meta.json');
  const tmpExport = join(indexDir, '_export-tmp.json');

  log('Starting full re-index...');

  if (existsSync(indexFile)) {
    rmSync(indexFile, { force: true });
    log('Removed existing index file');
  }
  if (existsSync(metaFile)) {
    rmSync(metaFile, { force: true });
    log('Removed existing index metadata');
  }
  if (existsSync(tmpExport)) {
    rmSync(tmpExport, { force: true });
  }

  const indexScript = join(__dirname, 'engram-vector-index.ps1');
  if (!existsSync(indexScript)) {
    log(
      'Vector index script removed in Phase 1 cleanup — using engram export for freshness',
      'Yellow',
    );
    try {
      runSync('engram', ['--version'], { stdio: 'pipe' });
      const exportArgs = ['export', tmpExport];
      if (args.project) exportArgs.push('--project', args.project);
      runSync('engram', exportArgs, { stdio: 'pipe' });
      if (existsSync(tmpExport)) rmSync(tmpExport, { force: true });
      log('engram export completed', 'Green');
    } catch {
      log('engram CLI not available', 'Yellow');
    }

    const ragLog = join(repoRoot, '.atl', 'rag-reindex.log');
    const ragLogDir = dirname(ragLog);
    mkdirSync(ragLogDir, { recursive: true });
    const ts = new Date().toISOString().slice(0, 19).replace('T', ' ');
    writeFileSync(
      ragLog,
      `[RAG-REINDEX] ${ts} — completed — project=${args.project || 'all'} — method=engram-export`,
      'utf8',
    );
    log(`Freshness log: ${ragLog}`, 'Green');
    return;
  }

  const argsList = ['-Force'];
  if (args.project) argsList.push('-Project', args.project);
  if (args.exportFile) argsList.push('-ExportFile', args.exportFile);

  log(`Running: engram-vector-index.ps1 ${argsList.join(' ')}`);
  try {
    runSync('powershell', ['-File', indexScript, ...argsList], { stdio: 'inherit' });
  } catch (e) {
    const code = (e as { status?: number }).status;
    log(`Re-index failed with exit code ${code}`, 'Red');
    process.exit(code ?? 1);
  }

  log('Re-index complete', 'Green');

  const ragLog = join(repoRoot, '.atl', 'rag-reindex.log');
  const ragLogDir = dirname(ragLog);
  mkdirSync(ragLogDir, { recursive: true });
  const ts = new Date().toISOString().slice(0, 19).replace('T', ' ');
  writeFileSync(
    ragLog,
    `[RAG-REINDEX] ${ts} — completed — project=${args.project || 'all'} — index=${indexFile}`,
    'utf8',
  );
  log(`Freshness log: ${ragLog}`, 'Green');
}

main();
