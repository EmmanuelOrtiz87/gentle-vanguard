---
created: 2026-08-08 13:44:29
tags: [engram, bugfix]
engram_id: 2655
type: bugfix
---

# Herencia de modelos IMPLEMENTADA - Requiere reinicio

**SOLUCIÓN COMPLETA IMPLEMENTADA: Herencia de modelos en subagentes**

## Problem

Los subagentes SDD (sdd-explore, sdd-apply, etc.) usaban opencode/deepseek-v4-flash-free hardcodeado en lugar de heredar kimi-2-5 del orquestador.

## Root cause

- Los agentes en opencode.json tenían modelo explícito opencode/deepseek-v4-flash-free
- El script fix-models.ts solo inyectaba cuando NO había modelo
- Los system agents (explore, general) heredan nativamente y funcionaban

## Solution

### Paso 1: Clear existing models

```bash
npx tsx scripts/utilities/MODEL-ROUTER/clear-models.ts
```

Borró campos model de 20 subagentes.

### Paso 2: Inject inherited model

```bash
npx tsx scripts/utilities/MODEL-ROUTER/fix-models.ts --model kimi-2-5
```

Resultado: 20 agentes inyectados con kimi-2-5

## Changes made

- opencode.json: 20 subagentes ahora tienen model: kimi-2-5
- .runtime/model-active.json: Estado del modelo activo
- .runtime/backups/: Backup de configuración anterior
- scripts/utilities/MODEL-ROUTER/clear-models.ts: Nuevo script para borrar modelos

## Status

✅ Configuración aplicada
⚠️ Pendiente: Reiniciar opencode/claude para que surta efecto
⚠️ Nota: opencode solo re-lee opencode.json al iniciar sesión

## Next steps after restart

1. Validar que subagentes usen kimi-2-5
2. Ejecutar las 8 tareas de skills pendientes
3. Verificar que task() funcione correctamente

---
*Imported from Engram on 2026-09-06*
