---
name: modern-web-design
version: 1.0.0
description:
  Diseño web moderno, dinámico y profesional para las presentaciones HTML del stack
  Gentle-Vanguard (docs/presentations/): lightbox de imágenes corregido (centrado, click en
  backdrop, zoom con scroll, navegación multi-imagen), sistema Info + Expand, footer centralizado,
  headers homologados, efectos visuales modernos (spotlight, lift, glassmorphism, aurora, parallax),
  carruseles con dots/autoplay e iconografía Bootstrap Icons animada. Cubre accesibilidad,
  rendimiento y testing visual (CDP).
triggers:
  - modern-web-design
  - diseño web moderno
  - lightbox
  - image viewer
  - visor de imágenes
  - carousel
  - carrusel
  - tooltip
  - expand
  - footer centralizado
  - hero section
  - glassmorphism
  - parallax
  - particles
  - aurora
  - bootstrap icons
  - hover spotlight
  - fade-in
  - gv-lightbox
  - gv.css
  - gv.js
  - docs/presentations
---

# Modern Web Design Skill

Guía para implementar diseño web moderno, dinámico y profesional en las presentaciones HTML del
stack Gentle-Vanguard (`docs/presentations/`). Todo el conocimiento está alineado con el design
system existente: **gv.css** (tokens OKLCH), **gv.js** (efectos vanilla, sin deps), Bootstrap 5.3.3,
Bootstrap Icons 1.11.3 y el sistema i18n `en/es/pt-BR`.

## Contexto del stack (leer primero)

| Pieza | Ubicación | Rol |
| ----- | --------- | --- |
| Design system | `docs/presentations/assets/css/gv.css` | Tokens, aurora, navbar, hero, cards, modales, lightbox |
| Effects layer | `docs/presentations/assets/js/gv.js` | Spotlight, count-up, tilt, reveal, lightbox, info modal |
| i18n | `assets/js/i18n.js` + `i18n-content.js` | Diccionarios `tip_*` / `c_*` × 3 idiomas |
| Páginas | `docs/presentations/*.html` | 24 páginas (index, autonomy, health, …) |
| Referencia del libro | `docs/presentations/index.html` | Página canónica con info-triggers + hero + footer |

**CDNs estandarizados** (usar siempre estos, nunca duplicar):

```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" />
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" />
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
```

**Tokens disponibles en `gv.css`** (usarlos vía `var(--…)`, nunca hardcodear colores):

```css
--p: #22d3ee;   /* cyan primario */
--a: #a78bfa;   /* purple acento */
--ok: #34d399;  /* verde éxito */
--wn: #fbbf24;  /* amber warning */
--er: #f87171;  /* rojo error */
--bg: oklch(0.17 0.03 262);   /* fondo base (nunca #000 puro) */
--card: oklch(0.22 0.03 262); --card2: oklch(0.25 0.03 262); --card3: oklch(0.28 0.03 262);
--br: oklch(0.3 0.03 262);     --br-soft: color-mix(in oklab, white 8%, transparent);
--text: #e2e8f0; --text-dim: #94a3b8; --text-faint: #64748b;
--r-lg: 18px; --r-md: 12px; --r-sm: 8px;
--glow-cyan: 0 0 24px oklch(0.8 0.15 210 / 0.18);
--glow-purple: 0 0 24px oklch(0.7 0.18 290 / 0.16);
```

---

## 1. Visor de imágenes corregido (`.gv-lightbox`)

El lightbox para diagramas (`initDiagramModal` en gv.js) ya existe con pan/zoom estilo Google
Photos. Cuando se modifica o se reutiliza en otra página, respetar estas reglas.

### 1.1 Reglas de centrado (crítico)

```css
/* CORRECTO — el flex del contenedor centra la imagen; NO limitar la imagen misma */
.gv-lightbox {
  position: fixed; inset: 0; z-index: 4000;
  display: flex; align-items: center; justify-content: center;
  padding: 1.5rem;
  visibility: hidden; opacity: 0;
  transition: opacity 0.3s ease, visibility 0.3s ease;
}
.gv-lightbox.open { visibility: visible; opacity: 1; }

.gv-lightbox-img {
  width: auto; height: auto;          /* ← NUNCA max-width/max-height 100% */
  transform-origin: 0 0;              /* ancla del zoom top-left */
  transition: transform 0.08s ease-out;
}
```

> **GOTCHA (heredado del skill presentations-maintenance)**: NO poner
> `max-width:100%; max-height:100%` en `.gv-lightbox-img` — provoca doble escalado (navegador + JS).
> El fit lo hace `fitToStage()` en JS usando `stage.clientWidth/Height` y el tamaño natural.

### 1.2 Cerrar al hacer click fuera de la imagen (backdrop)

La imagen vive dentro de `.gv-lightbox-stage`; el backdrop es el elemento `.gv-lightbox-backdrop`.
Cerrar SOLO si el click no fue drag:

```js
overlay.addEventListener('click', function (e) {
  // e.target === overlay o el backdrop → cerrar (si no hubo drag)
  if ((e.target === overlay || e.target.classList.contains('gv-lightbox-backdrop')) && !moved)
    close();
});
overlay.querySelector('.gv-lightbox-close').addEventListener('click', close);
```

Puntos a respetar:

- El click en la **imagen/stage** NO cierra (solo backdrop y botón ✕).
- **ESC** siempre cierra (`document.addEventListener('keydown', e => e.key === 'Escape' && close())`).
- Cerrar libera el body scroll: `document.body.style.overflow = ''`.
- `aria-modal="true"` + `role="dialog"` en el overlay (ya incluidos en gv.js).

### 1.3 Animaciones suaves de entrada/salida

```css
/* Entrada: backdrop fade + imagen scale-up */
.gv-lightbox.open .gv-lightbox-img {
  animation: gv-lbox-in 0.3s cubic-bezier(0.22, 1, 0.36, 1);
}
@keyframes gv-lbox-in {
  from { opacity: 0; transform: scale(0.92); }
  to   { opacity: 1; transform: scale(1); }
}
/* Salida: fade del overlay (la transición base ya lo cubre) */
@media (prefers-reduced-motion: reduce) {
  .gv-lightbox-img { transition: none; }
}
```

### 1.4 Zoom con scroll wheel (centrado en cursor)

```js
stage.addEventListener('wheel', function (e) {
  e.preventDefault();                                   // passive: false obligatorio
  var rect = stage.getBoundingClientRect();
  var factor = e.deltaY < 0 ? 1.18 : 1 / 1.18;
  zoomAt(e.clientX - rect.left, e.clientY - rect.top, factor);
}, { passive: false });

function zoomAt(px, py, factor) {
  var newScale = clamp(scale * factor, minScale, maxScale);
  var k = newScale / scale;
  tx = px - (px - tx) * k;        // mantiene el punto bajo el cursor fijo
  ty = py - (py - ty) * k;
  scale = newScale;
  apply();                          // activeEl().style.transform = translate(tx,ty) scale(s)
}
```

Extras ya implementados en gv.js que NO romper: drag-pan (`pointerdown/move/up` con
`setPointerCapture`), double-click para alternar zoom 2×, botones `+/−/reset` del toolbar, límites
`minScale = fitScale * 0.8`, `maxScale = 12`.

### 1.5 Navegación multi-imagen (prev/next)

Para galerías (varias imágenes en un solo lightbox), añadir botones `‹ ›` al toolbar y un índice:

```html
<div class="gv-lightbox-toolbar">
  <button class="gv-lightbox-btn" data-nav="prev" aria-label="Previous image">‹</button>
  <span class="gv-lightbox-count" aria-live="polite">1 / 4</span>
  <button class="gv-lightbox-btn" data-nav="next" aria-label="Next image">›</button>
  <button class="gv-lightbox-btn" data-zoom="out" aria-label="Zoom out">−</button>
  <button class="gv-lightbox-btn" data-zoom="reset" aria-label="Reset zoom">⟲</button>
  <button class="gv-lightbox-btn" data-zoom="in" aria-label="Zoom in">+</button>
</div>
```

```js
var sources = [];      // llenar en open(): array de {src, alt}
var index = 0;
function show(i) {
  index = (i + sources.length) % sources.length;
  resetZoom();                              // aplicar fitToStage antes de cargar
  loadImage(sources[index]);                // mismo pipeline afterLoad de gv.js
  countEl.textContent = (index + 1) + ' / ' + sources.length;
}
overlay.querySelector('[data-nav="prev"]').addEventListener('click', function (e) {
  e.stopPropagation(); show(index - 1);
});
overlay.querySelector('[data-nav="next"]').addEventListener('click', function (e) {
  e.stopPropagation(); show(index + 1);
});
```

> **Accesibilidad**: el contador usa `aria-live="polite"`; los botones tienen `aria-label`. Al cargar
> imágenes en una galería, `loading="lazy"` en las thumbnails y `img.decode().then(afterLoad)` en el
> lightbox (las imágenes cacheadas pueden reportar `complete=true` con `naturalWidth=0`).

---

## 2. Sistema Info + Expand

### 2.1 Info-trigger estándar (modal "i")

Patrón canónico (ya en index.html y replicado vía validación automática):

```html
<span class="info-trigger" data-i18n-title="tip_auto_loop" title="fallback en inglés">i</span>
```

```css
/* Ya en gv.css §15 — si se extiende, mantener la identidad visual */
.info-trigger {
  display: inline-flex; align-items: center; justify-content: center;
  width: 18px; height: 18px; border-radius: 50%;
  background: oklch(0.8 0.14 210 / 0.15); color: var(--p);
  font-size: 0.6rem; font-weight: 700; cursor: help;
  margin-left: 6px; vertical-align: middle;
  transition: all 0.3s ease; border: none;
}
.info-trigger:hover {
  background: var(--p); color: #04121c;
  transform: scale(1.15); box-shadow: var(--glow-cyan);
}
```

Reglas de uso:

- `initInfoModal()` resuelve `data-i18n-title` → `getDict()` → fallback `title`/`aria-label`.
- **DENTRO de un `<td>` traducido**, el trigger es un span **HERMANO** del texto traducido
  (el `translate()` de i18n.js reemplaza los hijos del nodo):

  ```html
  <td><span data-i18n="key">texto</span><span class="info-trigger" data-i18n-title="tip_*">i</span></td>
  ```

- Para hotspots SVG: `window.__gvShowInfo(tipKey)` abre el modal directamente.
- **Homologación**: `npm run presentations:validate` transforma tds → `span + info-trigger`
  (title fallback EN) en TODAS las páginas. Correr tras editar HTML.

### 2.2 Expandable inline (tooltip expandible, "como en index.html")

Para explicaciones cortas sin abrir modal — componente `gv-expand`:

```html
<button type="button" class="gv-expand" aria-expanded="false" aria-controls="exp-1">
  <i class="bi bi-info-circle me-1"></i>¿Qué es Nexus?
</button>
<div class="gv-expand-panel" id="exp-1" hidden>
  Nexus es la base de datos operacional del stack (.runtime/gentle-vanguard.db).
</div>
```

```css
.gv-expand {
  display: inline-flex; align-items: center; gap: 0.4rem;
  background: oklch(0.8 0.14 210 / 0.08); color: var(--p);
  border: 1px solid oklch(0.8 0.14 210 / 0.3); border-radius: 999px;
  padding: 0.35rem 0.9rem; font-size: 0.78rem; font-weight: 600;
  cursor: pointer; transition: all 0.3s cubic-bezier(0.22, 1, 0.36, 1);
}
.gv-expand:hover { box-shadow: var(--glow-cyan); transform: translateY(-1px); }
.gv-expand[aria-expanded="true"] .bi {
  transform: rotate(180deg); transition: transform 0.3s ease;
}
.gv-expand-panel {
  margin-top: 0.5rem; padding: 0.85rem 1rem;
  background: var(--card); border: 1px solid var(--br-soft);
  border-left: 3px solid var(--p); border-radius: var(--r-md);
  font-size: 0.84rem; color: var(--text-dim); line-height: 1.6;
  animation: gv-expand-in 0.25s cubic-bezier(0.22, 1, 0.36, 1);
}
@keyframes gv-expand-in {
  from { opacity: 0; transform: translateY(-6px); }
  to   { opacity: 1; transform: translateY(0); }
}
```

```js
// En gv.js — inicialización de expandibles (delegación de eventos)
function initExpand() {
  document.querySelectorAll('.gv-expand').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var panel = document.getElementById(btn.getAttribute('aria-controls'));
      if (!panel) return;
      var open = panel.hidden;
      panel.hidden = !open;
      btn.setAttribute('aria-expanded', String(open));
      // cerrar los demás del mismo grupo (opcional)
      document.querySelectorAll('.gv-expand[aria-expanded="true"]').forEach(function (other) {
        if (other !== btn) { other.setAttribute('aria-expanded', 'false');
          var p = document.getElementById(other.getAttribute('aria-controls'));
          if (p) p.hidden = true; }
      });
    });
  });
}
```

> **Accesibilidad**: `aria-expanded` + `aria-controls` + `hidden` (el contenido queda fuera del tab
> order cuando está oculto — es el patrón disclosure correcto).

### 2.3 Replicar en páginas que lo falten (autonomy.html, etc.)

Checklist para añadir Info + Expand a una página:

1. Verificar que incluye `assets/js/i18n.js` + `i18n-content.js` + `assets/js/gv.js` al final.
2. Añadir triggers `data-i18n-title="tip_…"` en las celdas/términos clave (siguen las secciones).
3. Insertar las claves `tip_*` en **los 3 bloques** de `i18n.js` (`en`, `es`, `'pt-BR'`) con el mismo
   identificador — comprobar **por bloque de idioma**, no globalmente (gotcha de idempotencia).
4. `node --check assets/js/i18n.js` para validar sintaxis.
5. `npm run presentations:validate` → esperado 11/11 PASS.
6. Verificación CDP: `node scripts/cdp-verify-page.cjs --page=autonomy.html`.

---

## 3. Footer centralizado

### 3.1 Clase consistente `gv-footer`

Actualmente las páginas usan `<footer>` suelto con estilos inline. Homologar a una clase única:

```css
.gv-footer {
  text-align: center;                    /* ← texto centralizado */
  padding: 3rem 1.5rem 2.5rem;
  border-top: 1px solid var(--br-soft);
  background: linear-gradient(180deg, transparent, oklch(0.19 0.03 262 / 0.8));
  margin-top: 3rem;
}
.gv-footer p { margin: 0.35rem 0; color: var(--text-dim); }
.gv-footer a { color: var(--text-dim); text-decoration: none; transition: color 0.25s ease; }
.gv-footer a:hover { color: var(--p); }
.gv-footer .gv-footer-links {
  display: flex; flex-wrap: wrap; justify-content: center; gap: 0.75rem 1.2rem;
  margin: 0.75rem 0;
}
```

```html
<footer class="gv-footer">
  <p>Gentle-Vanguard <strong>v4.0</strong> — 100% Autonomous AI Stack ·
    <span class="text-secondary">✦ Plataforma Autónoma de Orquestración AI</span></p>
  <nav class="gv-footer-links" aria-label="Footer">
    <a href="architecture.html"><i class="bi bi-diagram-3 me-1"></i>Architecture</a>
    <a href="autonomy.html"><i class="bi bi-robot me-1"></i>Autonomy</a>
    <a href="dashboard.html"><i class="bi bi-speedometer2 me-1"></i>Dashboard</a>
    <a href="https://github.com/EmmanuelOrtiz87/gentle-vanguard" target="_blank"
       ><i class="bi bi-github me-1"></i>GitHub</a>
  </nav>
  <p class="gv-footer-badges">
    <span class="badge-gv badge-p">294 TS Files</span>
    <span class="badge-gv badge-ok">103 Test Files</span>
    <span class="badge-gv badge-wn">112/112 Health</span>
  </p>
  <p><small><i class="bi bi-cpu me-1"></i>Don't let your mellow hustle be faded.</small></p>
</footer>
```

> **Bootstrap** también provee utilidades (`text-center`, `d-flex justify-content-center`) — usarlas
> como refuerzo dentro de `.gv-footer`, pero la clase única es la que garantiza consistencia.

---

## 4. Headers homologados (hero section)

Todos los headers deben compartir la misma estructura visual: badge con shimmer + título con glow +
descripción + CTAs. Plantilla canónica:

```html
<header class="hero" id="overview">
  <div>
    <span class="hero-badge mb-3">✦ v4.0 — Autonomous Executive Layer</span>
    <h1><span class="glow">Autonomous Systems</span></h1>
    <p class="lead">
      Descripción de una o dos frases que explica la página (max-width 720px centrado).
    </p>
    <div class="mt-4 d-flex gap-2 flex-wrap justify-content-center">
      <a href="index.html" class="btn-gv"><i class="bi bi-book me-1"></i>Overview</a>
      <a href="architecture.html" class="btn-gv-alt"><i class="bi bi-diagram-3 me-1"></i>Architecture</a>
    </div>
  </div>
</header>
```

Componentes ya definidos en gv.css (no redefinir, solo reutilizar):

- `.hero` — centrado, min-height 72vh, radial-gradients de fondo vía `::before`.
- `.hero-badge` — pill con shimmer animado (`::after` + `@keyframes shimmer`).
- `.glow` — texto con gradiente animado (`background-size: 200%` + `glow-shift`).
- `.lead` — tipografía fluida `clamp(1rem, 2vw, 1.3rem)`, color `--text-dim`.
- `.btn-gv` / `.btn-gv-alt` — botones pill con hover gradient + shine sweep.

Checklist de homologación de headers:

1. Misma estructura: `<header class="hero">` → badge → `h1` con `.glow` → `.lead` → CTAs.
2. Navbar idéntica: `nav.navbar.navbar-expand-xl.nav-blur.fixed-top` con brand `GV` + link activo
   (`class="nav-link active"`) marcando la página actual.
3. Badges/estadísticas con `data-count` para el count-up (si aplica).
4. No duplicar `<style>` por página para estilos que ya están en gv.css — añadir solo
   específicos (ej: `.flow-row` en autonomy.html).

---

## 5. Efectos visuales modernos

### 5.1 Transiciones CSS smooth (base)

```css
/* Curva estándar del stack — usar SIEMPRE en interacciones */
--ease-gv: cubic-bezier(0.22, 1, 0.36, 1);
transition: all 0.3s var(--ease-gv);

/* Preferir transform/opacity (GPU-friendly) sobre top/left/width/height */
```

### 5.2 Hover en cards (spotlight + lift)

Ya implementado en `.section-card` (gv.css §7). Al crear nuevas cards, reutilizar la clase; el JS
`initSpotlight()` actualiza `--sx/--sy` en `pointermove`. Si se necesita el efecto en un componente
nuevo:

```css
.card-lift {
  background: var(--card); border: 1px solid var(--br-soft); border-radius: var(--r-lg);
  padding: 1.5rem; position: relative; overflow: hidden;
  transition: transform 0.35s var(--ease-gv), box-shadow 0.35s ease, border-color 0.35s ease;
}
.card-lift::before {   /* spotlight radial que sigue al cursor */
  content: ''; position: absolute; inset: 0;
  background: radial-gradient(600px circle at var(--sx, 50%) var(--sy, 50%),
    oklch(0.75 0.14 210 / 0.12), transparent 42%);
  opacity: 0; transition: opacity 0.35s ease; pointer-events: none;
}
.card-lift:hover { transform: translateY(-4px); box-shadow: var(--glow-cyan); }
.card-lift:hover::before { opacity: 1; }
```

### 5.3 Animaciones de entrada (fade-in, slide-in)

```css
/* fade-in + slide-up (ya en gv.css §12, activado por IntersectionObserver) */
.fade-in { opacity: 0; transform: translateY(26px);
  transition: opacity 0.8s var(--ease-gv), transform 0.8s var(--ease-gv); }
.fade-in.visible { opacity: 1; transform: translateY(0); }
.fade-in-d1 { transition-delay: 0.1s; }  /* d2 = 0.2s, d3 = 0.3s */

/* slide-in lateral (para paneles/columnas) */
.slide-in-left { opacity: 0; transform: translateX(-32px);
  transition: opacity 0.6s var(--ease-gv), transform 0.6s var(--ease-gv); }
.slide-in-left.visible { opacity: 1; transform: translateX(0); }
```

En JS, un solo IntersectionObserver puede cubrir ambas clases (el de `initReveal` ya cubre
`.fade-in`; ampliar el selector a `.fade-in, .slide-in-left`).

### 5.4 Glassmorphism en modales

El stack ya lo aplica (navbar, `.gv-lightbox-backdrop`, `.gv-info-box`). Patrón:

```css
.glass-panel {
  background: oklch(0.25 0.03 262 / 0.72);
  -webkit-backdrop-filter: blur(16px) saturate(1.4);
  backdrop-filter: blur(16px) saturate(1.4);
  border: 1px solid var(--br-soft);
  border-radius: var(--r-lg);
  box-shadow: 0 8px 30px oklch(0.1 0.02 262 / 0.5);
}
```

Reglas: `backdrop-filter` + fallback `-webkit-`; superficie translúcida NUNCA opaca al 100%; borde
`--br-soft` para el "edge highlight".

### 5.5 Parallax sutil

```css
.parallax-bg {
  background-attachment: fixed;              /* fallback CSS-only */
  background-size: cover; background-position: center;
}
@media (hover: none) { .parallax-bg { background-attachment: scroll; } }  /* móvil */
```

Para parallax por scroll con transform (más control), en gv.js:

```js
function initParallax() {
  if (REDUCED) return;
  var els = document.querySelectorAll('[data-parallax]');
  if (!els.length) return;
  var ticking = false;
  function update() {
    els.forEach(function (el) {
      var r = el.getBoundingClientRect();
      var speed = Number(el.dataset.parallax || 0.2);
      el.style.transform = 'translateY(' + (r.top * speed) + 'px)';
    });
    ticking = false;
  }
  window.addEventListener('scroll', function () {
    if (!ticking) { ticking = true; requestAnimationFrame(update); }
  }, { passive: true });
  update();
}
```

> **Rendimiento**: parallax vía transform + rAF + passive listener; nunca en `prefers-reduced-motion`
> ni en touch (móviles). Limitar a 1-2 elementos por página.

### 5.6 Partículas / aurora

La aurora ya existe (`.aurora` con 3 blobs + `@keyframes aurora-drift`) y el grain (`.grain::after`).
Siempre incluir ambos en `<body>`:

```html
<body class="grain">
  <div class="scroll-progress"></div>
  <div class="aurora" aria-hidden="true"><span></span><span></span><span></span></div>
  ...
</body>
```

Para partículas ligeras (canvas, opcional):

```js
function initParticles(canvas) {
  if (REDUCED || !canvas || canvas.dataset.init) return;
  canvas.dataset.init = '1';
  var ctx = canvas.getContext('2d');
  var ps = []; var W, H;
  function resize() { W = canvas.width = canvas.offsetWidth; H = canvas.height = canvas.offsetHeight; }
  resize(); window.addEventListener('resize', resize, { passive: true });
  for (var i = 0; i < 40; i++) ps.push({ x: Math.random() * W, y: Math.random() * H,
    vx: (Math.random() - 0.5) * 0.4, vy: (Math.random() - 0.5) * 0.4, r: Math.random() * 1.6 + 0.4 });
  function frame() {
    ctx.clearRect(0, 0, W, H); ctx.fillStyle = 'rgba(34, 211, 238, 0.55)';
    ps.forEach(function (p) {
      p.x += p.vx; p.y += p.vy;
      if (p.x < 0 || p.x > W) p.vx *= -1; if (p.y < 0 || p.y > H) p.vy *= -1;
      ctx.beginPath(); ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2); ctx.fill();
    });
    requestAnimationFrame(frame);
  }
  frame();
}
```

---

## 6. Carruseles y diapositivas

### 6.1 HTML (estructura)

```html
<div class="gv-carousel" data-autoplay="5000">
  <div class="gv-carousel-track">
    <div class="gv-carousel-slide"><div class="section-card">Feature 1</div></div>
    <div class="gv-carousel-slide"><div class="section-card">Feature 2</div></div>
    <div class="gv-carousel-slide"><div class="section-card">Feature 3</div></div>
  </div>
  <button class="gv-carousel-arrow prev" aria-label="Previous slide"><i class="bi bi-chevron-left"></i></button>
  <button class="gv-carousel-arrow next" aria-label="Next slide"><i class="bi bi-chevron-right"></i></button>
  <div class="gv-carousel-dots" role="tablist" aria-label="Slides"></div>
</div>
```

### 6.2 CSS (transiciones entre slides)

```css
.gv-carousel { position: relative; overflow: hidden; border-radius: var(--r-lg); }
.gv-carousel-track {
  display: flex; transition: transform 0.5s var(--ease-gv);
  will-change: transform;
}
.gv-carousel-slide { flex: 0 0 100%; min-width: 0; padding: 0 0.5rem; }
.gv-carousel-arrow {
  position: absolute; top: 50%; transform: translateY(-50%); z-index: 2;
  width: 40px; height: 40px; border-radius: 50%;
  border: 1px solid var(--br-soft); background: oklch(0.28 0.03 262 / 0.8);
  color: var(--text); cursor: pointer;
  -webkit-backdrop-filter: blur(8px); backdrop-filter: blur(8px);
  transition: all 0.25s ease;
}
.gv-carousel-arrow.prev { left: 0.75rem; }
.gv-carousel-arrow.next { right: 0.75rem; }
.gv-carousel-arrow:hover { background: linear-gradient(135deg, var(--p), var(--a)); color: #fff; }
.gv-carousel-dots {
  display: flex; justify-content: center; gap: 0.4rem; margin-top: 0.9rem;
}
.gv-carousel-dots button {
  width: 8px; height: 8px; border-radius: 50%; border: none; cursor: pointer;
  background: var(--br); padding: 0; transition: all 0.3s var(--ease-gv);
}
.gv-carousel-dots button.active { width: 22px; border-radius: 999px;
  background: linear-gradient(90deg, var(--p), var(--a)); }
@media (prefers-reduced-motion: reduce) { .gv-carousel-track { transition: none; } }
```

### 6.3 JS (navegación + dots + autoplay)

```js
function initCarousel() {
  document.querySelectorAll('.gv-carousel').forEach(function (car) {
    var track = car.querySelector('.gv-carousel-track');
    var slides = car.querySelectorAll('.gv-carousel-slide');
    if (!track || slides.length < 2) return;
    var i = 0, timer = null;
    var dotsBox = car.querySelector('.gv-carousel-dots');
    var dots = [];
    // construir dots
    slides.forEach(function (_, n) {
      var b = document.createElement('button');
      b.setAttribute('role', 'tab'); b.setAttribute('aria-label', 'Slide ' + (n + 1));
      b.addEventListener('click', function () { go(n); });
      dotsBox.appendChild(b); dots.push(b);
    });
    function go(n) {
      i = (n + slides.length) % slides.length;
      track.style.transform = 'translateX(-' + (i * 100) + '%)';
      dots.forEach(function (d, k) { d.classList.toggle('active', k === i); });
      restart();
    }
    var prev = car.querySelector('.gv-carousel-arrow.prev');
    var next = car.querySelector('.gv-carousel-arrow.next');
    if (prev) prev.addEventListener('click', function () { go(i - 1); });
    if (next) next.addEventListener('click', function () { go(i + 1); });
    function restart() {
      if (timer) clearInterval(timer);
      var ms = Number(car.dataset.autoplay || 0);
      if (ms && !REDUCED) timer = setInterval(function () { go(i + 1); }, ms);
    }
    // pausar al hover/focus (accesibilidad)
    car.addEventListener('pointerenter', function () { if (timer) clearInterval(timer); });
    car.addEventListener('pointerleave', restart);
    document.addEventListener('keydown', function (e) {           // ← solo si carousel visible
      if (e.key === 'ArrowLeft' && isNear(car)) { go(i - 1); }
      if (e.key === 'ArrowRight' && isNear(car)) { go(i + 1); }
    });
    go(0);
  });
}
function isNear(el) {  // el carousel está dentro del viewport activo
  var r = el.getBoundingClientRect();
  return r.bottom > 0 && r.top < window.innerHeight;
}
```

> **Bootstrap nativo**: Bootstrap 5.3 ya trae `.carousel` con indicators y `data-bs-ride`.
> Preferir el componente Bootstrap para carruseles simples; usar `gv-carousel` cuando se necesite
> autoplay configurable, dots animados o thumbnails.

### 6.4 Thumbnails (opcional)

```css
.gv-carousel-thumbs { display: flex; gap: 0.5rem; margin-top: 0.9rem; }
.gv-carousel-thumbs img {
  width: 56px; height: 40px; object-fit: cover; border-radius: var(--r-sm);
  border: 2px solid transparent; cursor: pointer; opacity: 0.55;
  transition: all 0.25s ease;
}
.gv-carousel-thumbs img.active { border-color: var(--p); opacity: 1; }
```

---

## 7. Iconografía y emojis

### 7.1 Bootstrap Icons consistente

- Usar SOLO iconos de **bootstrap-icons 1.11.3** — verificar que el nombre existe antes de usarlo.
  > **GOTCHA conocido**: `bi-brain` NO existe → usar `bi-book` (verificado en CDN).
- Patrón de uso: `<i class="bi bi-robot me-1"></i>Texto` (el `me-1` da el gutter).
- Iconos con color funcional: `style="color: var(--p)"` o clases `.badge-*`.

```html
<a class="nav-link" href="autonomy.html"><i class="bi bi-robot me-1"></i>Autonomy</a>
<i class="bi bi-shield-check" style="color: var(--ok); font-size: 2rem"></i>
```

### 7.2 Animaciones en iconos (pulse, bounce, rotate)

```css
@keyframes gv-pulse { 0%,100% { transform: scale(1); } 50% { transform: scale(1.18); } }
@keyframes gv-bounce { 0%,100% { transform: translateY(0); } 50% { transform: translateY(-4px); } }
@keyframes gv-rotate { to { transform: rotate(360deg); } }

.icon-pulse  { animation: gv-pulse 2s ease-in-out infinite; }
.icon-bounce { animation: gv-bounce 1.6s ease-in-out infinite; }
.icon-spin   { animation: gv-rotate 4s linear infinite; }
/* Uso: <i class="bi bi-bell icon-pulse" style="color: var(--p)"></i> */
```

Reglas: solo animar iconos decorativos (`aria-hidden="true"`), nunca iconos que transmiten estado
sin un fallback estático; respetar `prefers-reduced-motion`.

### 7.3 Tooltips con iconos

Tooltip nativo Bootstrap (requiere `bootstrap.bundle.min.js`):

```html
<button type="button" class="btn btn-sm" data-bs-toggle="tooltip" data-bs-title="Health 112/112">
  <i class="bi bi-heart-pulse" style="color: var(--ok)"></i>
</button>
```

```js
// Inicializar en gv.js (o en DOMContentLoaded si no existe)
document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(function (el) {
  new bootstrap.Tooltip(el, { trigger: 'hover focus' });
});
```

Alternativa ligera sin Bootstrap: el `.info-trigger` (tooltip + modal) ya cubre el caso de
"icono con explicación". Para tooltips flotantes de SVG usar `.gv-tooltip` existente.

---

## 8. Mejores prácticas de accesibilidad

1. **Contraste**: texto principal `--text (#e2e8f0)` sobre `--bg`; `--text-faint` solo para texto
   decorativo/estado, nunca para contenido esencial.
2. **Reduced motion**: toda animación (entrada, hover, autoplay, parallax, particles, count-up)
   debe desactivarse o reducirse cuando `matchMedia('(prefers-reduced-motion: reduce)')` → gv.js ya
   lo hace con la constante `REDUCED`; añadir `@media (prefers-reduced-motion: reduce)` en CSS.
3. **Teclado**: modales `role="dialog"` + `aria-modal="true"`; cerrar con ESC; botones siempre
   `<button>` (no `<div>` clicable); focus visible (`.gv-hotspot:focus-visible` es el ejemplo).
4. **ARIA**: `aria-expanded`/`aria-controls` en expandibles; `aria-label` en botones de icono puro;
   `aria-live="polite"` en contadores (carousel 1/4).
5. **Imágenes**: `alt` descriptivo; `loading="lazy"` fuera del viewport inicial; SVG inline con
   `role="img"` + `aria-label` cuando sea contenido.
6. **i18n**: todo texto visible pasa por `data-i18n`; los modales se re-traducen con
   `__i18n.translate(lang)` al abrir.
7. **Focus trap**: en modales de una página corta, mínimo devolver foco al trigger al cerrar
   (guardar `document.activeElement` al abrir).

## 9. Consideraciones de rendimiento

1. **GPU-friendly**: animar `transform` + `opacity` solamente; evitar layout thrash (leer
   `getBoundingClientRect` una vez por frame).
2. **rAF + passive**: scroll/wheel listeners con `requestAnimationFrame` y `{ passive: true }`
   (excepto `wheel` del lightbox que necesita `preventDefault` → `{ passive: false }`).
3. **Autoplay**: `setInterval` solo cuando el carousel está visible (`isNear`); pausar en hover.
4. **Límites**: 1-2 elementos parallax, ≤40 partículas, aurora solo con 3 blobs, `mix-blend-mode`
   usado con moderación (cuesta render).
5. **CDN**: no duplicar Bootstrap/Icons/fonts por página (cache browser); versionar recursos propios
   con query `?v=2.1` al cambiar `gv.css`/`gv.js`.
6. **Imágenes**: `loading="lazy"` + `decode()` en lightbox; thumbnails con `object-fit: cover`.
7. **Nada de JS pesado en scroll**: delegar eventos (un listener por `document` con `closest`)
   en vez de uno por elemento (el lightbox SVG ya usa esta técnica para hotspots).

## 10. Guía de testing visual

### 10.1 Validación estructural (rápida)

```powershell
node --check assets/js/gv.js          # sintaxis del JS del navegador
node --check assets/js/i18n.js
npm run presentations:validate        # 11/11 PASS esperado
npm run presentations:serve           # sirve en :3000 y abre navegador
```

### 10.2 Verificación en Chrome real (CDP)

```powershell
# Servidor sin caché de modales i18n
npm run presentations:serve -- --port 8899 --no-browser --no-store
node scripts/cdp-verify-page.cjs --page=autonomy.html     # info-triggers + modales EN/ES/PT
node scripts/cdp-verify-hotspot.cjs                       # click hotspot → modal info
# Genérico para cualquier página:
node scripts/cdp-verify-page.cjs --cdp 9225
```

> **GOTCHA CDP**: `Runtime.evaluate` con `returnByValue:true` ya devuelve el objeto deserializado en
> `result.value` — NO hacer `JSON.parse` encima. Forzar idioma base con
> `localStorage.setItem('gv-lang','en')` al inicio.

### 10.3 Checklist visual manual (por página)

- [ ] Lightbox: centrado, click en backdrop cierra, ESC cierra, zoom wheel centrado en cursor,
      drag-pan, botones +/−/reset, sin scroll del body detrás.
- [ ] Info-trigger "i": hover scale, click abre modal con glassmorphism, cierre por backdrop/✕/ESC.
- [ ] Expand: `aria-expanded` cambia, panel aparece con slide-down, se cierran los hermanos.
- [ ] Footer: texto centrado, clase `gv-footer`, links con hover cyan, responsive (wrap).
- [ ] Header: badge shimmer, título glow, lead centrado, nav con link `active` correcto.
- [ ] Cards: spotlight sigue al cursor, lift al hover, sin scroll horizontal en móvil.
- [ ] Carousel: dots activo, flechas, autoplay pausa al hover, transición suave, `1/N` correcto.
- [ ] Iconos: todos cargan (sin `?` roto del CDN), animaciones solo decorativas.
- [ ] `prefers-reduced-motion: reduce` → sin animaciones, contenido visible al instante.
- [ ] Las 3 resoluciones: ≥1400px, 768px, 375px (Chrome DevTools responsive).

## 11. Gotchas específicos del stack

1. **`bi-brain` NO existe** en bootstrap-icons 1.11.3 → `bi-book` (verificado en CDN).
2. **Lightbox**: nunca `max-width/height:100%` en `.gv-lightbox-img` (doble escalado); usar
   `img.decode().then(afterLoad)` + `naturalWidth > 0` (cacheadas mienten con `complete=true`).
3. **i18n translate()** reemplaza hijos → info-trigger como span HERMANO del texto traducido.
4. **Idempotencia i18n**: insertar claves por bloque de idioma (en/es/'pt-BR'), no globalmente.
5. **`$var:` en PowerShell** en interpolación → `${var}:`.
6. **ESM vs CJS**: `"type": "module"` en package.json → scripts de verificación con `require`
   deben llamarse `.cjs`.
7. **Escritura de archivos en PS**: `[System.IO.File]::WriteAllText` con BOM UTF-8 para no corromper
   los diccionarios.
8. **node --check** = test de sintaxis del JS de navegador (no TS).
9. **SVG**: tras editar, verificar viewBox y balance de `<g>`. Footer no debe colisionar con leyendas.
10. **Footer inline styles**: al homologar, mover a `.gv-footer` en gv.css y quitar los `style=`
    inline (el index.html todavía los tiene).

## 12. Flujo de trabajo recomendado

1. **Identificar el alcance**: ¿nueva página, reparar lightbox, homologar header/footer?
2. **Reutilizar antes de crear**: verificar que el componente ya existe en gv.css/gv.js.
3. **Editar en capas**: HTML de la página → CSS en gv.css (nunca `<style>` duplicado) → JS en gv.js
   (nunca `<script>` inline, salvo init específico).
4. **i18n**: cualquier texto nuevo pasa a `data-i18n` + claves en 3 bloques.
5. **Validar**: `node --check` + `npm run presentations:validate`.
6. **Verificar visual**: servidor + CDP (`cdp-verify-page.cjs`) + checklist manual de §10.3.
7. **Commit**: solo archivos de trabajo (HTML, gv.css, gv.js, i18n) — nunca archivos automáticos de
   daemons ni `.runtime/`.
