---
created: 2026-09-10 04:44:42
tags: [engram, architecture]
engram_id: 3854
type: architecture
---

# Dashboard: alertas de Academy (leads + exports)

**What**: Alertas de Academy en el sistema de alertas del stack. Métricas `academy.leadsTotal/leads24h/exportsTotal/exports24h` en generateMetrics() + 2 reglas en dashboard-alerts.json: "New Academy Leads" (leads24h >= 1, info) y "Academy Exports Activity" (exports24h >= 1, info).

**Why**: El usuario pidió conectar el stack. Los leads/exports de Academy ahora disparan alertas en el dashboard — visibilidad inmediata de actividad comercial.

**Where**:
- `apps/web-dashboard/server/ws-hub/metrics.ts` — `readAcademyMetrics()` (cuenta JSONL de leads/exports, total + ventana 24h) + `countJsonl()` helper (best-effort, ignora líneas incompletas); `academy` agregado al objeto de generateMetrics()
- `config/dashboard-alerts.json` — reglas `academy_new_leads` (leads24h >= 1, info) + `academy_exports_activity` (exports24h >= 1, info)

**Learned**: (1) El sistema de alertas evalúa métricas de generateMetrics() contra thresholds — para "actividad reciente" se usa una ventana de 24h (ts del JSONL) en vez del total. (2) GOTCHA recurrente: al reiniciar el dashboard vía command-center, Vite (5173) puede no levantarse — verificar ambos procesos y reiniciar si falta. (3) Verificado: alerta academy_new_leads triggered=True con 1 lead, academy_exports_activity triggered=True con 1 export; ambos paneles + CSV + alertas renderizan en el dashboard. (4) typecheck + lint pasan. (5) Estado: 20 cursos + 12 ebooks + 9 toolkits + 9 paquetes + Landing (home) con leads + Store + dashboard con 2 paneles Academy + 2 alertas Academy.

---
*Imported from Engram on 2026-09-10*
