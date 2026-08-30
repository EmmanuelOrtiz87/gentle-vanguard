# Troubleshooting — Presentations Maintenance

## Icono invisible en una capa (Layer 4 sin icono)

**Síntoma**: un `.layer-name` no muestra icono aunque el HTML tiene `<i class="bi ...">`.

**Causa**: el icono bootstrap no existe en la versión 1.11.3 (p. ej. `bi-brain`). El `<i>` se
renderiza pero vacío.

**Fix**: reemplazar por un icono existente (p. ej. `bi-book`). Lista de iconos válidos:
`bi-book`, `bi-gear`, `bi-cpu`, `bi-box`, `bi-diagram-3`, `bi-lightning`, `bi-shield-check`,
`bi-database`, `bi-graph-up`, `bi-cloud`.

**Verificación**: `cdp-verify-final.js` comprueba `hasBrain=false, hasBook=true` en el DOM real.

## Info-trigger no abre modal o texto vacío

**Síntomas y causas**:
1. El trigger es HIJO de un elemento traducido (`data-i18n`) → `translate()` hace
   `el.textContent = merged[key]` y borra el trigger. **Fix**: span hermano.
2. Falta `data-i18n-title` en el trigger → `initInfoModal()` no encuentra clave. **Fix**: añadir
   `data-i18n-title="tip_*"`.
3. La clave `tip_*` no existe en los 3 bloques de idioma → `getDict()` devuelve fallback. **Fix**:
   añadir en en/es/pt-BR (mismo identificador).
4. Modal muestra el `title` en inglés aunque el idioma es es/pt-BR → la clave de i18n.js no está en
   el bloque correspondiente o el identificador no coincide.

## Duplicados en i18n.js tras añadir claves

**Causa**: script de inserción que comprueba la existencia GLOBAL de la clave (gotcha #3): detecta
la del primer idioma y omite los demás.

**Fix**: comprobación POR BLOQUE + script dedupe por sección. Estado sano: 208 claves/bloque,
0 duplicados.

## Lightbox mal centrado (imagen pegada a la esquina)

**Síntomas y causas**:
1. `max-width/max-height` en `.gv-lightbox-img` → doble escalado navegador+JS. **Fix**: eliminar.
2. Imagen en caché: `img.complete === true` pero `naturalWidth === 0` → el cálculo fallback usa
   (1,0,0). **Fix**: `img.decode().then(afterLoad)` + comprobar `naturalWidth > 0`.

## SVG: elementos solapados (footer sobre leyenda)

**Causa**: el viewBox es demasiado pequeño para el contenido nuevo (p. ej. leyenda de colores).

**Fix**: ampliar viewBox (p. ej. 800×500 → 800×540) y reposicionar footer a y=523-535. Verificar
balance de grupos `<g>`/`</g>` (12/12 en executive-loop, 19/19 en architecture-layers).

## Validación estructural da FAIL en presentaciones que no he tocado

El validador es estricto sobre restos del selector antiguo. Verificar que el HTML no tenga:
- `data-bs-toggle="dropdown"` (dropdown Bootstrap viejo)
- `dropdown-item` (restos)
- `lang-btn` / `lang-menu` (selector antiguo)

Si la página heredó esos restos, migrarla al selector `lang-seg` antes de que pase la validación.

## Caracteres corruptos (U+FFFD) en diccionarios

**Causa**: escritura con codificación incorrecta (PS con `Out-File` por defecto).

**Fix**: usar siempre `[System.IO.File]::WriteAllText($path, $content, (New-Object
System.Text.UTF8Encoding($true)))` — BOM UTF-8.
