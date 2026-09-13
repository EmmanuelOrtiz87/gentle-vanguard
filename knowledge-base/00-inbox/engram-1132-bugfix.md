---
created: 2026-05-25 15:10:27
tags: [engram, bugfix]
engram_id: 1132
type: bugfix
---

# Fix masivo: deteccion de repo root en 40 scripts

**What**: Fix masivo del patrón frágil `Test-Path (Join-Path $root 'config')` → `Join-Path $root 'config\orchestrator.json'` en 40 scripts PowerShell.

**Why**: El directorio `scripts/utilities/CONFIG/` existe literalmente, causando que `Test-Path 'config'` devuelva $true prematuramente. La detección de repo root se detenía en `scripts/utilities/` en vez de subir hasta el workspace root. Esto rompía la resolución de paths en 40 scripts — incluyendo `token-usage-notifier.ps1` que buscaba `.session/token-display-config.json` en `scripts/utilities/.session/` en vez del `.session/` real del proyecto.

**Where**: 40 archivos en `scripts/utilities/`, `scripts/adaptive/`, `scripts/security/` — reemplazo exacto de string con `.Replace()` para las variantes: `$root`, `$repoRoot`, `$WorkspaceRoot` + comillas simples/dobles.

**Learned**:
- `Test-Path (Join-Path $root 'config')` es demasiado permisivo — cualquier subdirectorio llamado "config" o "CONFIG" lo detiene.
- El patrón correcto es `Test-Path (Join-Path $root 'config\orchestrator.json')` que verifica un archivo específico.
- Tras este fix, las notificaciones de tokens funcionan al 100%: ambos paneles "This Turn" y "Session Accumulated" se renderizan correctamente con input/output/context/cost.

---
*Imported from Engram on 2026-09-06*
