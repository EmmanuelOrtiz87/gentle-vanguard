---
created: 2026-08-06 11:19:59
tags: [engram, bugfix]
engram_id: 2577
type: bugfix
---

# Fix DNS opencode.ai - Bypass Telefonica

**What**: Diagnóstico y solución del error ECONNREFUSED 127.9.9.9:443 en opencode
**Why**: El DNS de Telefónica estaba haciendo Walled Garden, redirigiendo opencode.ai a 127.9.9.9 en lugar de 104.21.40.138, impidiendo el uso de modelos y subagentes
**Where**:
- Backup hosts: `$env:TEMP\hosts.backup.*`
- Fix script: `C:\Users\emman\Documents\opencode-dns-fix.ps1`
- Documentación: `C:\Users\emman\Documents\opencode-dns-fix-README.md`
**Learned**:
- DNS Walled Garden: `walledgardenloopback.telefonica → 127.9.9.9`
- IPs reales opencode: `104.21.40.138` y `172.67.189.155` (Cloudflare)
- URLs afectadas: opencode.ai, api.opencode.ai, deepseek.opencode.ai
- Fix requiere: archivo hosts + flushdns + reinicio de opencode

---
*Imported from Engram on 2026-09-06*
