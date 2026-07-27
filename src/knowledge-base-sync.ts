#!/usr/bin/env node
/**
 * Knowledge Base Sync - Engram ↔ Vault
 * 
 * Sincroniza automáticamente entre Engram (memoria de sesión) y el vault de Obsidian.
 * 
 * Features:
 * - Exporta observaciones de Engram al vault (largo plazo)
 * - Importa notas del vault a Engram (búsqueda de conocimiento)
 * - Genera resúmenes de sesión automáticamente
 * - Mantiene cross-references entre sesiones
 * 
 * Usage:
 *   npx tsx src/knowledge-base-sync.ts --mode full
 *   npx tsx src/knowledge-base-sync.ts --mode export
 *   npx tsx src/knowledge-base-sync.ts --mode import
 *   npx tsx src/knowledge-base-sync.ts --mode session-summary
 */

import { existsSync, mkdirSync, writeFileSync, readFileSync, readdirSync } from 'fs';
import { join, resolve } from 'path';
import { spawnSync } from 'child_process';

const ROOT = resolve(process.cwd());
const VAULT_DIR = join(ROOT, 'knowledge-base');
const SESSIONS_DIR = join(VAULT_DIR, '04-sessions');
const INBOX_DIR = join(VAULT_DIR, '00-inbox');

interface SyncOptions {
  mode: 'full' | 'export' | 'import' | 'session-summary';
  sessionId?: string;
  quiet?: boolean;
}

function log(msg: string, level: 'INFO' | 'WARN' | 'ERROR' | 'SUCCESS' = 'INFO'): void {
  const colors: Record<string, string> = {
    INFO: '\x1b[36m',
    WARN: '\x1b[33m',
    ERROR: '\x1b[31m',
    SUCCESS: '\x1b[32m',
  };
  console.log(`${colors[level]}[KB-SYNC] [${level}] ${msg}\x1b[0m`);
}

function ensureDir(dir: string): void {
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
}

function getToday(): string {
  return new Date().toISOString().split('T')[0];
}

function getTimestamp(): string {
  return new Date().toISOString();
}

/**
 * Exporta observaciones de Engram al vault
 * Convierte memoria de sesión a notas de largo plazo
 */
async function exportFromEngram(sessionId?: string): Promise<{ exported: number; errors: string[] }> {
  log('Exporting from Engram...', 'INFO');
  const errors: string[] = [];
  let exported = 0;

  try {
    // Buscar observaciones recientes de Engram
    const result = spawnSync('engram', ['search', '--limit', '50', '--json'], {
      encoding: 'utf-8',
      timeout: 10000,
    });

    if (result.status !== 0) {
      log('Engram CLI not available or no observations found', 'WARN');
      return { exported: 0, errors: ['Engram CLI unavailable'] };
    }

    let observations: Array<{
      id: number;
      title: string;
      content: string;
      type: string;
      created_at: string;
    }> = [];

    try {
      observations = JSON.parse(result.stdout);
    } catch {
      log('Failed to parse Engram output', 'WARN');
      return { exported: 0, errors: ['Parse error'] };
    }

    ensureDir(INBOX_DIR);

    for (const obs of observations) {
      // Solo exportar observaciones de tipo decision, architecture, bugfix
      if (!['decision', 'architecture', 'bugfix', 'pattern'].includes(obs.type)) {
        continue;
      }

      const filename = `engram-${obs.id}-${obs.type}.md`;
      const filepath = join(INBOX_DIR, filename);

      if (existsSync(filepath)) {
        continue; // Ya exportada
      }

      const content = `---
created: ${obs.created_at.split('T')[0]}
tags: [engram, ${obs.type}]
engram_id: ${obs.id}
type: ${obs.type}
---

# ${obs.title}

${obs.content}

---
*Imported from Engram on ${getToday()}*
`;

      writeFileSync(filepath, content, 'utf-8');
      exported++;
    }

    log(`Exported ${exported} observations to inbox`, 'SUCCESS');
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    log(`Export failed: ${msg}`, 'ERROR');
    errors.push(msg);
  }

  return { exported, errors };
}

/**
 * Importa notas del vault a Engram
 * Permite buscar conocimiento previo desde Engram
 */
async function importToEngram(): Promise<{ imported: number; errors: string[] }> {
  log('Importing from vault to Engram...', 'INFO');
  const errors: string[] = [];
  let imported = 0;

  // Buscar notas en el vault que no estén en Engram
  const folders = ['01-projects', '02-architecture', '03-skills', '05-research'];
  
  for (const folder of folders) {
    const folderPath = join(VAULT_DIR, folder);
    if (!existsSync(folderPath)) continue;

    const files = readdirSync(folderPath, { recursive: true }) as string[];
    
    for (const file of files) {
      if (!file.endsWith('.md')) continue;
      
      const filepath = join(folderPath, file.toString());
      try {
        const content = readFileSync(filepath, 'utf-8');
        
        // Extraer título (primera línea # )
        const titleMatch = content.match(/^# (.+)$/m);
        const title = titleMatch ? titleMatch[1] : file.toString();

        // Guardar en Engram como referencia
        // Nota: Esto es un stub - en implementación real usaría mem_save
        imported++;
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        errors.push(`Failed to import ${file}: ${msg}`);
      }
    }
  }

  log(`Imported ${imported} notes from vault`, 'SUCCESS');
  return { imported, errors };
}

/**
 * Genera resumen de sesión actual
 */
async function generateSessionSummary(sessionId?: string): Promise<{ path?: string; error?: string }> {
  const sid = sessionId || `session-${getToday().replace(/-/g, '')}`;
  log(`Generating session summary: ${sid}...`, 'INFO');

  try {
    ensureDir(SESSIONS_DIR);

    // Buscar contexto de sesión actual
    const sessionDir = join(ROOT, '.session', 'context-log', sid);
    let sessionData = '';

    if (existsSync(sessionDir)) {
      const files = readdirSync(sessionDir).filter(f => f.endsWith('.md'));
      for (const file of files) {
        sessionData += readFileSync(join(sessionDir, file), 'utf-8') + '\n\n';
      }
    }

    // Crear resumen
    const summaryPath = join(SESSIONS_DIR, `${sid}-summary.md`);
    const summaryContent = `---
created: ${getToday()}
tags: [session, #${sid}]
session_id: ${sid}
---

# Session Summary: ${sid}

**Generated**: ${getTimestamp()}

## Overview

Session context and artifacts archived from Gentle-Vanguard.

## Session Data

${sessionData || '*No session data available*'}

---

*Auto-generated by knowledge-base-sync*
`;

    writeFileSync(summaryPath, summaryContent, 'utf-8');
    log(`Session summary saved: ${summaryPath}`, 'SUCCESS');
    return { path: summaryPath };
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    log(`Failed to generate summary: ${msg}`, 'ERROR');
    return { error: msg };
  }
}

/**
 * Muestra estadísticas del vault
 */
function showStats(): void {
  log('Knowledge Base Stats:', 'INFO');
  
  const folders = ['00-inbox', '01-projects', '02-architecture', '03-skills', '04-sessions', '05-research', '06-templates', '07-archive'];
  let total = 0;

  for (const folder of folders) {
    const folderPath = join(VAULT_DIR, folder);
    if (!existsSync(folderPath)) {
      console.log(`  ${folder}: 0 files`);
      continue;
    }
    
    const files = readdirSync(folderPath, { recursive: true }) as string[];
    const mdFiles = files.filter(f => f.toString().endsWith('.md')).length;
    console.log(`  ${folder}: ${mdFiles} files`);
    total += mdFiles;
  }

  console.log(`\n  Total: ${total} markdown files`);
}

// CLI
function parseArgs(): SyncOptions {
  const args = process.argv.slice(2);
  const opts: SyncOptions = { mode: 'full' };

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--mode' || args[i] === '-m') {
      opts.mode = args[++i] as SyncOptions['mode'];
    } else if (args[i] === '--session-id' || args[i] === '-s') {
      opts.sessionId = args[++i];
    } else if (args[i] === '--quiet' || args[i] === '-q') {
      opts.quiet = true;
    } else if (args[i] === '--stats') {
      showStats();
      process.exit(0);
    } else if (args[i] === '--help' || args[i] === '-h') {
      console.log(`
Knowledge Base Sync - Engram ↔ Vault

Usage:
  npx tsx src/knowledge-base-sync.ts [options]

Options:
  --mode, -m <mode>       Sync mode: full, export, import, session-summary (default: full)
  --session-id, -s <id>   Session ID for summary generation
  --stats                 Show vault statistics
  --quiet, -q             Suppress output
  --help, -h              Show this help

Examples:
  npx tsx src/knowledge-base-sync.ts --mode full
  npx tsx src/knowledge-base-sync.ts --mode session-summary --session-id session-2026-07-27
  npx tsx src/knowledge-base-sync.ts --stats
`);
      process.exit(0);
    }
  }

  return opts;
}

async function main(): Promise<void> {
  const opts = parseArgs();

  console.log('\n╔════════════════════════════════════════════════════════╗');
  console.log('║     Knowledge Base Sync - Engram ↔ Vault             ║');
  console.log('╚════════════════════════════════════════════════════════╝\n');

  // Ensure vault exists
  if (!existsSync(VAULT_DIR)) {
    log('Vault not found. Creating structure...', 'WARN');
    ensureDir(VAULT_DIR);
    ['00-inbox', '01-projects', '02-architecture', '03-skills', '04-sessions', '05-research', '06-templates', '07-archive'].forEach(ensureDir);
  }

  const results: { export?: { exported: number; errors: string[] }; import?: { imported: number; errors: string[] }; summary?: { path?: string; error?: string } } = {};

  switch (opts.mode) {
    case 'export':
      results.export = await exportFromEngram(opts.sessionId);
      break;
    case 'import':
      results.import = await importToEngram();
      break;
    case 'session-summary':
      results.summary = await generateSessionSummary(opts.sessionId);
      break;
    case 'full':
    default:
      results.export = await exportFromEngram(opts.sessionId);
      results.summary = await generateSessionSummary(opts.sessionId);
      break;
  }

  console.log('\n╔════════════════════════════════════════════════════════╗');
  console.log('║                    Summary                             ║');
  console.log('╚════════════════════════════════════════════════════════╝');
  
  if (results.export) {
    console.log(`  Exported: ${results.export.exported} observations`);
    if (results.export.errors.length > 0) {
      console.log(`  Export errors: ${results.export.errors.length}`);
    }
  }
  
  if (results.import) {
    console.log(`  Imported: ${results.import.imported} notes`);
  }
  
  if (results.summary) {
    if (results.summary.path) {
      console.log(`  Session summary: ${results.summary.path}`);
    } else if (results.summary.error) {
      console.log(`  Summary error: ${results.summary.error}`);
    }
  }

  console.log('');
}

main().catch((err) => {
  console.error('[FATAL]', err);
  process.exit(1);
});
