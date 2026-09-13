---
created: 2026-09-10 03:40:38
tags: [engram, architecture]
engram_id: 3845
type: architecture
---

# Dashboard: panel Academy Exports (verificado)

**What**: Panel "Academy Exports" en el dashboard React de Gentle-Vanguard. Muestra las exportaciones de PDF de Academy (eBooks, Toolkits, Paquetes) sincronizadas desde el navegador al stack.

**Why**: Cierra el loop de la estrategia de venta: Academy (escaparate comercial) → sync → stack → dashboard con métricas de qué productos se exportan.

**Where**:
- `apps/web-dashboard/src/components/AcademyExportsPanel.tsx` — NUEVO: self-fetching con polling 15s (patrón ContinuationsPanel), fetch a /api/academy-exports, muestra total + top productos con badge de tipo (ebook cyan / toolkit purple / paquete emerald), se oculta si total=0
- `apps/web-dashboard/src/components/Dashboard.tsx` — import + panel en grilla "SQLite Stack Tables" (tras RoutingRulesPanel)
- `apps/web-dashboard/src/i18n/ui-strings.ts` — claves `ui.academy_exports` + `ui.academy_exports_total` (es/en/pt)

**Learned**: (1) El patrón de panel self-fetching: useCallback refresh + AbortController + setInterval 15s + cleanup. (2) Los archivos del dashboard están en el ignore pattern de eslint (warning "File ignored" no es error). (3) typecheck pasa, npm run build pasa (13.37s). (4) Verificado en navegador: el panel renderiza con datos reales (Manual Práctico + IA para Emprendedores visibles). (5) El dashboard usa locale EN por defecto — el título aparece como "Academy Exports".

---
*Imported from Engram on 2026-09-10*
