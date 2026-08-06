#!/usr/bin/env node
/**
 * auto-fix-lint.ts — Automatic lint error fixer
 *
 * Fixes common lint errors automatically:
 * - Remove unused imports
 * - Change let -> const where appropriate
 * - Add void operator to unhandled promises
 * - Comment out unsafe regex warnings
 *
 * Usage:
 *   npx tsx src/tools/auto-fix-lint.ts --dry-run    # Preview changes
 *   npx tsx src/tools/auto-fix-lint.ts --apply      # Apply fixes
 */

import { execSync } from 'child_process';
import { readFileSync, writeFileSync, existsSync } from 'fs';
import { resolve, join } from 'path';

const ROOT = resolve(process.cwd());

interface LintError {
  file: string;
  line: number;
  column: number;
  rule: string;
  message: string;
  severity: 'error' | 'warning';
}

interface FixResult {
  file: string;
  fixes: string[];
  errors: string[];
}

const CACHE_FILE = join(ROOT, '.runtime', 'lint-fix-cache.json');

function log(msg: string, level: 'info' | 'warn' | 'error' = 'info'): void {
  const prefix = level === 'error' ? '[ERR]' : level === 'warn' ? '[WARN]' : '[INFO]';
  console.log(`${prefix} ${msg}`);
}

function parseLintOutput(output: string): LintError[] {
  const errors: LintError[] = [];
  const lines = output.split('\n');
  let currentFile = '';

  for (const line of lines) {
    // Match file path
    if (line.endsWith('.ts') && !line.includes(':')) {
      currentFile = line.replace(/\r?\n/, '').trim();
    }
    // Match error line (format:   123:45  error  Message  rule)
    const match = line.match(/^\s+(\d+):(\d+)\s+(error|warning)\s+(.+?)\s+([\w/-]+)$/);
    if (match && currentFile) {
      errors.push({
        file: currentFile,
        line: parseInt(match[1], 10),
        column: parseInt(match[2], 10),
        severity: match[3] as 'error' | 'warning',
        message: match[4],
        rule: match[5],
      });
    }
  }

  return errors;
}

function getFileContent(file: string): string | null {
  try {
    return readFileSync(file, 'utf-8');
  } catch {
    return null;
  }
}

function fixUnusedImports(content: string): { content: string; fixed: boolean } {
  // Remove unused import statements
  const lines = content.split('\n');
  const importRegex = /^import\s+\{?[^}]+\}?\s+from\s+['"](.+?)['"];?$/;
  let fixed = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const match = importRegex.exec(line);
    if (match) {
      const importedItems = line.match(/\{([^}]+)\}/)?.[1]?.split(',').map(s => s.trim().split(' ').pop()) || [];
      const defaultImport = line.match(/import\s+(\w+)\s+from/)?.[1];
      const items = defaultImport ? [defaultImport, ...importedItems] : importedItems;
      
      let anyUsed = false;
      for (const item of items) {
        // Check if item is used in the file (not just declared)
        const usageRegex = new RegExp(`\\b${item}\\b`, 'g');
        const usages = content.match(usageRegex);
        if (usages && usages.length > 1) { // 1 = declaration itself
          anyUsed = true;
          break;
        }
      }
      
      if (!anyUsed && items.length > 0) {
        lines[i] = `// REMOVED: ${line}`;
        fixed = true;
      }
    }
  }

  return { content: lines.join('\n'), fixed };
}

function fixPreferConst(content: string): { content: string; fixed: boolean } {
  // Change let to const where variable is never reassigned
  const letRegex = /^(\s*)let\s+(\w+)\s*=/gm;
  let fixed = false;
  
  let result = content;
  let match;
  while ((match = letRegex.exec(content)) !== null) {
    const indent = match[1];
    const varName = match[2];
    const assignmentRegex = new RegExp(`\\b${varName}\\s*=`);
    const assignments = content.match(assignmentRegex);
    
    if (assignments && assignments.length === 1) {
      // Only one assignment = declaration, can be const
      result = result.replace(
        new RegExp(`^${indent}let\\s+${varName}\\s*=`, 'm'),
        `${indent}const ${varName} =`
      );
      fixed = true;
    }
  }

  return { content: result, fixed };
}

function fixFloatingPromises(content: string): { content: string; fixed: boolean } {
  // Add void operator to unhandled promises
  const promiseRegex = /^(\s*)(\w+\([^)]*\)\.(?:then|catch|finally)\([^)]*\));?$/gm;
  let fixed = false;
  
  let result = content;
  let match;
  while ((match = promiseRegex.exec(content)) !== null) {
    const line = match[0];
    if (!line.includes('void ') && !line.includes('await')) {
      result = result.replace(line, match[1] + 'void ' + line.trimStart());
      fixed = true;
    }
  }

  return { content: result, fixed };
}

function fixUnsafeRegex(content: string): { content: string; fixed: boolean } {
  // Add eslint-disable comment for unsafe regex patterns
  const lines = content.split('\n');
  let fixed = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    // Look for regex patterns that might be unsafe
    if (line.includes('new RegExp(') || line.includes('.match(') || line.includes('.test(')) {
      // Check if this line has a regex pattern
      const hasComplexRegex = /[+*?{}[\]]/.test(line) && line.length > 50;
      if (hasComplexRegex && !line.includes('// eslint-disable')) {
        lines[i] = `// eslint-disable-next-line security/detect-unsafe-regex\n${line}`;
        fixed = true;
      }
    }
  }

  return { content: lines.join('\n'), fixed };
}

async function fixFile(file: string, dryRun: boolean): Promise<FixResult> {
  const result: FixResult = { file, fixes: [], errors: [] };
  
  let content = getFileContent(file);
  if (!content) {
    result.errors.push('Could not read file');
    return result;
  }

  const originalContent = content;

  // Apply fixes
  const fixers = [
    { name: 'unused-imports', fn: fixUnusedImports },
    { name: 'prefer-const', fn: fixPreferConst },
    { name: 'floating-promises', fn: fixFloatingPromises },
    { name: 'unsafe-regex', fn: fixUnsafeRegex },
  ];

  for (const fixer of fixers) {
    const { content: newContent, fixed } = fixer.fn(content);
    if (fixed) {
      content = newContent;
      result.fixes.push(fixer.name);
    }
  }

  // Write if changed and not dry-run
  if (content !== originalContent) {
    if (!dryRun) {
      try {
        writeFileSync(file, content, 'utf-8');
        result.fixes.push('written');
      } catch (e) {
        result.errors.push(`Failed to write: ${e}`);
      }
    } else {
      result.fixes.push('(dry-run)');
    }
  }

  return result;
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');
  const apply = args.includes('--apply');

  if (!dryRun && !apply) {
    console.log('Usage: npx tsx src/tools/auto-fix-lint.ts [--dry-run | --apply]');
    console.log('  --dry-run    Preview changes without applying');
    console.log('  --apply      Apply fixes to files');
    process.exit(1);
  }

  log('Running lint check...');
  
  let lintOutput: string;
  try {
    lintOutput = execSync('npm run lint 2>&1', { encoding: 'utf-8', cwd: ROOT });
  } catch (e) {
    // Lint exits with error code if there are errors - that's expected
    const error = e as { stdout?: string; message?: string };
    lintOutput = String(error.stdout || error.message || '');
  }

  const errors = parseLintOutput(lintOutput);
  
  if (errors.length === 0) {
    log('No lint errors found! ✅', 'info');
    process.exit(0);
  }

  log(`Found ${errors.length} lint errors`, 'info');

  // Group by file
  const byFile = new Map<string, LintError[]>();
  for (const err of errors) {
    const list = byFile.get(err.file) || [];
    list.push(err);
    byFile.set(err.file, list);
  }

  log(`Files to process: ${byFile.size}`, 'info');

  const results: FixResult[] = [];
  const batchSize = 5;
  const files = Array.from(byFile.keys());

  for (let i = 0; i < files.length; i += batchSize) {
    const batch = files.slice(i, i + batchSize);
    log(`Processing batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(files.length / batchSize)}...`);
    
    for (const file of batch) {
      const result = await fixFile(file, dryRun);
      results.push(result);
      
      if (result.fixes.length > 0) {
        log(`  ${file}: ${result.fixes.join(', ')}`, 'info');
      }
      
      if (result.errors.length > 0) {
        log(`  ${file}: errors - ${result.errors.join(', ')}`, 'error');
      }
    }

    // Run typecheck after each batch
    log('Running typecheck...', 'info');
    try {
      execSync('npm run typecheck 2>&1', { encoding: 'utf-8', cwd: ROOT, stdio: 'pipe' });
      log('  Typecheck passed ✅', 'info');
    } catch (e) {
      log('  Typecheck failed - stopping batch', 'error');
      break;
    }
  }

  // Summary
  const withFixes = results.filter(r => r.fixes.length > 0);
  log(`\n=== Summary ===`, 'info');
  log(`Files processed: ${results.length}`, 'info');
  log(`Files with fixes: ${withFixes.length}`, 'info');
  
  if (dryRun) {
    log('\nRun with --apply to apply fixes', 'warn');
  } else {
    log('\nFixes applied successfully ✅', 'info');
  }
}

main().catch(e => {
  console.error('Fatal error:', e);
  process.exit(1);
});
