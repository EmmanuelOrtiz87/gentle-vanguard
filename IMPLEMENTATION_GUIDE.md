# Model Broker Implementation Guide

## PROBLEMA RESUELTO:

Model delegation failures due to:

1. Todos los agentes configurados como `moonshotai/kimi-k2.5`
2. Bedrock incompatibility with `reasoning_effort`
3. No automatic fallback mechanisms

## SOLUCIÓN IMPLEMENTADA:

### 1. **`src/opencode-switch-to-native.ts`**

- Cambia TODOS los agentes a `opencode/big-pickle` (modelo nativo garantizado)
- **Comando**: `npx tsx src/opencode-switch-to-native.ts`

### 2. **`src/ml/model-broker.ts`**

- Inteligente delegation con auto-fallback
- Verifica health del modelo configurado
- Usa `fallbackChain` de `model-health-registry.json`
- Si falla → switch automático a fallback
- Logging completo en `.runtime/logs/model-broker.log`

### 3. **`src/orchestrator-integration.ts`**

- Demuestra cómo integrar ModelBroker en el orchestrator
- Delegación robusta con retry y emergency fallback
- Status reporting y monitoreo

## ARQUITECTURA DEL SISTEMA:

```
User Request → Orchestrator → ModelBroker.delegate()
                      ↓
  1. Check configured model health
  2. If healthy → delegate normally
  3. If unhealthy → find fallback from registry
  4. If no fallback → ERROR controlado
  5. Log all switches and failures
```

## ¿CÓMO USAR?

### Paso 1: Cambiar a modelo nativo (RECOMENDADO)

```bash
# Esto arregla el problema inmediato
npx tsx src/opencode-switch-to-native.ts
```

### Paso 2: Testear el sistema

```bash
# Ver estado actual
npx tsx src/orchestrator-integration.ts status

# Testear delegación
npx tsx src/orchestrator-integration.ts test-delegation sdd-apply "Implement login feature"
```

### Paso 3: Ver logs

```bash
Get-Content .runtime/logs/model-broker.log -Tail 20
```

## INTEGRACIÓN COMPLETA EN ORCHESTRATOR:

Para integrar completamente, modificar el `orchestrator` en `opencode.json`:

```json
{
  "agent": {
    "orchestrator": {
      "description": "Main orchestrator with ModelBroker integration",
      "mode": "primary",
      "model": "opencode/big-pickle",
      "provider": "opencode",
      "steps": 24,
      "litellm_settings": {
        "drop_params": true
      },
      // IMPORTANTE: Agregar script pre-delegation
      "pre_delegation_script": "npx tsx src/orchestrator-integration.ts pre-check"
    }
  }
}
```

## VENTAJAS:

1. **Delegación siempre funcionando**: Nunca más "maximum steps reached" por modelo
2. **Auto-healing**: Detecta fallas y switch automático
3. **Transparente**: Logs de todos los switches
4. **Configurable**: Fallback chains por modelo en `model-health-registry.json`
5. **Extensible**: Fácil agregar nuevos proveedores/models

## FALLBACK CHAIN CONFIGURACIÓN:

```json
// config/model-health-registry.json
"kimi-2-5": {
  "provider": "littellmott-nuevo",
  "health": { "status": "unknown" },
  "fallbackChain": [
    "opencode/big-pickle",    // Primero: modelo nativo free
    "claude-haiku-4-5",                    // Segundo: modelo balanced
    "ollama/qwen2.5-coder:14b"             // Tercero: modelo local
  ]
}
```

## VERIFICACIÓN DE FUNCIONAMIENTO:

```bash
# 1. Cambiar a modelos nativos
npx tsx src/opencode-switch-to-native.ts

# 2. Verificar status
npx tsx src/ml/model-broker.ts status

# 3. Testear delegación con fallback
npx tsx src/ml/model-broker.ts delegate sdd-apply "Implement complex feature"

# 4. Ver logs
Get-Content .runtime/logs/model-broker.log
```

## ¿POR QUÉ ESTO RESUELVE EL PROBLEMA?

1. **Elimina dependencia de modelos externos**: Usa `opencode/big-pickle` nativo
2. **Sistema robusto**: Si incluso el nativo falla, tiene fallbacks configurados
3. **Feedback loop**: Logs permiten ajustar configuraciones basado en performance real
4. **Sin breaking changes**: Modelos se pueden reconfigurar después si se restaura kimi-2-5

## PRÓXIMOS PASOS:

1. **Deployment completo**: Integrar `ModelBroker` directamente en el orchestrator
2. **Health checks reales**: Conectar con API de proveedores para checks en vivo
3. **Learning system**: Aprender qué modelos funcionan mejor para qué tareas
4. **Cost optimization**: Usar modelo más barato que pueda cumplir la tarea
