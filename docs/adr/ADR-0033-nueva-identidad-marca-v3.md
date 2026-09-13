# ADR-0033 — Nueva identidad de marca GV (v3): monograma geométrico integrado + Design Hub Proposals

## Status

accepted

- **Date**: 2026-09-08
- **Author**: mavis (root) — sesión del usuario
- **Relacionado**: ADR-0026 (gv-design-system v2), ADR-0017 (local-first),
  `docs/brand/BRAND-DECISION-2026-09-01.md`, `docs/brand/BRAND-KIT.md`

---

## Context

El usuario proporcionó un **nuevo set de assets SVG** en
`C:\Users\emman\Downloads\Gentle_Vanguard_App_Assets_SVG_NEW_FINAL\` que representa una **nueva
identidad visual** para el monograma GV de Gentle-Vanguard. Este set incluye:

- **13 archivos SVG** con un monograma GV geométrico integrado (filled/relleno), completamente
  diferente al logo actual (monograma "G" con trazo stroke + "V" angular).
- **Nueva paleta**: `#0B1020` (midnight), `#1E40AF` (blue), `#06B6D4` (cyan), `#8B5CF6` (violet),
  `#F8FAFC` (soft-white), `#050A14` (black).
- **Nuevo gradiente oficial**: `#6E4DEB → #7B63E8 → #06B6D4` (diagonal inferior-izquierda →
  superior-derecha).
- **BRAND_SYSTEM.md** con documentación completa de uso en Web, PWA, Android, iOS, Desktop, React,
  Next.js, Flutter, React Native, Electron/Tauri.
- **asset-manifest.json** con metadatos de trazado (viewBox 0 0 1000 1000, trace_source:
  logo_crop2.png).

### Actualización 2026-09-08: SVG Asset System v2.0 (APPLICATION FINAL)

El usuario proporcionó un **segundo set mejorado** en
`C:\Users\emman\Downloads\Gentle_Vanguard_SVG_Assets_v2_APPLICATION_FINAL\` que **reemplaza al
anterior** como la versión candidata vigente:

- **19 SVGs** (15 icons + 4 logos) — SVG Asset System v2.0.
- **Canvas 1024×1024** (vs 1000×1000 del anterior).
- **Símbolo GV centrado matemática y visualmente** — corrige el desequilibrio visual del trazado
  anterior (mayor margen izquierdo, riesgo de que la V pareciera cortada).
- **Safe area 15-20%**, marca de 800px dentro del canvas.
- **Misma paleta**: Midnight `#0B1020`, Electric Blue `#1E40AF`, Tech Cyan `#06B6D4`, Vanguard
  Violet `#8B5CF6`, Soft White `#F8FAFC`, Black `#050A14`.
- **Mismo gradiente**: `#6E4DEB → #7B63E8 → #06B6D4`.
- **Nuevos assets**: logos horizontales/verticales con wordmark, app icons (dark/light/gradient/
  maskable), `gv-currentColor` (color controlado por CSS), `safari-pinned-tab`.
- **Ruta integrada**: `assets/brand/gentle-vanguard/v2/` (recomendada por el propio paquete).
- **Tipografía**: Inter (primaria), Manrope (fallback), wordmark weight 800.

**Decisión**: La v2.0 APPLICATION FINAL es la **candidata vigente** para validación. El set anterior
(`assets/brand/v3-candidate/`) queda como histórico. La v2.0 se aplicó ya a: favicon canónico
(`docs/brand/assets/favicon.svg`), 5 banners sociales (`docs/brand/assets/banner-*.svg`), el v3
Editor (path centrado 1024×1024), el Asset Generator (canvas con monograma GV) y las referencias de
favicon del Design Hub.

### Actualización 2026-09-08 (feedback del usuario): fixes de favicon, ancho y edición permanente

El usuario validó la identidad v2.0 y reportó 3 mejoras, todas aplicadas:

1. **Favicon con gradiente**: El generador dibujaba el monograma con gradiente sobre fondo gradiente
   (mala legibilidad). **Fix**: cuando el estilo es "gradient", se usa el monograma **blanco**
   (`gv-white.svg`) sobre fondo gradiente 2-stop (`#6E4DEB → #06B6D4`), replicando el diseño oficial
   de `app-icon-gradient.svg`. Verificado por muestreo de píxeles (centro del monograma =
   `#FFFFFF`).

2. **Homologación del ancho**: El `.gv-main` del Design Hub era 1400px mientras el topbar canónico
   es 1180px. **Fix**: `.gv-header-inner`, `.gv-main` y `.gv-footer-inner` ahora usan **1180px**,
   alineados con el estándar canónico (`assets/gv-design-system.css`) y academy-web. Verificado:
   topbar y contenido miden ambos 1180px.

3. **Edición permanente (no solo v3)**: El "v3 Editor" se renombró a **"Brand Editor"** — la
   herramienta de edición de identidad (gradiente + paleta + preview en vivo) es ahora permanente y
   general, aplicable a cualquier versión de marca (v2 Premium oficial, v2.0 candidata, o uploads
   propios). El flujo de Proposals (upload → análisis → propuesta → versionado → aprobación) queda
   como el workflow permanente de gestión de cambios de diseño.

### Formalización 2026-09-08: v2.0 APPLICATION FINAL = OFICIAL

El usuario validó la identidad v2.0 y ordenó formalizarla como **oficial y productiva**. Acciones:

1. **Propagación LIVE ejecutada** (`node apps/design-hub/tools/propagate.js`): 7 assets copiados a
   ubicaciones oficiales (`assets/logo.svg`, `assets/logo-icon.svg`, `assets/logo-mono-*.svg`,
   `docs/brand/assets/logo-primary.svg`, `apps/design-hub/public/assets/favicon.svg`,
   `docs/brand/assets/logo-v2.svg`).
2. **Propagación a todas las apps**: logos actualizados en academy-web, archify, command-center,
   content-cms, gv-analytics, prompt-studio, web-dashboard (public/ y dist/).
3. **BRAND-KIT.md actualizado**: v2.0 APPLICATION FINAL = ✅ OFICIAL; v2 Premium = 🗄 SUPERSEDED.
4. **Este ADR pasa a status `accepted`**.

Además, el usuario expresó la necesidad de **poder operar con todas las herramientas a
disposición**: subir imágenes (PNG/JPG), analizarlas, crear propuestas de diseño, versionarlas, y
decidir qué versión se vuelve oficial e implementarla en todo el stack. Esto requiere una
**funcionalidad de upload/análisis/propuestas** en el Design Hub.

## Decision

### 1. Nueva identidad de marca v3 (candidata)

1. **Integrar los nuevos assets SVG como candidatos v3** en:
   - `assets/brand/v3-candidate/` (raíz del repo)
   - `apps/design-hub/public/assets/v3-candidate/` (Design Hub)
   - `docs/brand/assets/v3/` (documentación)
2. **NO reemplazar los oficiales** (`assets/logo.svg`, etc.) hasta que el usuario decida
   explícitamente promover la v3 a oficial.
3. **Documentar la nueva identidad** en `docs/brand/BRAND-KIT.md` como candidata v3, con su paleta y
   gradiente propios.
4. **Crear registro de decisión** (este ADR) para que la decisión de promoción sea trazable.

### 2. Design Hub Proposals (funcionalidad de ciclo de vida)

1. **Nueva sección "Proposals"** en el Design Hub (`apps/design-hub/src/proposals/`) que permite:
   - Subir imágenes (PNG, JPG, SVG, WebP, GIF) y archivos markdown (.md).
   - Analizar imágenes client-side (dimensiones, colores dominantes, transparencia, formato).
   - Crear propuestas de diseño con metadatos (tipo, estado, fecha, autor).
   - Versionar propuestas (cada subida nueva crea una versión).
   - Comparar versiones lado a lado.
   - Aprobar/rechazar propuestas (flujo: `draft → proposed → approved/rejected`).
   - Exportar/importar propuestas como JSON.
   - Persistir en IndexedDB (browser) para sobrevivir sesiones.
2. **Herramienta CLI de propagación** (`apps/design-hub/tools/propagate.js`) que copia assets
   aprobados a ubicaciones oficiales en todo el stack.
3. **Manifest.json** para mapear assets aprobados a sus destinos oficiales.

## Razones

- **El usuario tiene una nueva identidad visual** que quiere evaluar e implementar. El stack debe
  soportar el ciclo de vida completo: ingesta → análisis → propuesta → versión → aprobación →
  propagación.
- **Local-first (ADR-0017)**: la funcionalidad de Proposals es 100% client-side (IndexedDB + Canvas
  API), sin dependencias externas ni cloud.
- **El Design Hub ya es la app nativa oficial** para gestionar el sistema de diseño. Extenderlo con
  Proposals es la evolución natural.
- **La propagación CLI** preserva el principio de "cero dependencias" (Node.js ya está en el stack).
- **El nuevo logo es un asset vectorial reconstruido** desde una referencia visual (logo_crop2.png).
  Si aparece el archivo vectorial original del diseñador (.AI, .EPS, .PDF), ese debe convertirse en
  el master definitivo.

## Consecuencias

### Positivas

- **Ciclo de vida completo de diseño** en el stack: ingesta → análisis → propuesta → versión →
  aprobación → propagación.
- **Nueva identidad visual** lista para evaluar e implementar.
- **Trazabilidad** de decisiones de marca (ADR + historial de propuestas).
- **Local-first**: todo funciona sin cloud ni dependencias externas.

### Negativas / Trade-offs

- **La nueva identidad es un cambio significativo** del logo actual. Requiere decisión explícita del
  usuario para promoverla a oficial.
- **El Design Hub Proposals** es una funcionalidad nueva que necesita testing end-to-end.
- **La propagación** a `packages/gv-design-system/` requiere confirmación explícita (no auto-write).
- **Token budget**: este ADR + implementación consumen tokens. Aplicar `review-workload-guard`.

## Alternativas consideradas

1. **Reemplazar directamente los oficiales** — ❌ Rejected: requiere decisión explícita del usuario.
2. **Crear app separada para Proposals** — ❌ Rejected: el Design Hub ya es la app nativa oficial.
3. **Usar cloud API para análisis de imágenes** — ❌ Rejected: viola ADR-0017 (local-first).
4. **No hacer nada** — ❌ Rejected: el usuario tiene una nueva identidad que quiere evaluar.

## Plan de implementación

Fase 1 (esta sesión):

- [x] Revisar y validar los nuevos assets SVG (geometría, paleta, gradiente)
- [x] Integrar nuevos assets SVG en `assets/brand/v3-candidate/`,
      `apps/design-hub/public/assets/v3-candidate/`, `docs/brand/assets/v3/`
- [x] Construir funcionalidad de upload de imágenes en Design Hub (drag-drop, análisis client-side)
- [x] Construir sistema de propuestas con versionado y flujo de aprobación en Design Hub
- [x] Construir CLI de propagación para implementar assets oficiales en todo el stack
- [x] Crear manifest.json de ejemplo para la herramienta de propagación
- [x] Actualizar `tools/validate.js` con los nuevos archivos
- [ ] Actualizar `BRAND-KIT.md` con la nueva paleta y tokens v3
- [ ] Actualizar tokens CSS/JSON con los nuevos valores de color
- [ ] Ejecutar validación completa (validate.js, impeccable)
- [ ] Probar funcionalidad de Proposals en Design Hub
- [ ] Integrar con CLI `gv.ts` — agregar comandos proposals

Fase 2 (próximas sesiones):

- [ ] Promover v3 a oficial (si el usuario lo decide)
- [ ] Propagar assets v3 a `assets/`, `docs/brand/assets/`, `packages/gv-design-system/`
- [ ] Actualizar todas las apps del stack con el nuevo logo
- [ ] Actualizar `docs/brand/BRAND-KIT.md` con la decisión final
- [ ] Actualizar `docs/brand/TOKENS-v2.json` con la nueva paleta

## Métricas de éxito

- **Proposals**: el usuario puede subir una imagen, ver el análisis, crear una propuesta,
  versionarla y aprobarla.
- **Propagación**: `node tools/propagate.js --dry-run` muestra los archivos a copiar; `--live` los
  copia.
- **Validación**: `node tools/validate.js` pasa con 0 failures.
- **Documentación**: `BRAND-KIT.md` documenta la candidata v3 con su paleta y gradiente.

## Riesgos y mitigaciones

| Riesgo                                         | Probabilidad | Impacto | Mitigación                                  |
| ---------------------------------------------- | ------------ | ------- | ------------------------------------------- |
| La nueva identidad no es la deseada            | Media        | Alto    | Mantener oficiales hasta decisión explícita |
| Proposals no funciona en todos los navegadores | Baja         | Medio   | IndexedDB + Canvas API son universales      |
| Propagación rompe referencias                  | Baja         | Medio   | `--dry-run` primero, `validate.js` después  |
| Token budget excedido                          | Media        | Medio   | Aplicar `review-workload-guard`             |

## Referencias

- `docs/brand/BRAND-DECISION-2026-09-01.md` (decisión de marca v2)
- `docs/brand/BRAND-KIT.md` (brand kit operativo)
- `docs/brand/TOKENS-v2.json` (tokens v2)
- `apps/design-hub/README.md` (Design Hub)
- `apps/design-hub/src/proposals/` (nueva sección Proposals)
- `apps/design-hub/tools/propagate.js` (herramienta de propagación)
- `C:\Users\emman\Downloads\Gentle_Vanguard_App_Assets_SVG_NEW_FINAL\BRAND_SYSTEM.md` (nueva
  identidad)
- ADR-0017 (local-first)
- ADR-0026 (gv-design-system v2)
