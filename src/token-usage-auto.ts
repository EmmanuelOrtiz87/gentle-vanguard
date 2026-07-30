#!/usr/bin/env node

import { existsSync, readFileSync, readdirSync } from 'fs';
import { join, resolve } from 'path';
import { pathToFileURL } from 'url';
import { spawnSync } from 'child_process';
import { createRequire } from 'module';

const _require = createRequire(import.meta.url);

// Lazy SQLite connection for Nexus DB dual-write
let _nexusDb: any = null;
function getNexusDb(): any {
  if (_nexusDb) return _nexusDb;
  try {
    const Database = _require('better-sqlite3');
    const dbPath = join(resolve(process.cwd()), '.runtime', 'gentle-vanguard.db');
    if (existsSync(dbPath)) {
      _nexusDb = new Database(dbPath);
      return _nexusDb;
    }
  } catch {
    // SQLite not available
  }
  return null;
}

function writeTokenToNexus(sessionId: string, promptTokens: number, completionTokens: number, model: string): void {
  try {
    const db = getNexusDb();
    if (db) {
      db.prepare(
        `INSERT INTO token_usage (session_id, prompt_tokens, completion_tokens, cost, model, timestamp)
         VALUES (?, ?, ?, 0, ?, datetime('now'))`
      ).run(sessionId, promptTokens, completionTokens, model || null);
    }
  } catch {
    // Dual-write failure is non-critical
  }
}

export interface TokenUsageArgs {
  InputTokens?: number;
  OutputTokens?: number;
  ContextChars?: number;
  SessionId?: string;
  TurnLabel?: string;
  InputSummary?: string;
  OutputSummary?: string;
  ToolCalls?: string;
  Model?: string;
}

function parseArgs(argv: string[]): Record<string, string> {
  const args: Record<string, string> = {};
  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    if (arg.startsWith('-')) {
      const key = arg.replace(/^-+/, '');
      const next = argv[i + 1];
      if (next && !next.startsWith('-')) {
        args[key] = next;
        i++;
      } else {
        args[key] = 'true';
      }
    }
  }
  return args;
}

function findRepoRoot(start: string): string {
  const root = resolve(start);
  let current = root;
  for (let i = 0; i < 10; i++) {
    if (existsSync(join(current, 'config', 'orchestrator.json'))) return current;
    const parent = resolve(current, '..');
    if (parent === current) break;
    current = parent;
  }
  return root;
}

function callPowerShell(scriptPath: string, psArgs: Record<string, string | number | undefined>): void {
  const cmdArgs: string[] = ['-NoProfile', '-File', scriptPath];
  for (const [k, v] of Object.entries(psArgs)) {
    if (v !== undefined && v !== '') {
      cmdArgs.push(`-${k}`, String(v));
    }
  }
  const result = spawnSync('pwsh', cmdArgs, { stdio: 'pipe', encoding: 'utf8' });
  if (result.status !== 0 && result.status !== null) {
    const stderr = result.stderr?.toString().trim();
    if (stderr) {
      console.debug(`[token-usage-auto] Subprocess stderr: ${stderr}`);
    }
  }
}

function main() {
  const raw = parseArgs(process.argv);
  const args: TokenUsageArgs = {
    InputTokens: raw['InputTokens'] ? parseInt(raw['InputTokens'], 10) : 0,
    OutputTokens: raw['OutputTokens'] ? parseInt(raw['OutputTokens'], 10) : 0,
    ContextChars: raw['ContextChars'] ? parseInt(raw['ContextChars'], 10) : 0,
    SessionId: raw['SessionId'] ?? '',
    TurnLabel: raw['TurnLabel'] ?? '',
    InputSummary: raw['InputSummary'] ?? '',
    OutputSummary: raw['OutputSummary'] ?? '',
    ToolCalls: raw['ToolCalls'] ?? '',
    Model: raw['Model'] ?? '',
  };

  const {
    ContextChars = 0, TurnLabel = '', InputSummary = '', OutputSummary = '', ToolCalls = '', Model = '',
  } = args;
  let {
    InputTokens = 0, OutputTokens = 0, SessionId = '',
  } = args;

  const ROOT = process.env.GENTLE_VANGUARD_BASE_DIR
    ? resolve(process.env.GENTLE_VANGUARD_BASE_DIR)
    : findRepoRoot(process.cwd());

  if (!SessionId) {
    const tokenFile = join(ROOT, '.session', 'token-usage.json');
    if (existsSync(tokenFile)) {
      try {
        const td = JSON.parse(readFileSync(tokenFile, 'utf8')) as Record<string, unknown>;
        if (typeof td.sessionId === 'string') SessionId = td.sessionId;
      } catch {
        // ignore parse errors
      }
    }
  }

  if (!SessionId) {
    const sessionDir = join(ROOT, '.session');
    if (existsSync(sessionDir)) {
      try {
        const files = readdirSync(sessionDir)
          .filter(f => f.startsWith('session-') && f.endsWith('.json'))
          .sort()
          .reverse();
        if (files.length > 0) {
          const sd = JSON.parse(readFileSync(join(sessionDir, files[0]), 'utf8')) as Record<string, unknown>;
          if (typeof sd.sessionId === 'string') SessionId = sd.sessionId;
        }
      } catch {
        // ignore
      }
    }
  }

  const notifierScript = join(ROOT, 'scripts', 'utilities', 'token-usage-notifier.ps1');
  if (existsSync(notifierScript)) {
    if (InputTokens === 0 && OutputTokens === 0) {
      InputTokens = Math.max(1, Math.floor(ContextChars / 4));
      OutputTokens = Math.max(1, Math.floor(500 / 4));
    }
    callPowerShell(notifierScript, {
      Action: 'accumulate',
      InputTokens,
      OutputTokens,
      ContextChars,
      SessionId,
      Model,
    });
  }

  const ctxLog = join(ROOT, 'scripts', 'utilities', 'session-context-log.ps1');
  if (existsSync(ctxLog)) {
    const ctxDir = join(ROOT, '.session', 'context-log');
    if (!existsSync(ctxDir)) {
      callPowerShell(ctxLog, { Action: 'init', SessionId, Model, Silent: 'true' });
    }
    callPowerShell(ctxLog, {
      Action: 'log',
      SessionId,
      TurnLabel,
      InputTokens,
      OutputTokens,
      ContextChars,
      InputSummary,
      OutputSummary,
      ToolCalls,
      Model,
      Silent: 'true',
    });
  }

  // Nexus DB dual-write: persist tokens to SQLite
  writeTokenToNexus(SessionId, InputTokens, OutputTokens, Model);

  process.exit(0);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
