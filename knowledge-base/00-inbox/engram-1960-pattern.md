---
created: 2026-07-25 01:03:58
tags: [engram, pattern]
engram_id: 1960
type: pattern
---

# NORMATIVA: Budget config single source of truth

**What**: NORMATIVA OBLIGATORIA — token-budget-guard.json es la ÚNICA fuente de verdad para toda configuración de budget en el stack.

**Why**: Se detectaron 3+ fuentes inconsistentes que causaban falsos HARD_LIMIT alerts. La consolidación elimina gaps.

**Where**: config/token-budget-guard.json (v2.0.0+), config/token-budget-limits.json (DEPRECATED)

**Learned**:
- NO crear nuevos archivos de budget. Siempre editar token-budget-guard.json.
- token-budget-guard.ts SIEMPRE debe leer de token-budget-guard.json primero (Priority 1), con fallback a orchestrator.json (Priority 2).
- Cualquier nuevo agente en opencode.json#agent debe reflejarse en token-budget-guard.json#agentLimits.
- Dashboard health API debe exponer budget como componente (9+ componentes).
- Si se modifican límites, hacerlo SOLO en token-budget-guard.json.

---
*Imported from Engram on 2026-09-06*
