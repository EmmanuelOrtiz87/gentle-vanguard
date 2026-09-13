---
created: 2026-08-11 00:17:12
tags: [engram, decision]
engram_id: 2736
type: decision
---

# GGA es la solución definitiva para fallback de modelos de IA

**What**: El stack ya resuelve el problema de fallback de modelos de IA con GGA (Guardian Angel) en `src/gga.ts` (711 líneas), inspirado en el componente GGA de gentle-ai. Detecta "Free usage exceeded, subscribe to Go", cuota agotada, rate limit, auth errors, timeouts y cambia automáticamente al siguiente proveedor en la cadena de fallback.

**Why**: En una sesión se intentó crear `src/model-fallback-runtime.ts` como solución al problema de sdd-apply que no heredaba el modelo del orquestador (kimi-2-5 via littellmott-nuevo) y usaba opencode/deepseek-v4-flash-free sin crédito. El archivo era redundante — GGA ya cubre todo. Fue eliminado.

**Where**: src/gga.ts, src/orchestrator-task-wrapper.ts (drop-in replacement de task()), src/universal-task-wrapper.ts, src/model-fallback-orchestrator.ts, tests/gga-comprehensive.test.ts, docs/gga-system.md, scripts npm: gga:delegate / gga:status / gga:reset / delegate.

**Learned**:
1. NO crear nuevos sistemas de fallback de modelos — GGA ya es la solución definitiva y está production-ready.
2. La cadena de fallback de GGA: modelo preferido → modelo del orquestador (auto-detectado) → kimi-2-5 → claude-haiku-4-5 → opencode/deepseek-v4-flash-free → ollama/qwen2.5-coder:14b.
3. El model-enforcer (paso 1 de autostart) cambia el primary a opencode/deepseek-v4-flash-free cuando kimi-2-5 tiene estado 'unknown' en model-health-registry.json — esto es comportamiento normal, no un bug.
4. Para delegar con fallback: usar orchestrator-task-wrapper en lugar de task() directo.

---
*Imported from Engram on 2026-09-06*
