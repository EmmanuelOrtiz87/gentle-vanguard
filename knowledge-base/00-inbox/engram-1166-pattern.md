---
created: 2026-05-26 18:18:17
tags: [engram, pattern]
engram_id: 1166
type: pattern
---

# JSON Construction Normative - Agent Mandatory

**What**: Creada normativa obligatoria para construcción de JSON: `rules/NORMATIVAS-JSON-CONSTRUCTION.md`

**Why**: El error JSON recurrente es causado por el agente no verificando balance de quotes/braces/brackets antes de enviar. Esta normativa establece reglas CRÍTICAS que el agente debe seguir.

**Where**:
- `rules/NORMATIVAS-JSON-CONSTRUCTION.md` - Normativa completa
- `CLAUDE.md` - Agregada como Core Rule #11
- `docs/AGENTS.md` - Referencia en Key References

**Learned**:
- Verificar quotes pares, braces/brackets balanceados
- JSON debe terminar con `}` o `]`
- No trailing commas
- Violación = CRÍTICA (tool call falla, tokens wasted)
- Quick check mental antes de cada tool call

---
*Imported from Engram on 2026-09-06*
