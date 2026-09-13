---
created: 2026-09-11 13:47:32
tags: [engram, architecture]
engram_id: 3872
type: architecture
---

# CRM: botones compra removidos + vistas calendario + hover fix

**What**: Verificación end-to-end de los 3 fixes: (1) botones "Comprar / Contratar" eliminados de cursos, ebooks y toolkits en Academy, (2) vistas Día/Semana/Mes en Sessions del CRM funcionando, (3) hover del logo sin subrayado.

**Why**: El usuario reportó que los botones de compra no debían estar (Academy es gestión interna, no pública), que el logo se subrayaba al hover (a diferencia de las otras apps), y que Sessions necesitaba vistas de calendario por día/semana/mes.

**Where**:
- `apps/academy-web/app.js` — 3 botones "Comprar / Contratar" removidos de viewCourseHome (~2800), viewEbookHome (~3281), viewToolkit (~3530)
- `apps/academy-crm/src/shell.css` — `.gv-brand:hover { text-decoration: none; }` agregado
- `apps/academy-crm/src/pages/Sessions.tsx` — estado `view` (day/week/month), `selectedDay`, `monthOffset`; selector segmentado; render condicional por vista; navegación contextual
- `apps/academy-crm/src/i18n.ts` — claves sessions_view_day/week/month + sessions_empty_day/month (es/en/pt)

**Learned**: (1) Los botones "Comprar / Contratar" estaban en 3 lugares: viewCourseHome, viewEbookHome, viewToolkit — todos usaban `purchaseLink()` + `trackCrmEvent('buy_intent')`. Al removerlos, los hero-ctas quedan solo con botones internos (Comenzar, Leer, Exportar, Volver). (2) El hover subrayado venía de que `.gv-brand` es un `<a>` y el CSS global de academy-web tiene `a:hover { text-decoration: underline }` — el fix es `.gv-brand:hover { text-decoration: none; }`. (3) Las vistas de calendario usan un `crm-segmented` (mismo patrón que el selector de período en Dashboard) con render condicional: week = grid de 7 días, day = lista de cards, month = grid de cards con fecha. (4) Verificado: dump-dom de curso/ebook/toolkit confirma que "Comprar" y "Contratar" NO aparecen. Sessions page muestra Día/Semana/Mes con crm-segmented. (5) El error JSX era `</header>` en vez de `</div>` para cerrar el crm-section-head — error común al copiar estructura de un elemento a otro.

---
*Imported from Engram on 2026-09-12*
