---
created: 2026-09-07 04:45:42
tags: [engram, bugfix]
engram_id: 3768
type: bugfix
---

# Fix: scripts start/stop de apps fallaban por bash WSL en PATH

**What**: Los scripts `apps/*/start.sh|stop.sh` fallaban con exit 127 (`netstat: command not found`, `node: command not found`) al ejecutarlos manualmente. Causa: `bash` en el PATH resolvía al stub de WSL (`C:\Users\emman\AppData\Local\Microsoft\WindowsApps\bash.exe`, 0 bytes) en vez de Git Bash. WSL Ubuntu no tiene netstat/node en su PATH.

**Why**: El PATH de usuario tenía `WindowsApps` pero no `C:\Program Files\Git\bin` (solo `Git\cmd`, que trae git.exe pero no bash.exe). La doc `docs/APP-LIFECYCLE.md` asume Git Bash.

**Where**: PATH de usuario (fix persistente vía `[Environment]::SetEnvironmentVariable("Path", "C:\Program Files\Git\bin;<userPath>", "User")`). Scripts afectados: apps/{command-center,web-dashboard,gv-analytics,content-cms,academy-web,prompt-studio,archify,design-hub}/start.sh|stop.sh.

**Learned**:
- Verificación: `Get-Command bash` debe resolver a `C:\Program Files\Git\bin\bash.exe`, no a WindowsApps.
- El fix requiere terminal NUEVA para tomar efecto (PATH se lee al arrancar el proceso).
- Los scripts funcionan con Git Bash: probados start+stop de academy-web (puerto 4173) y start de command-center/dashboard (idempotentes).
- El autostart de sesión levanta dashboard (8080/5173) + command-center (8090) por lazy steps; el resto de apps quedan stopped hasta pedirlas.
- Nota: al invocar start.sh desde el shell tool, el wrapper foreground muere con "ChildProcess.kill" pero el daemon detached sobrevive (regla procesos-ocultos) — es comportamiento esperado.

---
*Imported from Engram on 2026-09-08*
