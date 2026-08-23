---
name: presentations-maintenance
aliases: ["presentations-maintenance"]
description:
  Mantenimiento de la pantalla de inicio y el libro de presentaciones (docs/presentations/):
  info-triggers "i", i18n multi-idioma (en/es/pt-BR), lightbox de diagramas, capas SVG y
  validación estructural. Absorbe el conocimiento de la ronda de mejora de la home screen.
version: 1.0.0
  
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
metadata:
  source: opencode-migrated
  migrated: true
  migratedAt: "2026-08-09T21:55:57.075Z"
  originalPath: C:\Workspace_local\gentle-vanguard\.opencode\skills\presentations-maintenance\SKILL.md
  version: "1.0.0"
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
npm run presentations:verify:cdp -- --page=health.html   # Verificación CDP en Chrome real (3 idiomas)
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
| `diagrams/architecture-layers.svg`                  | Capas de la arquitectura (6 hotspots)                  |
| `diagrams/executive-loop.svg`                       | Loop ejecutivo (11 hotspots)                          |
| `diagrams/pipeline-flow.svg`                        | Pipeline de 101 pasos (8 hotspots)                    |
| `diagrams/data-architecture.svg`                    | Arquitectura Nexus DB (5 hotspots)                    |
| `diagrams/stack-dashboard.svg`                      | Arquitectura del dashboard (5 hotspots)               |
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
12. **Hotspots SVG**: el lightbox carga el SVG inline (fetch) y delega clicks en `.gv-hotspot` (closest) → `__gvShowInfo(data-i18n-title)`. Los hotspots pueden ser `<g>` existentes (convertidos con `src/cli/validate-presentations.ts`) o `<rect>` transparentes inyectados (`src/cli/validate-presentations.ts`). El CSS `.gv-lightbox-svg .gv-hotspot` da fill transparente + hover púrpura.
13. **`\n` literal en PS**: escribir `"\n"` en PowerShell NO crea un salto de línea real (backslash-n literal). Usar `` "`n" `` (backtick-n) o `[Environment]::NewLine`. Un `\n` literal dentro del XML SVG es texto inofensivo pero sucio.
14. **`$args` es automático en PowerShell**: no usarlo como nombre de variable propia dentro de un script (colisiona con los argumentos posicionales del script). Usar `$passArgs` o splatting de hashtable `@{ param = valor }`.
15. **CDP con `returnByValue`**: `Runtime.evaluate` con `returnByValue:true` + `awaitPromise:true` devuelve el objeto YA deserializado en `result.value` — NO hacer `JSON.parse` encima. Plantillas de string con interpolación de variables Node: usar `${var}` dentro del template literal, nunca concatenar con `' + var + '` (queda como texto literal en el navegador).
16. **localStorage `gv-lang` persiste entre páginas CDP**: al navegar en una verificación, forzar el idioma base con `localStorage.setItem('gv-lang','en')` + click en `[data-lang="en"]` antes de evaluar EN.

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
| `src/cli/validate-presentations.ts`         | Inserta claves `tip_*` desde JSON en i18n.js (por bloque) | `pwsh scripts/src/cli/validate-presentations.ts -DryRun` |
| `src/cli/validate-presentations.ts`         | Elimina duplicados en un bloque de idioma            | `pwsh scripts/src/cli/validate-presentations.ts -Block en` |
| `src/cli/validate-presentations.ts`   | Convierte tds de la Feature Matrix en span + trigger | `pwsh scripts/src/cli/validate-presentations.ts -DryRun` |
| `src/cli/validate-presentations.ts`    | Homologa tds en TODAS las páginas (title fallback EN desde i18n-content.js) | `pwsh scripts/src/cli/validate-presentations.ts -Page health.html` |
| `src/cli/validate-presentations.ts`          | Genera claves `tip_c_*` en 3 idiomas desde i18n-content.js (traducción automática de modales) | `pwsh scripts/src/cli/validate-presentations.ts -DryRun` |
| `cdp-verify-final.cjs`    | Verificación en Chrome real (CDP), 6 checks (index.html) | `node scripts/cdp-verify-final.cjs --cdp 9225` |
| `cdp-verify-page.cjs`     | Verificación genérica de info-triggers + modales EN/ES/PT en CUALQUIER página | `node scripts/cdp-verify-page.cjs --page=health.html` |
| `src/cli/validate-presentations.ts`      | Convierte `<g class="gv-node">` → `gv-hotspot` + `data-i18n-title` en SVG | `pwsh scripts/src/cli/validate-presentations.ts -File architecture-layers.svg -DryRun` |
| `src/cli/validate-presentations.ts`     | Inyecta rects `<rect class="gv-hotspot">` transparentes (zona clicable) antes de `</svg>` | `pwsh scripts/src/cli/validate-presentations.ts -DryRun` |
| `src/cli/validate-presentations.ts`        | Aplana `svg-zones.json` → formato insert-tips y delega (87 claves en 3 idiomas) | `pwsh scripts/src/cli/validate-presentations.ts -DryRun` |
| `cdp-verify-svg.cjs`      | Verifica SVG inline en lightbox (hotspots, viewBox, fit) | `node scripts/cdp-verify-svg.cjs` |
| `cdp-verify-hotspot.cjs`  | Verifica click en hotspot → modal info (un SVG, idioma actual) | `node scripts/cdp-verify-hotspot.cjs` |
| `cdp-verify-hotspot-multilang.cjs` | Verifica hotspot en los 3 idiomas (cambia con botones data-lang) | `node scripts/cdp-verify-hotspot-multilang.cjs` |
| `cdp-verify-hotspots-all.cjs` | Verifica 1 hotspot de cada diagrama en 3 idiomas (autonomy/agents-pipeline/operations-cloud/dashboard) | `node scripts/cdp-verify-hotspots-all.cjs` |
| `tips-new.json`           | Claves `tip_*` genéricas (en/es/pt-BR) para insertar | dato para `src/cli/validate-presentations.ts`               |
| `tips-fm.json`            | Claves `tip_fm_*` de la Feature Matrix               | dato para `src/cli/validate-presentations.ts`         |
| `tips-hs.json`            | Claves `tip_hs_*` de hotspots gv-node (en/es/pt-BR) | dato para `src/cli/validate-presentations.ts`               |
| `svg-zones.json`          | Zonas hotspot de los 4 SVG: `{archivo: {tipKey: {rect, en, es, pt-BR}}}` | dato para `src/cli/validate-presentations.ts` + `src/cli/validate-presentations.ts` |

Los scripts detectan el repo por defecto (paths relativos desde el cwd) y aceptan `-JsonPath`/`-JsPath`/`-HtmlPath`/`--origin`/`--page` explícitos. Se verificaron en seco: insert-tips idempotente (0 claves reinsertadas), dedupe 0 duplicados (353/bloque), homologate 0 filas restantes.

## Flujo completo de homologación multi-idioma

1. `src/cli/validate-presentations.ts -DryRun` — ver alcance (tds sin trigger)
2. `src/cli/validate-presentations.ts` — transforma tds → `span + info-trigger` (title fallback EN)
3. `src/cli/validate-presentations.ts -DryRun` — ver claves `tip_c_*` a generar
4. `src/cli/validate-presentations.ts` — inserta traducciones en los 3 bloques (modales multi-idioma)
5. `npm run presentations:validate` — 11/11 PASS esperado
6. Verificación CDP en Chrome real (health/security-governance/quickstart): modales EN+ES traducidos

## Flujo de hotspots SVG interactivos

Los diagramas ampliados en el lightbox son clicables: cada zona (`data-i18n-title="tip_hs_*"`) abre
el modal info multi-idioma vía `__gvShowInfo()`.

1. **Definir zonas**: en `scripts/svg-zones.json` — `{ "<archivo>.svg": { "<tipKey>": { "rect": [x,y,w,h], "en": "..", "es": "..", "pt-BR": ".." } } }`.
   - Las coordenadas `rect` son del viewBox del SVG (obtenerlas del `<rect>`/`<circle>` existente del elemento).
   - Para `gv-node` existentes (architecture-layers) usar `src/cli/validate-presentations.ts` que añade la clase + atributo sin coordenadas.
2. **Inyectar rects**: `pwsh scripts/src/cli/validate-presentations.ts -DryRun` → luego sin flag. Añade `<rect class="gv-hotspot" ... fill="transparent">` antes de `</svg>`. Idempotente.
3. **Insertar claves i18n**: `pwsh scripts/src/cli/validate-presentations.ts -DryRun` → luego sin flag (87 claves = 29 zonas × 3 idiomas).
4. **Validar**: `node --check assets/js/i18n.js` + `npm run presentations:validate` (11/11 PASS).
5. **Verificar CDP**: `node scripts/cdp-verify-hotspots-all.cjs` (4 diagramas × 3 idiomas, ALL PASS esperado).
   - Páginas: autonomy→executive-loop, agents-pipeline→pipeline-flow, operations-cloud→data-architecture, dashboard→stack-dashboard.
   - Forzar `gv-lang` en localStorage al inicio (gotcha #16).
6. **Piloto concreto (architecture-layers)**: sus 6 `gv-node` usan `src/cli/validate-presentations.ts` + `tips-hs.json` (18 claves).

## Usage

Use **presentations-maintenance** when a task matches its triggers (presentations - info-trigger - home screen - pantalla de inicio - lightbox - i18n - executive-loop - architecture-layers - gv.js - gv.css - tip_).

Purpose: Mantenimiento de la pantalla de inicio y el libro de presentaciones (docs/presentations/):

## Examples

Concrete usage drawn from this skill's own documentation:

```powershell
npm run presentations:serve          # Sirve la carpeta (puerto 3000, abre navegador)
npm run presentations:serve -- --port 8899 --no-browser --no-store   # Modo verificación CDP (sin caché)
npm run presentations:stop           # Detiene el servidor
npm run presentations:validate       # Validación estructural (11 archivos, 0 deps)
npm run presentations:verify:cdp -- --page=health.html   # Verificación CDP en Chrome real (3 idiomas)
npx tsx src/cli/validate-presentations.ts --dir <path>   # Validar con ruta custom
```
