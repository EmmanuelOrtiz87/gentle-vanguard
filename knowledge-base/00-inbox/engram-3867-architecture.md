---
created: 2026-09-11 01:04:38
tags: [engram, architecture]
engram_id: 3867
type: architecture
---

# CRM registrado en command-center + link Academy + verificado

**What**: CRM de Academy registrado en command-center + link desde Academy nav + server y UI verificados end-to-end.

**Why**: El usuario reportó que no veía el CRM en command-center ni en Academy. El CRM existía en apps/academy-crm/ pero no estaba registrado en APPS_REGISTRY ni tenía link de navegación.

**Where**:
- `apps/command-center/server.ts` — academy-crm agregado a APPS_REGISTRY (server: node --import tsx apps/academy-crm/server/server.ts, client: vite, url: http://127.0.0.1:4791)
- `apps/academy-web/index.html` — link "CRM ↗" en el nav (target _blank a http://127.0.0.1:4791)
- `apps/academy-crm/server/server.ts` — server en puerto 4790, health OK, dashboard API con datos reales (4 contactos, 1 deal sold $40, 1 sesión)
- `apps/academy-crm/` — UI Vite en puerto 4791, render verificado (brand, dashboard, deals, contactos, sesiones, pipeline)

**Learned**: (1) El CRM ya existía con código completo (React+Vite frontend, server REST en 4790, repo Nexus con 5 tablas crm_*) pero no estaba integrado al command-center ni al nav de Academy. (2) Vite por defecto bindea a IPv6 (::1) — usar --host 127.0.0.1 para que Chrome (IPv4) lo alcance. (3) El CRM tiene datos reales: 4 contactos, 1 deal sold ($40), 1 sesión completada. (4) El UI renderiza todas las secciones correctamente (verificado con dump-dom).

---
*Imported from Engram on 2026-09-12*
