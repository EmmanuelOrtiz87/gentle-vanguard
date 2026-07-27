#!/usr/bin/env node
import { appendFileSync, mkdirSync, readFileSync, existsSync } from 'fs';
import { join, resolve } from 'path';
import { spawn, type ChildProcess } from 'child_process';
import { getPipelineTimeouts } from './timeout-config';

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

function loadConfig(): PipelineConfig {
  try {
    const raw = readFileSync(CONFIG_PATH, 'utf-8');
    return JSON.parse(raw);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error(`[SESSION-AUTOSTART] Failed to load config: ${msg}`);
    return { pipeline: { steps: [] } };
  }
}

function buildStepCommand(scriptPath: string, step: PipelineStep): string {
  if (scriptPath.endsWith('.ps1')) {
    return `pwsh -NoProfile -File "${scriptPath}" ${step.args || ''}`;
  }
  if (scriptPath.endsWith('.ts')) {
    return `npx tsx "${scriptPath}" ${step.args || ''}`;
  }
  return `"${scriptPath}" ${step.args || ''}`;
}

function killProcessTree(child: ChildProcess): void {
  if (!child.pid) return;
  if (process.platform === 'win32') {
    spawn('taskkill', ['/pid', String(child.pid), '/t', '/f'], {
      cwd: ROOT,
      stdio: 'ignore',
      windowsHide: true,
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
    const spawnOptions: import('child_process').SpawnOptions = {
      cwd: ROOT,
      stdio: 'inherit',
      shell: true,
      windowsHide: true,
    };

    const child = spawn(buildStepCommand(scriptPath, step), [], spawnOptions);
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

function startLazyStep(step: PipelineStep): { success: boolean; error?: string } {
  const scriptPath = join(ROOT, step.script);
  if (!existsSync(scriptPath)) {
    return { success: false, error: `Script not found: ${step.script}` };
  }

  mkdirSync(LOG_DIR, { recursive: true });
  appendFileSync(
    LAZY_LOG_PATH,
    `[${new Date().toISOString()}] starting ${step.id}: ${buildStepCommand(scriptPath, step)}\n`,
    'utf-8',
  );

  const child = spawn(buildStepCommand(scriptPath, step), [], {
    cwd: ROOT,
    stdio: 'ignore',
    shell: true,
    detached: true,
    windowsHide: true,
  });
  child.unref();
  return { success: true };
}

async function main() {
  console.log(`[SESSION-AUTOSTART] Loading pipeline from ${CONFIG_PATH}\n`);

  const timeoutConfig = getPipelineTimeouts();
  const config = loadConfig();
  const allSteps = config.pipeline.steps.filter((s) => s.enabled === true);
  const steps = allSteps.filter((s) => !s.lazy);
  const lazySteps = allSteps.filter((s) => s.lazy);

  const totalSteps = steps.length;
  let stepNum = 0;
  const failed: string[] = [];
  const requiredFailed: string[] = [];

  console.log(`[INFO] Pipeline steps: ${totalSteps} enabled (phased parallel)`);
  if (lazySteps.length > 0) {
    console.log(`[INFO] ${lazySteps.length} lazy steps deferred to background\n`);
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
          console.log(`[${stepNum}/${totalSteps}] [OK] ${step.id} completed`);
        } else {
          const errMsg = result.error || 'Failed';
          console.log(`[${stepNum}/${totalSteps}] [WARNING] ${step.id}: ${errMsg}`);
          failed.push(step.id);
          if (isRequired) requiredFailed.push(step.id);
        }
        if (isRequired && !result.success) break;
      }
    } else {
      console.log(`--- Phase ${phaseNum} (${phaseSteps.length} steps in parallel) ---`);
      for (const step of phaseSteps) {
        stepNum++;
        console.log(`[${stepNum}/${totalSteps}] ${step.id}...`);
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
          console.log(`  [OK] ${step.id} completed`);
        } else {
          const errMsg =
            result.status === 'rejected'
              ? result.reason?.message || 'Rejected'
              : result.value?.error || 'Failed';
          console.log(`  [WARNING] ${step.id}: ${errMsg}`);
          failed.push(step.id);
          if (isRequired) requiredFailed.push(step.id);
        }
      }
    }

    if (requiredFailed.length > 0) break;
  }

  if (lazySteps.length > 0) {
    console.log(`\n=== Starting Lazy Steps ===`);
    for (const step of lazySteps) {
      const result = startLazyStep(step);
      if (result.success) {
        console.log(`  [OK] ${step.id} (lazy started)`);
      } else {
        console.log(`  [WARN] ${step.id} (lazy): ${result.error || 'Failed'}`);
      }
    }
    console.log(`[INFO] Lazy step launch log: ${LAZY_LOG_PATH}`);
  }

  console.log(`\n=== Session Autostart Summary ===`);
  console.log(`Steps executed: ${stepNum}`);
  console.log(`Lazy steps:     ${lazySteps.length}`);
  console.log(`Steps failed:   ${failed.length}`);
  console.log(`Required fails: ${requiredFailed.length}`);

  if (requiredFailed.length > 0) {
    console.error(`[ERROR] Required steps failed: ${requiredFailed.join(', ')}`);
    console.log(`[ACTION] Fix the issues above and re-run session autostart.`);
    process.exit(1);
  }

  if (failed.length > 0) {
    console.log(`[WARNING] Non-required steps with issues: ${failed.join(', ')}`);
  }

  console.log(`[READY] Workspace ready for operations`);
}

main().catch((err) => {
  console.error('[SESSION-AUTOSTART] Fatal error:', err);
  process.exit(1);
});
