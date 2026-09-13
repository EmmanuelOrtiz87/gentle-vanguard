---
created: 2026-08-07 20:40:24
tags: [engram, architecture]
engram_id: 2626
type: architecture
---

# Presentaciones GV renovadas: design system 2026 + i18n real + modal + selector idioma

**What**: Renovación completa de las 11 presentaciones HTML en `docs/presentations/` con design system 2025-2026 compartido.

**Why**: El usuario pidió unificar criterios visuales/UX, modernizar con tendencias actuales, añadir diagramas interactivos y arreglar que el i18n no traducía nada.

**Where**:
- `docs/presentations/assets/css/gv.css` — design system v2.0 (~700 líneas): tokens OKLCH, aurora gradients, grain noise, glass navbar, spotlight cards, scroll progress, btn-gv, modal, lang selector
- `docs/presentations/assets/js/gv.js` — effects: navbar scroll, scroll-progress fallback, reveal, spotlight, count-up, tilt, tooltips SVG (`[data-tip]`/`data-group`), modal de diagramas (`initDiagramModal`), typing
- `docs/presentations/assets/js/i18n.js` — diccionario ~140 claves por idioma (en/es/pt-BR) con `sec_*` para todos los títulos de sección + selector premium `.lang-btn`/`.lang-menu` (position:fixed para evitar recorte por overflow del navbar)
- `docs/presentations/diagrams/architecture-layers.svg` — rediseñado: chips sólidos #1e293b/texto #e2e8f0, 2 filas para capas densas, counters corregidos (Data 11, Pipeline 101, Memory 6, Agents 21), 6 capas con data-group+data-tip
- Las 11 presentaciones: todas con gv.css+gv.js+i18n.js, v3.5.0, datos reales (328 TS, 97 tests, 112/112 health, 21 agents, 170 skills, 65 rules), marcas "new" eliminadas → todo Active, h2 con data-i18n

**Learned**:
- En Windows PowerShell, `Set-Content` corrompe em-dashes/Unicode — usar `[System.IO.File]::WriteAllText($f, $t, (New-Object System.Text.UTF8Encoding $true))` siempre.
- El dump-dom de Chrome headless devuelve vacío en este entorno — usar happy-dom (npm i happy-dom en temp) para validación funcional del render JS.
- PELIGRO: un agente sdd-apply corrompió security-governance.html convirtiendo TODOS los `<` en `s` (sspan/sdiv) — se restauró desde git HEAD. Siempre verificar con regex `sdiv|sspan` tras ediciones de agentes.
- i18n real: traducir títulos de sección con data-i18n + claves sec_* es suficiente para que el cambio de idioma sea visible (el contenido de párrafos internos queda en inglés).
- Commits: fecc588f (design system + datos reales + diagramas) y cfaca261 (modal + selector idioma + i18n + fixes).

---
*Imported from Engram on 2026-09-06*
