import { mkdirSync, writeFileSync } from 'fs';
import { join } from 'path';
import { guardianCheck, learnFromMistake } from '../session-close-guardian.js';
import { PhaseResult, LOG, log, ok, warn, SESSION_DIR, runScript } from './helpers.js';
import { isStartupClose } from './process.js';
import {
  phasePreClose,
  phasePreValidate,
  phasePersist,
  phaseBackup,
  phaseAudit,
  phaseCleanup,
  phaseVerify,
} from './phases.js';

// ─── Orchestrator ───────────────────────────────────────────────────────────────

export interface CloseReport {
  timestamp: string;
  reason: string;
  totalPhases: number;
  passed: number;
  failed: number;
  skipped: number;
  phases: {
    preClose: PhaseResult[];
    preValidate: PhaseResult[];
    persist: PhaseResult[];
    backup: PhaseResult[];
    audit: PhaseResult[];
    cleanup: PhaseResult[];
    verify: PhaseResult[];
  };
  validationScore?: number;
  overall: 'PASS' | 'PASS_WITH_WARNINGS' | 'FAIL';
}

export async function runCloseOrchestrator(reason = 'session-end'): Promise<CloseReport> {
  log('═══════════════════════════════════════════');
  log('  SESSION CLOSE ORCHESTRATOR v2.0');
  log(`  Reason: ${reason}`);
  log('═══════════════════════════════════════════');

  // Run pre-validation (Capa 1 — always)
  const preValidateResults = phasePreValidate();

  const isStartup = isStartupClose(reason);
  if (isStartup) log('[STARTUP] Skipping daemon-kill phase (autostart-close)');

  const phases = {
    preClose: phasePreClose(reason),
    preValidate: preValidateResults,
    persist: await phasePersist(reason),
    backup: phaseBackup(),
    audit: phaseAudit(),
    cleanup: await phaseCleanup(isStartup),
    verify: phaseVerify(),
  };

  const allResults = [
    ...phases.preClose,
    ...phases.preValidate,
    ...phases.persist,
    ...phases.backup,
    ...phases.audit,
    ...phases.cleanup,
    ...phases.verify,
  ];

  const passed = allResults.filter((r) => r.status === 'PASS').length;
  const failed = allResults.filter((r) => r.status === 'FAIL').length;
  const skipped = allResults.filter((r) => r.status === 'SKIP').length;

  let overall: CloseReport['overall'] = 'PASS';
  if (failed > 0) overall = 'FAIL';
  else if (skipped > 0 && passed > 0) overall = 'PASS_WITH_WARNINGS';

  // Calculate validation score (0-100) from pre-validate results
  const validationScore =
    preValidateResults.length > 0
      ? Math.round(
          (preValidateResults.filter((r) => r.status === 'PASS').length /
            preValidateResults.length) *
            100,
        )
      : undefined;

  log('═══════════════════════════════════════════');
  log(`  RESULTS: ${passed} PASS / ${failed} FAIL / ${skipped} SKIP`);
  log(`  VALIDATION: ${validationScore !== undefined ? `${validationScore}/100` : 'N/A'}`);
  log(`  OVERALL: ${overall}`);
  log('═══════════════════════════════════════════');

  for (const r of allResults) {
    const icon = r.status === 'PASS' ? '✅' : r.status === 'FAIL' ? '❌' : '⏭️';
    console.log(`  ${icon} [${r.phase}] ${r.detail}`);
  }

  if (overall === 'FAIL') {
    warn('Some phases failed. Review the details above.');
  }

  return {
    timestamp: new Date().toISOString(),
    reason,
    totalPhases: allResults.length,
    passed,
    failed,
    skipped,
    phases,
    validationScore,
    overall,
  };
}

// ─── CLI ────────────────────────────────────────────────────────────────────────

export async function main() {
  const args = process.argv.slice(2);

  // ─── Guardian Protection ────────────────────────────────────────────────────
  // Detect previous informal close attempts before proceeding with the official
  // close protocol. If a prior informal attempt is detected, record the learning
  // so the pattern is registered for future sessions.
  const guardian = guardianCheck();
  if (!guardian.passed) {
    learnFromMistake(
      `Orchestrator invoked after informal close attempt: ${guardian.warning || 'unknown reason'}`,
    );
  }

  // Lightweight mode for session-start cleanup (skip pre-validate, backup, audit, verify)
  if (args.includes('--lightweight') || args.includes('-l')) {
    let reason = 'startup-cleanup';
    for (let i = 0; i < args.length; i++) {
      if (args[i] === '--reason' && i + 1 < args.length) reason = args[++i];
    }
    // Run only the essential startup-cleanup phases
    phasePreClose(reason);
    await phasePersist(reason);
    const cleanupResults = await phaseCleanup(isStartupClose(reason));
    const passed = cleanupResults.filter((r) => r.status === 'PASS').length;
    const failed = cleanupResults.filter((r) => r.status === 'FAIL').length;
    ok(`Lightweight cleanup: ${passed} pass, ${failed} fail`);
    process.exit(failed > 0 ? 1 : 0);
  }

  if (args.includes('--verify') || args.includes('-v')) {
    log('Running verification-only mode...');
    const verifyResults = phaseVerify();
    log('═══════════════════════════════════════════');
    log('  VERIFICATION RESULTS');
    log('═══════════════════════════════════════════');
    for (const r of verifyResults) {
      const icon = r.status === 'PASS' ? '✅' : r.status === 'FAIL' ? '❌' : '⏭️';
      LOG.info(`  ${icon} [${r.phase}] ${r.detail}`);
    }
    const allPass = verifyResults.every((r) => r.status === 'PASS');
    LOG.info(`\n  Overall: ${allPass ? '✅ ALL PASS' : '❌ SOME FAILURES'}`);
    process.exit(allPass ? 0 : 1);
  }

  let reason = 'session-end';
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--reason' && i + 1 < args.length) reason = args[++i];
  }

  const report = await runCloseOrchestrator(reason);

  // Write report
  mkdirSync(SESSION_DIR, { recursive: true });
  const reportFile = join(
    SESSION_DIR,
    `close-report-${new Date().toISOString().slice(0, 16).replace(/[:-]/g, '')}.json`,
  );
  writeFileSync(reportFile, JSON.stringify(report, null, 2));
  ok(`Report written to ${reportFile}`);

  // If --validate, run deep validator as spawned process (non-blocking if lazy)
  if (args.includes('--validate')) {
    const validateMode = args.includes('--deep')
      ? 'deep'
      : args.includes('--full')
        ? 'full'
        : 'quick';
    const dryRun = args.includes('--dry-run');
    const autoFix = args.includes('--auto-fix');
    log(`Invoking session-close-validator (mode: ${validateMode})...`);
    const vr = runScript(
      'src/session/session-close-validator.ts',
      [
        '--mode',
        validateMode,
        ...(dryRun ? ['--dry-run'] : []),
        ...(autoFix ? ['--auto-fix'] : []),
        '--report',
      ],
      120000,
    );
    if (vr.status === 0) ok('Deep validation passed');
    else warn(`Deep validation finished with exit code ${vr.status}`);
  }

  process.exit(report.overall === 'FAIL' ? 1 : 0);
}
