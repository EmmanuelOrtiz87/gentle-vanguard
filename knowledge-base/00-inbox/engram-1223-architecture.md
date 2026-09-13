---
created: 2026-05-30 04:39:44
tags: [engram, architecture]
engram_id: 1223
type: architecture
---

# Diagnóstico optimización tokens y sistema prompt

**What**: Análisis completo de consumo de tokens y optimización del stack gentle-vanguard

**Why**: Costos elevados (miles de USD/semana) por crecimiento acumulativo de contexto mensaje a mensaje y sistema prompt inflado

**Where**:
- CLAUDE.md (system prompt): 117→58 líneas (~50% reducción)
- scripts/utilities/pre-process-input.ps1: agregado cache SHA256 + token tracking + pre-compact hook
- scripts/utilities/PERFORMANCE-OPTIMIZATION/pre-compact-hook.ps1: corregido hardcoded → lectura real de token-usage.json
- scripts/hooks/pre-task-compress.ps1: nuevo hook para comprimir prompts de subagentes (~30% reducción)
- scripts/utilities/DETECT/, SESSION/, TOKEN/, HANDOFF/: scripts movidos a subdirectorios con forwarders

**Learned**:
1. El costo principal viene de: (a) modelo premium (claude-sonnet-4 / glm-5), (b) historial completo reenviado cada turno, (c) sistema prompt de 117 líneas (~900 tokens) reenviado sin cambios
2. OpenCode no compacta automáticamente el historial — depende de configuración externa
3. Cache de respuestas (SHA256, TTL 30min) nunca se poblaba — corregido
4. Pre-compact hook usaba valor hardcoded 16000 en lugar de métricas reales — corregido
5. Response cache funciona: 2da llamada mismo input = cache hit, salta routing
6. Ahorro estimado: ~500 tokens/turno por CLAUDE.md comprimido + ~30% en prompts de subagentes + cache en inputs repetitivos
7. Para máximo ahorro: cambiar modelo de glm-5 ($0.002/$0.006) a qwen-3.6-plus ($0.0005/$0.0015) = 4x más barato

---
*Imported from Engram on 2026-09-06*
