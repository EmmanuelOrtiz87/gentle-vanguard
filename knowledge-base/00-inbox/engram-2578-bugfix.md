---
created: 2026-08-06 11:30:29
tags: [engram, bugfix]
engram_id: 2578
type: bugfix
---

# Fix DNS opencode.ai Aplicado - Completo

**What**: Fix DNS opencode.ai aplicado exitosamente - Bypass Telefonica Walled Garden completado
**Why**: DNS de Telefonica resolvía opencode.ai a 127.9.9.9, bloqueando subagentes y modelos
**Where**:
- Archivo hosts: `C:\Windows\System32\drivers\etc\hosts`
- Backup: `$env:TEMP\hosts.backup.*`
- Entradas agregadas: `104.21.40.138 opencode.ai` (y otras)
**Learned**:
- A veces es necesario detener/iniciar servicio Dnscache para forzar recarga
- cmd /c funciona mejor que PowerShell para algunas operaciones en hosts
- Verificación final: nslookup debe mostrar 104.21.40.138, no 127.9.9.9
- Fix permanente hasta borrar líneas del hosts

---
*Imported from Engram on 2026-09-06*
