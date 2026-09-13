# academy-multi-course — INIT

**Fecha**: 2026-09-06 **Workspace**: `apps/academy-web/` **Trigger**: usuario explícito "convertir
academy-web en centro de estudio multi-tema tipo Udemy, con gentle-vanguard como un curso más".
**Fase SDD**: INIT (completada en este turno).

## Stack detectado

- **App shell**: SPA vanilla (HTML + JS + CSS), cero dependencias, cero build.
- **Servidor dev**: `python -m http.server 4173 -d .`
- **Versión stack**: v3.9.0 (`STACK_VERSION` en `app.js:11`).
- **Design system**: v2 Premium, snapshot canónico + 6 CSS locales (`academy-tokens-v2.css`,
  `academy-atmosphere-v2.css`, `academy-style-v2.css`, `academy-components-v2.css`,
  `academy-layout.css`, `academy-motion.css`).
- **Logo**: `assets/logo.svg` (monograma v1 + gradiente v2), wordmark "Vanguard" con gradiente via
  regla local `.name span` en `academy-layout.css` (waiver brand).
- **i18n**: 3 locales hardcoded en `app.js` (`es`/`en`/`pt`), persistencia en
  `localStorage gv-cc-lang`. Keys de tracks (fundamentals, architecture, ...) están acopladas a IDs
  de gentle-vanguard.
- **Tema**: dark/light toggle, persistencia en `localStorage gv-cc-theme`.
- **Router**: hash-based (`#/`, `#/track/:id`, `#/lesson/:track/:lesson`, `#/glosario`, `#/demo`).
- **Búsqueda**: global sobre todos los tracks + glosario, en `app.js`.
- **Persistencia progreso**: localStorage, solo en academy-web (no Nexus).

## Convenciones detectadas

- Contenido: `window.GV_CONTENT[trackId] = { lessons: [{id, title, minutes, type, md}] }`. Markdown
  subset: títulos, énfasis, código, listas, citas, tablas, separadores, resaltado `==texto==`,
  bloques `:::diagram <id>:::`.
- Tracks: `window.GV_TRACKS = [{id, type, title, desc}]` plano, 12 entries.
- Glosario: `window.GV_GLOSSARY = [{term, cat, def}]` plano, global, categorías
  `ia|tecnico|negocio|stack`.
- Imágenes demo: `window.GV_DEMO_IMAGES` y `window.GV_FILES` (assets compartidos).
- Comandos operativos (start/stop): `start.sh` / `stop.sh` (bash, no PowerShell).
- Otras apps lo invocan bajo demanda desde Command Center (`:8090`).

## Bootstrap persistence

- Sin backend. localStorage para progreso/tema/idioma.
- No requiere Nexus ni Engram.
- El refactor mantiene el principio LOCAL-FIRST (ADR-0017).

## Versión de academy-web actual

- v3.8.2 (`package.json`).
- Plan: bumpear a v4.0.0 cuando se aplique el refactor (breaking change de URLs si no se hace
  redirect legacy).

## Estado de memoria

- Ya estaba en memoria como "roadmap próxima sesión" (MEMORY.md, sección
  `roadmap proxima sesion gentle-vanguard`).
- La versión de apps está en el aire (3 opciones: sub-repos por app, monorepo full, dejar working
  tree). Esto NO bloquea el SDD, pero afecta cómo se committean los archivos nuevos. Decidir antes
  de APPLY.
