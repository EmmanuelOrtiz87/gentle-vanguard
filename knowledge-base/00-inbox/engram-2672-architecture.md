---
created: 2026-08-08 19:28:04
tags: [engram, architecture]
engram_id: 2672
type: architecture
---

# Arquitectura de delegación con herencia del modelo del orquestador

**What**: Diseño de sistema de delegación donde subagentes operan PRIMERO con el modelo del orquestador

**Why**: Es más eficiente, consistente y económico usar el mismo modelo del orquestador primero antes de usar otros modelos

**Where**:
- opencode.json (21 agentes configurados)
- config/model-health-registry.json (routing rules)
- src/model-broker.ts (lógica de delegación)

**Learned**:
1. **Eficiencia de costo**: Si orquestador usa `deepseek-v3-2` (free/barato), los subagentes deberían usar el mismo
2. **Consistencia**: Mismo modelo → mismo comportamiento, mismo "thinking style"
3. **Simplificación**: No tenemos que mantener múltiples configuraciones de modelo
4. **Fallback estratégico**: Solo si el modelo del orquestador falla, entonces usamos otros

**Problema identificado**: El sistema tenía `no_inherit_model: true` que PREVIENE esta herencia natural

**Solución**:
- Los subagentes DEBERÍAN heredar modelo del orquestador POR DEFECTO
- Solo agregar `drop_params: true` para compatibilidad
- Factorizar lógica de fallback en model-broker

---
*Imported from Engram on 2026-09-06*
