---
created: 2026-05-24 12:55:52
tags: [engram, architecture]
engram_id: 1110
type: architecture
---

# Full bootstrap automation — lefthook + scheduled task + autostart

**What**: Completada la automatización total del stack para fresh clones. Implementado: (1) bootstrap.ps1 ahora instala lefthook + registra hooks + crea scheduled task, (2) nuevo step lefthook-verify en session-autostart pipeline, (3) scripts/git-hooks/ marcado como deprecated, (4) lefthook-verify.ps1 para verificar hooks en cada startup.

**Why**: En PC nueva, el stack quedaba roto porque: (a) lefthook no se instalaba automáticamente, (b) hooks post-commit/post-merge para CodeGraph no existían, (c) scheduled task no se creaba, (d) bootstrap.ps1 apuntaba a scripts/git-hooks/ legacy que rompía lefthook.

**Where**:
- scripts/core/bootstrap.ps1 — Step 4 reescrito (lefthook install + scheduled task + health report expandido)
- scripts/utilities/lefthook-verify.ps1 — nuevo script de verificación
- config/session-autostart.config.json — nuevo step lefthook-verify antes de codegraph-sync
- scripts/git-hooks/README.md — marcado como DEPRECATED con guía de migración
  
**Learned**: ScheduledTask requiere -Once con -RepetitionInterval (no -Daily). [TimeSpan]::MaxValue excede límite de 31 días. Lefthook requiere .git/hooks por defecto, incompatible con core.hooksPath. La autostart pipeline acepta steps no-required (required: false) sin que un warn bloquee el startup.

---
*Imported from Engram on 2026-09-06*
