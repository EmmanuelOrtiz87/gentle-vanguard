---
created: 2026-09-07 11:03:27
tags: [engram, bugfix]
engram_id: 3773
type: bugfix
---

# Fix file:// en academy-web — manifests embebidos

**What**: Fix del bug file:// en academy-web: el home mostraba "0 Cursos disponibles" al abrir index.html por doble clic. Causa raíz: fetchManifest usaba XHR síncrono como fallback para file://, y Chromium moderno lo bloquea por CORS ("Cross origin requests are only supported for protocol schemes: chrome, data, http, https"). Solución: manifests embebidos en data/courses.js generados desde course.json (fuente única de verdad) por scripts/build-courses-registry.mjs. app.js getManifest() usa course.manifest si está presente (sin fetch/XHR). Validador ampliado con check "manifest embebido == course.json" por curso.

**Why**: La academia promete "100% LOCAL, sin backend, sin build" — debía funcionar por doble clic. El XHR a file:// quedó obsoleto en Chromium moderno.

**Where**: apps/academy-web/scripts/build-courses-registry.mjs (nuevo generador), apps/academy-web/data/courses.js (regenerado con 5 manifests embebidos), apps/academy-web/app.js getManifest() (~línea 321), apps/academy-web/scripts/validate-multi-course.mjs (check de consistencia), apps/academy-web/scripts/smoke-academy.mjs (nuevo smoke test HTTP+file://, 10/10 PASS).

**Learned**:
1. XHR (síncrono o no) a file:// está bloqueado por CORS en Chromium moderno — no es viable como fallback. Script tags y manifests embebidos SÍ funcionan en file://.
2. Patrón reutilizable: fuente única (course.json) → artefacto generado commiteado (courses.js con manifests) → check de consistencia en el validador → smoke test en ambos modos (http + file).
3. El PASS del diagrama en smoke tests previos era falso positivo (SVGs del layout renderizan igual en view not-found). Verificar SIEMPRE el contenido real (cards, stats, texto), no solo presencia de elementos genéricos.
4. stop.sh de academy-web usa netstat (no disponible en git-bash de Windows) — matar python por puerto con Get-NetTCPConnection.

---
*Imported from Engram on 2026-09-08*
