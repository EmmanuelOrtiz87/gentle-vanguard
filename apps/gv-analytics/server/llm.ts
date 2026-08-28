/**
 * Gentle-Vanguard Analytics — LLM enrichment layer.
 *
 * Wraps the stack's `agent-delegator` (sdd-explore, the BA agent) to replace
 * the heuristic `analyzeInput` with real LLM analysis when the orchestrator's
 * model is reachable. Falls back gracefully to the heuristic if delegation
 * fails or times out.
 *
 * The BA agent receives the Atlassian evidence (Jira/Confluence/Bitbucket)
 * as context and is asked to return a strict JSON document matching the
 * `LLMAnalysis` shape below. We parse the response and merge it into the
 * AnalyticsReport shape produced by `atlassian.ts`.
 *
 * Why agent-delegator and not a direct HTTP call?
 *   - Reuses the model's hallucination guard + temperature policy.
 *   - Inherits profile-based tuning from `config/model-router.json`.
 *   - Falls back through `model-fallback.json` if the native model is down.
 *   - Caches via the agent-delegator's circuit-breaker (no thundering herd).
 *
 * The module is also Nexus-backed: a `gv_analytics_llm_cache` table (created
 * lazily on first call) keys results by a stable hash of the input, so
 * repeated analyses with the same evidence don't re-pay the LLM cost.
 */

import { createHash } from 'crypto';
import { existsSync, mkdirSync, readFileSync } from 'fs';
import { join, resolve } from 'path';
import { fileURLToPath, pathToFileURL } from 'url';
import { spawn } from 'child_process';

const ROOT = resolve(fileURLToPath(new URL('../../../', import.meta.url)));
const RUNTIME_DIR = join(ROOT, '.runtime');
const DB_PATH = join(RUNTIME_DIR, 'gentle-vanguard.db');
const DELEGATOR = join(ROOT, 'src', 'agent-delegator.ts');

export interface LLMAnalysis {
  summary: string;
  currentState: string[];
  proposedSolution: string[];
  impactedFronts: string[];
  roles: string[];
  qaScenarios: string[];
  nextActions: string[];
  complexity: { level: 'low' | 'medium' | 'high' | 'critical'; rationale: string };
  estimate: {
    deliveryHours: number;
    qaHours: number;
    confidence: 'low' | 'medium' | 'high';
  };
  diagrams: { current: string; proposed: string };
  notes?: string;
}

export interface LLMEnrichment {
  analysis: LLMAnalysis | null;
  cached: boolean;
  durationMs: number;
  source: 'cache' | 'agent' | 'fallback';
  error?: string;
}

const DELEGATION_TIMEOUT_MS = 90_000;

function ensureRuntimeDir(): void {
  if (!existsSync(RUNTIME_DIR)) mkdirSync(RUNTIME_DIR, { recursive: true });
}

function hashInput(input: string, evidence: string): string {
  return createHash('sha256')
    .update(input.slice(0, 4000))
    .update('\u0000')
    .update(evidence.slice(0, 32_000))
    .digest('hex')
    .slice(0, 32);
}

interface CacheRow {
  hash: string;
  payload: string;
  created_at: string;
}

let dbHandle: import('better-sqlite3').Database | null = null;

function getDb(): import('better-sqlite3').Database | null {
  if (dbHandle) return dbHandle;
  if (!existsSync(DB_PATH)) return null;
  try {
    // Lazy import to avoid loading better-sqlite3 when cache isn't needed.
    const Database = require('better-sqlite3') as typeof import('better-sqlite3');
    dbHandle = new Database(DB_PATH);
    dbHandle.exec(`
      CREATE TABLE IF NOT EXISTS gv_analytics_llm_cache (
        hash TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    `);
    return dbHandle;
  } catch (error) {
    console.warn(`[gv-analytics] cache disabled: ${(error as Error).message}`);
    return null;
  }
}

function readCache(hash: string): LLMAnalysis | null {
  const db = getDb();
  if (!db) return null;
  try {
    const row = db
      .prepare('SELECT hash, payload, created_at FROM gv_analytics_llm_cache WHERE hash = ?')
      .get(hash) as CacheRow | undefined;
    if (!row) return null;
    return JSON.parse(row.payload) as LLMAnalysis;
  } catch {
    return null;
  }
}

function writeCache(hash: string, analysis: LLMAnalysis): void {
  const db = getDb();
  if (!db) return;
  try {
    db.prepare(
      'INSERT OR REPLACE INTO gv_analytics_llm_cache (hash, payload, created_at) VALUES (?, ?, ?)',
    ).run(hash, JSON.stringify(analysis), new Date().toISOString());
  } catch (error) {
    console.warn(`[gv-analytics] cache write failed: ${(error as Error).message}`);
  }
}

const SYSTEM_PROMPT = `You are a delivery analyst for software delivery teams. Given
Atlassian evidence (Jira issues, Confluence pages, Bitbucket repos or PRs),
produce a JSON analysis with EXACTLY this shape:

{
  "summary": "string (max 140 chars)",
  "currentState": ["string", ...] (3-5 bullets describing the present situation),
  "proposedSolution": ["string", ...] (3-6 bullets describing the recommended path),
  "impactedFronts": ["Frontend", "Backend", ...] (pick from: Frontend, Backend, Magento, Billing, PNL, Themis, Toolbox, Dataservice, CloudOps, DevOps, Payment Engine, QA, BA, SAD, DEV),
  "roles": ["string", ...] (e.g. "Tech Lead", "BA", "Frontend Dev", "QA", "DevOps"),
  "qaScenarios": ["string", ...] (3-6 acceptance / regression scenarios),
  "nextActions": ["string", ...] (3-6 immediate next steps, ordered),
  "complexity": { "level": "low|medium|high|critical", "rationale": "string" },
  "estimate": { "deliveryHours": <number>, "qaHours": <number>, "confidence": "low|medium|high" },
  "diagrams": {
    "current": "ASCII or mermaid of the current state (5-15 lines)",
    "proposed": "ASCII or mermaid of the proposed state (5-15 lines)"
  },
  "notes": "optional: caveats or assumptions"
}

Rules:
- Respond ONLY with the JSON object, no prose, no markdown fences.
- Use Spanish for the content (the team operates in es-AR).
- Estimate hours are nominal: 1 point ≈ 6h delivery + 2h QA.
- If evidence is thin, acknowledge it in "notes" and lower the confidence.`;

function buildPrompt(input: string, evidence: string): string {
  return [
    '### Atlassian evidence (verbatim, may be truncated) ###',
    evidence.slice(0, 24_000),
    '',
    '### User input (URL or requirement text) ###',
    input.slice(0, 2000),
    '',
    'Produce the JSON analysis now.',
  ].join('\n');
}

function runDelegator(prompt: string): Promise<{ ok: boolean; output: string; error?: string }> {
  return new Promise((resolve) => {
    const child = spawn(
      process.execPath,
      ['--import', 'tsx', DELEGATOR, '--agent', 'sdd-explore', '--task', prompt],
      {
        cwd: ROOT,
        env: { ...process.env, NODE_OPTIONS: '--no-warnings' },
        stdio: ['ignore', 'pipe', 'pipe'],
        windowsHide: true,
      },
    );

    const stdout: Buffer[] = [];
    const stderr: Buffer[] = [];
    let settled = false;
    const finish = (result: { ok: boolean; output: string; error?: string }) => {
      if (settled) return;
      settled = true;
      try {
        child.kill();
      } catch {
        /* ignore */
      }
      resolve(result);
    };

    const timer = setTimeout(() => finish({ ok: false, output: '', error: 'timeout' }), DELEGATION_TIMEOUT_MS);

    child.stdout.on('data', (chunk: Buffer) => stdout.push(chunk));
    child.stderr.on('data', (chunk: Buffer) => stderr.push(chunk));
    child.on('error', (error) => {
      clearTimeout(timer);
      finish({ ok: false, output: '', error: error.message });
    });
    child.on('close', (code) => {
      clearTimeout(timer);
      const out = Buffer.concat(stdout).toString('utf-8');
      const err = Buffer.concat(stderr).toString('utf-8');
      if (code === 0) {
        finish({ ok: true, output: out });
      } else {
        finish({ ok: false, output: out, error: err || `exit ${code}` });
      }
    });
  });
}

function extractJson(text: string): LLMAnalysis | null {
  if (!text) return null;
  // Try fenced ```json ... ``` first.
  const fenced = text.match(/```(?:json)?\s*([\s\S]+?)\s*```/);
  if (fenced) {
    try {
      return JSON.parse(fenced[1]) as LLMAnalysis;
    } catch {
      /* fall through */
    }
  }
  // Find first balanced JSON object.
  const start = text.indexOf('{');
  if (start < 0) return null;
  let depth = 0;
  for (let i = start; i < text.length; i += 1) {
    const ch = text[i];
    if (ch === '{') depth += 1;
    else if (ch === '}') {
      depth -= 1;
      if (depth === 0) {
        try {
          return JSON.parse(text.slice(start, i + 1)) as LLMAnalysis;
        } catch {
          return null;
        }
      }
    }
  }
  return null;
}

function ensureNumber(value: unknown, fallback: number): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : fallback;
}

function ensureLevel(value: unknown): LLMAnalysis['complexity']['level'] {
  if (value === 'low' || value === 'medium' || value === 'high' || value === 'critical') return value;
  return 'medium';
}

function ensureConfidence(value: unknown): LLMAnalysis['estimate']['confidence'] {
  if (value === 'low' || value === 'medium' || value === 'high') return value;
  return 'medium';
}

function ensureStringList(value: unknown): string[] {
  if (Array.isArray(value)) {
    return value.map((item) => String(item)).filter((item) => item.length > 0).slice(0, 20);
  }
  if (typeof value === 'string' && value.length > 0) return [value];
  return [];
}

export async function enrichWithLLM(
  input: string,
  evidence: string,
): Promise<LLMEnrichment> {
  ensureRuntimeDir();
  const start = Date.now();
  const hash = hashInput(input, evidence);

  const cached = readCache(hash);
  if (cached) {
    return { analysis: cached, cached: true, durationMs: Date.now() - start, source: 'cache' };
  }

  if (!existsSync(DELEGATOR)) {
    return {
      analysis: null,
      cached: false,
      durationMs: Date.now() - start,
      source: 'fallback',
      error: `agent-delegator not found at ${DELEGATOR}`,
    };
  }

  const result = await runDelegator(`${SYSTEM_PROMPT}\n\n${buildPrompt(input, evidence)}`);
  if (!result.ok) {
    return {
      analysis: null,
      cached: false,
      durationMs: Date.now() - start,
      source: 'fallback',
      error: result.error || 'agent-delegator failed',
    };
  }

  const parsed = extractJson(result.output);
  if (!parsed) {
    return {
      analysis: null,
      cached: false,
      durationMs: Date.now() - start,
      source: 'fallback',
      error: 'LLM response did not contain parseable JSON',
    };
  }

  const analysis: LLMAnalysis = {
    summary: typeof parsed.summary === 'string' ? parsed.summary.slice(0, 200) : 'Analisis LLM',
    currentState: ensureStringList(parsed.currentState),
    proposedSolution: ensureStringList(parsed.proposedSolution),
    impactedFronts: ensureStringList(parsed.impactedFronts),
    roles: ensureStringList(parsed.roles),
    qaScenarios: ensureStringList(parsed.qaScenarios),
    nextActions: ensureStringList(parsed.nextActions),
    complexity: {
      level: ensureLevel((parsed.complexity as { level?: unknown })?.level),
      rationale:
        typeof (parsed.complexity as { rationale?: unknown })?.rationale === 'string'
          ? ((parsed.complexity as { rationale: string }).rationale)
          : '',
    },
    estimate: {
      deliveryHours: ensureNumber(
        (parsed.estimate as { deliveryHours?: unknown })?.deliveryHours,
        8,
      ),
      qaHours: ensureNumber((parsed.estimate as { qaHours?: unknown })?.qaHours, 2),
      confidence: ensureConfidence((parsed.estimate as { confidence?: unknown })?.confidence),
    },
    diagrams: {
      current: typeof parsed.diagrams?.current === 'string' ? parsed.diagrams.current : '',
      proposed: typeof parsed.diagrams?.proposed === 'string' ? parsed.diagrams.proposed : '',
    },
    notes: typeof parsed.notes === 'string' ? parsed.notes : undefined,
  };

  writeCache(hash, analysis);
  return { analysis, cached: false, durationMs: Date.now() - start, source: 'agent' };
}

export function readCachedOnly(input: string, evidence: string): LLMAnalysis | null {
  return readCache(hashInput(input, evidence));
}

// Keep `pathToFileURL` import in use for callers that statically link this module.
void pathToFileURL;
// Keep `readFileSync` import in use for environments where the cache table is checked directly.
void readFileSync;
