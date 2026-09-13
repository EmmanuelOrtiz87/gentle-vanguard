---
created: 2026-05-22 17:30:16
tags: [engram, bugfix]
engram_id: 1017
type: bugfix
---

# Session autostart pipeline fix - token notifier path issue

**What**: Fixed session autostart pipeline execution and identified token-usage-notifier path resolution issue.

**Why**:
1. El autostart pipeline fallaba silenciosamente con error ChildProcess.kill porque el timeout de 120s era insuficiente para 25 pasos.
2. El token-usage-notifier guardaba datos en .session/token-usage.json pero el script buscaba en scripts/.session/token-usage.json (path incorrecto).
3. El skill session-workflow-skill existe pero la herramienta skill de OpenCode no lo encuentra porque el sistema de skills no esta registrado en OpenCode (limitacion de la herramienta, no del archivo).

**Where**:
- scripts/utilities/token-usage-notifier.ps1 - linea 28-29: usa repoRoot para construir path, pero repoRoot se calcula incorrectamente cuando el script se ejecuta desde ubicacion diferente.

**Learned**:
- El autostart pipeline funciona correctamente cuando se ejecuta con timeout suficiente (completo 25/25 pasos).
- El token notifier funciona pero el archivo se guarda en .session/ (root) no en scripts/.session/.
- Los skills existen en el filesystem pero la herramienta skill de OpenCode no tiene acceso al registro de skills de gentle-vanguard.

---
*Imported from Engram on 2026-09-06*
