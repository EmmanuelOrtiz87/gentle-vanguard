---
created: 2026-09-15 18:03:14
tags: [engram, bugfix]
engram_id: 3927
type: bugfix
---

# Fixes visuales shell: wordmark+idioma gv-analytics+font-size homologado

**Fix 1 — wordmark "Gentle" blanco + "Vanguard" gradiente (archify)**: `.gv-brand-wordmark span, .gv-wordmark span` en shell.css ya pinta el span con gradiente. Verifiqué que archify usa `<Shell appName="Archify">` del paquete — el wordmark compartido ya está homologado. Si en vivo se ve "Gentle" cian, es un override propio en `archify/src/App.css` (`.ar-brand-*`). **Pendiente de verificar en vivo** — no alcancé a snapshot del wordmark.

**Fix 2 — icono de idioma de gv-analytics**: usa botón con `文A` (glifo) pero NORM pide el dropdown homologado `.gv-lang-dropdown` del shell. **Pendiente** → migrar el botón suelto al dropdown compartido.

**Fix 3 — font-size del botón idioma homologado**: `.gv-lang-dropdown .gv-icon-btn, .gv-lang-dropdown-menu button` → fijar `font-size: 13.5px` en shell.css para que el botón de idioma sea idéntico en TODAS las apps (algunas lo pintan más grande y cubre el botón o se sale). Este es el fix nativo en el CSS compartido.

**Dónde**: `packages/gv-design-system/src/shell/shell.css` (font-size fijo) + `apps/gv-analytics/src/App.css|App.tsx` (dropdown homologado) + verificación archify wordmark en vivo.

---
*Imported from Engram on 2026-09-15*
