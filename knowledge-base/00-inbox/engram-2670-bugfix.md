---
created: 2026-08-08 19:05:35
tags: [engram, bugfix]
engram_id: 2670
type: bugfix
---

# OpenCode inherit-from-session bug

**What**: OpenCode usando `inherit-from-session/` automáticamente, causando error "Model not found"

**Why**: OpenCode tiene mecanismo de herencia de modelos automática desde orquestador padre

**Where**:
- opencode.json (configuración de 21 agentes)
- Sistema delegation via `task` tool
- Model broker con fallback chains configuradas

**Learned**:
- OpenCode intenta heredar modelo automáticamente de orquestador actual (`littellmott-nuevo/deepseek-v3-2`)
- El nombre `inherit-from-session/` parece ser pseudo-modelo para "use same as parent"
- Si falla: "Model not found: inherit-from-session/"
- Solución: `litellm_settings.no_inherit_model: true`
- Añadir `provider: "opencode"` explícitamente
- Modificar `model-health-registry.json` routing rules

**Fix Aplicado**:
- orchestrator: `no_inherit_model: true`
- sdd-apply: `no_inherit_model: true`, `provider: "opencode"`

---
*Imported from Engram on 2026-09-06*
