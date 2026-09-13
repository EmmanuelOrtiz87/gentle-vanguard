---
created: 2026-07-31 21:41:45
tags: [engram, bugfix]
engram_id: 2418
type: bugfix
---

# Fix plugin graphify.js - sesión 20260731T2020

**What**: Eliminado plugin graphify.js que inyectaba mensaje en TODOS los comandos bash

**Why**: El plugin estaba mal implementado - injectaba el recordatorio de graphify antes de cada comando bash, no solo cuando el usuario escribía /graphify. Según AGENTS.md línea 23: "When the user types /graphify, invoke the skill tool with skill: graphify" - esto es un trigger del usuario, no un plugin automático.

**Where**:
- .opencode/plugins/graphify.js (eliminado)
- .opencode/opencode.json (eliminada referencia a plugin)

**Learned**:
- Los plugins de OpenCode se cargan automáticamente al inicio
- El plugin usaba el hook "tool.execute.before" para inyectar en bash
- La documentación decía invocar skill, no usar plugin automático
- Skill graphify no existía, así que aunque el plugin funcionara no haría nada útil

**Status**: Cambio debe mantenerse (no hacer rollback)

---
*Imported from Engram on 2026-09-06*
