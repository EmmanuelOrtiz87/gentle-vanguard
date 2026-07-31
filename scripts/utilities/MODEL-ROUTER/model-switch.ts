#!/usr/bin/env npx tsx
/**
 * Model Switch — Non-blocking model selection for the Gentle-Vanguard stack.
 *
 * Filosofía (no bloqueante, sin ruido):
 *   - El stack SIEMPRE funciona con el modelo de sesión (nativo opencode).
 *   - Cambiar de modelo es config SECUNDARIA a demanda — nunca bloquea ni falla.
 *   - Lee los providers REALES desde la config global de opencode
 *     (~/.config/opencode/opencode.json) — no inventa proveedores.
 *   - Detecta capacidad de subagentes: si no hay providers con API key,
 *     el orquestador NO usa task() y trabaja directamente.
 *
 * Uso:
 *   npx tsx scripts/utilities/MODEL-ROUTER/model-switch.ts current
 *   npx tsx scripts/utilities/MODEL-ROUTER/model-switch.ts list
 *   npx tsx scripts/utilities/MODEL-ROUTER/model-switch.ts switch <provider/model>
 *   npx tsx scripts/utilities/MODEL-ROUTER/model-switch.ts capability
 *   npx tsx scripts/utilities/MODEL-ROUTER/model-switch.ts help
 *
 * npm run model:current | model:list | model:switch -- <provider/model> | model:capability
 */

import { readFileSync, existsSync, mkdirSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { homedir } from 'os';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..', '..', '..');
const GLOBAL_OPENCODE_CONFIG = join(homedir(), '.config', 'opencode', 'opencode.json');
const PROJECT_OPENCODE_CONFIG = join(ROOT, 'opencode.json');
const ACTIVE_MODEL_STATE = join(ROOT, '.runtime', 'model-active.json');

interface OpenCodeConfig {
  model?: string;
  small_model?: string;
  provider?: Record<string, ProviderConfig>;
}

interface ProviderConfig {
  id?: string;
  name?: string;
  api?: string;
  options?: {
    baseURL?: string;
    apiKey?: string;
    headers?: Record<string, string>;
  };
  models?: Record<string, { id?: string; name?: string; tool_call?: boolean }>;
}

interface ActiveModelState {
  model: string;
  provider: string;
  changedAt: string;
  source: 'global-config' | 'switch-command';
}

/**
 * Loads a JSON config, returning null on any error (never throws).
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
 * Reads the effective opencode config (global first, project as overlay).
 */
function getEffectiveConfig(): OpenCodeConfig {
  const global = loadJsonSafe<OpenCodeConfig>(GLOBAL_OPENCODE_CONFIG) ?? {};
  const project = loadJsonSafe<OpenCodeConfig>(PROJECT_OPENCODE_CONFIG) ?? {};
  return {
    model: project.model ?? global.model ?? '',
    small_model: project.small_model ?? global.small_model ?? '',
    provider: { ...(global.provider ?? {}), ...(project.provider ?? {}) }
  };
}

/**
 * Returns the currently active model — never throws, never blocks.
 * Priority: state file (last switch) → global config model → project config → fallback.
 */
function getCurrentModel(): { model: string; provider: string; source: string } {
  const state = loadJsonSafe<ActiveModelState>(ACTIVE_MODEL_STATE);
  if (state?.model) {
    return { model: state.model, provider: state.provider, source: 'switch-command' };
  }
  const config = getEffectiveConfig();
  if (config.model) {
    const provider = config.model.split('/')[0] ?? 'opencode';
    return { model: config.model, provider, source: 'global-config' };
  }
  return {
    model: 'opencode/deepseek-v4-flash-free',
    provider: 'opencode',
    source: 'builtin-default'
  };
}

/**
 * Lists every model available from ALL configured providers (global + project).
 * Native opencode models are listed first as the zero-config default.
 */
function listAvailableModels(): Array<{
  provider: string;
  model: string;
  label: string;
  hasApiKey: boolean;
  local: boolean;
}> {
  const config = getEffectiveConfig();
  const models: Array<{ provider: string; model: string; label: string; hasApiKey: boolean; local: boolean }> = [];

  // 1. Native opencode free models (always available — zero config)
  const nativeModels = [
    'opencode/deepseek-v4-flash-free',
    'opencode/llama-3.3-70b',
    'opencode/qwen2.5-coder-32b'
  ];
  for (const m of nativeModels) {
    models.push({ provider: 'opencode', model: m, label: m, hasApiKey: true, local: false });
  }

  // 2. Configured providers
  for (const [providerKey, provider] of Object.entries(config.provider ?? {})) {
    const baseURL = provider.options?.baseURL ?? '';
    const local = baseURL.includes('localhost') || baseURL.includes('127.0.0.1') || baseURL.includes('192.168.');
    const hasApiKey = Boolean(
      provider.options?.apiKey ||
      (provider.options?.headers &&
        Object.values(provider.options.headers).some(v => String(v).length > 3))
    );
    for (const [modelId, model] of Object.entries(provider.models ?? {})) {
      models.push({
        provider: providerKey,
        model: `${providerKey}/${model.id ?? model.name ?? modelId}`,
        label: model.name ?? model.id ?? modelId,
        hasApiKey,
        local
      });
    }
  }
  return models;
}

/**
 * Capability detection — tells the orchestrator whether task() subagents are viable.
 * Rule: subagents are ONLY viable if there is at least one provider (besides native)
 * with an API key configured. Otherwise the orchestrator works inline with the
 * session model (zero noise, zero failures).
 */
function detectCapability(): {
  status: 'ok' | 'degraded';
  subagentsAvailable: boolean;
  reason: string;
  activeModel: string;
  providers: Array<{ name: string; models: number; hasApiKey: boolean; local: boolean }>;
} {
  const config = getEffectiveConfig();
  const providers = Object.entries(config.provider ?? {}).map(([name, p]) => {
    const baseURL = p.options?.baseURL ?? '';
    const local = baseURL.includes('localhost') || baseURL.includes('127.0.0.1') || baseURL.includes('192.168.');
    const hasApiKey = Boolean(
      p.options?.apiKey ||
      (p.options?.headers && Object.values(p.options.headers).some(v => String(v).length > 3))
    );
    return { name, models: Object.keys(p.models ?? {}).length, hasApiKey, local };
  });

  const viable = providers.filter(p => p.hasApiKey || p.local);
  const active = getCurrentModel();

  if (viable.length > 0) {
    return {
      status: 'ok',
      subagentsAvailable: true,
      reason: `Providers disponibles: ${viable.map(p => p.name).join(', ')}. Subagentes viables.`,
      activeModel: active.model,
      providers
    };
  }
  return {
    status: 'degraded',
    subagentsAvailable: false,
    reason: 'Sin providers con API key o locales. El orquestador trabaja inline con el modelo de sesión (sin ruido, sin fallos).',
    activeModel: active.model,
    providers
  };
}

/**
 * Switches the active model by writing the global opencode config.
 * Creates a timestamped backup first. NEVER throws — reports success/failure.
 */
function switchModel(modelRef: string): { ok: boolean; message: string; backup?: string } {
  try {
    if (!existsSync(GLOBAL_OPENCODE_CONFIG)) {
      return { ok: false, message: `Config global no encontrada: ${GLOBAL_OPENCODE_CONFIG}` };
    }

    // Validate the requested model exists among available ones
    const available = listAvailableModels().map(m => m.model);
    const exact = available.includes(modelRef);
    const bySuffix = available.find(m => m.toLowerCase().endsWith(modelRef.toLowerCase()));

    if (!exact && !bySuffix) {
      return {
        ok: false,
        message: `Modelo "${modelRef}" no encontrado. Usa "npm run model:list" para ver los disponibles.`
      };
    }
    const resolved: string = exact ? modelRef : (bySuffix as string);

    // Backup global config
    const backupPath = join(ROOT, '.runtime', 'backups', `opencode.json.bak-${Date.now()}`);
    const dir = dirname(backupPath);
    if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
    writeFileSync(backupPath, readFileSync(GLOBAL_OPENCODE_CONFIG, 'utf-8'), 'utf-8');

    // Write new model
    const global = loadJsonSafe<OpenCodeConfig>(GLOBAL_OPENCODE_CONFIG) ?? {};
    global.model = resolved;
    global.small_model = global.small_model ?? resolved;
    writeFileSync(GLOBAL_OPENCODE_CONFIG, JSON.stringify(global, null, 2) + '\n', 'utf-8');

    // Persist state
    const state: ActiveModelState = {
      model: resolved,
      provider: resolved.split('/')[0] ?? 'unknown',
      changedAt: new Date().toISOString(),
      source: 'switch-command'
    };
    const stateDir = dirname(ACTIVE_MODEL_STATE);
    if (!existsSync(stateDir)) mkdirSync(stateDir, { recursive: true });
    writeFileSync(ACTIVE_MODEL_STATE, JSON.stringify(state, null, 2) + '\n', 'utf-8');

    return {
      ok: true,
      message: `Modelo cambiado a ${resolved}. Backup en ${backupPath}.`,
      backup: backupPath
    };
  } catch (err) {
    return { ok: false, message: `Error: ${err instanceof Error ? err.message : String(err)}` };
  }
}

function printHelp(): void {
  console.log(`Model Switch — selección de modelo no bloqueante

USO:
  npm run model:current                 Modelo activo actual
  npm run model:list                    Todos los modelos disponibles
  npm run model:switch -- <modelo>      Cambiar modelo activo (global)
  npm run model:capability              Detectar si los subagentes son viables
  npm run model:help                    Esta ayuda

REGLAS (diseño):
  1. El stack SIEMPRE funciona con el modelo de sesión — sin configuración extra.
  2. Cambiar modelo es opcional (a demanda), nunca bloqueante.
  3. Si no hay providers con API key, los subagentes NO se usan y el
     orquestador trabaja inline — sin errores ni ruido.
  4. Los modelos se leen de la config real de opencode
     (${GLOBAL_OPENCODE_CONFIG} + opencode.json del proyecto).
`);
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const command = args[0]?.toLowerCase() ?? 'current';

  switch (command) {
    case 'current': {
      const current = getCurrentModel();
      console.log(JSON.stringify({
        status: 'ok',
        model: current.model,
        provider: current.provider,
        source: current.source,
        note: 'El stack funciona con este modelo; el cambio es opcional.'
      }, null, 2));
      break;
    }
    case 'list': {
      const models = listAvailableModels();
      console.log(JSON.stringify({
        status: 'ok',
        count: models.length,
        native: models.filter(m => m.provider === 'opencode').map(m => m.model),
        providers: models.filter(m => m.provider !== 'opencode'),
        tip: 'Para cambiar: npm run model:switch -- <provider/model>'
      }, null, 2));
      break;
    }
    case 'switch': {
      const target = args[1];
      if (!target) {
        console.log(JSON.stringify({ status: 'error', message: 'Uso: model:switch -- <provider/model>', tip: 'npm run model:list para ver opciones' }, null, 2));
        process.exitCode = 0;
        break;
      }
      const result = switchModel(target);
      console.log(JSON.stringify(result, null, 2));
      break;
    }
    case 'capability': {
      console.log(JSON.stringify(detectCapability(), null, 2));
      break;
    }
    case 'help':
    case '--help':
    case '-h':
      printHelp();
      break;
    default: {
      console.log(JSON.stringify({
        status: 'error',
        message: `Comando desconocido: ${command}`,
        valid: ['current', 'list', 'switch', 'capability', 'help']
      }, null, 2));
    }
  }
}

main().catch(err => {
  // NEVER blocks the stack — report and exit 0
  console.log(JSON.stringify({
    status: 'error',
    error: err instanceof Error ? err.message : String(err),
    note: 'Error no bloqueante — el stack sigue con el modelo de sesión.'
  }, null, 2));
});
