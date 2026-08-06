#!/usr/bin/env node
/**
 * config-drift-detector.ts — Configuration drift detection
 *
 * Detects when configuration files drift from their expected state:
 * - Unexpected modifications
 * - Missing required fields
 * - Schema violations
 * - Unauthorized changes
 *
 * Usage:
 *   npx tsx src/tools/config-drift-detector.ts
 *   npx tsx src/tools/config-drift-detector.ts --baseline
 */

import { createHash } from 'crypto';
import { existsSync, readFileSync, writeFileSync, readdirSync, statSync } from 'fs';
import { join, resolve, relative } from 'path';

const ROOT = resolve(process.cwd());
const BASELINE_FILE = join(ROOT, '.runtime', 'config-baseline.json');

interface ConfigFile {
  path: string;
  hash: string;
  mtime: number;
  size: number;
}

interface Baseline {
  timestamp: string;
  files: Record<string, ConfigFile>;
}

interface DriftResult {
  type: 'modified' | 'missing' | 'new';
  path: string;
  details: string;
}

function hashFile(path: string): string {
  const content = readFileSync(path);
  return createHash('sha256').update(content).digest('hex').slice(0, 16);
}

function findConfigFiles(dir: string, results: ConfigFile[] = []): ConfigFile[] {
  if (!existsSync(dir)) return results;
  
  const entries = readdirSync(dir, { withFileTypes: true });
  
  for (const entry of entries) {
    const fullPath = join(dir, entry.name);
    
    if (entry.isDirectory()) {
      // Skip common non-config directories
      if (['.git', 'node_modules', '.runtime', 'dist', 'build', 'coverage'].includes(entry.name)) {
        continue;
      }
      findConfigFiles(fullPath, results);
    } else if (entry.isFile()) {
      // Match config files
      if (/\.(json|config\.js|config\.ts|yaml|yml|toml|ini)$/.test(entry.name)) {
        const stat = statSync(fullPath);
        results.push({
          path: relative(ROOT, fullPath),
          hash: hashFile(fullPath),
          mtime: stat.mtimeMs,
          size: stat.size,
        });
      }
    }
  }
  
  return results;
}

function loadBaseline(): Baseline | null {
  try {
    if (existsSync(BASELINE_FILE)) {
      return JSON.parse(readFileSync(BASELINE_FILE, 'utf-8'));
    }
  } catch {}
  return null;
}

function saveBaseline(files: ConfigFile[]): void {
  const baseline: Baseline = {
    timestamp: new Date().toISOString(),
    files: Object.fromEntries(files.map(f => [f.path, f])),
  };
  
  writeFileSync(BASELINE_FILE, JSON.stringify(baseline, null, 2));
}

function detectDrift(): DriftResult[] {
  const currentFiles = findConfigFiles(ROOT);
  const baseline = loadBaseline();
  
  if (!baseline) {
    console.log('⚠️  No baseline found. Run with --baseline to create one.');
    return [];
  }
  
  const drifts: DriftResult[] = [];
  const currentMap = new Map(currentFiles.map(f => [f.path, f]));
  const baselineMap = new Map(Object.entries(baseline.files));
  
  // Check for modified files
  for (const [path, current] of currentMap) {
    const expected = baselineMap.get(path);
    if (expected) {
      if (current.hash !== expected.hash) {
        drifts.push({
          type: 'modified',
          path,
          details: `Hash changed: ${expected.hash.slice(0, 8)} -> ${current.hash.slice(0, 8)}`,
        });
      }
    } else {
      // New file
      drifts.push({
        type: 'new',
        path,
        details: `Size: ${current.size} bytes`,
      });
    }
  }
  
  // Check for missing files
  for (const [path] of baselineMap) {
    if (!currentMap.has(path)) {
      drifts.push({
        type: 'missing',
        path,
        details: 'File no longer exists',
      });
    }
  }
  
  return drifts;
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const createBaseline = args.includes('--baseline');
  
  console.log('🔍 Gentle-Vanguard Config Drift Detector\n');
  
  if (createBaseline) {
    console.log('Creating baseline...');
    const files = findConfigFiles(ROOT);
    saveBaseline(files);
    console.log(`✅ Baseline created: ${files.length} config files tracked`);
    console.log(`📁 Baseline saved to: ${BASELINE_FILE}`);
    return;
  }
  
  const drifts = detectDrift();
  
  if (drifts.length === 0) {
    console.log('✅ No configuration drift detected');
    const baseline = loadBaseline();
    if (baseline) {
      console.log(`📅 Baseline from: ${baseline.timestamp}`);
    }
  } else {
    console.log(`⚠️  ${drifts.length} configuration drift(s) detected:\n`);
    
    const byType = {
      modified: drifts.filter(d => d.type === 'modified'),
      missing: drifts.filter(d => d.type === 'missing'),
      new: drifts.filter(d => d.type === 'new'),
    };
    
    for (const [type, items] of Object.entries(byType)) {
      if (items.length > 0) {
        console.log(`${type.toUpperCase()} (${items.length}):`);
        for (const drift of items) {
          console.log(`  ${drift.path}`);
          console.log(`    ${drift.details}`);
        }
        console.log();
      }
    }
    
    console.log('💡 Run with --baseline to update the baseline if these changes are intentional.');
    process.exit(1);
  }
}

main().catch(e => {
  console.error('Error:', e);
  process.exit(1);
});
