---
created: 2026-09-10 20:31:59
tags: [engram, architecture]
engram_id: 3861
type: architecture
---

# Academy: 4 verticales Pro finales + fix priceTier en registries

**What**: Completadas las 4 verticales Pro restantes (Docentes, Estudiantes, Administración, Legal) + fix de 2 bugs estructurales. El catálogo Academy queda en 20 ebooks (10 micro + 10 premium) + 12 toolkits + 12 paquetes.

**Why**: El usuario pidió avanzar con lo pendiente. Los subagentes fallaron con timeout 504, así que el contenido se generó directamente (4 toolkits 50/8/8/6/4 + 4 ebooks premium de 12-15 capítulos cada uno).

**Where**:
- `apps/academy-web/data/toolkits/{ia-docentes-pro,ia-estudiantes-pro,ia-administracion-pro,ia-legal-pro}/` — toolkits premium
- `apps/academy-web/data/ebooks/{manual-ia-docentes,manual-ia-estudiantes,manual-ia-administracion,manual-ia-legal}/` — ebooks premium
- `apps/academy-web/scripts/build-{ebooks,toolkits,courses}-registry.mjs` — fix priceTier
- `apps/academy-web/README.md` — tabla de 12 toolkits + lista de 10 ebooks premium

**Learned**: (1) BUG priceTier: los 3 scripts de registry derivaban priceTier en memoria pero no lo persistían en el manifest de disco → el validador detectaba mismatch embebido vs disco (105 fallos). Fix: el campo derivado se escribe de vuelta al manifest (writeFileSync condicional con flag mutated). Los 3 scripts ahora son idempotentes y auto-persisten. (2) BUG IDs duplicados: manual-ia-docentes tenía cap-9 duplicado (15 caps); renumerado a secuencia limpia cap-1..cap-15. La renumeración con replaceAll colisiona si no se hace de mayor a menor Y se maneja el segundo duplicado por índice (indexOf), no por replaceAll. (3) GOTCHA: los subagentes pueden fallar con 504 (upstream timeout/overload) — ante fallo masivo, generar contenido directamente es más confiable. (4) Verificación Store: 12 paquete-cards + 19 pro-cards (10 premium + 9 Pro toolkits). (5) Estado final: 20 cursos + 20 ebooks (10 micro + 10 premium) + 12 toolkits + 12 paquetes + 52 portadas + Store + dashboard con 2 paneles + 2 alertas.

---
*Imported from Engram on 2026-09-12*
