# Design Hub — Documentación integral

> App: `apps/design-hub` v2.0.0 | Puerto **8095** | Local-first, HTML/CSS/JS vanilla, cero deps,
> cero build. Estado: Production Ready (2026-09-01). Reemplazó y eliminó a
> `gv-design-system-catalog` y `gv-design-studio`.

## 1. Documentación de negocio

### Propósito

Centralizar TODO lo referido a diseño de la marca Gentle-Vanguard en una sola herramienta nativa:
ver, comparar, editar, exportar y aprobar el sistema de diseño (tokens, componentes, assets, brand).

### Objetivos

1. **Decisión de branding informada**: comparación v1 vs v2 lado a lado (sliders, IDs técnicos,
   historial de cambios) para aprobar/rechazar/alterar el nuevo diseño antes de migrar apps.
2. **Fuente única**: tokens v2 (`public/tokens/tokens-v2.json`, espejo de
   `docs/brand/TOKENS-v2.json`) editables con exportación CSS/JSON.
3. **Escala**: una vez aprobado en Academy (app inicial), normalizar el resto del ecosistema.

### Usuarios y valor

| Usuario                | Valor                                                                   |
| ---------------------- | ----------------------------------------------------------------------- |
| Owner/decisor de marca | Comparar v1/v2 y aprobar con historial, sin depender de devs            |
| Devs de apps           | Tokens exportables + componentes copiables → adopción rápida v2         |
| Marketing              | Asset generator (logos, favicons, banners OG) sin herramientas externas |

### Deprecaciones ejecutadas

- `gv-design-system-catalog` → Tokens + Components del hub. App eliminada (etapa 4, 2026-09-02).
- `gv-design-studio` → Token Editor del hub. App eliminada (etapa 4, 2026-09-02).
- Sus entradas comentadas fueron removidas de `apps/command-center/server.ts`.

## 2. Documentación funcional

| Herramienta       | URL (relativa a :8095)    | Funciones                                                                                                                                         |
| ----------------- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| Dashboard         | `/`                       | Panorama, stats de tokens, accesos                                                                                                                |
| Visual Comparison | `/src/visual-comparison/` | Split v1/v2 en vivo, sliders, IDs (ej. `COLOR-BG-BASE`), tabs Comparar/Controles/Exportar                                                         |
| Token Editor      | `/src/tokens-editor/`     | Editar tokens (color/gradient/shadow/typography/size/motion), preview en vivo, export CSS+JSON, historial localStorage con approve/reject/restore |
| Component Library | `/src/components/`        | gv2-btn (3 sizes × 4 variants × 4 estados), card, input, tag, icon-btn; código copiable                                                           |
| Asset Generator   | `/src/asset-generator/`   | Matriz logo×fondo×tamaño, favicon canvas, banner OG 1200×630                                                                                      |
| Documentation     | `/src/documentation/`     | Brand Guidelines v2, Implementation Guide v2, Summary, Changelog, Migration status                                                                |

### Flujo de aprobación de diseño (uso previsto)

1. Abrir Visual Comparison → revisar v1 vs v2 (tipografía, color, atmósfera, componentes).
2. Ajustes finos en Token Editor (cada cambio queda en History como _proposed_).
3. Marcar cada cambio _approved_ / _rejected_; exportar JSON final.
4. Aplicar a Academy (app inicial) → validar → expandir al resto de apps.

## 3. Documentación técnica

### Estructura

```
apps/design-hub/
├── index.html, package.json, README.md
├── scripts/ start.js|stop.js|status.js  (pidfile .runtime/app-design-hub-http.pid)
├── start.sh / stop.sh                   (bash nativo, ver docs/APP-LIFECYCLE.md)
├── public/assets/       4 SVGs logo v2
├── public/tokens/       tokens-v2.json|css, tokens-v1.css
├── src/styles/main.css  clases gv-* / gv2-*
├── src/{visual-comparison,tokens-editor,components,asset-generator,documentation}/
└── tools/ export-tokens.js | build-docs.js | validate.js
```

### Ciclo de vida

- Bash directo: `./start.sh` / `./stop.sh` (idempotentes, fallback netstat+taskkill).
- Node: `npm run start|stop|status` (dentro de apps/design-hub).
- Command Center: app id `design-hub` en `apps/command-center/server.ts` (UI :8090).
- Server: `python -m http.server 8095 --bind 127.0.0.1` (loopback only, ADR-0017).

### Fuentes de verdad y sincronización

- Tokens v2: `docs/brand/TOKENS-v2.json` → espejo servido en `public/tokens/tokens-v2.json`. Tras
  editar la fuente: copiar + `node tools/export-tokens.js` (regenera CSS v1/v2).
- Docs de marca: `docs/brand/*.md` → regenerar HTML con `node tools/build-docs.js`.
- Validación CI-able: `node tools/validate.js` (archivos requeridos, sin 404s internos, CSS
  completo).

### Limitaciones conocidas

- Token Editor persiste en localStorage del navegador (no escribe la fuente JSON — decisión
  deliberada: los cambios aprobados se exportan y se aplican por commit).
- El editor requiere servirse por HTTP (fetch), no file://.
