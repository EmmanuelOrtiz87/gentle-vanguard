/**
 * codemod-console-to-logger.ts
 *
 * Migrates console.* calls in LIBRARY modules (non-CLI) to the structured
 * logger (src/utils/logger.ts). CLI sections (direct execution via main())
 * keep console.* by design.
 *
 * Strategy per file:
 *  1. Detect if the file has console.* in library code (before the CLI
 *     section, if any).
 *  2. Add `import { log } from '<rel>/utils/logger.js'` and a logger instance.
 *  3. Replace console.log/warn/error/info/debug -> logger.info/warn/error/...
 *     Only for single-argument calls (safe). Multi-arg calls are left for
 *     manual review (reported).
 *
 * Usage:
 *   npx tsx scripts/codemod-console-to-logger.ts [--dry-run]
 */

import { readdirSync, readFileSync, writeFileSync } from 'fs';
import { join, relative, dirname } from 'path';

const ROOT = process.cwd();
const SRC = join(ROOT, 'src');
const DRY_RUN = process.argv.includes('--dry-run');

// Files that must NOT be migrated (special cases)
const SKIP = new Set([
  'src/core/auto-token-tracker.ts', // intercepts console.log on purpose
  'src/utils/logger.ts', // the logger itself
]);

// CLI files by convention (keep console.* by design)
function isCliByPath(rel: string): boolean {
  return (
    rel.startsWith('src/cli/') ||
    rel.startsWith('src/scripts/') ||
    rel.endsWith('/cli.ts') ||
    rel.endsWith('cli.ts')
  );
}

const CONSOLE_RE = /console\.(log|warn|error|info|debug)\s*\(/g;

interface FileReport {
  file: string;
  replaced: number;
  multiArg: number;
  skipped: string[];
}

function isCliSection(line: string): boolean {
  // Heuristic: lines that start a CLI/direct-execution block
  return (
    line.includes('process.argv[1]') ||
    line.includes('import.meta.url ===') ||
    line.includes('isMainModule') ||
    line.includes("main().catch") ||
    line.includes('if (isMainModule)')
  );
}

function collectTsFiles(dir: string): string[] {
  const out: string[] = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      out.push(...collectTsFiles(full));
    } else if (entry.name.endsWith('.ts') && !entry.name.endsWith('.d.ts')) {
      out.push(full);
    }
  }
  return out;
}

function relImport(fromFile: string): string {
  const fromDir = dirname(fromFile);
  const target = join(SRC, 'utils', 'logger');
  let rel = relative(fromDir, target).replace(/\\/g, '/');
  if (!rel.startsWith('.')) rel = './' + rel;
  return rel + '.js';
}

function modulePrefix(file: string): string {
  const rel = relative(SRC, file).replace(/\\/g, '/').replace(/\.ts$/, '');
  return rel.toUpperCase().replace(/[^A-Z0-9]+/g, '-').replace(/^-|-$/g, '');
}

function migrateFile(file: string): FileReport {
  const report: FileReport = { file, replaced: 0, multiArg: 0, skipped: [] };
  const rel = relative(ROOT, file).replace(/\\/g, '/');
  if (SKIP.has(rel) || isCliByPath(rel)) {
    report.skipped.push(isCliByPath(rel) ? 'cli-by-path' : 'explicit-skip');
    return report;
  }

  const lines = readFileSync(file, 'utf-8').split('\n');
  const hasShebang = lines[0]?.startsWith('#!');
  if (hasShebang) {
    report.skipped.push('cli-shebang');
    return report;
  }

  // Find console.* occurrences and whether they're in library vs CLI section
  let inCliSection = false;
  const replacements: { lineIdx: number; method: string }[] = [];
  let multiArg = 0;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (isCliSection(line)) inCliSection = true;
    if (inCliSection) continue;

    const m = line.match(CONSOLE_RE);
    if (m) {
      // Check if single-argument call (rough heuristic: count commas at top level)
      const after = line.slice(line.indexOf('console.'));
      // Count args by splitting on commas not inside strings/parens (rough)
      const openParen = after.indexOf('(');
      const closeParen = after.lastIndexOf(')');
      if (openParen !== -1 && closeParen !== -1 && closeParen > openParen) {
        const inner = after.slice(openParen + 1, closeParen);
        const argCount = countTopLevelCommas(inner) + 1;
        if (argCount > 1) {
          multiArg++;
          continue; // leave for manual review
        }
      }
      for (const mm of after.matchAll(CONSOLE_RE)) {
        replacements.push({ lineIdx: i, method: mm[1] });
      }
    }
  }

  if (replacements.length === 0) {
    report.skipped.push('no-library-console');
    return report;
  }

  // Add import + logger instance after the last import line
  const importIdx = findLastImportIdx(lines);
  const importLine = `import { log } from '${relImport(file)}';`;
  const loggerLine = `const logger = log('${modulePrefix(file)}');`;
  const insertAt = importIdx >= 0 ? importIdx + 1 : 0;
  lines.splice(insertAt, 0, loggerLine, importLine);

  // Apply replacements (adjust for inserted lines)
  const offset = 2;
  for (const r of replacements) {
    const idx = r.lineIdx + offset;
    const methodMap: Record<string, string> = {
      log: 'info',
      warn: 'warn',
      error: 'error',
      info: 'info',
      debug: 'debug',
    };
    lines[idx] = lines[idx].replace(
      new RegExp(`console\\.${r.method}\\s*\\(`, 'g'),
      `logger.${methodMap[r.method]}(`,
    );
    report.replaced++;
  }

  if (!DRY_RUN) {
    writeFileSync(file, lines.join('\n'));
  }
  report.multiArg = multiArg;
  return report;
}

function countTopLevelCommas(s: string): number {
  let depth = 0;
  let inStr: string | null = null;
  let count = 0;
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (inStr) {
      if (c === inStr && s[i - 1] !== '\\') inStr = null;
      continue;
    }
    if (c === '"' || c === "'" || c === '`') {
      inStr = c;
      continue;
    }
    if (c === '(' || c === '[' || c === '{') depth++;
    else if (c === ')' || c === ']' || c === '}') depth--;
    else if (c === ',' && depth === 0) count++;
  }
  return count;
}

function findLastImportIdx(lines: string[]): number {
  let last = -1;
  for (let i = 0; i < lines.length; i++) {
    if (/^\s*import\s/.test(lines[i])) {
      last = i;
      // If this import spans multiple lines (no trailing ';' or '{' block),
      // advance past the continuation lines so we insert AFTER the whole block.
      let j = i;
      while (j < lines.length && !lines[j].trimEnd().endsWith(';')) {
        j++;
      }
      i = j;
    }
  }
  return last;
}

function main(): void {
  const files = collectTsFiles(SRC);
  const reports: FileReport[] = [];
  let totalReplaced = 0;
  let totalMultiArg = 0;

  for (const file of files) {
    const r = migrateFile(file);
    if (r.replaced > 0 || r.multiArg > 0) {
      reports.push(r);
      totalReplaced += r.replaced;
      totalMultiArg += r.multiArg;
    }
  }

  console.log(`\n=== CODEMOD console.* -> logger ===`);
  console.log(`Mode: ${DRY_RUN ? 'DRY-RUN (no writes)' : 'WRITE'}`);
  console.log(`Files processed: ${reports.length}`);
  console.log(`Total console.* replaced: ${totalReplaced}`);
  console.log(`Total multi-arg (left for manual): ${totalMultiArg}`);
  console.log('');
  for (const r of reports) {
    console.log(
      `  ${r.file}  +${r.replaced} replaced  ${r.multiArg > 0 ? `(${r.multiArg} multi-arg)` : ''}  ${r.skipped.join(',')}`,
    );
  }
}

main();
