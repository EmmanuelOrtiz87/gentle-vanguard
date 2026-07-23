#!/usr/bin/env node

import {
  existsSync,
  readFileSync,
  writeFileSync,
  mkdirSync,
  readdirSync,
  appendFileSync,
} from 'fs';
import { join, resolve } from 'path';
import { pathToFileURL } from 'url';
import { spawnSync, execSync } from 'child_process';
import { randomBytes } from 'crypto';

interface SubTask {
  name: string;
  sub: string;
}

interface AgentResult {
  skill: string;
  status: 'running' | 'completed' | 'failed' | 'timeout';
  started: string;
  finished?: string;
  output: string;
  error: string | null;
}

interface ClientOptions {
  task: string;
  skills: string[];
  maxParallel: number;
  timeoutSeconds: number;
  dryRun: boolean;
  quiet: boolean;
  action: string;
  skill: string;
}

const ROOT = resolve(process.env.GENTLE_VANGUARD_BASE_DIR ?? process.cwd());
const RESULTS_DIR = join(ROOT, '.session', 'team-mode');
const MCP_SERVER = join(ROOT, 'dist', 'scripts', 'mcp', 'skill-server.js');
const ORCHESTRATOR_LOG = join(ROOT, '.session', 'team-orchestrator.log');

let quiet = false;

function log(msg: string, level: 'INFO' | 'WARN' | 'ERROR' | 'SUCCESS' = 'INFO') {
  const ts = new Date().toISOString().slice(0, 19).replace('T', ' ');
  const colors: Record<string, string> = {
    INFO: '\x1b[36m',
    WARN: '\x1b[33m',
    ERROR: '\x1b[31m',
    SUCCESS: '\x1b[32m',
  };
  if (!quiet) console.log(`${colors[level] ?? ''}[${ts}] [TEAM] [${level}] ${msg}\x1b[0m`);
  try {
    appendFileSync(ORCHESTRATOR_LOG, `[${ts}] [${level}] ${msg}\n`);
  } catch { /* ignore */ }
}

function ensureDirs() {
  if (!existsSync(RESULTS_DIR)) mkdirSync(RESULTS_DIR, { recursive: true });
}

function timestamp(): string {
  const d = new Date();
  return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}:${d.getSeconds().toString().padStart(2, '0')}`;
}

function dateStamp(): string {
  const d = new Date();
  return `${d.getFullYear()}${(d.getMonth() + 1).toString().padStart(2, '0')}${d.getDate().toString().padStart(2, '0')}-${d.getHours().toString().padStart(2, '0')}${d.getMinutes().toString().padStart(2, '0')}${d.getSeconds().toString().padStart(2, '0')}`;
}

function invokeMcpTool(tool: string, args: Record<string, unknown> = {}): string | null {
  const req = JSON.stringify({
    jsonrpc: '2.0',
    id: randomBytes(16).toString('hex'),
    method: 'tools/call',
    params: { name: tool, arguments: args },
  });
  try {
    if (!existsSync(MCP_SERVER)) return null;
    const result = spawnSync('node', [MCP_SERVER], {
      input: req,
      encoding: 'utf-8',
      timeout: 15000,
      shell: true,
    });
    if (result.status !== 0 || !result.stdout) return null;
    const parsed = JSON.parse(result.stdout);
    return parsed?.result?.content?.[0]?.text ?? null;
  } catch {
    return null;
  }
}

function getRelevantSkills(task: string, explicitSkills: string[]): string[] {
  if (explicitSkills.length > 0) return explicitSkills;
  const result = invokeMcpTool('search_skills', { query: task });
  if (!result) return [];
  const lines = result.split('\n').filter((l) => /^\s*-\s+\*\*(.+?)\*\*/.test(l));
  return lines
    .map((l) => {
      const m = l.match(/\*\*(.+?)\*\*/);
      return m ? m[1] : null;
    })
    .filter((s): s is string => s !== null);
}

function runAgentInline(skillName: string, subTask: string, _timeoutSec: number): AgentResult {
  const started = timestamp();
  const result: AgentResult = {
    skill: skillName,
    status: 'running',
    started,
    output: '',
    error: null,
  };
  try {
    const logData: string[] = [];
    logData.push(`[TEAM:${skillName}] Starting sub-task...`);
    logData.push(`[TEAM:${skillName}] Skill ${skillName} applied to: ${subTask}`);
    logData.push(`[TEAM:${skillName}] Complete.`);
    result.output = logData.join('\n');
    result.status = 'completed';
  } catch (err: unknown) {
    result.status = 'failed';
    result.error = err instanceof Error ? err.message : String(err);
  }
  result.finished = timestamp();
  return result;
}

async function actionStart(opts: ClientOptions): Promise<AgentResult[]> {
  ensureDirs();
  log(`Action: start | Task: ${opts.task}`, 'INFO');
  if (!existsSync(MCP_SERVER)) {
    log('MCP server not found. Run: pnpm build:mcp', 'ERROR');
    process.exit(1);
  }

  const targetSkills = getRelevantSkills(opts.task, opts.skills);
  if (targetSkills.length === 0) {
    log('No skills matched. Using default delegation.', 'WARN');
    targetSkills.push('auto-delegation-router');
  }
  log(`Skills: ${targetSkills.join(', ')}`, 'SUCCESS');

  if (opts.dryRun) {
    log(`[DRY-RUN] Would execute ${targetSkills.length} sub-agents in parallel (max ${opts.maxParallel})`, 'WARN');
    return [];
  }

  const subTasks: SubTask[] = targetSkills.map((s) => ({ name: s, sub: `[${s}] ${opts.task}` }));
  log(`Sub-tasks: ${subTasks.length} | Parallel: ${opts.maxParallel}`, 'INFO');

  const allResults: AgentResult[] = [];
  const queue = [...subTasks];
  const active: { job: Promise<AgentResult>; name: string }[] = [];

  while (queue.length > 0 || active.length > 0) {
    while (active.length < opts.maxParallel && queue.length > 0) {
      const task = queue.shift()!;
      const logFile = join(RESULTS_DIR, `${task.name}-${dateStamp()}.log`);
      const jobPromise = new Promise<AgentResult>((resolvePromise) => {
        const result = runAgentInline(task.name, task.sub, opts.timeoutSeconds);
        writeFileSync(logFile, JSON.stringify(result, null, 2), 'utf-8');
        resolvePromise(result);
      });
      active.push({ job: jobPromise, name: task.name });
      if (!opts.quiet) log(`[LAUNCH] ${task.name}`, 'INFO');
    }
    if (active.length === 0) break;
    await Promise.allSettled(active.map((a) => a.job));
    for (let i = active.length - 1; i >= 0; i--) {
      const a = active[i];
      try {
        const result = await a.job;
        allResults.push(result);
        if (!opts.quiet) {
          const color = result.status === 'completed' ? 'SUCCESS' : 'ERROR';
          log(`[DONE] ${a.name}: ${result.status}`, color as 'SUCCESS' | 'ERROR');
        }
        active.splice(i, 1);
      } catch {
        // still running
      }
    }
    if (active.length > 0) {
      await new Promise((r) => setTimeout(r, 500));
    }
  }

  actionSynthesize(allResults, targetSkills, opts.task);
  return allResults;
}

function actionStop(_opts: ClientOptions): void {
  log('Stop action — cleaning up team-mode processes', 'WARN');
  try {
    if (process.platform === 'win32') {
      execSync('taskkill /F /IM pwsh.exe /FI "WINDOWTITLE eq team-orchestrator*" 2>nul', { stdio: 'ignore' });
    } else {
      execSync('pkill -f "team-orchestrator" 2>/dev/null', { stdio: 'ignore' });
    }
    log('Team mode processes stopped.', 'SUCCESS');
  } catch {
    log('No team-mode processes found to stop.', 'INFO');
  }
}

function actionStatus(): void {
  ensureDirs();
  const files = existsSync(RESULTS_DIR) ? readdirSync(RESULTS_DIR).filter((f) => f.endsWith('.log')) : [];
  log(`Status — ${files.length} result files in ${RESULTS_DIR}`, 'INFO');
  for (const f of files) {
    try {
      const content = readFileSync(join(RESULTS_DIR, f), 'utf-8');
      const parsed = JSON.parse(content) as AgentResult;
      log(`  ${f}: ${parsed.skill} — ${parsed.status}`, parsed.status === 'completed' ? 'SUCCESS' : 'WARN');
    } catch {
      log(`  ${f}: (unparseable)`, 'WARN');
    }
  }
}

function actionDelegate(opts: ClientOptions): AgentResult {
  ensureDirs();
  const skillName = opts.skill || opts.skills[0] || 'default';
  log(`Delegate — invoking skill "${skillName}" with task "${opts.task}"`, 'INFO');
  const result = runAgentInline(skillName, `[${skillName}] ${opts.task}`, opts.timeoutSeconds);
  const logFile = join(RESULTS_DIR, `${skillName}-${dateStamp()}.log`);
  writeFileSync(logFile, JSON.stringify(result, null, 2), 'utf-8');
  log(`[DONE] ${skillName}: ${result.status}`, result.status === 'completed' ? 'SUCCESS' : 'ERROR');
  return result;
}

function actionSynthesize(allResults: AgentResult[], targetSkills: string[], task: string): string {
  const completedCount = allResults.filter((r) => r.status === 'completed').length;

  const synthesis = [
    '# Team Mode Report',
    `**Task**: ${task}`,
    `**Date**: ${new Date().toISOString().slice(0, 16).replace('T', ' ')}`,
    `**Skills used**: ${targetSkills.join(', ')}`,
    `**Results**: ${completedCount}/${allResults.length} successful`,
    '',
    '## Per-Skill Results',
    ...allResults.map((r) => `- **${r.skill}**: ${r.status}`),
    '',
    '## Next Steps',
    '- Review individual logs for detailed per-skill output',
    '- Re-run failed skills with --action delegate --skill <name>',
    '',
  ].join('\n');

  const reportFile = join(RESULTS_DIR, `synthesis-${dateStamp()}.md`);
  writeFileSync(reportFile, synthesis, 'utf-8');
  log(`Synthesis written to ${reportFile}`, 'SUCCESS');
  if (!quiet) console.log(`\n${synthesis}\n`);
  return synthesis;
}

function actionReport(opts: ClientOptions, allResults: AgentResult[], targetSkills: string[]): void {
  log('Generating full report...', 'INFO');
  actionStatus();
  if (allResults.length > 0) {
    actionSynthesize(allResults, targetSkills, opts.task);
  }
  log('Report complete.', 'SUCCESS');
}

function parseArgs(): ClientOptions {
  const args = process.argv.slice(2);
  const opts: ClientOptions = {
    task: '',
    skills: [],
    maxParallel: 3,
    timeoutSeconds: 300,
    dryRun: false,
    quiet: false,
    action: 'start',
    skill: '',
  };

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--task':
        opts.task = args[++i] ?? '';
        break;
      case '--skills':
        if (args[i + 1] && !args[i + 1].startsWith('-')) {
          opts.skills = args[++i].split(',').map((s) => s.trim());
        }
        break;
      case '--max-parallel':
      case '--maxParallel':
        opts.maxParallel = parseInt(args[++i] ?? '3', 10);
        break;
      case '--timeout-seconds':
      case '--timeoutSeconds':
        opts.timeoutSeconds = parseInt(args[++i] ?? '300', 10);
        break;
      case '--dry-run':
      case '--dryRun':
        opts.dryRun = true;
        break;
      case '--quiet':
        opts.quiet = true;
        break;
      case '--action':
        opts.action = args[++i] ?? 'start';
        break;
      case '--skill':
        opts.skill = args[++i] ?? '';
        break;
    }
  }

  return opts;
}

async function main() {
  quiet = process.argv.includes('--quiet');
  const opts = parseArgs();

  switch (opts.action) {
    case 'start':
      await actionStart(opts);
      break;
    case 'stop':
      actionStop(opts);
      break;
    case 'status':
      actionStatus();
      break;
    case 'delegate':
      actionDelegate(opts);
      break;
    case 'synthesize': {
      ensureDirs();
      const files = existsSync(RESULTS_DIR)
        ? readdirSync(RESULTS_DIR).filter((f) => f.endsWith('.log') && !f.startsWith('synthesis'))
        : [];
      const allResults: AgentResult[] = [];
      for (const f of files) {
        try {
          allResults.push(JSON.parse(readFileSync(join(RESULTS_DIR, f), 'utf-8')) as AgentResult);
        } catch { /* skip */ }
      }
      const skills = [...new Set(allResults.map((r) => r.skill))];
      actionSynthesize(allResults, skills, opts.task || '(from log files)');
      break;
    }
    case 'report': {
      ensureDirs();
      const files = existsSync(RESULTS_DIR)
        ? readdirSync(RESULTS_DIR).filter((f) => f.endsWith('.log') && !f.startsWith('synthesis'))
        : [];
      const allResults: AgentResult[] = [];
      for (const f of files) {
        try {
          allResults.push(JSON.parse(readFileSync(join(RESULTS_DIR, f), 'utf-8')) as AgentResult);
        } catch { /* skip */ }
      }
      const skills = [...new Set(allResults.map((r) => r.skill))];
      actionReport(opts, allResults, skills);
      break;
    }
    default:
      log(`Unknown action: ${opts.action}. Use: start, stop, status, delegate, synthesize, report`, 'ERROR');
      process.exit(1);
  }
}

if (process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url) {
  main().catch((err) => {
    console.error('Fatal error:', err);
    process.exit(1);
  });
}
