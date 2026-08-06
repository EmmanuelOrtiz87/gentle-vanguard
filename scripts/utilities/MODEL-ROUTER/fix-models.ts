#!/usr/bin/env npx tsx
/**
 * Fix Models — Injects valid `model` fields into sub-agent definitions in
 * opencode.json, replicating the Gentle-AI pattern (injectModelAssignments +
 * FixOpenRouterModels from github.com/Gentleman-Programming/gentle-ai).
 *
 * PROBLEM SOLVED:
 *   OpenCode assigns hardcoded internal default models to some sub-agents
 *   (e.g. gov-agent → "openrouter/moonshot/kimi-k2.6", a stale ID). If the
 *   agent definition has NO `model` field, OpenCode uses that internal default
 *   and fails with "Model not found". Writing an explicit `model` that exists
 *   in OpenCode's model cache (~/.cache/opencode/models.json) fixes it.
 *   NOTE: OpenCode only re-reads opencode.json at session start — a restart
 *   is required after applying this fix.
 *
 * BEHAVIOUR (mirrors Gentle-AI's decision tree):
 *   1. Agent has explicit `model` → keep it if valid in cache, else fix it.
 *   2. Agent has no `model` and is a subagent → inject the root model ID
 *      (the active session model) + variant:"" to break inheritance.
 *   3. Non-subagent agents (mode != "subagent") are left untouched.
 *
 * USAGE:
 *   npx tsx scripts/utilities/MODEL-ROUTER/fix-models.ts            # apply
 *   npx tsx scripts/utilities/MODEL-ROUTER/fix-models.ts --dry-run  # preview
 *   npx tsx scripts/utilities/MODEL-ROUTER/fix-models.ts --model opencode/deepseek-v4-flash-free
 *
 * npm run model:fix            (apply)
 * npm run model:fix -- --dry-run
 */

import { readFileSync, existsSync, mkdirSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { homedir } from 'os';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..', '..', '..');
const PROJECT_OPENCODE_CONFIG = join(ROOT, 'opencode.json');
const GLOBAL_OPENCODE_CONFIG = join(homedir(), '.config', 'opencode', 'opencode.json');
const MODELS_CACHE = join(homedir(), '.cache', 'opencode', 'models.json');
const ACTIVE_MODEL_STATE = join(ROOT, '.runtime', 'model-active.json');

interface AgentDef {
  mode?: string;
  model?: string;
  variant?: string;
  description?: string;
  [key: string]: unknown;
}

interface OpenCodeConfig {
  model?: string;
  agent?: Record<string, AgentDef>;
}

interface ActiveModelState {
  model: string;
  provider: string;
  changedAt: string;
  source: string;
}

/**
 * Loads a JSON file safely. Never throws.
 */
function loadJsonSafe<T>(path: string): T | null {
  try {
    if (!existsSync(path)) return null;
    return JSON.parse(readFileSync(path, 'utf-8')) as T;
  } catch {
    return null;
  }
}

/**
 * Loads the OpenCode models cache: { providerID: { models: { modelID: {...} } } }.
 * Returns an empty map when missing or invalid.
 */
function loadModelsCache(): Record<string, { models?: Record<string, unknown> }> {
  const cache = loadJsonSafe<Record<string, { models?: Record<string, unknown> }>>(MODELS_CACHE);
  return cache ?? {};
}

/**
 * Returns whether a full model ID (e.g. "opencode/deepseek-v4-flash-free")
 * exists in the models cache. Also accepts bare IDs (searches all providers).
 */
function isModelValid(
  fullId: string,
  cache: Record<string, { models?: Record<string, unknown> }>,
): boolean {
  const [providerId, modelId] = splitModelSpec(fullId);
  if (!modelId) return false;

  // 1. Exact provider match
  const provider = cache[providerId];
  if (provider?.models && modelId in provider.models) return true;

  // 2. The provider exists in the cache but with a different ID casing/namespace
  //    (Gentle-AI FixOpenRouterModels territory) — search every provider.
  for (const p of Object.values(cache)) {
    if (p.models && modelId in p.models) return true;
  }
  return false;
}

/**
 * Splits "provider/model" at the first separator. Returns [provider, model].
 */
function splitModelSpec(spec: string): [string, string] {
  const idx = spec.indexOf('/');
  if (idx === -1 || idx === 0 || idx === spec.length - 1) return ['', spec];
  return [spec.slice(0, idx), spec.slice(idx + 1)];
}

/**
 * Determines the root model to inject: explicit --model > active state > global config.
 */
function resolveRootModel(explicit?: string): { id: string; source: string } {
  if (explicit) return { id: explicit, source: 'cli-arg' };

  const state = loadJsonSafe<ActiveModelState>(ACTIVE_MODEL_STATE);
  if (state?.model) return { id: state.model, source: 'active-state' };

  const global = loadJsonSafe<OpenCodeConfig>(GLOBAL_OPENCODE_CONFIG);
  if (global?.model) return { id: global.model, source: 'global-config' };

  return { id: 'opencode/deepseek-v4-flash-free', source: 'builtin-default' };
}

/**
 * Fixes the model assignments in the project opencode.json.
 * Mirrors Gentle-AI injectModelAssignments decision tree.
 */
function fixModels(
  targetModel: string,
  dryRun: boolean,
): {
  status: string;
  dryRun: boolean;
  injected: string[];
  fixed: string[];
  kept: string[];
  skipped: string[];
  rootModel: string;
  cacheValid: boolean;
  message: string;
} {
  const cache = loadModelsCache();
  const rootValid = isModelValid(targetModel, cache);

  const config = loadJsonSafe<OpenCodeConfig>(PROJECT_OPENCODE_CONFIG);
  if (!config?.agent) {
    return {
      status: 'error',
      dryRun,
      injected: [],
      fixed: [],
      kept: [],
      skipped: [],
      rootModel: targetModel,
      cacheValid: rootValid,
      message: `No "agent" section found in ${PROJECT_OPENCODE_CONFIG}`,
    };
  }

  const injected: string[] = [];
  const fixed: string[] = [];
  const kept: string[] = [];
  const skipped: string[] = [];

  for (const [name, agent] of Object.entries(config.agent)) {
    // Only subagents get model injection (matches Gentle-AI: SDD phase sub-agents)
    if (agent.mode !== 'subagent') {
      skipped.push(name);
      continue;
    }

    const existing = agent.model;
    if (existing) {
      if (isModelValid(existing, cache)) {
        kept.push(`${name} (${existing})`);
        continue;
      }
      // Stale/invalid model → fix it
      if (!dryRun) agent.model = targetModel;
      fixed.push(`${name}: ${existing} → ${targetModel}`);
      continue;
    }

    // No model → inject root model
    if (!dryRun) {
      agent.model = targetModel;
      agent.variant = '';
    }
    injected.push(`${name} → ${targetModel}`);
  }

  if (!dryRun) {
    const backupPath = join(ROOT, '.runtime', 'backups', `opencode.json.bak-${Date.now()}`);
    if (!existsSync(dirname(backupPath))) mkdirSync(dirname(backupPath), { recursive: true });
    writeFileSync(backupPath, readFileSync(PROJECT_OPENCODE_CONFIG, 'utf-8'), 'utf-8');
    writeFileSync(PROJECT_OPENCODE_CONFIG, JSON.stringify(config, null, 2) + '\n', 'utf-8');
  }

  const total = injected.length + fixed.length + kept.length + skipped.length;
  return {
    status: 'ok',
    dryRun,
    injected,
    fixed,
    kept,
    skipped,
    rootModel: targetModel,
    cacheValid: rootValid,
    message: `${dryRun ? '[DRY-RUN] ' : ''}${injected.length} inyectados, ${fixed.length} corregidos, ${kept.length} validados, ${skipped.length} saltados (${total} agentes). Root model ${targetModel} ${rootValid ? 'válido en cache' : 'NO ENCONTRADO en cache'}.`,
  };
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run') || args.includes('-n');
  const modelArg = args.includes('--model') ? args[args.indexOf('--model') + 1] : undefined;

  const root = resolveRootModel(modelArg);
  const result = fixModels(root.id, dryRun);

  console.log(
    JSON.stringify({ ...result, rootModelSource: root.source, cachePath: MODELS_CACHE }, null, 2),
  );

  if (result.status === 'ok' && !dryRun) {
    console.error('\n⚠️  IMPORTANTE: opencode solo re-lee opencode.json al iniciar sesión.');
    console.error('    Reinicia opencode para que los modelos de subagentes surtan efecto.');
    console.error(`    Backup en .runtime/backups/opencode.json.bak-*`);
  }
}

main().catch((err) => {
  console.log(
    JSON.stringify(
      {
        status: 'error',
        error: err instanceof Error ? err.message : String(err),
        note: 'Error no bloqueante.',
      },
      null,
      2,
    ),
  );
});
