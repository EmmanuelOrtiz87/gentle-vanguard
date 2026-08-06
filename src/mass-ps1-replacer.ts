#!/usr/bin/env node
/**
 * Mass PS1 Replacer
 * Reemplaza TODAS las referencias .ps1 por .ts o las elimina
 *
 * USO: npx tsx src/mass-ps1-replacer.ts [--dry-run]
 */

import { runSync, runSyncShell } from './core/run-command.js';
import { readFileSync, writeFileSync, existsSync } from 'fs';

const ROOT = process.cwd();

// Mapeo completo de PS1 -> TS
const PS1_TO_TS_MAP: Record<string, string | null> = {
  // Scripts utilidades
  'scripts/utilities/pre-process-input.ps1': 'src/pre-process-input.ts',
  'scripts/utilities/pre-compact-hook.ps1': 'src/pre-compact-hook.ts',
  'scripts/utilities/handoff-compress.ps1': 'src/handoff-compress.ts',
  'scripts/utilities/validate-tool-configs.ps1': 'src/validate-tool-configs.ts',
  'scripts/utilities/session/session-autostart.ps1': 'src/session-autostart.ts',
  'scripts/utilities/session/session-manager.ps1': 'src/session-manager.ts',
  'scripts/utilities/session/session-start-optimized.ps1': 'src/session-start-optimized.ts',
  'scripts/utilities/session/session-notification.ps1': 'src/session-notification.ts',
  'scripts/utilities/lefthook-verify.ps1': 'src/lefthook-verify.ts',
  'scripts/utilities/setup/DETECT/detect-tool.ps1': 'src/detect-tool.ts',

  // Dashboard
  'scripts/utilities/dashboard/dashboard-common.ps1': 'src/dashboard-common.ts',
  'scripts/utilities/dashboard/dashboard-start.ps1': 'src/dashboard-start.ts',
  'scripts/utilities/dashboard/dashboard-stop.ps1': 'src/dashboard-stop.ts',
  'scripts/utilities/dashboard/dashboard-ws-autostart.ps1': 'src/dashboard-ws-autostart.ts',
  'scripts/utilities/dashboard/optimize-dashboard.ps1': null, // Obsoleto

  // Hooks
  'scripts/hooks/check-security.ps1': 'src/check-security.ts',
  'scripts/hooks/check-sdd-gate.ps1': 'src/hooks/check-sdd-gate.ts',
  'scripts/hooks/lockfile-lint-pre-commit.ps1': 'src/lockfile-lint-pre-commit.ts',
  'scripts/hooks/npm-audit-pre-push.ps1': 'src/npm-audit-pre-push.ts',
  'hooks/pre-commit.ps1': 'src/hooks/pre-commit.ts',
  'hooks/pre-commit-privacy.ps1': 'src/hooks/pre-commit-privacy.ts',
  'hooks/validate-readme-hook.ps1': 'src/hooks/validate-readme-hook.ts',

  // Security
  'scripts/security/security-orchestrator.ps1': 'src/security/security-orchestrator.ts',
  'scripts/security/privacy-gateway.ps1': 'src/privacy-gateway.ts',
  'scripts/security/audit-pipeline.ps1': 'src/audit-pipeline.ts',
  'scripts/security/scan-skill-hook.ps1': null, // No equivalente

  // Ops
  'scripts/utilities/ops/CLOUD-CONNECTORS/hybrid-executor.ps1': 'src/hybrid-executor.ts',
  'scripts/utilities/ops/CLOUD-CONNECTORS/aws-delegator.ps1': 'src/aws-delegator.ts',
  'scripts/utilities/ops/CLOUD-CONNECTORS/azure-delegator.ps1': 'src/azure-delegator.ts',
  'scripts/utilities/ops/STATE-PERSISTENCE/checkpoint-manager.ps1': 'src/checkpoint-manager.ts',
  'scripts/utilities/ops/STATE-PERSISTENCE/snapshot-manager.ps1': 'src/snapshot-manager.ts',
  'scripts/utilities/ops/STATE-PERSISTENCE/rollback-orchestrator.ps1':
    'src/rollback-orchestrator.ts',
  'scripts/utilities/ops/TRACING/tracing-instrument.ps1': 'src/tracing-instrument.ts',
  'scripts/utilities/ops/ADVANCED-PATTERNS/event-sourcing.ps1': 'src/event-sourcing.ts',
  'scripts/utilities/ops/ADVANCED-PATTERNS/saga-orchestrator.ps1': 'src/saga-orchestrator.ts',

  // Engram
  'scripts/utilities/memory/ENGRAM/engram-integrity-check.ps1': 'src/engram-integrity-check.ts',
  'scripts/utilities/memory/ENGRAM/engram-auto-sync.ps1': 'src/engram-auto-sync.ts',
  'scripts/utilities/memory/ENGRAM-RAG/engram-rag-reindex.ps1': 'src/engram-rag-reindex.ts',

  // MCP
  'scripts/utilities/MCP/mcp-gateway.ps1': 'src/mcp-gateway.ts',
  'scripts/utilities/MCP/mcp-manager.ps1': 'src/mcp-manager.ts',

  // Knowledge base
  'scripts/utilities/knowledge-base/knowledge-base-manager.ps1': 'src/knowledge-base-manager.ts',
  'scripts/utilities/knowledge-base/knowledge-base-sync.ps1': 'src/knowledge-base-sync.ts',
  'scripts/utilities/knowledge-base/knowledge-base-autoinit.ps1': 'src/knowledge-base-autoinit.ts',
  'scripts/utilities/knowledge-base/knowledge-base-init.ps1': 'src/knowledge-base-init.ts',

  // Profiles
  'scripts/utilities/profile/PROFILE-ADAPTIVE/adaptive-opencode-profile.ps1':
    'src/adaptive-opencode-profile.ts',
  'scripts/utilities/profile/PROFILE-ADAPTIVE/adaptive-codex-windsurf-profile.ps1':
    'src/adaptive-codex-windsurf-profile.ts',
  'scripts/utilities/adaptive-claude-cline-profile.ps1': 'src/adaptive-claude-profile.ts',
  'scripts/utilities/adaptive-common.ps1': 'src/adaptive-common.ts',

  // Git
  'scripts/utilities/git/GIT-VERSION-CONTROL/pre-commit-validation.ps1':
    'src/pre-commit-validation.ts',
  'scripts/utilities/git/GIT-VERSION-CONTROL/post-merge-sync.ps1': 'src/post-merge-sync.ts',

  // Bootstrap
  'scripts/gentle-vanguard/bootstrap.ps1': 'src/bootstrap.ts',
  'scripts/gentle-vanguard/bootstrap-machine.ps1': 'src/bootstrap-machine.ts',
  'scripts/gentle-vanguard/setup-complete.ps1': 'src/setup-complete.ts',

  // Workflow
  'scripts/utilities/WORKFLOW-ORCHESTRATION/gv.ps1': 'src/cli/gv.ts',
  'scripts/mcp-bridge/mcp-bridge.ps1': 'src/mcp-bridge.ts',

  // Auto
  'scripts/adaptive/karpathy-enforcer.ps1': 'src/karpathy-enforcer.ts',
  'scripts/adaptive/correction-rules-engine.ps1': 'src/correction-rules-engine.ts',
  'scripts/adaptive/session-scoring.ps1': 'src/session-scoring.ts',

  // Utils
  'scripts/utilities/post-autostart-summary.ps1': 'src/post-autostart-summary.ts',
  'scripts/utilities/final-resolution.ps1': 'src/final-resolution.ts',
  'scripts/utilities/codegraph/codegraph-post-modification-sync.ps1':
    'src/codegraph-post-modification-sync.ts',
  'scripts/utilities/orchestrate-auto-fix.ps1': 'src/orchestrate-auto-fix.ts',
  'scripts/utilities/token-metrics-store.ps1': 'src/token-metrics-store.ts',
  'scripts/run-tests-simple.ps1': null, // No equivalente
  'scripts/testing/*.ps1': null, // No equivalente
};

// Extensiones de archivo a procesar
const EXTENSIONS = ['.json', '.md', '.ts', '.yml', '.yaml'];

function findFiles(): string[] {
  const files: string[] = [];

  for (const ext of EXTENSIONS) {
    try {
      const output = runSyncShell(`find . -name "*${ext}" -type f 2>/dev/null | head -500`, {
        cwd: ROOT,
      }).stdout;
      files.push(
        ...output
          .trim()
          .split('\n')
          .filter((f) => f),
      );
    } catch {
      // Fallback Windows
      try {
        const output = runSync(
          'powershell',
          [
            '-NoProfile',
            '-Command',
            `Get-ChildItem -Recurse -Filter "*${ext}" | Select-Object -ExpandProperty FullName`,
          ],
          { cwd: ROOT },
        ).stdout;
        files.push(
          ...output
            .trim()
            .split('\n')
            .filter((f) => f),
        );
      } catch {}
    }
  }

  return [...new Set(files)].filter(
    (f) => !f.includes('node_modules') && !f.includes('.git') && !f.includes('dist'),
  );
}

function processFile(filePath: string, dryRun: boolean): { changes: number; action: string } {
  if (!existsSync(filePath)) return { changes: 0, action: 'not_found' };

  let content = readFileSync(filePath, 'utf-8');
  const originalContent = content;
  let changes = 0;

  // Reemplazar cada PS1 del mapa
  for (const [ps1Path, tsPath] of Object.entries(PS1_TO_TS_MAP)) {
    const escaped = ps1Path.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(escaped, 'g');

    if (content.match(regex)) {
      if (tsPath) {
        // Reemplazar con TS
        content = content.replace(regex, tsPath);
      } else {
        // Eliminar referencia
        content = content.replace(regex, '[REMOVED - no TS equivalent]');
      }
      changes++;
    }
  }

  // Reemplazar comandos pwsh
  content = content.replace(
    /pwsh\s+-NoProfile\s+-ExecutionPolicy\s+Bypass\s+-File\s+[^\s]+\.ps1/g,
    'npx tsx src/gv.ts',
  );
  content = content.replace(/powershell\s+-File\s+[^\s]+\.ps1/g, 'npx tsx src/gv.ts');

  // Reemplazar ./gv.ps1 con npx tsx src/cli/gv.ts
  content = content.replace(/\.\/gv\.ps1/g, 'npx tsx src/cli/gv.ts');
  content = content.replace(/gv\.ps1/g, 'npx tsx src/cli/gv.ts');

  if (content !== originalContent && !dryRun) {
    writeFileSync(filePath, content, 'utf-8');
    return { changes, action: 'modified' };
  }

  return { changes, action: content !== originalContent ? 'would_modify' : 'no_change' };
}

function main() {
  const dryRun = process.argv.includes('--dry-run');

  console.log(`[MASS REPLACER] ${dryRun ? 'DRY RUN' : 'LIVE MODE'}`);
  console.log('Scanning for PS1 references...\n');

  const files = findFiles();
  console.log(`Found ${files.length} files to scan\n`);

  let totalChanges = 0;
  let modifiedFiles = 0;

  for (const file of files.slice(0, 100)) {
    // Limitar a 100 archivos por seguridad
    const result = processFile(file, dryRun);
    if (result.changes > 0) {
      console.log(`${file}: ${result.action} (${result.changes} changes)`);
      totalChanges += result.changes;
      modifiedFiles++;
    }
  }

  console.log(`\n${'='.repeat(50)}`);
  console.log(`Total files modified: ${modifiedFiles}`);
  console.log(`Total changes: ${totalChanges}`);
  console.log(`${dryRun ? 'DRY RUN - No files were changed' : 'LIVE MODE - Files modified'}`);
}

main();
