#!/usr/bin/env node
/** Validate that active apps consume the canonical Gentle-Vanguard shell. */

import { existsSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';

const packageRoot = resolve(import.meta.dirname, '..', '..');
const repoRoot = resolve(packageRoot, '..', '..');
const sourceShell = join(packageRoot, 'src', 'shell', 'shell.css');

type Check = { label: string; ok: boolean; detail?: string };
const checks: Check[] = [];

function file(path: string): string {
  return readFileSync(join(repoRoot, path), 'utf8');
}

function add(label: string, ok: boolean, detail?: string): void {
  checks.push({ label, ok, detail });
}

const shell = readFileSync(sourceShell, 'utf8');
add('canonical shell exists', shell.length > 1000);
add('shell has responsive contract', shell.includes('@media (max-width: 1023px)'));
add('shell has reduced motion contract', shell.includes('prefers-reduced-motion'));
add(
  'shell has canonical primitives',
  ['.gv-topbar', '.gv-view-tabs', '.gv-panel', '.gv-footer'].every((name) => shell.includes(name)),
);
// Identity contract (homologación 2026-09-15): "Gentle" white, only "Vanguard"
// gradient, 文A lang button pinned to 13px. Checked at SOURCE level so the
// snapshots (byte-identical below) inherit the guarantee transitively.
add(
  'identity: wordmark "Gentle" white',
  /\.gv-brand-wordmark[^{]*\{[^}]*color:\s*var\(--gv-text/.test(shell),
);
add(
  'identity: only "Vanguard" span gradient',
  /\.gv-brand-wordmark\s+span[^{]*\{[^}]*background-clip:\s*text/.test(shell),
);
add(
  'identity: lang button 13px',
  /\.gv-lang-dropdown\s+\.gv-icon-btn[^{]*\{[^}]*font-size:\s*13px/.test(shell),
);

for (const snapshot of ['assets/gv-shell.css', 'apps/design-hub/public/gv-shell.css']) {
  const value = file(snapshot);
  add(
    `${snapshot} matches source`,
    value === shell,
    `expected ${shell.length} bytes, got ${value.length}`,
  );
}

for (const app of [
  'apps/gv-analytics/src/main.tsx',
  'apps/content-cms/src/main.tsx',
  'apps/prompt-studio/src/main.tsx',
  'apps/archify/src/main.tsx',
  'apps/web-dashboard/src/main.tsx',
  'apps/academy-crm/src/main.tsx',
]) {
  add(`${app} imports shell`, file(app).includes('shell.css'));
}

for (const app of [
  'apps/gv-analytics/src/App.tsx',
  'apps/content-cms/src/App.tsx',
  'apps/prompt-studio/src/App.tsx',
  'apps/archify/src/App.tsx',
  'apps/web-dashboard/src/App.tsx',
]) {
  // Apps either declare .gv-app-shell directly OR consume the shared <Shell>
  // component (which renders it internally — see src/react/Shell.tsx).
  const src = file(app);
  add(
    `${app} declares gv-app-shell (direct or via <Shell>)`,
    src.includes('gv-app-shell') || /<Shell[\s/>]/.test(src),
  );
}

add(
  'command center serves shell',
  file('apps/command-center/public/index.html').includes('/gv-shell.css'),
);
add(
  'package exports shell',
  file('packages/gv-design-system/package.json').includes('"./shell.css"'),
);

const failures = checks.filter((check) => !check.ok);
for (const check of checks) {
  console.log(
    `${check.ok ? 'PASS' : 'FAIL'} ${check.label}${check.detail ? ` (${check.detail})` : ''}`,
  );
}
if (failures.length) {
  console.error(`\n${failures.length} conformance check(s) failed.`);
  process.exit(1);
}
console.log(`\nAll ${checks.length} shell conformance checks passed.`);
