#!/usr/bin/env node
/**
 * PS1 Terminator - Eliminación masiva de referencias PS1
 *
 * Estrategia:
 * 1. Mapear todas las referencias PS1 conocidas
 * 2. Reemplazar en todos los archivos JSON y MD
 * 3. Generar reporte de cambios
 */

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join } from 'path';

const ROOT = process.cwd();

// Mapeo completo: PS1 path → TS path (o null para eliminar)
const REPLACEMENTS = {
  // Scripts utilidades
  'scripts/utilities/pre-process-input.ps1': 'src/pre-process-input.ts',
  'scripts/utilities/pre-compact-hook.ps1': 'src/pre-compact-hook.ts',
  'scripts/utilities/handoff-compress.ps1': 'src/handoff-compress.ts',
  'scripts/utilities/validate-tool-configs.ps1': 'src/validate-tool-configs.ts',

  // Hooks
  'hooks/pre-commit.ps1': 'src/hooks/pre-commit.ts',
  'hooks/pre-commit-privacy.ps1': 'src/hooks/pre-commit-privacy.ts',
  'hooks/validate-readme.ps1': 'src/validate-readme.ts',
  'scripts/hooks/check-security.ps1': 'src/check-security.ts',
  'scripts/hooks/check-sdd-gate.ps1': 'src/hooks/check-sdd-gate.ts',

  // Bootstrap
  'scripts/gentle-vanguard/bootstrap.ps1': 'src/bootstrap.ts',
  'scripts/gentle-vanguard/setup-complete.ps1': 'src/setup-complete.ts',

  // Workflow
  'scripts/utilities/WORKFLOW-ORCHESTRATION/gv.ps1': 'src/cli/gv.ts',
  'scripts/utilities/gv.ps1': 'src/cli/gv.ts',
  'gv.ps1': 'src/cli/gv.ts',

  // Legacy - reemplazar con comandos npm
  'create-gitflow-branch.ps1': null,
  'create-pull-request.ps1': null,
  'pre-commit-validation.ps1': 'src/pre-commit-validation.ts',
  'post-merge-sync.ps1': 'src/post-merge-sync.ts',
};

// Archivos a procesar
const TARGET_FILES = [
  'config/cline-dify.config.json',
  'config/tool-opencode.json',
  'config/tool-codex.json',
  'config/tool-cursor.json',
  'config/tool-windsurf.json',
  'config/access-control.json',
  'config/evolution-config.json',
  'config/gentle-vanguard-sync.json',
  'config/metrics-config.json',
  'config/observability-config.json',
  'config/orchestrator.json',
  'config/prometheus/prometheus-config.json',
  'docs/agents/AGENTS.md',
  'docs/agents/AI-MANDATORY-BEHAVIOR.md',
  'docs/operations/PRODUCTION-RUNBOOK.md',
  'docs/operations/procedures/ENGRAM-UPDATE-PROCEDURE.md',
];

interface ProcessResult {
  file: string;
  changes: number;
  success: boolean;
}

function processFile(filePath: string): ProcessResult {
  const fullPath = join(ROOT, filePath);

  if (!existsSync(fullPath)) {
    return { file: filePath, changes: 0, success: false };
  }

  try {
    let content = readFileSync(fullPath, 'utf-8');
    let changes = 0;

    // Reemplazar cada patrón
    for (const [from, to] of Object.entries(REPLACEMENTS)) {
      const escaped = from.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const regex = new RegExp(escaped, 'g');

      if (content.match(regex)) {
        if (to) {
          content = content.replace(regex, to);
        } else {
          // Reemplazar con placeholder si no hay equivalente
          content = content.replace(regex, '[REMOVED: migrated to TS]');
        }
        changes++;
      }
    }

    // Reemplazar comandos pwsh genéricos
    content = content.replace(
      /pwsh\s+-NoProfile\s+-ExecutionPolicy\s+Bypass\s+-File\s+[^\s]+\.ps1/g,
      'npx tsx src/cli/gv.ts',
    );

    // Reemplazar powershell -File
    content = content.replace(/powershell\s+-File\s+[^\s]+\.ps1/g, 'npx tsx src/cli/gv.ts');

    if (changes > 0) {
      writeFileSync(fullPath, content, 'utf-8');
    }

    return { file: filePath, changes, success: true };
  } catch {
    return { file: filePath, changes: 0, success: false };
  }
}

function main(): void {
  console.log('╔════════════════════════════════════════════════════════╗');
  console.log('║  PS1 TERMINATOR - Migra referencias a TypeScript       ║');
  console.log('╚════════════════════════════════════════════════════════╝');
  console.log();

  const results: ProcessResult[] = [];
  let totalChanges = 0;

  for (const file of TARGET_FILES) {
    const result = processFile(file);
    results.push(result);
    totalChanges += result.changes;

    if (result.changes > 0) {
      console.log(`✓ ${file}: ${result.changes} cambios`);
    }
  }

  console.log();
  console.log('═══════════════════════════════════════════════════════════');
  console.log(`Archivos procesados: ${results.length}`);
  console.log(`Archivos modificados: ${results.filter((r) => r.changes > 0).length}`);
  console.log(`Total cambios: ${totalChanges}`);
  console.log('═══════════════════════════════════════════════════════════');
}

// Guardar para ejecutar
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
