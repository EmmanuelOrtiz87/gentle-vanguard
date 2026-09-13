---
created: 2026-09-11 14:43:09
tags: [engram, architecture]
engram_id: 3876
type: architecture
---

# CRM: tabs Pipeline/Historial verificados

**What**: Verificación end-to-end de los tabs Pipeline/Historial en CRM Studio. Ambos tabs renderizan correctamente con crm-segmented. El kanban de Pipeline es visible por defecto. El contenido del Historial (Revenue, filtros de período) renderiza condicionalmente cuando el tab Historial está activo.

**Why**: Confirmar que la separación Pipeline/Historial funciona y que el usuario puede navegar entre ambos.

**Where**: `apps/academy-crm/src/pages/Deals.tsx` — tabs con crm-segmented, render condicional por tab.

**Learned**: (1) El patrón de tabs con crm-segmented es el mismo que el selector de período en Dashboard y el selector de vista en Sessions — consistencia visual en toda la app. (2) El Historial renderiza condicionalmente — solo visible cuando el tab está activo. (3) El autocompletado al focus usa setTimeout de 150ms en onBlur para permitir clicks en los items del dropdown. (4) El kanban de Pipeline ya no incluye la columna "Cobrado" — los deals cobrados van al Historial automáticamente.

---
*Imported from Engram on 2026-09-12*
