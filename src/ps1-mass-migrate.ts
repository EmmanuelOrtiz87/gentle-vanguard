#!/usr/bin/env node
/**
 * PS1 Mass Migration Tool v2
 * Procesa TODOS los archivos con referencias PS1 de forma automatizada
 */

import { runSyncShell } from './core/run-command.js';
import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join } from 'path';

const ROOT = process.cwd();

// Mapeo completo de reemplazos
const PATTERNS = [
  // Archivos ejecutables -> TS equivalentes
  { from: /scripts\/utilities\/pre-process-input\.ps1/g, to: 'src/pre-process-input.ts' },
  { from: /scripts\/utilities\/pre-compact-hook\.ps1/g, to: 'src/pre-compact-hook.ts' },
  { from: /scripts\/utilities\/handoff-compress\.ps1/g, to: 'src/handoff-compress.ts' },
  {
    from: /scripts\/utilities\/session-start-optimized\.ps1/g,
    to: 'src/session-start-optimized.ts',
  },
  { from: /scripts\/utilities\/session-autostart\.ps1/g, to: 'src/session-autostart.ts' },
  { from: /scripts\/utilities\/detect-tool\.ps1/g, to: 'src/detect-tool.ts' },
  { from: /scripts\/utilities\/self-diagnosis\.ps1/g, to: 'src/self-diagnosis.ts' },
  { from: /scripts\/utilities\/review-workload-guard\.ps1/g, to: 'src/review-workload-guard.ts' },
  { from: /scripts\/utilities\/validate-tool-configs\.ps1/g, to: 'src/validate-tool-configs.ts' },
  { from: /scripts\/utilities\/normativa-resolver\.ps1/g, to: 'src/normativa-resolver.ts' },

  // Bootstrap
  { from: /scripts\/gentle-vanguard\/bootstrap\.ps1/g, to: 'src/bootstrap.ts' },
  { from: /scripts\/gentle-vanguard\/setup-complete\.ps1/g, to: 'src/setup-complete.ts' },
  { from: /scripts\/gentle-vanguard\/bootstrap-machine\.ps1/g, to: 'src/bootstrap-machine.ts' },

  // Workflow
  { from: /scripts\/utilities\/WORKFLOW-ORCHESTRATION\/gv\.ps1/g, to: 'src/cli/gv.ts' },
  { from: /scripts\/utilities\/gv\.ps1/g, to: 'src/cli/gv.ts' },
  { from: /gv\.ps1/g, to: 'src/cli/gv.ts' },

  // Comandos pwsh genéricos -> npx tsx
  {
    from: /pwsh\s+-NoProfile\s+-ExecutionPolicy\s+Bypass\s+-File\s+[^\s]+\.ps1/g,
    to: 'npx tsx src/gv.ts',
  },
  { from: /pwsh\s+-File\s+[^\s]+\.ps1/g, to: 'npx tsx src/gv.ts' },
  { from: /powershell\s+-File\s+[^\s]+\.ps1/g, to: 'npx tsx src/gv.ts' },
  { from: /\.\\scripts\\[^\\]+\.ps1/g, to: 'npx tsx src/gv.ts' },

  // Scripts sin equivalente -> placeholder
  { from: /create-gitflow-branch\.ps1/g, to: null },
  { from: /create-pull-request\.ps1/g, to: null },
  { from: /agent-verify\.ps1/g, to: null },
  { from: /run-tests.*\.ps1/g, to: null },
];

interface FileBatch {
  priority: 'high' | 'medium' | 'low';
  files: string[];
}

const BATCHES: FileBatch[] = [
  {
    priority: 'high',
    files: [
      'config/cline-dify.config.json',
      'config/cline-dify-optimized.config.json',
      'config/evolution-config.json',
      'config/adaptive-config.json',
      'config/mcp-registry.json',
    ],
  },
  {
    priority: 'medium',
    files: [
      'config/gentle-vanguard-sync.json',
      'config/orchestrator.json',
      'config/metrics-config.json',
      'config/provider-costs.json',
      '.clinerules',
      '.clinerules.optimized',
    ],
  },
  {
    priority: 'low',
    files: [
      'ps1-ts-migration.json', // Intentional - migration history
      'docs/**/*.md', // Documentation (informational only)
    ],
  },
];

function processFile(filePath: string): { changes: number; processed: boolean } {
  const fullPath = join(ROOT, filePath);
  if (!existsSync(fullPath)) return { changes: 0, processed: false };

  try {
    let content = readFileSync(fullPath, 'utf-8');
    let changes = 0;

    for (const pattern of PATTERNS) {
      if (content.match(pattern.from)) {
        if (pattern.to) {
          content = content.replace(pattern.from, pattern.to);
        } else {
          // Replace with placeholder for removed scripts
          content = content.replace(pattern.from, '[MIGRATED: use npm run commands]');
        }
        changes++;
      }
    }

    if (changes > 0) {
      writeFileSync(fullPath, content, 'utf-8');
    }

    return { changes, processed: true };
  } catch {
    return { changes: 0, processed: false };
  }
}

function main(): void {
  console.log('╔════════════════════════════════════════════════════════╗');
  console.log('║  PS1 MASS MIGRATION - BATCH PROCESSING                 ║');
  console.log('╚════════════════════════════════════════════════════════╝');
  console.log();

  let totalChanges = 0;
  let totalFiles = 0;

  for (const batch of BATCHES) {
    console.log(`\n[${batch.priority.toUpperCase()} PRIORITY BATCH]`);
    console.log('='.repeat(50));

    for (const file of batch.files) {
      const result = processFile(file);
      totalFiles++;
      totalChanges += result.changes;

      if (result.changes > 0) {
        console.log(`✓ ${file}: ${result.changes} cambios`);
      }
    }
  }

  console.log('\n' + '='.repeat(50));
  console.log(`Total archivos: ${totalFiles}`);
  console.log(`Total cambios: ${totalChanges}`);
  console.log('='.repeat(50));

  // Verificar cuántas referencias quedan
  try {
    const remaining = runSyncShell(
      'find config docs .cursor -name "*.json" -o -name "*.md" | xargs grep -l "\\.ps1" 2>/dev/null | wc -l',
      { cwd: ROOT },
    ).stdout;
    console.log(`\nArchivos con referencias PS1 restantes: ${remaining.trim()}`);
  } catch {}
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
