# Motion & UX Standard GV — v1.0 (oficial)

> **Oficial desde 2026-09-06** · Decisión: ADR-0031 · Referencia viva: `apps/academy-web` (v4)
> Complementa: `rules/NORMATIVA-DESIGN-SYSTEM.md` (qué es oficial y dónde vive) y los tokens v2
> Premium de `packages/gv-design-system/` (colores, tipografía, espaciado). Este documento define
> **cómo se mueve y responde** una app GV. Toda app nueva nace con esto; las existentes homologan
> según `docs/apps/HOMOLOGACION-UX-2026-09-06.md`.

## 1. Principios

1. **Motion con propósito**: cada efecto comunica estado (entrada, jerarquía, feedback o foco). Cero
   decoración gratuita.
2. **CSS-first, cero dependencias**: nada de librerías de animación. CSS moderno + ~150 líneas de JS
   delegado máximo.
3. **Opt-out siempre**: todo se apaga bajo `prefers-reduced-motion: reduce`.
4. **Accesible**: feedback por toasts en `aria-live`, foco visible en todo control, navegación por
   teclado equivalente al mouse.
5. **Tokens, no valores sueltos**: duraciones/easings de `--gv-duration-*` y `--gv-ease-*`; los
   efectos no inventan constantes.

## 2. Arquitectura de capas CSS (orden de carga obligatorio)

```
tokens → atmosphere → style → components → layout → motion
```

La capa **motion** es la última (puede overdear las anteriores) y es portátil: en apps React se
importa después del styles.css del shell; en apps vanilla se enlaza al final del `<head>`.
Referencia implementada: `apps/academy-web/academy-motion.css`.

## 3. Vocabulario de efectos (canónico)

| #   | Efecto             | Qué es                                                                    | Cuándo usarlo                                     |
| --- | ------------------ | ------------------------------------------------------------------------- | ------------------------------------------------- |
| 1   | `spotlight-card`   | Highlight radial que sigue al puntero (`--mx/--my` + 1 listener delegado) | Cards navegables/interactivas de grids            |
| 2   | `reveal-stagger`   | Entrada on-scroll con delay `calc(var(--reveal-i) * 45ms)`                | Grids y listas al aparecer                        |
| 3   | `toast`            | Notificación glass con barra de acento, icono y auto-dismiss (2.6s)       | Éxito/aviso de acciones (copiar, marcar, guardar) |
| 4   | `lightbox`         | Visor de imágenes con zoom-in, caption, contador y ← → / Escape           | Galerías de media/capturas                        |
| 5   | `copy-code`        | Botón flotante sobre `<pre>` con feedback y fallback `execCommand`        | Bloques de código                                 |
| 6   | `back-to-top`      | Botón flotante con anillo SVG de progreso de scroll                       | Páginas largas (lecciones, docs, listas)          |
| 7   | `img blur-up`      | Media de blur+scale a nítida al cargar (`img-blur-up.loaded`)             | Imágenes grandes/data-URIs                        |
| 8   | `gradient-pan`     | Gradiente de marca animado en badges/bordes destacados                    | Máximo 1–2 por vista (hero badge, banner)         |
| 9   | `dash-flow`        | Aristas SVG con `stroke-dasharray` animado                                | Diagramas "vivos"                                 |
| 10  | `tilt/sheen media` | Sheen diagonal + zoom sutil en hover de media-cards                       | Cards con captura/imagen                          |

### Micro-patrones transversales

- **View transition**: `.view-fade` (`viewIn` 280ms ease-out-expo) en cada cambio de vista — ya
  canónico.
- **Navegación por teclado**: `Ctrl+K` o `/` focusea búsqueda; `↑↓` navega resultados; `Enter` abre;
  `←→` paginan (lecciones, lightbox); `Escape` cierra overlays.
- **Breadcrumbs** en vistas anidadas (`.gv-crumbs`).
- **Scroll-spy**: TOC local con IntersectionObserver (`rootMargin: -80px 0px -70% 0px`).
- **Continue-where-you-left-off**: banner de reanudación con borde animado (`.gv-anim-border` +
  `.continue-banner`).
- **Celebración sobria**: track/flujo completo = pill verde con pop-in + toast — sin confetti.
- **i18n**: es/en/pt con clave compartida `localStorage gv-cc-lang`; tema con `gv-cc-theme`.

## 4. Tokens de motion

```css
--gv-duration-instant: 100ms;
--gv-duration-fast: 180ms;
--gv-duration-base: 280ms;
--gv-duration-slow: 400ms;
--gv-duration-epic: 800ms;
--gv-ease-smooth: cubic-bezier(0.16, 1, 0.3, 1);
--gv-ease-bounce-subtle: cubic-bezier(0.34, 1.56, 0.64, 1); /* solo micro-interacciones */
--gv-ease-out-expo: cubic-bezier(0.19, 1, 0.22, 1);
--gv-ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1); /* extensión motion layer */
```

Reglas de dosificación: un elemento anima **una propiedad compuesta** (transform+opacity); nada
anima `width/height/top/left`; delays de stagger ≤ 45ms/ítem y tope 12 ítems.

## 5. Diagramas vivos (SVG)

- Gradientes definidos **por instancia** con ids únicos (los diagramas pueden repetirse en página).
- Nodos en `<g class="gv-node">` con hover-glow; aristas clave con `class="gv-flow"`.
- Caption siempre (el diagrama enseña, el caption interpreta).
- Números factuales verificados contra el repo (ej. Nexus = 37 tablas, medido en `sqlite_master`).

## 6. Capturas de producto (regla anti-mockup)

Las galerías de demo usan **capturas reales** regeneradas con
`apps/academy-web/scripts/capture-v4.mjs` (Playwright, login por API con token de env, cookie
efímera) + `scripts/build-demoimgs.mjs` (data-URIs para que funcione en `file://`). Si la app
cambió, se recaptura — nunca se retoca una captura vieja.

## 7. Checklist de adopción (por app)

- [ ] Carga la capa motion después de sus estilos (o porta los patrones a su stack).
- [ ] Cards interactivas con `spotlight-card`; grids con reveal-stagger.
- [ ] Acciones con feedback por toast (`aria-live`), no alertas nativas.
- [ ] Búsqueda con `Ctrl+K` + navegación por teclado (si tiene búsqueda).
- [ ] Overlays cierran con Escape y click-fuera; foco visible en todo.
- [ ] `prefers-reduced-motion` apaga el vocabulario completo.
- [ ] i18n es/en/pt + tema claro/oscuro con claves compartidas.
- [ ] Footer/topbar con identidad canónica (logo 32px, wordmark Space Grotesk, footer mono).
- [ ] Sin pageerrors en consola (los de widget CC en file:// son conocidos y tolerados).
- [ ] Validación visual: screenshots dark/light/mobile leídos y aprobados.
