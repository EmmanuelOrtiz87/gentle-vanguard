---
created: 2026-09-10 04:29:09
tags: [engram, architecture]
engram_id: 3851
type: architecture
---

# Dashboard: panel Academy Leads (verificado)

**What**: Panel "Academy Leads" en el dashboard React — muestra los leads capturados desde la landing de Academy (nombre + email + audiencia) con breakdown por audiencia (Personas/Estudiantes/Empresas). Completa el loop: landing → leads → sync → stack → dashboard.

**Why**: El usuario pidió seguir conectando el stack. Los leads capturados en la landing ahora son visibles en el dashboard junto al panel de exports.

**Where**:
- `apps/web-dashboard/src/components/AcademyLeadsPanel.tsx` — NUEVO: self-fetching con polling 15s, fetch a /api/academy-leads, muestra total + barras por audiencia (gradiente cyan→purple), se oculta si total=0
- `apps/web-dashboard/src/components/Dashboard.tsx` — import + panel en grilla "SQLite Stack Tables" (junto a AcademyExportsPanel)
- `apps/web-dashboard/src/i18n/ui-strings.ts` — claves `ui.academy_leads` + `ui.academy_leads_total` (es/en/pt)

**Learned**: (1) GOTCHA: al reiniciar el dashboard vía command-center, el proceso Vite puede no levantarse (alive=False) — hay que verificar ambos procesos (server 8080 + vite 5173) y reiniciar de nuevo si falta. (2) El Vite dev server proxya /api/* al backend — los endpoints nuevos funcionan automáticamente una vez que Vite está arriba. (3) typecheck + build pasan. (4) Verificado en navegador: ambos paneles (Exports + Leads) renderizan con datos reales. (5) Estado: 20 cursos + 12 ebooks + 9 toolkits + 9 paquetes + Landing (home) con leads + Store + dashboard con 2 paneles Academy.

---
*Imported from Engram on 2026-09-10*
