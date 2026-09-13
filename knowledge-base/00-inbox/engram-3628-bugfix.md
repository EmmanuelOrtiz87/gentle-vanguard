---
created: 2026-09-02 15:58:46
tags: [engram, bugfix]
engram_id: 3628
type: bugfix
---

# Academy actualizada a datos reales del stack (v4.0.0, 113 checks, 23 skills)

**What**: Actualicé TODA la documentación de la Academy (`apps/academy-web/data/*.js`, 15 archivos) contra los datos reales del stack, corrigiendo cifras y versiones obsoletas.

**Why**: La Academy es la app de capacitación que monetiza; contenía cifras desactualizadas que no coincidían con la realidad del stack (v3.x, 12 skills, 95/97 checks, 21 componentes).

**Where**: `apps/academy-web/data/` — content-agentes.js, content-arquitectura.js, content-automatizaciones.js, content-fundamentos.js, content-laboratorio.js, content-negocio.js, content-optimizacion.js, content-workflows.js, glossary.js, files.js.

**Learned**:
- Número canónico del watchtower: **113 checks / 26 componentes** (verificado en `src/core/watchtower/checks-*.ts`; 26 componentes contados de comentarios `Component:`, 113 checks = 112 PASS + 1 WARN real).
- CRITICAL_SKILLS en `src/integrations/zcode-sync.ts` = **23 skills** (referencia canónica).
- Versión actual del stack = **v4.0.0**.
- GOTCHA: los bloques de código Markdown dentro de las cadenas JS de `data/*.js` usan backticks ESCAPADOS (`\`\`\``). Al editar con`edit`, si se reemplaza por backticks literales (`` ``` ``) se rompe la sintaxis del archivo. Siempre verificar con`node --check` tras editar.
- Correcciones aplicadas: 12→23 skills (8 refs), v3.x→v4.0.0 (6 refs), 95/97 checks→113 (muchas refs en 10 archivos), 21→26 componentes.
- Validación: todos los `data/*.js` pasan `node --check` (0 FAIL), la app sirve y renderiza (DOM 13K chars), typecheck EXIT=0, lint EXIT=0.

---
*Imported from Engram on 2026-09-06*
