---
created: 2026-08-20 06:08:22
tags: [engram, decision]
engram_id: 2891
type: decision
---

# Discord-bot NO es un objetivo — revertir cambios, no tocar

**What**: El usuario aclaró que NO quiere un Discord bot — no tiene ninguno y no es la idea disponer de uno. Se revirtieron los cambios que se habían empezado en apps/discord-bot (package.json y logger.ts).
**Why**: El orquestador asumió erróneamente que el discord-bot (esqueleto con imports rotos) era un gap de capacidad a arreglar. El usuario corrigió el rumbo: ese app no es parte de la intención.
**Where**: apps/discord-bot/ (revertido a estado original con git checkout)
**Learned**:
- NO tocar apps/discord-bot — el usuario no quiere un bot de Discord.
- Los productos derivados (discord-bot, doc-gentle) NO son todos objetivos activos. Antes de "arreglar" cualquier app derivada, confirmar con el usuario si es parte del plan.
- El foco del usuario es el stack principal (src/, dashboard, skills, gobernanza) y el CMS de marketing (docs/presentations/).

---
*Imported from Engram on 2026-09-06*
