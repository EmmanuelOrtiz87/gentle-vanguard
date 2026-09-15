#!/usr/bin/env node
/**
 * Gentle-Vanguard Design System v2 — Audit CLI.
 *
 * Runs impeccable detect on a path and pretty-prints results.
 * Wraps `impeccable detect` with stack-friendly output.
 *
 * Usage:
 *   npx tsx src/cli/audit.ts <path>
 *   npx tsx src/cli/audit.ts <path> --json
 *   npx tsx src/cli/audit.ts <path> --scope type
 */
import { execSync } from 'node:child_process';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { argv } from 'node:process';
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
// src/cli/audit.ts -> packages/gv-design-system/
const DS_ROOT = join(__dirname, '..', '..');
// packages/gv-design-system/ -> repo root
const REPO_ROOT = resolve(DS_ROOT, '..', '..');
const args = argv.slice(2);
if (args.length === 0) {
    console.error('Usage: npx tsx src/cli/audit.ts <path> [--json] [--scope <type|layout|color|motion>]');
    process.exit(1);
}
const target = args[0];
if (typeof target !== 'string' || target.length === 0) {
    console.error('Audit target is required.');
    process.exit(1);
}
const json = args.includes('--json');
const scopeFlag = args.indexOf('--scope');
const scope = scopeFlag >= 0 ? args[scopeFlag + 1] : null;
const targetPath = target.startsWith('/') || target.match(/^[a-z]:\\/i) ? target : resolve(REPO_ROOT, target);
const cmd = ['npx', 'impeccable', 'detect', targetPath, json ? '--json' : '--quiet'];
if (scope)
    cmd.push('--scope', scope);
console.log(`🔍 Auditing: ${targetPath}`);
console.log(`   Mode: ${json ? 'JSON' : 'human'}${scope ? ` (scope: ${scope})` : ''}`);
console.log('');
try {
    const output = execSync(cmd.join(' '), {
        cwd: REPO_ROOT,
        encoding: 'utf-8',
        maxBuffer: 10 * 1024 * 1024,
        stdio: ['ignore', 'pipe', 'pipe'],
    });
    console.log(output || '✅ Clean — no issues found.');
    process.exit(0);
}
catch (err) {
    const e = err;
    const text = e.stdout || e.stderr || String(err);
    console.log(text);
    // Exit 2 = issues found, that's expected
    // Exit 0 = clean
    // Exit > 2 = real error
    if ((e.status ?? 0) > 2) {
        console.error('❌ Audit failed.');
        process.exit(1);
    }
    process.exit(2);
}
//# sourceMappingURL=audit.js.map