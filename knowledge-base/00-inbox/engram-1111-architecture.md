---
created: 2026-05-24 13:12:26
tags: [engram, architecture]
engram_id: 1111
type: architecture
---

# 86 skills split — zero warnings en check-skill-sizes

**What**: Split 86 skills oversized (>1000 tokens o >150 líneas) moviendo contenido detallado a references/detail.md. Cada SKILL.md mantiene frontmatter + ~60-100 líneas esenciales + link a referencia. Quedan 148 skills dentro de límites, 0 warnings.

**Why**: check-skill-sizes.ps1 reportaba 82 skills oversized. Causa: SKILL.md acumulaba contenido de referencia (ejemplos, troubleshooting, tablas) que debía estar en references/.

**Where**:
- scripts/utilities/skill-splitter.ps1 — nuevo script automatizado de split
- 86 skills/ */SKILL.md — reducidos
- 86 skills/ */references/detail.md — creados con contenido movido

**Learned**: chained-pr es el skill más denso (~15 tokens/línea), requirió KeepLines=45 para bajar de 1000 tokens. El splitter usa frontmatterEnd + KeepLines como punto de corte. Cada SKILL.md se actualiza con un link al references/detail.md al final.

---
*Imported from Engram on 2026-09-06*
