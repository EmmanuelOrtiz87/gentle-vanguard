# Common Tasks — Presentations Maintenance

## Añadir un info-trigger "i"

1. Insertar en el HTML donde corresponda (span HERMANO del texto, NUNCA hijo — ver gotcha #2):

```html
<span class="info-trigger" data-i18n-title="tip_mi_clave" title="Fallback en inglés">i</span>
```

2. Añadir la clave `tip_mi_clave` en los 3 bloques de idioma de `assets/js/i18n.js`
   (`const en = {...}`, `const es = {...}`, `const pt = {...}`). El formato es
   `tip_mi_clave: { en: "...", es: "...", "pt-BR": "..." }`.

3. Si el texto que acompaña también es traducible y está en un `<td>`, usar:
   `<td><span data-i18n="key">texto</span><span class="info-trigger" ...>i</span></td>`

4. Validar: `npm run presentations:validate` (el validador comprueba que todos los
   `.info-trigger` tengan `data-i18n-title`).

## Añadir una clave al diccionario i18n.js

- **Idempotencia**: comprobar POR BLOQUE de idioma si la clave existe. Si se comprueba globalmente,
  el primer idioma detectado hace que el resto se omita (gotcha #3).
- Después de editar: `node --check docs/presentations/assets/js/i18n.js` para sintaxis.
- Estado sano: 208 claves por bloque (en/es/pt-BR), 0 duplicados. Verificar con
  `npm run presentations:maintenance -- dedupe-i18n --dry-run` (reporta total sin escribir).

## Editar un SVG de diagrama

- Verificar que el icono/bootstrap class existe (gotcha #1).
- Tras reposicionar elementos, comprobar:
  - `viewBox` suficiente para todo el contenido (ampliar altura si se añade leyenda).
  - Balance de grupos: `<g>` == `</g>`.
  - Footer no colisiona con contenido nuevo (reposicionar y, o ampliar viewBox).
- Validador global: el HTML que referencia el SVG debe seguir pasando `presentations:validate`.

## Verificación en Chrome real (CDP)

El validador estructural NO comprueba render. Para verificación visual/DOM en Chrome:

```bash
# 1. Servir con no-store (evita caché de modales i18n en recargas)
npm run presentations:serve -- --port 8899 --no-browser --no-store

# 2. Lanzar Chrome con CDP remoto (puerto 9225):
#    chrome --remote-debugging-port=9225

# 3. Ejecutar verificación (página específica, 3 idiomas)
node .opencode/skills/presentations-maintenance/scripts/cdp-verify-page.cjs --page=health.html

# 3b. Verificación completa de index.html (6 checks: icono, secciones, modales EN/ES/PT, lightbox)
node .opencode/skills/presentations-maintenance/scripts/cdp-verify-final.cjs
```

Checks CDP de `cdp-verify-page.cjs`: triggers por página (todos con data-i18n-title), apertura del
modal con texto (EN), traducción activa en ES y pt-BR (no fallback en inglés).
`cdp-verify-final.cjs` añade: icono Layer 4 (bi-book presente, bi-brain ausente), conteos por
sección de index.html, y centrado matemático del lightbox (comparar transform scale/translate
contra lo esperado).

## Lightbox

- **CSS**: `.gv-lightbox-img` NO debe tener `max-width/max-height` (gotcha #6).
- **JS**: `open()` debe usar `img.decode().then(afterLoad)` + comprobación `naturalWidth > 0`.
- Centrado matemático: imagen con ancho W en viewport V → `scale = min(0.9, V/W)`,
  `translateX = (V - W*scale)/2`. Si W*scale > V, scale = V/W.
