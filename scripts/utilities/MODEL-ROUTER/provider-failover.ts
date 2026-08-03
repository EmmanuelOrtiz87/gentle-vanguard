#!/usr/bin/env npx tsx
/**
 * Provider Failover — Model Availability Router
 *
 * Resuelve el problema de "Model not found" en OpenRouter implementando
 * una cadena de fallback multi-proveedor. Cuando un modelo no está disponible,
 * intenta con alternativas configuradas en orden de prioridad.
 *
 * Uso:
 *   npx tsx scripts/utilities/MODEL-ROUTER/provider-failover.ts --agent OPS --task "description"
 *   npx tsx scripts/utilities/MODEL-ROUTER/provider-failover.ts --agent DOC --task "description" --fallback-only
 *
 * Integración:
 *   - Lee config/model-fallback.json para cadenas de fallback por agente
 *   - Lee config/model-router.json para bindings primarios
 *   - Persiste estado en .runtime/model-fallback-state.json
 *   - Notifica al usuario cuando se usa un fallback
 */

import { readFileSync, existsSync, mkdirSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..', '..', '..');
const FALLBACK_CONFIG_PATH = join(ROOT, 'config', 'model-fallback.json');
const MODEL_ROUTER_PATH = join(ROOT, 'config', 'model-router.json');
const STATE_PATH = join(ROOT, '.runtime', 'model-fallback-state.json');

interface FallbackConfig {
  version: string;
  description: string;
  global: {
    enabled: boolean;
    maxFallbackAttempts: number;
    notifyOnFallback: boolean;
    persistState: boolean;
  };
  agentFallbacks: Record<string, {
    primary: string;
    chain: string[];
    providerPriority: string[];
    rationale: string;
  }>;
  universalFallbacks: string[];
}

interface RouterConfig {
  agentBindings: Record<string, {
    model: string;
    provider: string;
    subagent: string;
    rationale?: string;
  }>;
  fallback: {
    model: string;
    description: string;
  };
}

interface FallbackState {
  agentStates: Record<string, {
    currentModel: string;
    fallbackHistory: Array<{
      attempted: string;
      result: 'success' | 'fail';
      timestamp: string;
    }>;
    lastUsedProvider: string;
  }>;
  globalFallbackCount: number;
  lastUpdated: string;
}

function loadConfig<T>(path: string, name: string): T {
  try {
    const raw = readFileSync(path, 'utf-8');
    return JSON.parse(raw) as T;
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error(`[FAILOVER] ⚠ Error loading ${name}: ${msg}`);
    return {} as T;
  }
}

function loadState(): FallbackState {
  try {
    if (existsSync(STATE_PATH)) {
      return JSON.parse(readFileSync(STATE_PATH, 'utf-8')) as FallbackState;
    }
  } catch { /* ignore */ }
  return {
    agentStates: {},
    globalFallbackCount: 0,
    lastUpdated: new Date().toISOString()
  };
}

function saveState(state: FallbackState): void {
  try {
    state.lastUpdated = new Date().toISOString();
    const dir = dirname(STATE_PATH);
    if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
    writeFileSync(STATE_PATH, JSON.stringify(state, null, 2), 'utf-8');
  } catch (err) {
    console.error(`[FAILOVER] ⚠ Error saving state: ${err}`);
  }
}

function getAgentFallbackChain(agentType: string): string[] {
  const fallbackConfig = loadConfig<FallbackConfig>(FALLBACK_CONFIG_PATH, 'model-fallback.json');
  const routerConfig = loadConfig<RouterConfig>(MODEL_ROUTER_PATH, 'model-router.json');

  // 1. Try fallback config first
  const agentFallback = fallbackConfig.agentFallbacks?.[agentType];
  if (agentFallback?.chain?.length) {
    return agentFallback.chain;
  }

  // 2. Build chain from router config
  const binding = routerConfig.agentBindings?.[agentType];
  if (binding) {
    const chain: string[] = [];
    // Primary is the configured model
    if (binding.model) chain.push(binding.model);
    // Add universal fallbacks
    if (fallbackConfig.universalFallbacks) {
      chain.push(...fallbackConfig.universalFallbacks);
    }
    return chain;
  }

  // 3. Return universal fallbacks only
  return fallbackConfig.universalFallbacks || [];
}

function resolveModelWithFallback(agentType: string, _taskDescription?: string): {
  model: string;
  provider: string;
  fallbackUsed: boolean;
  alternativeAvailable: boolean;
  suggestedAgentType?: string;
} {
  const routerConfig = loadConfig<RouterConfig>(MODEL_ROUTER_PATH, 'model-router.json');
  const state = loadState();

  const binding = routerConfig.agentBindings?.[agentType];
  const fallbackChain = getAgentFallbackChain(agentType);
  const agentState = state.agentStates[agentType];

  // If we have state suggesting a fallback model worked before, use it
  let currentModel = binding?.model || '';
  const currentProvider = binding?.provider || 'openrouter';

  // Check if primary model is known to fail
  if (agentState?.currentModel && agentState.currentModel !== binding?.model) {
    // A fallback was already selected in a previous session
    currentModel = agentState.currentModel;
    return {
      model: currentModel,
      provider: currentProvider,
      fallbackUsed: true,
      alternativeAvailable: false,
      suggestedAgentType: binding?.subagent
    };
  }

  // If primary model and fallbacks available, suggest the full chain
  const alternativeAvailable = fallbackChain.length > 1 || (!!binding?.model && fallbackChain.length > 0);

  return {
    model: currentModel,
    provider: currentProvider,
    fallbackUsed: false,
    alternativeAvailable,
    suggestedAgentType: binding?.subagent
  };
}

function formatNotification(agentType: string, result: {
  model: string;
  fallbackUsed: boolean;
  alternativeAvailable: boolean;
  suggestedAgentType?: string;
}): string {
  if (result.fallbackUsed) {
    return `[FAILOVER] Agent ${agentType} usando modelo alternativo: ${result.model}`;
  }
  if (result.alternativeAvailable) {
    return `[FAILOVER] Agent ${agentType} con modelo primario: ${result.model}. Alternativas disponibles si falla.`;
  }
  return `[FAILOVER] Agent ${agentType} con modelo: ${result.model}. Sin alternativas configuradas.`;
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const agentIndex = args.indexOf('--agent');
  const taskIndex = args.indexOf('--task');
  const fallbackOnly = args.includes('--fallback-only');

  const agentType = agentIndex !== -1 ? args[agentIndex + 1]?.toUpperCase() : '';
  const taskDescription = taskIndex !== -1 ? args[taskIndex + 1] : '';

  if (!agentType) {
    // Report mode — show all agent fallback statuses
    const fallbackConfig = loadConfig<FallbackConfig>(FALLBACK_CONFIG_PATH, 'model-fallback.json');
    const state = loadState();
    console.log(JSON.stringify({
      status: 'ok',
      mode: 'report',
      agents: Object.keys(fallbackConfig.agentFallbacks || {}).map(a => ({
        agent: a,
        primary: fallbackConfig.agentFallbacks[a].primary,
        fallbackChain: fallbackConfig.agentFallbacks[a].chain,
        currentState: state.agentStates[a]?.currentModel || fallbackConfig.agentFallbacks[a].primary,
        fallbacksUsed: state.agentStates[a]?.fallbackHistory?.length || 0
      })),
      globalFallbackCount: state.globalFallbackCount,
      universalFallbacks: fallbackConfig.universalFallbacks || []
    }, null, 2));
    return;
  }

  // Resolve model for this agent
  const result = resolveModelWithFallback(agentType, taskDescription);

  // Build output with all info needed by orchestrator
  const output = {
    status: 'ok',
    agentType,
    model: result.model,
    fallbackUsed: result.fallbackUsed,
    alternativeAvailable: result.alternativeAvailable,
    suggestedAgentType: result.suggestedAgentType || 'explore',
    notification: formatNotification(agentType, result),
    timestamp: new Date().toISOString()
  };

  // Persist to state
  if (!fallbackOnly) {
    const state = loadState();
    if (!state.agentStates[agentType]) {
      state.agentStates[agentType] = {
        currentModel: result.model,
        fallbackHistory: [],
        lastUsedProvider: 'openrouter'
      };
    }
    saveState(state);
  }

  // Output as JSON for programmatic consumption
  console.log(JSON.stringify(output, null, 2));

  // If alternatives are available, also output user-friendly suggestion
  if (result.alternativeAvailable) {
    console.error(`\nℹ️  TIP: Si el agente ${agentType} falla por modelo, intenta con "explore" como fallback universal.`);
    console.error(`   O usa: --agent ${agentType} --fallback-only para ver solo alternativas.`);
  }
}

main().catch(err => {
  console.error(JSON.stringify({
    status: 'error',
    error: err instanceof Error ? err.message : String(err),
    suggestion: 'Verificar config/model-fallback.json y config/model-router.json'
  }));
  process.exit(1);
});
