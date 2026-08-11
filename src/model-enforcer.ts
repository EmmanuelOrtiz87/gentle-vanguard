#!/usr/bin/env npx tsx
/**
 * Model Enforcer - Garantiza uso del modelo gratuito disponible
 *
 * Cuando se detecta que un modelo tiene cuota agotada o no está disponible,
 * automáticamente reasigna todo el stack a usar opencode/deepseek-v4-flash-free
 * que es el único modelo gratuito y disponible.
 *
 * Uso: npx tsx src/model-enforcer.ts [--check] [--apply]
 */

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join } from 'path';

const ROOT = process.cwd();
const REGISTRY_PATH = join(ROOT, 'config', 'model-health-registry.json');
const ACTIVE_MODEL_PATH = join(ROOT, '.runtime', 'model-active.json');

const FREE_MODEL = 'opencode/deepseek-v4-flash-free';
const FREE_PROVIDER = 'opencode';
const OPENCODE_JSON_PATH = join(ROOT, 'opencode.json');

interface ModelEntry {
  provider: string;
  health: { status: string };
  costPer1kTokens: { input: number; output: number };
}

interface ModelRegistry {
  models: Record<string, ModelEntry>;
  routingRules: {
    orchestrator: { primary: string };
    subagents: { default: string };
  };
}

/**
 * Detecta el modelo REAL del orquestador desde opencode.json.
 * Fuente de verdad: agent.orchestrator.model + provider.
 * Si no se encuentra, devuelve null (se usará el fallback).
 */
function detectOrchestratorModel(): { model: string; provider: string } | null {
  try {
    if (!existsSync(OPENCODE_JSON_PATH)) return null;
    const cfg = JSON.parse(readFileSync(OPENCODE_JSON_PATH, 'utf-8')) as {
      agent?: Record<string, { model?: string; provider?: string }>;
    };
    const orch = cfg.agent?.orchestrator;
    if (orch?.model) {
      return { model: orch.model, provider: orch.provider || 'opencode' };
    }
  } catch {
    /* opencode.json inválido o ilegible */
  }
  return null;
}

type LogEntry = {
  timestamp: string;
  action: string;
  details: string;
};

function log(message: string): void {
  const entry: LogEntry = {
    timestamp: new Date().toISOString(),
    action: 'ENFORCER',
    details: message,
  };
  console.log(`[${entry.timestamp}] ${message}`);
}

function checkModelHealth(): { healthy: string[]; unhealthy: string[]; free: string[] } {
  const registry: ModelRegistry = JSON.parse(readFileSync(REGISTRY_PATH, 'utf-8'));

  const healthy: string[] = [];
  const unhealthy: string[] = [];
  const free: string[] = [];

  for (const [id, model] of Object.entries(registry.models)) {
    const isHealthy = model.health.status === 'available';
    const isFree = model.costPer1kTokens.input === 0 && model.costPer1kTokens.output === 0;

    if (isFree) free.push(id);
    if (isHealthy && isFree) {
      healthy.push(id);
    } else {
      unhealthy.push(id);
    }
  }

  return { healthy, unhealthy, free };
}

function enforceFreeModel(): void {
  log('=== INICIANDO ENFORCEMENT DE MODELO ===');

  // 1. Detectar el modelo REAL del orquestador (dinámico — hereda lo que sea que el orquestador use)
  const orchestrator = detectOrchestratorModel();
  const registry: ModelRegistry = JSON.parse(readFileSync(REGISTRY_PATH, 'utf-8'));

  // 2. Verificar estado actual
  const status = checkModelHealth();
  log(`Modelos saludables y gratuitos: ${status.healthy.join(', ')}`);
  log(`Modelos con problemas: ${status.unhealthy.join(', ')}`);

  if (status.healthy.length === 0) {
    log('❌ ERROR: No hay modelos saludables disponibles');
    process.exit(1);
  }

  // 3. Determinar el modelo primario:
  //    - Si el modelo del orquestador está disponible en el registry → usarlo (herencia dinámica)
  //    - Si no → fallback al modelo gratuito
  let primaryModel = FREE_MODEL;
  let primaryProvider = FREE_PROVIDER;
  let reason = 'Auto-enforcement: modelo gratuito y disponible (orquestador no disponible)';

  if (orchestrator) {
    const orchEntry = registry.models[orchestrator.model];
    const orchAvailable = orchEntry?.health?.status === 'available';
    if (orchAvailable) {
      primaryModel = orchestrator.model;
      primaryProvider = orchestrator.provider;
      reason = `Herencia dinámica: el orquestador usa ${orchestrator.model} y está disponible`;
    } else {
      log(`⚠️ Modelo del orquestador (${orchestrator.model}) no disponible → fallback al gratuito`);
    }
  } else {
    log('⚠️ No se pudo detectar el modelo del orquestador → fallback al gratuito');
  }

  // 4. Actualizar registry para que el modelo primario sea el detectado
  if (registry.routingRules.orchestrator.primary !== primaryModel) {
    log(`Cambiando primary: ${registry.routingRules.orchestrator.primary} → ${primaryModel}`);
    registry.routingRules.orchestrator.primary = primaryModel;
  }

  if (registry.routingRules.subagents.default !== primaryModel) {
    log(`Cambiando default: ${registry.routingRules.subagents.default} → ${primaryModel}`);
    registry.routingRules.subagents.default = primaryModel;
  }

  // 5. Guardar cambios
  writeFileSync(REGISTRY_PATH, JSON.stringify(registry, null, 2), 'utf-8');
  log('✅ Registry actualizado');

  // 6. Guardar modelo activo
  const activeModel = {
    model: primaryModel,
    provider: primaryProvider,
    enforcedAt: new Date().toISOString(),
    reason,
    previousModel: process.env.GENTLE_VANGUARD_ACTIVE_MODEL || 'unknown',
  };

  writeFileSync(ACTIVE_MODEL_PATH, JSON.stringify(activeModel, null, 2), 'utf-8');
  log(`✅ Modelo activo guardado: ${primaryModel} (${reason})`);

  // 7. Exportar para el shell
  console.log('\n=== VARIABLES DE ENTORNO ===');
  console.log(`export GENTLE_VANGUARD_ACTIVE_MODEL="${primaryModel}"`);
  console.log(`export GENTLE_VANGUARD_PROVIDER="${primaryProvider}"`);
  console.log(`export GENTLE_VANGUARD_MODEL_ENFORCED="true"`);

  log('=== ENFORCEMENT COMPLETADO ===');
}

function checkCurrentStatus(): void {
  console.log('=== ESTADO ACTUAL DE MODELOS ===\n');

  const registry: ModelRegistry = JSON.parse(readFileSync(REGISTRY_PATH, 'utf-8'));

  console.log('Modelos en registro:');
  for (const [id, model] of Object.entries(registry.models)) {
    const isHealthy = model.health.status === 'available';
    const isFree = model.costPer1kTokens.input === 0 && model.costPer1kTokens.output === 0;
    const icon = isHealthy && isFree ? '✅' : '⚠️';
    console.log(`  ${icon} ${id}`);
    console.log(`     Estado: ${model.health.status}`);
    console.log(
      `     Costo: $${model.costPer1kTokens.input}/$${model.costPer1kTokens.output} per 1k`,
    );
    console.log(`     Gratis: ${isFree ? 'SÍ ✓' : 'NO'}`);
    console.log();
  }

  console.log('=== CONFIGURACIÓN DE ROUTING ===');
  console.log(`Primary: ${registry.routingRules.orchestrator.primary}`);
  console.log(`Default: ${registry.routingRules.subagents.default}`);
  console.log();

  console.log('=== MODELO ACTIVO ===');
  if (existsSync(ACTIVE_MODEL_PATH)) {
    const active = JSON.parse(readFileSync(ACTIVE_MODEL_PATH, 'utf-8'));
    console.log(`Modelo: ${active.model}`);
    console.log(`Provider: ${active.provider}`);
    console.log(`Desde: ${active.enforcedAt || active.changedAt}`);
    if (active.reason) console.log(`Razón: ${active.reason}`);
  } else {
    console.log('⚠️ No hay modelo activo configurado');
  }
}

function main(): void {
  const args = process.argv.slice(2);
  const command = args[0];

  switch (command) {
    case '--check':
      checkCurrentStatus();
      break;
    case '--apply':
      enforceFreeModel();
      break;
    case '--force':
      console.log('Forzando reasignación inmediata...');
      enforceFreeModel();
      break;
    default:
      console.log(`
Model Enforcer v1.0

Uso:
  npx tsx src/model-enforcer.ts --check    # Verificar estado actual
  npx tsx src/model-enforcer.ts --apply     # Aplicar enforcement
  npx tsx src/model-enforcer.ts --force     # Forzar reasignación

Descripción:
  Garantiza que todo el stack use el modelo del orquestador (detectado
  dinámicamente desde opencode.json → agent.orchestrator.model) cuando está
  disponible. Si el modelo del orquestador no está disponible, hace fallback
  al modelo gratuito (opencode/deepseek-v4-flash-free). Los subagentes
  heredan el modelo del orquestador de forma dinámica.
`);
  }
}

void main();
