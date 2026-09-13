---
created: 2026-09-09 05:26:24
tags: [engram, architecture]
engram_id: 3802
type: architecture
---

# Academy: 9 cursos nuevos (330 lecciones) + skill de autoría

**What**: Expansión de GV Academy de 7 a 16 cursos (~330 lecciones nuevas): alfabetizacion-digital (54 lecciones), sql (46), pl-sql (38), python-inicial (41), python-intermedio (36), python-avanzado (37), web-inicial/web-intermedio/web-avanzado (~36 c/u). Todos con estándar didáctico ia-fundamentos (gancho → analogía → código ejecutable → errores comunes → mini-ejercicio), i18n es/en/pt, glosarios por curso. Registry regenerado (build-courses-registry.mjs), validate-multi-course.mjs 0 failures, smoke-academy.mjs 18/18 PASS (check de home actualizado a dinámico >=16). Skill nativa creada: .opencode/skills/academy-course-authoring/SKILL.md con el contrato completo de autoría.
**Why**: Usuario pidió cursos de alfabetización digital, Python ×3 niveles, páginas web ×3 niveles, SQL y PL/SQL, completos y didácticos, con research web (PCEP/PCAP + Oracle confirmados vía npm run web:select).
**Where**: apps/academy-web/data/courses/{alfabetizacion-digital,sql,pl-sql,python-inicial,python-intermedio,python-avanzado,web-inicial,web-intermedio,web-avanzado}/; apps/academy-web/data/courses.js (regenerado); apps/academy-web/scripts/smoke-academy.mjs (check dinámico); .opencode/skills/academy-course-authoring/SKILL.md.
**Learned**: (1) Los strings "md" de las lecciones deben ser JSON de UNA sola línea con \n escapado — saltos reales rompen sintaxis JS (los agentes usaron sanitizador tras node --check). (2) El subagente general puede fallar SILENCIOSAMENTE (retorna vacío sin crear nada) — siempre verificar con Test-Path tras cada task y reintentar o hacer el trabajo directo. (3) PowerShell no acepta {a,b} en paths de Get-ChildItem — usar array de dirs + foreach. (4) El smoke tenía expectativa hardcodeada "7 cursos" — los checks de catálogo deben ser dinámicos (>=N) porque el catálogo crece. (5) Delegación en paralelo: 1 de 3 agentes iniciales falló por red (EHOSTUNREACH) — retry funciona.

---
*Imported from Engram on 2026-09-09*
