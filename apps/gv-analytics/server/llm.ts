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
const DELEGATION_MAX_RETRIES = 2;

/** Lists that must be non-empty for the analysis to be considered complete. */
const REQUIRED_LIST_FIELDS: (keyof LLMAnalysis)[] = [
  'currentState',
  'proposedSolution',
  'nextActions',
];

function isAnalysisComplete(analysis: LLMAnalysis): boolean {
  return REQUIRED_LIST_FIELDS.every(
    (field) => Array.isArray(analysis[field]) && (analysis[field] as string[]).length > 0,
  );
}

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
produce a JSON analysis with EXACTLY this shape (ALL fields are REQUIRED):

{
  "summary": "string (max 140 chars)",
  "currentState": ["bullet 1", "bullet 2", "bullet 3"],
  "proposedSolution": ["bullet 1", "bullet 2", "bullet 3"],
  "impactedFronts": ["Frontend", "Backend"],
  "roles": ["Tech Lead", "BA", "Frontend Dev"],
  "qaScenarios": ["Scenario 1", "Scenario 2", "Scenario 3"],
  "nextActions": ["Step 1", "Step 2", "Step 3"],
  "complexity": { "level": "low|medium|high|critical", "rationale": "why" },
  "estimate": { "deliveryHours": 16, "qaHours": 4, "confidence": "low|medium|high" },
  "diagrams": {
    "current": "ASCII or mermaid block showing the current state (min 3 lines)",
    "proposed": "ASCII or mermaid block showing the proposed state (min 3 lines)"
  },
  "notes": "caveats or assumptions, or empty string"
}

CRITICAL RULES — violations will cause the analysis to be discarded:
1. Respond ONLY with the raw JSON object. No prose, no markdown code fences, no \`\`\`json.
2. Every array field (currentState, proposedSolution, impactedFronts, roles, qaScenarios,
   nextActions) MUST have AT LEAST 2 items. Never return an empty array [].
3. If evidence is thin, still produce best-effort values and lower confidence to "low".
4. Use Spanish for all content (the team operates in es-AR).
5. Estimate hours are nominal: 1 story point ≈ 6h delivery + 2h QA.
6. impactedFronts must pick from: Frontend, Backend, Magento, Billing, PNL, Themis,
   Toolbox, Dataservice, CloudOps, DevOps, Payment Engine, QA, BA, SAD, DEV.

Example of a VALID minimal response when evidence is thin:
{
  "summary": "Tarea sin evidencia suficiente — analisis estimado.",
  "currentState": ["Sin detalle de estado actual en la evidencia.", "Se requiere relevamiento adicional."],
  "proposedSolution": ["Relevar requerimientos con el equipo.", "Definir alcance antes de estimar."],
  "impactedFronts": ["Backend"],
  "roles": ["BA", "Tech Lead"],
  "qaScenarios": ["Validar que el flujo principal no se rompa.", "Smoke test en ambiente de QA."],
  "nextActions": ["Reunión de kick-off.", "Crear ticket de relevamiento."],
  "complexity": { "level": "low", "rationale": "Evidencia insuficiente para determinar complejidad real." },
  "estimate": { "deliveryHours": 8, "qaHours": 2, "confidence": "low" },
  "diagrams": { "current": "Sin diagrama disponible.", "proposed": "Pendiente de relevamiento." },
  "notes": "Analisis basado en evidencia parcial."
}`;

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

  // Retry loop: up to DELEGATION_MAX_RETRIES attempts when the LLM returns
  // parseable JSON but with empty critical lists (partial-response problem).
  let lastError: string | undefined;
  let lastAnalysis: LLMAnalysis | null = null;

  for (let attempt = 1; attempt <= DELEGATION_MAX_RETRIES; attempt += 1) {
    // On retries, append a stern reminder about the empty arrays.
    const retryHint =
      attempt > 1
        ? '\n\n\u26a0 RETRY: The previous response had empty arrays. You MUST populate ALL array fields (currentState, proposedSolution, roles, qaScenarios, nextActions) with at least 2 items each. Return ONLY the corrected JSON.'
        : '';

    const result = await runDelegator(
      `${SYSTEM_PROMPT}\n\n${buildPrompt(input, evidence)}${retryHint}`,
    );

    if (!result.ok) {
      lastError = result.error || 'agent-delegator failed';
      break;
    }

    const parsed = extractJson(result.output);
    if (!parsed) {
      // Completely unparseable — no point retrying.
      lastError = 'LLM response did not contain parseable JSON';
      break;
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
            ? (parsed.complexity as { rationale: string }).rationale
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

    lastAnalysis = analysis;

    if (isAnalysisComplete(analysis)) {
      // Full response — cache and return.
      writeCache(hash, analysis);
      return { analysis, cached: false, durationMs: Date.now() - start, source: 'agent' };
    }

    // Partial response: log and retry if attempts remain.
    const emptyFields = REQUIRED_LIST_FIELDS.filter(
      (f) => !(analysis[f] as string[]).length,
    ).join(', ');
    console.warn(
      `[gv-analytics] LLM attempt ${attempt}/${DELEGATION_MAX_RETRIES}: partial JSON — empty fields: ${emptyFields}`,
    );
  }

  // All retries exhausted. If we got at least a partial analysis, cache and
  // return it with a warning — better than the heuristic fallback.
  if (lastAnalysis) {
    writeCache(hash, lastAnalysis);
    return {
      analysis: lastAnalysis,
      cached: false,
      durationMs: Date.now() - start,
      source: 'agent',
      error: 'LLM returned partial JSON after retries — some lists may be empty',
    };
  }

  return {
    analysis: null,
    cached: false,
    durationMs: Date.now() - start,
    source: 'fallback',
    error: lastError ?? 'agent-delegator failed',
  };
}

export function readCachedOnly(input: string, evidence: string): LLMAnalysis | null {
  return readCache(hashInput(input, evidence));
}

// Keep `pathToFileURL` import in use for callers that statically link this module.
void pathToFileURL;
// Keep `readFileSync` import in use for environments where the cache table is checked directly.
void readFileSync;
