---
created: 2026-07-25 01:04:01
tags: [engram, pattern]
engram_id: 1961
type: pattern
---

# NORMATIVA: Daemon spawn en Windows

**What**: NORMATIVA OBLIGATORIA — Para spawn de procesos detached en Windows, usar shell:true con full command string. NO usar shell:false con npx (npx.cmd no se encuentra con shell:false). NO usar shell:true con args array (genera deprecation warning en Node 24).

**Why**: En Windows, npx es npx.cmd (batch script). spawn con shell:false no encuentra .cmd files. spawn con shell:true + args array produce: "DeprecationWarning: Passing args to a child process with shell option true".

**Where**: src/start-monitor-daemon.ts, y cualquier script que haga spawn detached.

**Learned**:
- Usar: spawn('npx tsx script.ts --flag valor', [], { shell: true, detached: true, ... })
- NO usar: spawn('npx', ['tsx', 'script.ts'], { shell: false, ... }) — ENOENT en Windows
- NO usar: spawn('npx', ['tsx', 'script.ts'], { shell: true, ... }) — deprecation warning
- El error handler on('error') es obligatorio + un setTimeout de 500ms para verificar que el spawn fue exitoso antes de escribir PID file y hacer unref().

---
*Imported from Engram on 2026-09-06*
