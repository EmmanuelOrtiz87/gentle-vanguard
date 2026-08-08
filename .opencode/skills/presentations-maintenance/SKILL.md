---
name: presentations-maintenance
version: 1.0.0
description:
  Mantenimiento de la pantalla de inicio y el libro de presentaciones (docs/presentations/):
  info-triggers "i", i18n multi-idioma (en/es/pt-BR), lightbox de diagramas, capas SVG y
  validación estructural. Absorbe el conocimiento de la ronda de mejora de la home screen.
triggers:
  - presentations
  - info-trigger
  - home screen
  - pantalla de inicio
  - lightbox
  - i18n
  - executive-loop
  - architecture-layers
  - gv.js
  - gv.css
  - tip_
---

# Presentations Maintenance Skill

Libro de presentaciones interactivo en `docs/presentations/` con selector de idioma segmented
(`en/es/pt-BR`), info-triggers "i" que abren modales con explicaciones traducidas, y lightbox para
diagramas SVG.

## Comandos rápidos

```powershell
npm run presentations:serve          # Sirve la carpeta (puerto 3000, abre navegador)
npm run presentations:serve -- --port 8899 --no-browser --no-store   # Modo verificación CDP (sin caché)
npm run presentations:stop           # Detiene el servidor
npm run presentations:validate       # Validación estructural (11 archivos, 0 deps)
npx tsx src/cli/validate-presentations.ts --dir <path>   # Validar con ruta custom
```

Verificación en Chrome real (CDP): el servidor nativo con `--no-store` + Chrome CDP
(`--remote-debugging-port=9225`) + `scripts/cdp-verify-page.cjs` (cualquier página) o
`scripts/cdp-verify-final.cjs` (index.html completo). No depende de herramientas externas:
el flag `--no-store` del servidor TS evita la caché de modales i18n en recargas.

## Arquitectura de archivos

| Archivo                                             | Rol                                                        |
| --------------------------------------------------- | ---------------------------------------------------------- |
| `docs/presentations/index.html`                     | Home: 63 info-triggers en 6 secciones                      |
| `docs/presentations/*.html`                         | Resto del libro (11 páginas)                               |
| `assets/js/gv.js`                                   | Init modales (initInfoModal, initDiagramModal, lightbox)   |
| `assets/js/i18n.js`                                 | Diccionario `tip_*` + `sec_*` (208 claves × 3 idiomas)     |
| `assets/js/i18n-content.js`                         | Diccionario de contenido `c_*` (485 × 3)                   |
| `assets/css/gv.css`                                 | Estilos: `.info-trigger`, `.gv-lightbox`, `.lang-seg`      |
| `diagrams/architecture-layers.svg`                  | Capas de la arquitectura (L1-L4)                           |
| `diagrams/executive-loop.svg`                       | Loop ejecutivo con leyenda de colores                      |
| `src/cli/serve-presentations.ts`                    | Servidor estático TS (nativo)                              |
| `src/cli/stop-presentations.ts`                     | Parada del servidor (nativo)                               |
| `src/cli/validate-presentations.ts`                 | Validador estructural TS (nativo, 11/11 PASS)              |

## Conocimiento crítico (gotchas)

1. **`bi-brain` NO existe en bootstrap-icons 1.11.3** → usar `bi-book` (verificado en CDN). Siempre
   verificar que el icono existe antes de usarlo.
2. **GOTCHA `translate()` en i18n.js**: hace `el.textContent = merged[key]` que REEMPLAZA los hijos.
   En un `<td>` traducido, el info-trigger debe ser span HERMANO del texto traducido:
   `<td><span data-i18n="key">texto</span><span class="info-trigger" data-i18n-title="tip_*">i</span></td>`
3. **Idempotencia de inserción de claves**: si se comprueba globalmente "ya existe la clave", la
   detección del primer idioma omite el resto → comprobar POR BLOQUE de idioma + script dedupe.
4. **`$var:` en PowerShell** en interpolación rompe el parser → usar `${var}:`.
5. **Escritura de archivos**: usar siempre `[System.IO.File]::WriteAllText` con BOM UTF-8 en PS para
   no corromper los diccionarios.
6. **Lightbox centrado**: NO poner `max-width:100%; max-height:100%` en `.gv-lightbox-img` (doble
   escalado navegador+JS). El JS `open()` usa `img.decode().then(afterLoad)` + `naturalWidth > 0`
   (las imágenes cacheadas pueden reportar `complete=true` con `naturalWidth=0`).
7. **SVG**: tras editar, verificar viewBox y balance de grupos (`<g>`/`</g>`). El footer no debe
   colisionar con leyendas (reposicionar o ampliar viewBox).
8. **node --check** = test de sintaxis del JS del navegador (no usa TS).
9. **Commit**: solo archivos de trabajo de presentations; no tocar archivos automáticos de daemons.
10. **Doble convención de bloques**: `i18n.js` declara bloques como `en: {`, `es: {`, `'pt-BR': {` (pt-BR CON comillas simples, los otros sin). `i18n-content.js` usa `__GV_CONTENT.en = {`, `__GV_CONTENT.es = {`, `__GV_CONTENT['pt-BR'] = {` (corchetes). Cualquier regex de extracción que asuma un solo formato romperá: al recorrer TODOS los bloques sobrescribe con el último (pt-BR); al buscar el fin de un bloque con el formato equivocado captura todo el resto del archivo. Extraer SIEMPRE el bloque `en` de forma delimitada (entre su apertura y el siguiente bloque).
11. **ESM vs CommonJS**: el repo tiene `"type": "module"` en package.json → cualquier `.js` dentro del repo se trata como ES module y `require()` falla con "ReferenceError: require is not defined". Los scripts node que usan `require('ws')` deben llamarse `.cjs` (cdp-verify-final.cjs, cdp-verify-page.cjs). Fuera del repo (temp) pueden ser `.js`.

## Patrón de info-trigger (estándar)

```html
<span class="info-trigger" data-i18n-title="tip_auto_loop" title="fallback en inglés">i</span>
```

- `initInfoModal()` resuelve: `data-i18n-title` → `getDict()` → fallback `title`/`aria-label`.
- Claves en i18n.js: `tip_*` en 3 bloques de idioma (en/es/pt-BR) con el MISMO identificador.
- Secciones home: Autonomous (2), Data (10), Executive (12), Feature Matrix (38), Skills (9),
  Metrics (2). Total 63 + modal de Nexus.

## Reference Files

| File                              | Contenido                                          |
| --------------------------------- | -------------------------------------------------- |
| `references/common-tasks.md`      | Añadir info-triggers, claves i18n, editar SVG, CDP |
| `references/troubleshooting.md`   | Errores típicos y soluciones                       |

## Scripts nativos (carpeta `scripts/`)

Herramientas reutilizables, parametrizadas y probadas. Todas con `-DryRun` para ensayar sin escribir.

| Script                    | Función                                              | Uso                                      |
| ------------------------- | ---------------------------------------------------- | ---------------------------------------- |
| `insert-tips.ps1`         | Inserta claves `tip_*` desde JSON en i18n.js (por bloque) | `pwsh scripts/insert-tips.ps1 -DryRun` |
| `dedupe-i18n.ps1`         | Elimina duplicados en un bloque de idioma            | `pwsh scripts/dedupe-i18n.ps1 -Block en` |
| `homologate-matrix.ps1`   | Convierte tds de la Feature Matrix en span + trigger | `pwsh scripts/homologate-matrix.ps1 -DryRun` |
| `homologate-pages.ps1`    | Homologa tds en TODAS las páginas (title fallback EN desde i18n-content.js) | `pwsh scripts/homologate-pages.ps1 -Page health.html` |
| `gen-tips-c.ps1`          | Genera claves `tip_c_*` en 3 idiomas desde i18n-content.js (traducción automática de modales) | `pwsh scripts/gen-tips-c.ps1 -DryRun` |
| `cdp-verify-final.cjs`    | Verificación en Chrome real (CDP), 6 checks (index.html) | `node scripts/cdp-verify-final.cjs --cdp 9225` |
| `cdp-verify-page.cjs`     | Verificación genérica de info-triggers + modales EN/ES/PT en CUALQUIER página | `node scripts/cdp-verify-page.cjs --page=health.html` |
| `tips-new.json`           | Claves `tip_*` genéricas (en/es/pt-BR) para insertar | dato para `insert-tips.ps1`               |
| `tips-fm.json`            | Claves `tip_fm_*` de la Feature Matrix               | dato para `homologate-matrix.ps1`         |

Los scripts detectan el repo por defecto (paths relativos desde el cwd) y aceptan `-JsonPath`/`-JsPath`/`-HtmlPath`/`--origin`/`--page` explícitos. Se verificaron en seco: insert-tips idempotente (0 claves reinsertadas), dedupe 0 duplicados (353/bloque), homologate 0 filas restantes.

## Flujo completo de homologación multi-idioma

1. `homologate-pages.ps1 -DryRun` — ver alcance (tds sin trigger)
2. `homologate-pages.ps1` — transforma tds → `span + info-trigger` (title fallback EN)
3. `gen-tips-c.ps1 -DryRun` — ver claves `tip_c_*` a generar
4. `gen-tips-c.ps1` — inserta traducciones en los 3 bloques (modales multi-idioma)
5. `npm run presentations:validate` — 11/11 PASS esperado
6. Verificación CDP en Chrome real (health/security-governance/quickstart): modales EN+ES traducidos
