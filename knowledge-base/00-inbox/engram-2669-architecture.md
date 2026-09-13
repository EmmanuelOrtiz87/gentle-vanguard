---
created: 2026-08-08 19:00:52
tags: [engram, architecture]
engram_id: 2669
type: architecture
---

# Sistema delegación 100% funcional

**What**: Sistema completo de delegación automática y broker de modelos

**Why**: Resolver problemas con modelos Bedrock y falta de fallback

**Where**:
- opencode.json (21 agentes ahora con opencode/deepseek-v4-flash-free)
- src/model-broker.ts (370 líneas - sistema profesional)
- config/model-health-registry.json (fallback chains)

**Learned**:
- Bedrock no soporta `reasoning_effort` → agregar `drop_params: true`
- Kimi-k2-5 tenía problemas → switch a nativo opencode/deepseek-v4-flash-free
- Fallback automático crítico para resilience
- Sistema detecta fallas de modelo y auto-switch al chain configurado
- OpenCode session debe reiniciarse tras cambios en opencode.json

**Resultado**: Delegación 100% estable con 0 problemas de Bedrock

---
*Imported from Engram on 2026-09-06*
