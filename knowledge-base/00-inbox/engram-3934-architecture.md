---
created: 2026-09-15 18:22:15
tags: [engram, architecture]
engram_id: 3934
type: architecture
---

# Nativo stack: patron "goto+eval sin open" + homologación vía shell.css del paquete (10 apps, 2026-09-15)

**Hallazgo + recomendación nativa (conocimiento absorbido para que sea nativo en TODO el stack v2 Premium)**:

**Qué**: El método correcto para operar apps GV en vivo en este Windows (10 apps homologadas) NUNCA es abrir `playwright-cli open` directo en la terminal (deja ventanas fantasma/consolas y requiere reintentos). El método nativo del stack es:

1. Servir la app con **`npm run preview -- --port N --host 127.0.0.1`** (vite preview build, no dev, sin HMR window).
2. Verificar con **`playwright-cli goto http://127.0.0.1:N/`** + **`playwright-cli eval "..."`** (sin `open`).
3. Para homologar el shell SIN reescribir App.css: editar **ÚNICAMENTE** `packages/gv-design-system/src/shell/shell.css` y luego `npm run build:components` (propaga a las 10 apps vía el paquete compartido).

**Dónde**: `packages/gv-design-system/src/shell/shell.css` — wordmark/idioma/tema/footer/shared css. Docs: `docs/stack-manual-full.md` + `docs/reference/homologacion.md`.

**Aprendido**: Playwright-cli en este entorno solo abre navegador persistente vía el MCP del stack (`engram_mcp_dashboard`), NO por terminal standalone (el proceso se cae por autoclose / ventanas). El patrón "goto + eval" es el homologado y verificado en las 10 apps esta sesión.

---
*Imported from Engram on 2026-09-15*
