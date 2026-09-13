---
created: 2026-08-07 22:00:03
tags: [engram, bugfix]
engram_id: 2633
type: bugfix
---

# Fix: broken script tags blocked i18n.js in Chrome presentations

**What**: Las 11 presentaciones de docs/presentations tenían un tag `<script>` malformado: `<script src="assets/js/i18n-content.js?v=2.1"` sin `>` de cierre, con el siguiente `<script src="assets/js/i18n.js?v=2.1">` anidado DENTRO del atributo src del primero. Chrome lo ignoraba silenciosamente (sin errores en consola), por lo que i18n.js nunca se cargaba → window.__i18n nunca existía → el selector de idioma no traducía nada.
**Why**: La traducción funcionaba en happy-dom (parser permisivo) pero no en Chrome real. El usuario reportó "click en idioma no traduce nada" sin errores visibles. El modal de la "i" sí funcionaba porque gv.js SÍ cargaba (tenía tag bien formado) y usa fallback al title estático.
**Where**: docs/presentations/*.html (11 archivos) — bloque de scripts en <head>.
**Learned**:
1. Los validadores HTML lenient (happy-dom, jsdom) NO detectan tags <script> anidados dentro de atributos src. Solo un parser real (Chrome) lo expone.
2. Diagnóstico definitivo: Chrome DevTools Protocol (CDP) — `chrome --headless=new --remote-debugging-port=9225` + Node con ws + Runtime.evaluate para inspeccionar window.__i18n real, y `document.querySelectorAll('script[src]')` para ver qué scripts entraron al DOM. Esto reveló que i18n.js no estaba en la lista del DOM y que las respuestas HTTP no lo incluían.
3. `--dump-dom` de Chrome devuelve vacío en este entorno Windows (no usar).
4. Fix: separar en `<script src="i18n-content.js?v=2.1"></script>` + `<script src="i18n.js?v=2.1"></script>`.
5. Cache-busting con query string `?v=2.1` fuerza recarga de scripts nuevos.
6. Otros fixes de robustez: getCurrentLang() con try/catch (localStorage puede fallar en file://), getDict() usa getCurrentLang() por defecto, modal con fallback a title estático inyectado en el HTML.
7. Verificación final: cdp-verify-pages.js navega las 11 páginas, click EN→ES, confirma "Home"→"Inicio" en todas. PASs 11/11.

---
*Imported from Engram on 2026-09-06*
