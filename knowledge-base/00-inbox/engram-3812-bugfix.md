---
created: 2026-09-09 17:22:14
tags: [engram, bugfix]
engram_id: 3812
type: bugfix
---

# Fix modelos: deepseek-v4-flash-free retirado → ling-3.0-flash-fin-free + fallback general

**What**: Los subagentes fallaban con "Model not found: opencode/deepseek-v4-flash-free" (modelo retirado del registry). Diagnóstico vía ~/.config/opencode/model-health.json: deepseek-v4-flash-free = server_error "Model is unavailable"; mimo-v2.5-free y big-pickle = rate limited; los únicos free OK eran ling-3.0-flash-fin-free (1128ms) y nemotron-3.5-lightning-free (5156ms). Fix: opencode.json (21 agentes) → opencode/ling-3.0-flash-fin-free; model-fallback.json v2.2.0 actualizado con cadenas coherentes.
**Why**: El usuario pidió operar con todas las herramientas y crear lo necesario en el stack si falta capacidad.
**Where**: opencode.json, config/model-fallback.json
**Learned**: (1) Los cambios a opencode.json NO aplican en la sesión actual (config congelada al inicio; requiere nueva sesión — "no hot-reload"). (2) El fallback universal que SÍ funciona en la misma sesión es el agente tipo `general` (system-model, siempre disponible) — los 4 tasks de contenido se despacharon con `general` exitosamente. (3) model-health.json en ~/.config/opencode/ es la fuente de verdad del estado de modelos.

---
*Imported from Engram on 2026-09-09*
