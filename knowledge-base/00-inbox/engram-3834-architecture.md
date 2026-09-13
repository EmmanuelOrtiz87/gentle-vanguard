---
created: 2026-09-09 22:30:26
tags: [engram, architecture]
engram_id: 3834
type: architecture
---

# Academy: 4 toolkits (emprendedores, docentes, estudiantes, profesionales)

**What**: Expansión de la sección Toolkit de Academy de 1 a 4 toolkits completos, siguiendo la estrategia de venta (cada toolkit = curso + ebook + prompts + plantillas + emails + automatizaciones + casos).

**Why**: El usuario pidió continuar potenciando Academy. Los toolkits emparejan los ebooks existentes (lead magnets) con cursos, creando bundles de mayor valor para distintos públicos: emprendedores, docentes, estudiantes y profesionales.

**Where**:
- `apps/academy-web/data/toolkits/ia-docentes/` — 50 prompts + 8 plantillas + 8 emails + 6 automatizaciones + 4 casos (links: curso ia-fundamentos + ebook chatgpt-docentes)
- `apps/academy-web/data/toolkits/ia-estudiantes/` — 50/8/8/6/4 (links: ia-fundamentos + ia-estudiantes)
- `apps/academy-web/data/toolkits/ia-profesionales/` — 50/8/8/6/4 (links: ia-fundamentos + manual-ia-profesionales)
- `apps/academy-web/data/toolkits.js` — registry regenerado (4 toolkits)
- `apps/academy-web/README.md` — tabla de toolkits actualizada

**Learned**: (1) El patrón de toolkit es escalable: cada nuevo toolkit solo necesita toolkit.json (manifest con links a curso/ebook) + content.js (5 secciones con items). (2) La generación de contenido se delega eficientemente a subagentes en paralelo con instrucciones precisas (conteo exacto por sección). (3) Verificar SIEMPRE el output de los subagentes — uno devolvió solo "DONE" sin reporte, pero el archivo estaba correcto (50/8/8/6/4). (4) El validador validate-ebooks-toolkits.mjs cubre automáticamente los toolkits nuevos (requiere ≥3 secciones y ≥20 items).

---
*Imported from Engram on 2026-09-09*
