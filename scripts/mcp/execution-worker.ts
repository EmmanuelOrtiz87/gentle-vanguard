import { spawn, type ChildProcess } from 'node:child_process';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';
import type { ApprovedCommand } from './skill-execution-policy.js';

export const WORKER_BASELINE = 'restricted' as const;
const WORKER_TIMEOUT_MS = 300_000;
const WORKER_MAX_OUTPUT_BYTES = 10 * 1024 * 1024;
const WORKER_STARTUP_GRACE_MS = 5_000;

export interface ExecutionResult {
  stdout: string;
  stderr: string;
  timedOut: boolean;
  outputLimited: boolean;
}

interface WorkerRequest {
  executable: string;
  args: string[];
  timeoutMs: number;
  maxOutputBytes: number;
  cwd: string;
  env: NodeJS.ProcessEnv;
}

const workerPath = fileURLToPath(import.meta.url);
const tsxLoader = pathToFileURL(createRequire(import.meta.url).resolve('tsx')).href;

function minimalEnvironment(workspace: string): NodeJS.ProcessEnv {
  const env: NodeJS.ProcessEnv = {
    PATH: process.env.PATH,
    SystemRoot: process.env.SystemRoot,
    TEMP: workspace,
    TMP: workspace,
    TMPDIR: workspace,
  };
  return Object.fromEntries(Object.entries(env).filter(([, value]) => value !== undefined));
}

function terminate(child: ChildProcess): void {
  if (!child.killed) child.kill();
}

async function runWorker(request: WorkerRequest): Promise<ExecutionResult> {
  if (request.timeoutMs <= 0 || request.timeoutMs > WORKER_TIMEOUT_MS) {
    throw new Error('Worker timeout is outside the restricted limit');
  }
  if (request.maxOutputBytes <= 0 || request.maxOutputBytes > WORKER_MAX_OUTPUT_BYTES) {
    throw new Error('Worker output limit is outside the restricted limit');
  }

  return await new Promise<ExecutionResult>((resolve, reject) => {
    const child = spawn(request.executable, request.args, {
      cwd: request.cwd,
      env: request.env,
      shell: false,
      windowsHide: true,
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    let stdout = '';
    let stderr = '';
    let outputBytes = 0;
    let timedOut = false;
    let outputLimited = false;
    const timer = setTimeout(() => {
      timedOut = true;
      terminate(child);
    }, request.timeoutMs);

    const collect =
      (target: 'stdout' | 'stderr') =>
      (chunk: Buffer): void => {
        outputBytes += chunk.byteLength;
        if (outputBytes > request.maxOutputBytes) {
          outputLimited = true;
          terminate(child);
          return;
        }
        if (target === 'stdout') stdout += chunk.toString('utf8');
        else stderr += chunk.toString('utf8');
      };
    child.stdout?.on('data', collect('stdout'));
    child.stderr?.on('data', collect('stderr'));
    child.once('error', (error) => {
      clearTimeout(timer);
      reject(error);
    });
    child.once('close', () => {
      clearTimeout(timer);
      resolve({ stdout, stderr, timedOut, outputLimited });
    });
  });
}

async function main(): Promise<void> {
  let input = '';
  for await (const chunk of process.stdin) input += chunk;
  const request = JSON.parse(input) as WorkerRequest;
  const result = await runWorker(request);
  process.stdout.write(JSON.stringify(result));
}

export async function executeApprovedCommand(command: ApprovedCommand): Promise<ExecutionResult> {
  if (command.network === true || command.filesystem === 'broad') {
    throw new Error('MCP execution requires unavailable OS sandbox capabilities');
  }

  const workspace = await mkdtemp(join(tmpdir(), 'gentle-vanguard-mcp-'));
  const request: WorkerRequest = {
    executable: command.executable,
    args: command.args,
    timeoutMs: command.timeoutMs ?? 60_000,
    maxOutputBytes: command.maxOutputBytes ?? 1_048_576,
    cwd: workspace,
    env: minimalEnvironment(workspace),
  };

  return await new Promise<ExecutionResult>((resolve, reject) => {
    const worker = spawn(process.execPath, ['--import', tsxLoader, workerPath, '--worker'], {
      cwd: dirname(workerPath),
      env: minimalEnvironment(workspace),
      shell: false,
      windowsHide: true,
      stdio: ['pipe', 'pipe', 'pipe'],
    });
    let output = '';
    const timer = setTimeout(
      () => worker.kill(),
      (command.timeoutMs ?? 60_000) + WORKER_STARTUP_GRACE_MS,
    );
    worker.stdout.on('data', (chunk: Buffer) => {
      output += chunk.toString('utf8');
      if (Buffer.byteLength(output) > (command.maxOutputBytes ?? 1_048_576) + 1_024) worker.kill();
    });
    worker.stderr.resume();
    worker.once('error', reject);
    worker.once('close', async (code) => {
      clearTimeout(timer);
      for (let attempt = 0; attempt < 5; attempt++) {
        try {
          await rm(workspace, { recursive: true, force: true, maxRetries: 3, retryDelay: 50 });
          break;
        } catch (error) {
          if (attempt === 4) throw error;
          await new Promise((resolve) => setTimeout(resolve, 100 * (attempt + 1)));
        }
      }
      if (code !== 0) reject(new Error('MCP execution worker failed'));
      else {
        try {
          resolve(JSON.parse(output) as ExecutionResult);
        } catch {
          reject(new Error('MCP execution worker returned invalid output'));
        }
      }
    });
    worker.stdin.end(JSON.stringify(request));
  });
}

if (process.argv[2] === '--worker') {
  main().catch((error: unknown) => {
    process.stderr.write(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
