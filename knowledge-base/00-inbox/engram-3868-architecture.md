---
created: 2026-09-11 01:13:15
tags: [engram, architecture]
engram_id: 3868
type: architecture
---

# CRM integrado en command-center (APPS_REGISTRY + definitions)

**What**: CRM de Academy integrado al command-center. El problema era doble: (1) academy-crm no estaba en APPS_REGISTRY, (2) incluso agregándolo ahí, faltaba la entrada en la función definitions() que mapea cada app a sus procesos (server/vite con puertos y pidFiles).

**Why**: El usuario reportó que no veía el CRM en command-center. La causa raíz era que APPS_REGISTRY solo tiene metadata — la función definitions() dentro de createAppsController() tiene entradas hardcodeadas APPS_REGISTRY[0..N] con processes() que definen cómo arrancar cada proceso.

**Where**:
- `apps/command-center/server.ts` — academy-crm agregado a APPS_REGISTRY (índice 7) Y a definitions() con processes: server (port 4790, ts server/server.ts) + vite (port 4791)
- `apps/academy-web/index.html` — link "CRM ↗" en nav
- `apps/academy-crm/server/server.ts` — puerto 4790, health OK
- `apps/academy-crm/` — UI Vite en 4791

**Learned**: (1) El command-center tiene DOS lugares para registrar una app: APPS_REGISTRY (metadata) y definitions() (procesos con puertos/pidFiles/start functions). Agregar solo a APPS_REGISTRY NO es suficiente. (2) El patrón es: APPS_REGISTRY[N] con ...spread en definitions(), cada proceso con name/port/pidFile/start. (3) Vite necesita --host 127.0.0.1 para que Chrome IPv4 lo alcance. (4) Verificado end-to-end: start/stop/restart desde command-center API, health check, dashboard API con datos, UI render. (5) El CRM tiene 8 estados de deal (lead→contacted→quoted→sold→delivered→paid/lost/cancelled) y ya tiene datos reales.

---
*Imported from Engram on 2026-09-12*
