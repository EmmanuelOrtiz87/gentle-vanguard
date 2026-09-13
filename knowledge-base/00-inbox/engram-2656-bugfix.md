---
created: 2026-08-08 16:16:06
tags: [engram, bugfix]
engram_id: 2656
type: bugfix
---

# Herencia de modelos LISTA para reinicio - Fix completo aplicado

**SOLUCIÓN COMPLETA IMPLEMENTADA - Pendiente reinicio**

## Problema Raíz Identificado y Corregido

1. **Problema**: Orchestrator tenía valor especial `"inherit-from-session"` en lugar de modelo real
2. **Consecuencia**: Subagentes heredaban `"inherit-from-session"` literalmente → "Model not found"

## Cambios Aplicados

### Parte 1: Orchestrator

```json
"orchestrator": {
  "model": "kimi-2-5",
  "provider": "littellmott",
  ...
}
```

### Parte 2: Subagentes (20)

- Borrado campo `model` de todos los subagentes SDD
- Inyectado `kimi-2-5` + `variant: ""` vía fix-models.ts

## Estado Pre-Reinicio

| Componente | Valor | Backup |
|-----------|-------|--------|
| Orchestrator model | kimi-2-5 | .runtime/backups/opencode.json.bak-* |
| 20 Subagentes model | kimi-2-5 | .runtime/backups/opencode.json.bak-* |
| Modelo activo | kimi-2-5 | .runtime/model-active.json |
| Scripts creados | clear-models.ts | scripts/utilities/MODEL-ROUTER/ |

## Para Validar Post-Reinicio

```bash
# Test 1: Subagente SDD con modelo heredado
task --subagent_type sdd-explore --prompt "¿Qué modelo estás usando?"

# Esperado: Responde "kimi-2-5" sin error "Model not found"

# Test 2: Creación de skill
# Si funciona → ejecutar las 8 tareas de skills pendientes
```

Archivos modificados:
- opencode.json (orchestrator model)
- opencode.json (20 subagentes model)
- .runtime/model-active.json
- scripts/utilities/MODEL-ROUTER/clear-models.ts (nuevo)

---
*Imported from Engram on 2026-09-06*
