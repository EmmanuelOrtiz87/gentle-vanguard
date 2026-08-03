#!/usr/bin/env node
import { appendFileSync, mkdirSync, readFileSync, existsSync, writeFileSync, unlinkSync } from 'fs';
import { join, resolve } from 'path';
import { execSync, spawn, type ChildProcess } from 'child_process';
import { getPipelineTimeouts } from './timeout-config';
import { log as createLogger } from '../utils/logger.js';
import { printBanner } from '../cli/banner.js';

const LOG = createLogger('SESSION-AUTOSTART');

// ─── Optional output redirection ──────────────────────────────────────────
// The detached launcher (session-autostart-detached.ts) sets AUTOSTART_LOG_FILE
// so the pipeline run is observable even though nothing is written to the
// caller's pipe. We redirect ALL console output to that file natively (no
// reliance on cmd.exe `>` redirection, which breaks under detached process
// groups on Windows). Uses appendFileSync (synchronous) so every line survives
// the final `process.exit(0)` — an async stream would lose buffered lines.
const AUTOSTART_LOG_FILE = process.env.AUTOSTART_LOG_FILE;
if (AUTOSTART_LOG_FILE) {
  const mirror = (...args: unknown[]): void => {
    try { appendFileSync(AUTOSTART_LOG_FILE, args.map(String).join(' ') + '\n', 'utf-8'); } catch { /* best-effort */ }
  };
  console.log = (...args: unknown[]) => mirror(...args);
  console.warn = (...args: unknown[]) => mirror(...args);
  console.error = (...args: unknown[]) => mirror(...args);
}

// ─── Lock file: prevent running session-autostart more than once ──────

const LOCK_FILE = join(resolve(process.cwd()), '.runtime', 'session-autostart.lock');

/**
 * Robust lock-owner liveness check.
 *
 * `process.kill(pid, 0)` only verifies that SOME process exists with that PID.
 * On Windows, an orphaned `conhost.exe` (console host of a previously detached
 * run) or a recycled PID can keep that check true and block the pipeline with
 * a spurious "[LOCK] already running" skip.
 *
 * This verifies the PID actually belongs to a `node` process whose command
 * line references `session-autostart` before treating the lock as live.
 * Any ambiguity resolves to "stale" (proceed), matching the lock's intent of
 * preventing accidental duplicates while never wedging the pipeline.
 */
function isLockOwnerAlive(pid: number): boolean {
  if (!Number.isInteger(pid) || pid <= 0) return false;
  try {
    process.kill(pid, 0); // signal 0 = test existence
  } catch {
    return false; // no such process -> stale
  }
  // PID exists; on Windows confirm it is a node process running session-autostart.
  if (process.platform === 'win32') {
    try {
      const cmd = execSync(
        `powershell -NoProfile -Command "(Get-CimInstance Win32_Process -Filter \\"ProcessId=${pid}\\").CommandLine"`,
        { encoding: 'utf-8', windowsHide: true, timeout: 5000, stdio: ['ignore', 'pipe', 'ignore'] },
      ).trim();
      if (!cmd) return false; // no command line info -> treat as stale
      return /node(\.exe)?/i.test(cmd) && /session-autostart/i.test(cmd);
    } catch {
      return false; // powershell unavailable/failed -> treat as stale (safe to proceed)
    }
  }
  return true; // non-Windows: plain existence check is sufficient
}

function checkLock(): boolean {
  try {
    if (existsSync(LOCK_FILE)) {
      const pid = parseInt(readFileSync(LOCK_FILE, 'utf-8').trim(), 10);
      if (isLockOwnerAlive(pid)) {
        LOG.info(`[LOCK] Session-autostart already running (PID ${pid}). Skipping duplicate.`);
        return false;
      }
      // Owner is dead or not a real session-autostart process — lockfile is stale, remove it
      try { unlinkSync(LOCK_FILE); } catch { /* ignore */ }
    }
    writeFileSync(LOCK_FILE, String(process.pid), 'utf-8');
    return true;
  } catch {
    return true; // If lock fails, proceed anyway
  }
}

// ─── Types ────────────────────────────────────────────────────────────

interface PipelineStep {
  id: string;
  script: string;
  args?: string;
  required?: boolean;
  phase?: number;
  lazy?: boolean;
  enabled?: boolean;
  description?: string;
}

interface PipelineConfig {
  pipeline: {
    steps: PipelineStep[];
  };
}

const ROOT = resolve(process.cwd());
const CONFIG_PATH = join(ROOT, 'config', 'session-autostart.config.json');
const LOG_DIR = join(ROOT, 'logs');
const LAZY_LOG_PATH = join(LOG_DIR, 'session-autostart-lazy.log');

// Max concurrent lazy steps to prevent spawning 56 processes at once
const MAX_LAZY_CONCURRENCY = 5;

function loadConfig(): PipelineConfig {
  try {
    const raw = readFileSync(CONFIG_PATH, 'utf-8');
    return JSON.parse(raw);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    LOG.error(`[SESSION-AUTOSTART] Failed to load config: ${msg}`);
    return { pipeline: { steps: [] } };
  }
}

/**
 * Build shell command string.
 * On Windows, must use `shell: true` for npx.cmd batch files.
 * windowsHide: true is enforced at the spawn() call site.
 */
function buildStepCommand(step: PipelineStep): string {
  const scriptPath = join(ROOT, step.script);
  let cmd: string;
  if (scriptPath.endsWith('.ps1')) {
    cmd = `pwsh -NoProfile -File "${scriptPath}"`;
  } else if (scriptPath.endsWith('.ts')) {
    cmd = `npx tsx "${scriptPath}"`;
  } else {
    cmd = `"${scriptPath}"`;
  }
  if (step.args) cmd += ` ${step.args}`;
  return cmd;
}

function killProcessTree(child: ChildProcess): void {
  if (!child.pid) return;
  if (process.platform === 'win32') {
    spawn('taskkill', ['/pid', String(child.pid), '/t', '/f'], {
      cwd: ROOT,
      stdio: 'ignore',
      windowsHide: true,      // ✅ hide taskkill window
    });
    return;
  }
  child.kill('SIGTERM');
}

function executeStep(step: PipelineStep, timeoutMs: number): Promise<{ success: boolean; error?: string }> {
  const scriptPath = join(ROOT, step.script);

  if (!existsSync(scriptPath)) {
    return Promise.resolve({ success: false, error: `Script not found: ${step.script}` });
  }

  return new Promise((resolvePromise) => {
    const cmd = buildStepCommand(step);

    // shell:true is required on Windows for npx.cmd batch files.
    // windowsHide:true ensures no flashing cmd.exe windows.
    const spawnOptions: import('child_process').SpawnOptions = {
      cwd: ROOT,
      stdio: 'inherit',       // show output in parent console
      windowsHide: true,      // ✅ CRITICAL: hide window on Windows
      shell: true,            // required for npx.cmd on Windows
    };

    const child = spawn(cmd, [], spawnOptions);
    let settled = false;
    const timer = setTimeout(() => {
      if (settled) return;
      settled = true;
      killProcessTree(child);
      resolvePromise({ success: false, error: `Timeout after ${timeoutMs}ms` });
    }, timeoutMs);

    child.on('close', (code) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      resolvePromise({ success: code === 0 });
    });
    child.on('error', (err) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      resolvePromise({ success: false, error: err.message });
    });
  });
}

/**
 * Start a lazy step with windowsHide:true.
 * Lazy steps are batched to avoid spawning 56 processes simultaneously.
 */
function startLazyStep(step: PipelineStep): { success: boolean; error?: string } {
  const scriptPath = join(ROOT, step.script);
  if (!existsSync(scriptPath)) {
    return { success: false, error: `Script not found: ${step.script}` };
  }

  mkdirSync(LOG_DIR, { recursive: true });
  appendFileSync(
    LAZY_LOG_PATH,
    `[${new Date().toISOString()}] starting ${step.id}: ${buildStepCommand(step)}\n`,
    'utf-8',
  );

  const cmd = buildStepCommand(step);
  const child = spawn(cmd, [], {
    cwd: ROOT,
    stdio: 'ignore',
    windowsHide: true,       // ✅ CRITICAL: no flashing window
    shell: true,             // required for npx.cmd on Windows
    detached: true,          // ✅ CRITICAL: detach from parent console/pipe so lazy
                             //   daemons (setInterval watchers) never keep the
                             //   calling shell waiting on an open stdout pipe.
  });
  child.unref();
  return { success: true };
}

async function main() {
  // Lock check: only run once per OS user session
  if (!checkLock()) return;

  if (!process.env.GV_QUIET) printBanner('Session Autostart');
  LOG.info(`[SESSION-AUTOSTART] Loading pipeline from ${CONFIG_PATH}\n`);

  const timeoutConfig = getPipelineTimeouts();
  const config = loadConfig();
  const allSteps = config.pipeline.steps.filter((s) => s.enabled === true);
  const steps = allSteps.filter((s) => !s.lazy);
  const lazySteps = allSteps.filter((s) => s.lazy);

  const totalSteps = steps.length;
  let stepNum = 0;
  const failed: string[] = [];
  const requiredFailed: string[] = [];

  LOG.info(`[INFO] Pipeline steps: ${totalSteps} enabled (phased parallel)`);
  if (lazySteps.length > 0) {
    LOG.info(`[INFO] ${lazySteps.length} lazy steps deferred to background\n`);
  }

  const phaseMap = new Map<number, PipelineStep[]>();
  for (const step of steps) {
    const phase = step.phase ?? 1;
    if (!phaseMap.has(phase)) phaseMap.set(phase, []);
    phaseMap.get(phase)?.push(step);
  }

  const sortedPhases = [...phaseMap.entries()].sort(([a], [b]) => a - b);

  for (const [phaseNum, phaseSteps] of sortedPhases) {
    if (phaseNum === 0) {
      for (const step of phaseSteps) {
        stepNum++;
        const isRequired = step.required === true;
        const timeoutMs = isRequired
          ? timeoutConfig.required_step_ms ?? timeoutConfig.session_autostart_step_ms
          : timeoutConfig.session_autostart_step_ms;
        const result = await executeStep(step, timeoutMs);
        if (result.success) {
          LOG.info(`[${stepNum}/${totalSteps}] [OK] ${step.id} completed`);
        } else {
          const errMsg = result.error || 'Failed';
          LOG.info(`[${stepNum}/${totalSteps}] [WARNING] ${step.id}: ${errMsg}`);
          failed.push(step.id);
          if (isRequired) requiredFailed.push(step.id);
        }
        if (isRequired && !result.success) break;
      }
    } else {
      LOG.info(`--- Phase ${phaseNum} (${phaseSteps.length} steps in parallel) ---`);
      for (const step of phaseSteps) {
        stepNum++;
        LOG.info(`[${stepNum}/${totalSteps}] ${step.id}...`);
      }

      const results = await Promise.allSettled(
        phaseSteps.map((step) => {
          const timeoutMs = step.required === true
            ? timeoutConfig.required_step_ms ?? timeoutConfig.session_autostart_step_ms
            : timeoutConfig.session_autostart_step_ms;
          return executeStep(step, timeoutMs);
        }),
      );

      for (let i = 0; i < phaseSteps.length; i++) {
        const step = phaseSteps[i];
        const result = results[i];
        const isRequired = step.required === true;
        if (result.status === 'fulfilled' && result.value.success) {
          LOG.info(`  [OK] ${step.id} completed`);
        } else {
          const errMsg =
            result.status === 'rejected'
              ? result.reason?.message || 'Rejected'
              : result.value?.error || 'Failed';
          LOG.info(`  [WARNING] ${step.id}: ${errMsg}`);
          failed.push(step.id);
          if (isRequired) requiredFailed.push(step.id);
        }
      }
    }

    if (requiredFailed.length > 0) break;
  }

  if (lazySteps.length > 0) {
    LOG.info(`\n=== Starting Lazy Steps (batch=${MAX_LAZY_CONCURRENCY}) ===`);
    let launched = 0;
    for (let i = 0; i < lazySteps.length; i += MAX_LAZY_CONCURRENCY) {
      const batch = lazySteps.slice(i, i + MAX_LAZY_CONCURRENCY);
      for (const step of batch) {
        const result = startLazyStep(step);
        if (result.success) {
          launched++;
          LOG.info(`  [OK] ${step.id} (lazy started)`);
        } else {
          LOG.info(`  [WARN] ${step.id} (lazy): ${result.error || 'Failed'}`);
        }
      }
      // Small delay between batches to avoid overwhelming the OS
      if (i + MAX_LAZY_CONCURRENCY < lazySteps.length) {
        await new Promise(r => setTimeout(r, 100));
      }
    }
    LOG.info(`[INFO] Lazy step launch log: ${LAZY_LOG_PATH}`);
    LOG.info(`[INFO] Launched ${launched}/${lazySteps.length} lazy steps in batches of ${MAX_LAZY_CONCURRENCY}`);
  }

  LOG.info(`\n=== Session Autostart Summary ===`);
  LOG.info(`Steps executed: ${stepNum}`);
  LOG.info(`Lazy steps:     ${lazySteps.length}`);
  LOG.info(`Steps failed:   ${failed.length}`);
  LOG.info(`Required fails: ${requiredFailed.length}`);

  if (requiredFailed.length > 0) {
    LOG.error(`[ERROR] Required steps failed: ${requiredFailed.join(', ')}`);
    LOG.info(`[ACTION] Fix the issues above and re-run session autostart.`);
    process.exit(1);
  }

  if (failed.length > 0) {
    LOG.info(`[WARNING] Non-required steps with issues: ${failed.join(', ')}`);
  }

  LOG.info(`[READY] Workspace ready for operations`);

  // CRITICAL: Force explicit exit. Lazy steps are fire-and-forget background
  // processes; on Windows (shell:true) their grandchildren can inherit stdout
  // handles, keeping this process alive and blocking callers (CI, hooks, shells).
  // Exiting explicitly releases the pipe and avoids artificial timeouts.
  process.exit(0);
}

main().catch((err) => {
  LOG.error('[SESSION-AUTOSTART] Fatal error:', err);
  process.exit(1);
});
