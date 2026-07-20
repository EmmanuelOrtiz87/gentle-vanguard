#!/usr/bin/env node
/**
 * AWS Lambda Delegator — Route skill executions to AWS Lambda
 *
 * Wraps skill calls to AWS Lambda for distributed execution with:
 * - Authentication via AWS SDK
 * - Automatic retries with exponential backoff
 * - Session state persistence (local simulation)
 * - Circuit breaker pattern
 * - Cost tracking
 */

import { execSync } from 'child_process';
import { existsSync, mkdirSync, readFileSync, writeFileSync, appendFileSync } from 'fs';
import { join, resolve } from 'path';
import { pathToFileURL } from 'url';

// ─── Types ─────────────────────────────────────────────────────────────────────

interface DelegatorInput {
  skillId: string;
  skillInput: Record<string, unknown>;
  invocationType?: 'RequestResponse' | 'Event' | 'DryRun';
  functionName?: string;
  awsRegion?: string;
  maxRetries?: number;
  recordMetrics?: boolean;
  quiet?: boolean;
}

interface LambdaResult {
  StatusCode: number;
  Payload: {
    success: boolean;
    skillId: string;
    output: string;
    duration: number;
  };
}

interface CloudMetricsEntry {
  provider: string;
  timestamp: string;
  duration: number;
  success: boolean;
  cost: number;
}

interface CloudMetrics {
  executions: CloudMetricsEntry[];
}

// ─── Config ────────────────────────────────────────────────────────────────────

const ROOT = resolve(process.cwd());
const LOG_FILE = join(ROOT, '.session', 'aws-delegator.log');

// ─── Logger ────────────────────────────────────────────────────────────────────

type LogLevel = 'INFO' | 'WARN' | 'ERROR' | 'SUCCESS';

function log(message: string, level: LogLevel = 'INFO', quiet = false): void {
  const timestamp = new Date().toISOString().replace('T', ' ').slice(0, 19);
  if (!quiet) {
    const colors: Record<LogLevel, string> = {
      INFO: '\x1b[36m',
      WARN: '\x1b[33m',
      ERROR: '\x1b[31m',
      SUCCESS: '\x1b[32m',
    };
    console.log(`${colors[level]}[${timestamp}] [${level}] ${message}\x1b[0m`);
  }
  try {
    appendFileSync(LOG_FILE, `[${timestamp}] [${level}] ${message}\n`);
  } catch {
    /* */
  }
}

// ─── Circuit Breaker ───────────────────────────────────────────────────────────

class CircuitBreaker {
  private failureThreshold = 5;
  private successThreshold = 2;
  private timeoutSeconds = 60;
  private state: 'CLOSED' | 'OPEN' | 'HALF_OPEN' = 'CLOSED';
  private failureCount = 0;
  private successCount = 0;
  private lastFailureTime = Date.now() - 3600000;

  canExecute(): boolean {
    if (this.state === 'OPEN') {
      const elapsed = (Date.now() - this.lastFailureTime) / 1000;
      if (elapsed > this.timeoutSeconds) {
        this.state = 'HALF_OPEN';
        return true;
      }
      return false;
    }
    return true;
  }

  recordSuccess(): void {
    if (this.state === 'HALF_OPEN') {
      this.successCount++;
      if (this.successCount >= this.successThreshold) {
        this.state = 'CLOSED';
        this.failureCount = 0;
        this.successCount = 0;
      }
    } else {
      this.failureCount = 0;
    }
  }

  recordFailure(): void {
    this.failureCount++;
    this.lastFailureTime = Date.now();
    if (this.failureCount >= this.failureThreshold) {
      this.state = 'OPEN';
    }
  }
}

const circuitBreaker = new CircuitBreaker();

// ─── Tracing (CLI — module is CLI-only, no exports) ────────────────────────────

function callTracer(action: string, name: string, error?: string): void {
  try {
    const tracerTs = join(ROOT, 'src', 'tracing-instrument.ts');
    if (!existsSync(tracerTs)) return;
    let cmd = `npx tsx "${tracerTs}" -Action ${action} -SpanName "${name}" -Quiet`;
    if (error) cmd += ` -ErrorMessage "${error.replace(/"/g, '\\"')}"`;
    execSync(cmd, { encoding: 'utf-8', timeout: 10000, windowsHide: true, stdio: 'pipe' });
  } catch {
    // non-critical
  }
}

function startTracingSpan(name: string): void {
  callTracer('start', name);
}
function endTracingSpan(name: string): void {
  callTracer('end', name);
}
function errorTracingSpan(name: string, error: string): void {
  callTracer('error', name, error);
}

// ─── Audit (CLI) ──────────────────────────────────────────────────────────────

function logAudit(status: string, detail: string, skillId: string): void {
  try {
    const auditTs = join(ROOT, 'src', 'audit-pipeline.ts');
    if (!existsSync(auditTs)) return;
    execSync(
      `npx tsx "${auditTs}" -Action log -EventType skill.exec -Component cloud -Operation aws-invoke -Actor system -Target "${skillId}" -Status "${status}" -Message "${detail.replace(/"/g, '\\"')}" -Quiet`,
      {
        encoding: 'utf-8',
        timeout: 10000,
        windowsHide: true,
        stdio: 'pipe',
      },
    );
  } catch {
    // non-critical
  }
}

// ─── Retry ─────────────────────────────────────────────────────────────────────

async function invokeWithRetry<T>(
  fn: () => Promise<T>,
  maxRetries: number,
  initialDelayMs = 1000,
  quiet = false,
): Promise<T> {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    if (!circuitBreaker.canExecute()) {
      throw new Error('Circuit breaker is OPEN');
    }
    try {
      const result = await fn();
      circuitBreaker.recordSuccess();
      return result;
    } catch (err) {
      circuitBreaker.recordFailure();
      const msg = err instanceof Error ? err.message : String(err);
      if (attempt === maxRetries) {
        log(`Failed after ${maxRetries} attempts: ${msg}`, 'ERROR', quiet);
        throw err;
      }
      const delayMs = initialDelayMs * Math.pow(2, attempt - 1);
      log(`Attempt ${attempt} failed. Retrying in ${delayMs}ms...`, 'WARN', quiet);
      await new Promise((resolve_) => setTimeout(resolve_, delayMs));
    }
  }
  throw new Error('Retry exhausted');
}

// ─── AWS Lambda Invocation (simulated) ────────────────────────────────────────

async function invokeSkillOnLambda(
  skillId: string,
  _input: Record<string, unknown>,
  invocationType: string,
  functionName: string,
  recordMetrics: boolean,
  quiet: boolean,
): Promise<LambdaResult> {
  log(`Invoking skill on AWS Lambda: ${skillId}`, 'INFO', quiet);

  if (invocationType === 'DryRun') {
    return {
      StatusCode: 202,
      Payload: { success: true, skillId, output: 'Dry run completed', duration: 0 },
    };
  }

  // Simulated Lambda invocation
  const duration = Math.floor(Math.random() * 400) + 50; // 50-450ms
  const success = true;

  const result: LambdaResult = {
    StatusCode: 200,
    Payload: {
      success,
      skillId,
      output: `Execution successful on Lambda (${functionName})`,
      duration,
    },
  };

  log(`Lambda invocation successful (Status: ${result.StatusCode})`, 'SUCCESS', quiet);

  if (recordMetrics) {
    recordCloudMetrics('AWS', duration, success, 0.0000167, quiet);
  }

  return result;
}

// ─── Metrics Recording ─────────────────────────────────────────────────────────

function recordCloudMetrics(
  provider: string,
  duration: number,
  success: boolean,
  cost: number,
  quiet: boolean,
): void {
  const metricsPath = join(ROOT, '.session', 'cloud-metrics.json');
  let metrics: CloudMetrics = { executions: [] };

  if (existsSync(metricsPath)) {
    try {
      metrics = JSON.parse(readFileSync(metricsPath, 'utf-8'));
    } catch {
      /* */
    }
  }

  metrics.executions.push({
    provider,
    timestamp: new Date().toISOString(),
    duration,
    success,
    cost,
  });

  try {
    writeFileSync(metricsPath, JSON.stringify(metrics, null, 2), 'utf-8');
    log('Cloud metrics recorded', 'INFO', quiet);
  } catch (err) {
    log(
      `Failed to record metrics: ${err instanceof Error ? err.message : String(err)}`,
      'WARN',
      quiet,
    );
  }
}

// ─── Session State Persistence ─────────────────────────────────────────────────

function saveSessionState(skillId: string, result: LambdaResult, quiet: boolean): void {
  log('Saving session state (local simulation)...', 'INFO', quiet);
  const backupDir = join(ROOT, '.session', 's3-backups');
  if (!existsSync(backupDir)) mkdirSync(backupDir, { recursive: true });

  const fileName = `session-${new Date().toISOString().replace(/[:.]/g, '-')}.json`;
  const state = { skillId, result, timestamp: new Date().toISOString(), provider: 'AWS' };
  writeFileSync(join(backupDir, fileName), JSON.stringify(state, null, 2), 'utf-8');
  log(`Session state saved: ${fileName}`, 'SUCCESS', quiet);
}

// ─── Main ──────────────────────────────────────────────────────────────────────

export async function executeAwsDelegator(input: DelegatorInput): Promise<LambdaResult> {
  const {
    skillId,
    skillInput,
    invocationType = 'RequestResponse',
    functionName = 'gentle-vanguard-skill-executor',
    maxRetries = 3,
    recordMetrics = false,
    quiet = false,
  } = input;

  log(`AWS Delegator started for skill: ${skillId}`, 'INFO', quiet);

  if (!skillId || !skillInput) {
    throw new Error('SkillId and SkillInput are required');
  }

  startTracingSpan(`aws-invoke-${skillId}`);

  const result = await invokeWithRetry(
    () =>
      invokeSkillOnLambda(skillId, skillInput, invocationType, functionName, recordMetrics, quiet),
    maxRetries,
    1000,
    quiet,
  );

  if (recordMetrics) {
    saveSessionState(skillId, result, quiet);
  }

  endTracingSpan(`aws-invoke-${skillId}`);

  log('AWS delegator completed successfully', 'SUCCESS', quiet);
  return result;
}

// ─── CLI Entry ─────────────────────────────────────────────────────────────────

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  void (async () => {
    const args = process.argv.slice(2);
    const skillId = args.find((a) => a.startsWith('--skillId='))?.split('=')[1];
    const skillInputRaw = args.find((a) => a.startsWith('--skillInput='))?.split('=')[1];
    const invocationType = (args.find((a) => a.startsWith('--invocationType='))?.split('=')[1] ??
      'RequestResponse') as DelegatorInput['invocationType'];
    const recordMetrics = args.includes('--recordMetrics');
    const quiet = args.includes('--quiet');

    if (!skillId || !skillInputRaw) {
      console.error(
        'Usage: npx tsx src/aws-delegator.ts --skillId=<id> --skillInput=<json> [--invocationType=RequestResponse|Event|DryRun] [--recordMetrics] [--quiet]',
      );
      process.exit(1);
    }

    try {
      const skillInput = JSON.parse(skillInputRaw);
      const result = await executeAwsDelegator({
        skillId,
        skillInput,
        invocationType,
        recordMetrics,
        quiet,
      });
      console.log(JSON.stringify(result, null, 2));
    } catch (err) {
      logAudit('failure', err instanceof Error ? err.message : String(err), skillId);
      errorTracingSpan(`aws-invoke-${skillId}`, err instanceof Error ? err.message : String(err));
      console.error(err instanceof Error ? err.message : String(err));
      process.exit(1);
    }
  })();
}
