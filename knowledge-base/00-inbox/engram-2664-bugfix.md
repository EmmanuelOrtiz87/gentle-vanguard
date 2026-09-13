---
created: 2026-08-08 18:22:11
tags: [engram, bugfix]
engram_id: 2664
type: bugfix
---

# Stack Diagnostics: Bedrock reasoning_effort + Token Budget Fix

**What**: Diagnóstico completo del stack Gentle-Vanguard

**Problems Found**:
1. **JSON Syntax Error** en `config/model-router.json` - faltaba coma después de `authorization` (línea 340)
2. **Token Budget Excedido** (562% / 28M tokens) - tokens acumulativos en Nexus DB sin reset diario
3. **Bedrock Provider Issues**:
   - `reasoning_effort` no soportado por Bedrock/kimi-k2.5
   - Configuración `drop_params: true` ya presente en opencode.json (bueno)
   - Regla `ReasoningEffortIncompatible` en correction-rules.json

**Root Cause Bedrock**:
- El error `reasoning_effort` viene de que Bedrock (via LiteLLM) no soporta este parámetro
- La solución correcta ya está implementada: `drop_params: true` en `litellm_settings` del opencode.json
- Esto hace que LiteLLM descarte parámetros no soportados en lugar de reenviarlos al proveedor

**Archivos Corregidos**:
- `config/model-router.json`: Agregada coma faltante línea 340 (después de `authorization`)

**Reset Manual Token Budget**:
Para resetear tokens (no hay comando automático):

```
# Opción 1: Prune manual de token_usage en Nexus
npm run db:prune  # limpia datos >90 días

# Opción 2: Para reset total (perdería historial):
# backup + init de Nexus DB (no recomendado sin backup)
```

**Verificación Post-Fix**:
- `npm run health:check`: [PASS] costTracking section present ✓
- `npm run db:health`: [PASS] 23 tables, 29534 rows ✓

---
*Imported from Engram on 2026-09-06*
