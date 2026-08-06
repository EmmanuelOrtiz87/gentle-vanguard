#!/usr/bin/env node
/**
 * Config PS1 Cleaner
 * Limpia referencias a .ps1 en archivos de configuración JSON
 *
 * USO: npx tsx src/config-ps1-cleaner.ts [--apply]
 */

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join } from 'path';

const ROOT = process.cwd();

// Mapeo de PS1 -> TS (basado en auto-ps1-fixer.ts)
const PS1_TO_TS: Record<string, string | null> = {
  // Hooks
  'hooks/pre-commit.ps1': 'src/hooks/pre-commit.ts',
  'hooks/pre-commit-privacy.ps1': 'src/hooks/pre-commit-privacy.ts',
  'hooks/validate-readme-hook.ps1': 'src/hooks/validate-readme-hook.ts',
  'hooks/pre-tool-format.ps1': 'src/hooks/pre-tool-format.ts',

  // Security
  'scripts/security/security-orchestrator.ps1': 'src/security/security-orchestrator.ts',
  'scripts/security/privacy-gateway.ps1': 'src/privacy-gateway.ts',
  'scripts/security/audit-pipeline.ps1': 'src/audit-pipeline.ts',
  'scripts/security/siem-audit-bridge.ps1': 'src/siem-audit-bridge.ts',
  'scripts/security/setup-secure.ps1': 'src/setup-secure.ts',

  // Utilities principales
  'scripts/utilities/pre-process-input.ps1': 'src/pre-process-input.ts',
  'scripts/utilities/pre-compact-hook.ps1': 'src/pre-compact-hook.ts',
  'scripts/utilities/handoff-compress.ps1': 'src/handoff-compress.ts',
  'scripts/utilities/validate-tool-configs.ps1': 'src/validate-tool-configs.ts',
  'scripts/utilities/lefthook-verify.ps1': 'src/lefthook-verify.ts',
  'scripts/utilities/post-autostart-summary.ps1': 'src/post-autostart-summary.ts',
  'scripts/utilities/optimize-engram-usage.ps1': 'src/optimize-engram-usage.ts',
  'scripts/utilities/token-metrics-store.ps1': 'src/token-metrics-store.ts',

  // Session
  'scripts/utilities/session/session-manager.ps1': 'src/session-manager.ts',
  'scripts/utilities/session/session-cleanup-start.ps1': 'src/session-cleanup-start.ts',
  'scripts/utilities/session/session-notification.ps1': 'src/session-notification.ts',
  'scripts/utilities/session/session-metrics-tracker.ps1': 'src/session-metrics-tracker.ts',
  'scripts/utilities/session/session-start-optimized.ps1': 'src/session-start.ts',

  // Dashboard
  'scripts/utilities/dashboard/dashboard-common.ps1': 'src/dashboard-common.ts',
  'scripts/utilities/dashboard/dashboard-start.ps1': 'src/dashboard-start.ts',
  'scripts/utilities/dashboard/dashboard-stop.ps1': 'src/dashboard-stop.ts',
  'scripts/utilities/dashboard/dashboard-ws-autostart.ps1': 'src/dashboard-ws-autostart.ts',

  // MCP
  'scripts/utilities/MCP/mcp-gateway.ps1': 'src/mcp/mcp-gateway.ts',
  'scripts/utilities/MCP/mcp-manager.ps1': 'src/mcp/mcp-manager.ts',
  'scripts/mcp-bridge/mcp-bridge.ps1': 'src/mcp-bridge.ts',

  // OPS / Cloud
  'scripts/utilities/ops/CLOUD-CONNECTORS/hybrid-executor.ps1': 'src/hybrid-executor.ts',
  'scripts/utilities/ops/CLOUD-CONNECTORS/aws-delegator.ps1': 'src/aws-delegator.ts',
  'scripts/utilities/ops/CLOUD-CONNECTORS/azure-delegator.ps1': 'src/azure-delegator.ts',
  'scripts/utilities/ops/CLOUD-CONNECTORS/prometheus-deploy.ps1': 'src/prometheus-deploy.ts',
  'scripts/utilities/ops/CLOUD-CONNECTORS/azure-deploy.ps1': 'src/azure-deploy.ts',

  // State persistence
  'scripts/utilities/ops/STATE-PERSISTENCE/checkpoint-manager.ps1': 'src/checkpoint-manager.ts',
  'scripts/utilities/ops/STATE-PERSISTENCE/snapshot-manager.ps1': 'src/snapshot-manager.ts',
  'scripts/utilities/ops/STATE-PERSISTENCE/rollback-orchestrator.ps1':
    'src/rollback-orchestrator.ts',

  // Tracing / Events
  'scripts/utilities/ops/TRACING/tracing-instrument.ps1': 'src/tracing-instrument.ts',
  'scripts/utilities/ops/ADVANCED-PATTERNS/event-sourcing.ps1': 'src/event-sourcing.ts',
  'scripts/utilities/ops/ADVANCED-PATTERNS/saga-orchestrator.ps1': 'src/saga-orchestrator.ts',

  // Engram
  'scripts/utilities/memory/ENGRAM/engram-integrity-check.ps1': 'src/engram-integrity-check.ts',
  'scripts/utilities/memory/ENGRAM/engram-auto-sync.ps1': 'src/engram-auto-sync.ts',
  'scripts/utilities/memory/ENGRAM-RAG/engram-rag-reindex.ps1': 'src/engram-rag-reindex.ts',

  // Perfiles adaptativos
  'scripts/utilities/profile/PROFILE-ADAPTIVE/adaptive-opencode-profile.ps1':
    'src/adaptive-opencode-profile.ts',
  'scripts/utilities/profile/PROFILE-ADAPTIVE/adaptive-codex-windsurf-profile.ps1':
    'src/adaptive-codex-windsurf-profile.ts',
  'scripts/utilities/adaptive-claude-cline-profile.ps1': 'src/adaptive-claude-profile.ts',
  'scripts/utilities/adaptive-antigravity-profile.ps1': 'src/adaptive-antigravity-profile.ts',

  // Knowledge base
  'scripts/utilities/knowledge-base/knowledge-base-manager.ps1': 'src/knowledge-base-manager.ts',
  'scripts/utilities/knowledge-base/knowledge-base-sync.ps1': 'src/knowledge-base-sync.ts',

  // Workflow
  'scripts/utilities/WORKFLOW-ORCHESTRATION/gv.ps1': 'src/gv.ts',
  'scripts/utilities/WORKFLOW-ORCHESTRATION/validate-system-health.ps1':
    'src/validate-system-health.ts',
  'scripts/utilities/WORKFLOW-ORCHESTRATION/orchestrator-next-steps.ps1':
    'src/orchestrator-next-steps.ts',
  'scripts/utilities/WORKFLOW-ORCHESTRATION/intelligent-validator.ps1':
    'src/intelligent-validator.ts',

  // Git
  'scripts/utilities/GIT-VERSION-CONTROL/pre-commit-validation.ps1': 'src/pre-commit-validation.ts',
  'scripts/utilities/GIT-VERSION-CONTROL/post-merge-sync.ps1': 'src/post-merge-sync.ts',
  'scripts/utilities/git/GIT-VERSION-CONTROL/pre-commit-validation.ps1':
    'src/pre-commit-validation.ts',

  // Bootstrap
  'scripts/gentle-vanguard/bootstrap.ps1': 'src/bootstrap.ts',
  'scripts/gentle-vanguard/bootstrap-machine.ps1': 'src/bootstrap-machine.ts',
  'scripts/gentle-vanguard/setup-complete.ps1': 'src/setup-complete.ts',
  'scripts/gentle-vanguard/setup-multi-machine.ps1': 'src/setup-multi-machine.ts',

  // Maintenance
  'scripts/maintenance/maintenance-watchtower.ps1': 'src/maintenance-watchtower.ts',

  // Adaptive
  'scripts/adaptive/karpathy-enforcer.ps1': 'src/karpathy-enforcer.ts',
  'scripts/adaptive/correction-rules-engine.ps1': 'src/correction-rules-engine.ts',
  'scripts/adaptive/session-scoring.ps1': 'src/session-scoring.ts',
  'scripts/adaptive/auto-norm-enforcer.ps1': 'src/auto-norm-enforcer.ts',
  'scripts/adaptive/auto-norm-learner.ps1': 'src/auto-norm-learner.ts',
  'scripts/adaptive/auto-testing-final.ps1': 'src/auto-testing-final.ts',
  'scripts/adaptive/auto-backup-orchestrator.ps1': 'src/auto-backup-orchestrator.ts',
  'scripts/adaptive/auto-doc-drift-detector.ps1': 'src/auto-doc-drift-detector.ts',

  // Safety
  'scripts/utilities/SAFETY/safety-guardrails.ps1': 'src/safety-guardrails.ts',
  'scripts/utilities/SAFETY/mutation-safety-scorer.ps1': 'src/mutation-safety-scorer.ts',
  'scripts/utilities/SAFETY/prompt-injection-guard.ps1': 'src/prompt-injection-guard.ts',

  // Health
  'scripts/utilities/HEALTH/stack-health-check.ps1': 'src/stack-health-check.ts',

  // Audit
  'scripts/utilities/AUDIT-REPORTING/generate-session-artifacts.ps1':
    'src/generate-session-artifacts.ts',

  // Setup
  'scripts/utilities/setup/DETECT/detect-tool.ps1': 'src/detect-tool.ts',
  'scripts/utilities/setup/FIX/fix-emoji-cleanup.ps1': 'src/fix-emoji-cleanup.ts',

  // Normativa
  'scripts/utilities/normativa-resolver.ps1': 'src/normativa-resolver.ts',

  // Cloud Agent Management
  'scripts/utilities/AI-AGENT-MANAGEMENT/invoke-cloud-agent.ps1': 'src/invoke-cloud-agent.ts',
  'scripts/utilities/AI-AGENT-MANAGEMENT/invoke-judgment.ps1': 'src/invoke-judgment.ts',
  'scripts/utilities/AI-AGENT-MANAGEMENT/invoke-ai-review.ps1': 'src/invoke-ai-review.ts',
  'scripts/utilities/AI-AGENT-MANAGEMENT/sync-agent-instructions.ps1':
    'src/sync-agent-instructions.ts',
  'scripts/utilities/AI-AGENT-MANAGEMENT/collect-provider-telemetry.ps1':
    'src/collect-provider-telemetry.ts',

  // Deployment
  'scripts/utilities/DEPLOYMENT/install-github-runner.ps1': 'src/install-github-runner.ts',
  'scripts/utilities/DEPLOYMENT/migrate-gentle-vanguard-remotes.ps1':
    'src/migrate-gentle-vanguard-remotes.ts',
  'scripts/utilities/DEPLOYMENT/deploy.ps1': 'src/deploy.ts',
  'scripts/utilities/DEPLOYMENT/setup-wizard.ps1': 'src/setup-wizard.ts',
  'scripts/utilities/DEPLOYMENT/sync-to-public.ps1': 'src/sync-to-public.ts',

  // Skills
  'scripts/utilities/SKILLS-TOOLS/create-skill.ps1': 'src/create-skill.ts',
  'scripts/utilities/SKILLS-TOOLS/install-engram.ps1': 'src/install-engram.ts',
  'skills/docker-devops-skill/scripts/security-scan.ps1': null, // Obsoleto
  'skills/documentation-manager.ps1': null, // Obsoleto

  // Telemetry
  'scripts/utilities/TELEMETRY-METRICS/consolidate-telemetry.ps1': 'src/consolidate-telemetry.ts',
  'scripts/utilities/TELEMETRY-METRICS/generate-dashboard.ps1': 'src/generate-dashboard.ts',
  'scripts/utilities/TELEMETRY-METRICS/webhook-alerting.ps1': 'src/webhook-alerting.ts',
  'scripts/utilities/TELEMETRY-METRICS/validate-report-simple.ps1':
    'src/dashboard/validate-report-simple.ts',
  'scripts/utilities/TELEMETRY-METRICS/extract-engram-json.ps1': 'src/extract-engram-json.ts',

  // Performance
  'scripts/utilities/PERFORMANCE-OPTIMIZATION/optimize-performance-root.ps1':
    'src/optimize-performance-root.ts',
  'scripts/utilities/PERFORMANCE-OPTIMIZATION/compact-memory.ps1': 'src/compact-memory.ts',
  'scripts/utilities/PERFORMANCE-OPTIMIZATION/clean-runtime.ps1': 'src/clean-runtime.ts',

  // Utils
  'scripts/utilities/UTILITIES/stack-dashboard.ps1': 'src/stack-dashboard.ts',
  'scripts/utilities/UTILITIES/context-pack.ps1': 'src/context-pack.ts',
  'scripts/utilities/UTILITIES/manage-backlog.ps1': 'src/manage-backlog.ts',
  'scripts/utilities/UTILITIES/read-once-guard.ps1': 'src/read-once-guard.ts',
  'scripts/utilities/UTILITIES/manual-recovery.ps1': 'src/manual-recovery.ts',
  'scripts/utilities/UTILITIES/gentle-vanguard-sync.ps1': 'src/sync-to-public.ts',
  'scripts/utilities/UTILITIES/auto-init-dev-environment.ps1': 'src/auto-init-dev-environment.ts',
  'scripts/utilities/UTILITIES/fix-remaining-scripts.ps1': null, // Obsoleto

  // Config
  'scripts/utilities/CONFIG/JSON/json-validator.ps1': 'src/json-validator.ts',

  // Session reference
  'scripts/utilities/SESSION/session-reference-system.ps1': 'src/session-reference-system.ts',

  // Generate
  'scripts/utilities/GENERATE/generate-executive-summary.ps1': 'src/generate-executive-summary.ts',
  'scripts/utilities/GENERATE/svg-generator.ps1': 'src/svg-generator.ts',

  // Workflow Orchestration
  'scripts/utilities/workflow/WORKFLOW-ORCHESTRATION/homologate-local.ps1':
    'src/homologate-local.ts',
  'scripts/utilities/workflow/WORKFLOW-ORCHESTRATION/orchestrator-governance-integration.ps1':
    'src/orchestrator-governance-integration.ts',
  'scripts/utilities/workflow/WORKFLOW-ORCHESTRATION/event-governance-layer.ps1':
    'src/event-governance-layer.ts',
  'scripts/utilities/workflow/WORKFLOW-ORCHESTRATION/validate-system-health.ps1':
    'src/validate-system-health.ts',

  // Resilience
  'scripts/utilities/resilience-handler.ps1': 'src/resilience-handler.ts',

  // Agent router
  'scripts/utilities/agents/AI-AGENT-MANAGEMENT/collect-provider-telemetry.ps1':
    'src/collect-provider-telemetry.ts',
  'scripts/utilities/agents/AI-AGENT-MANAGEMENT/agent-router.ps1': 'src/agent-router.ts',

  // Proposal
  'scripts/utilities/proposal-executor.ps1': 'src/proposal-executor.ts',

  // Testing
  'scripts/utilities/testing/tests/run-test-suite.ps1': 'src/run-test-suite.ts',
  'scripts/utilities/testing/FINAL-VALIDATION/final-validation.ps1': 'src/final-validation.ts',

  // Hooks checks
  'scripts/hooks/check-architecture.ps1': 'src/hooks/check-architecture.ts',
  'scripts/hooks/check-quality.ps1': 'src/hooks/check-quality.ts',
  'scripts/hooks/check-testing.ps1': 'src/hooks/check-testing.ts',
  'scripts/hooks/check-api.ps1': 'src/hooks/check-api.ts',
  'scripts/hooks/check-documentation.ps1': 'src/hooks/check-documentation.ts',
  'scripts/hooks/check-gitflow.ps1': 'src/hooks/check-gitflow.ts',
  'scripts/hooks/hook-output-safety.ps1': 'src/hooks/hook-output-safety.ts',
  'scripts/hooks/auto-fix-delegate.ps1': 'src/hooks/auto-fix-delegate.ts',

  // Diagnostics
  'scripts/diagnostics/validate-gitflow.ps1': 'src/diagnostics/validate-gitflow.ts',

  // GitHub
  '.github/scripts/setup-branch-protection.ps1': 'src/github/setup-branch-protection.ts',

  // Hashline
  'scripts/hashline.ps1': 'src/hashline.ts',

  // Installer
  'scripts/utilities/INSTALLER/gentle-vanguard-installer-tui.ps1':
    'src/installer/gentle-vanguard-installer-tui.ts',
  'scripts/utilities/INSTALLER/install-prerequisites.ps1': 'src/installer/install-prerequisites.ts',

  // RDD
  'src/rdd/rdd-initializer.ps1': 'src/rdd/rdd-initializer.ts',
  'src/rdd/rdd-risk-classifier.ps1': 'src/rdd/rdd-risk-classifier.ts',

  // Auto-fix
  'scripts/utilities/orchestrate-auto-fix.ps1': 'src/orchestrate-auto-fix.ts',
  'scripts/utilities/orchestrate-auto-fix/auto-fix-delegate.ps1':
    'src/orchestrate-auto-fix/auto-fix-delegate.ts',
  'scripts/utilities/orchestrate-auto-fix/pre-push-script-validator.ps1':
    'src/pre-push-script-validator.ts',
  'scripts/utilities/orchestrate-auto-fix/cross-workspace-validator.ps1':
    'src/cross-workspace-validator.ts',

  // Codegraph
  'scripts/utilities/codegraph/codegraph-post-modification-sync.ps1':
    'src/codegraph-post-modification-sync.ts',

  // Final
  'scripts/utilities/final-resolution.ps1': 'src/final-resolution.ts',

  // Archive/legacy
  'scripts/archive/rotate-artifacts.ps1': null, // Obsoleto
  'scripts/utilities/rotate-artifacts.ps1': null, // Obsoleto
};

// Archivos de configuración a procesar
const CONFIG_FILES = [
  'config/gentle-vanguard-sync.json',
  'config/observability-config.json',
  'config/security-deploy.json',
  'config/system-prompt-tiers.json',
  'config/azure/container-app.json',
  'config/prometheus/prometheus-config.json',
  'config/documentation-governance.json',
  'config/cline-dify-optimized.config.json',
  'config/cline-dify.config.json',
];

interface ChangeLog {
  file: string;
  changes: Array<{ from: string; to: string }>;
  success: boolean;
}

function cleanJsonFile(filePath: string, apply: boolean): ChangeLog {
  const fullPath = join(ROOT, filePath);
  const log: ChangeLog = { file: filePath, changes: [], success: false };

  if (!existsSync(fullPath)) {
    console.warn(`⚠️ No encontrado: ${filePath}`);
    return log;
  }

  let content = readFileSync(fullPath, 'utf-8');
  const originalContent = content;

  // Reemplazar cada patrón conocido
  for (const [ps1Path, tsPath] of Object.entries(PS1_TO_TS)) {
    if (!tsPath) {
      // Marcar como obsoleto
      const escaped = ps1Path.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const regex = new RegExp(`"${escaped}"`, 'g');
      if (content.match(regex)) {
        content = content.replace(regex, `"[DEPRECATED] ${ps1Path} -> removed in TS migration"`);
        log.changes.push({ from: ps1Path, to: '[DEPRECATED]' });
      }
    } else {
      // Reemplazar con TS
      const escaped = ps1Path.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const regex = new RegExp(escaped, 'g');
      if (content.match(regex)) {
        content = content.replace(regex, tsPath);
        log.changes.push({ from: ps1Path, to: tsPath });
      }
    }
  }

  // Reemplazar comandos PowerShell
  const pwshCommands = [
    {
      pattern: /pwsh\s+-NoProfile\s+-Command\s+"&\s+'([^']+\.ps1)'[^"]*"/g,
      replacement: 'npx tsx $1',
    },
    { pattern: /pwsh\s+-NoProfile\s+-File\s+([^\s]+\.ps1)/g, replacement: 'npx tsx $1' },
    { pattern: /powershell\s+-File\s+([^\s]+\.ps1)/g, replacement: 'npx tsx $1' },
    { pattern: /&\s+'\.\/([^']+\.ps1)'/g, replacement: 'npx tsx src/$1' },
  ];

  for (const { pattern, replacement } of pwshCommands) {
    const matches = content.match(pattern);
    if (matches) {
      content = content.replace(pattern, replacement);
      for (const match of matches) {
        log.changes.push({ from: match, to: replacement.replace('$1', '...') });
      }
    }
  }

  log.success = content !== originalContent;

  if (apply && log.success) {
    writeFileSync(fullPath, content, 'utf-8');
  }

  return log;
}

function main() {
  const apply = process.argv.includes('--apply');

  console.log('╔════════════════════════════════════════════════════════╗');
  console.log('║   CONFIG PS1 CLEANER - Limpieza de Configuraciones    ║');
  console.log(
    `║   Modo: ${apply ? 'APLICAR CAMBIOS' : 'SIMULACIÓN (dry-run)'}                          ║`,
  );
  console.log('╚════════════════════════════════════════════════════════╝');
  console.log();

  let totalFiles = 0;
  let modifiedFiles = 0;
  let totalChanges = 0;

  for (const file of CONFIG_FILES) {
    totalFiles++;
    const log = cleanJsonFile(file, apply);

    if (log.changes.length > 0) {
      modifiedFiles++;
      totalChanges += log.changes.length;
      console.log(`\n📄 ${file}`);
      console.log(`   Cambios: ${log.changes.length}`);
      for (const change of log.changes.slice(0, 3)) {
        console.log(`   • ${change.from.slice(0, 50)}...`);
        console.log(`     → ${change.to.slice(0, 50)}...`);
      }
      if (log.changes.length > 3) {
        console.log(`   ... y ${log.changes.length - 3} más`);
      }
    }
  }

  console.log('\n' + '═'.repeat(60));
  console.log(`📊 RESUMEN:`);
  console.log(`   Archivos escaneados: ${totalFiles}`);
  console.log(`   Archivos modificados: ${modifiedFiles}`);
  console.log(`   Total cambios: ${totalChanges}`);
  console.log();

  if (apply) {
    console.log('✅ Cambios aplicados a los archivos de configuración');
  } else {
    console.log('💡 Usa --apply para aplicar los cambios');
  }
}

main();
