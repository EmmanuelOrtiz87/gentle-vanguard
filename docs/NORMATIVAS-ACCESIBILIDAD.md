# NORMATIVAS-ACCESIBILIDAD.md — Web Accessibility Standards

Version: 1.0.0
Framework: WCAG 2.2 Level AA + WCAG 2.3 Draft
Last updated: 2026-05-11

---

## 1. PROPOSITO

Define los estándares de accesibilidad web para todo frontend generado en el stack Foundation. Aplica a componentes UI, dashboards, landing pages, artifacts, y cualquier interfaz web producida por agentes. Toda implementacion debe cumplir WCAG 2.2 Level AA como minimo.

---

## 2. PRINCIPIOS RECTORES (POUR)

### 2.1 Perceivable — Perceptible

| Criterio | WCAG | Implementacion |
|----------|------|----------------|
| Text alternatives | 1.1.1 | `alt` en imagenes, `aria-label` en iconos, `role="img"` con etiqueta |
| Captions | 1.2.2 | Subtitulos en contenido multimedia |
| Adaptable | 1.3.x | Estructura semantica correcta (landmarks, headings, listas) |
| Distinguishable | 1.4.x | Contraste >= 4.5:1 (texto normal), >= 3:1 (texto grande) |

### 2.2 Operable — Operable

| Criterio | WCAG | Implementacion |
|----------|------|----------------|
| Keyboard accessible | 2.1.x | Todas las acciones accesibles via teclado, focus visible |
| Enough time | 2.2.x | Timers ajustables o removibles |
| Seizures | 2.3.x | No parpadeos > 3 flases/segundo |
| Navigable | 2.4.x | Skip links, headings jerarquicos, breadcrumbs |

### 2.3 Understandable — Comprensible

| Criterio | WCAG | Implementacion |
|----------|------|----------------|
| Readable | 3.1.x | `lang` en HTML definido correctamente |
| Predictable | 3.2.x | Comportamiento consistente, cambios contextuales con aviso |
| Input assistance | 3.3.x | Labels asociados, errores descriptivos, sugerencias |

### 2.4 Robust — Robusto

| Criterio | WCAG | Implementacion |
|----------|------|----------------|
| Compatible | 4.1.x | ARIA validado, HTML semantico, parsable |
| Status messages | 4.1.3 | `role="status"`, `aria-live="polite"` para mensajes dinamicos |

---

## 3. NIVELES DE CUMPLIMIENTO

| Nivel | Requisito | Verification | Timeline |
|-------|-----------|-------------|----------|
| A (Minimo) | 30 criterios base | axe-core automated | Release |
| AA (Target) | A + 20 criterios adicionales | axe-core + manual sampling | Release |
| AAA (Meta) | AA + 28 criterios avanzados | Full manual audit | Q2 2027 |

Todo nuevo componente frontend DEBE cumplir WCAG 2.2 AA desde el primer commit.

---

## 4. CONTROLES OBLIGATORIOS

### 4.1 Semantic HTML

```html
<!-- CORRECTO: landmark regions, headings jerarquicos -->
<header role="banner">
  <nav aria-label="Main">...</nav>
</header>
<main role="main">
  <h1>Title</h1>
  <section aria-labelledby="section-heading">
    <h2 id="section-heading">Section</h2>
  </section>
</main>
<footer role="contentinfo">...</footer>

<!-- INCORRECTO: divs sin semantica, headings saltados -->
<div class="header">...</div>
<div class="content">
  <h1>Title</h1>
  <h3>Skip h2?</h3>
</div>
```

### 4.2 Color & Contrast

1. **MUST** mantener contraste >= 4.5:1 para texto normal (< 18px)
2. **MUST** mantener contraste >= 3:1 para texto grande (>= 18px bold o >= 24px)
3. **MUST NOT** usar color como unico indicador de estado (ej: rojo = error, incluir icono + texto)
4. **SHOULD** soportar High Contrast Mode (Windows) y prefers-contrast: more
5. **MUST** testear con simuladores de daltonismo (monocromatico, deuteranopia, protanopia, tritanopia)

### 4.3 Keyboard Navigation

1. **MUST** soportar Tab, Enter, Space, Escape, Arrow keys en componentes interactivos
2. **MUST** mostrar focus visible en todos los elementos (outline o ring)
3. **MUST** mantener orden logico de tabulacion (DOM order)
4. **MUST NOT** usar `tabindex > 0`
5. **MUST** implementar skip links al inicio de cada pagina

### 4.4 ARIA

1. **MUST** usar ARIA solo cuando HTML semantico no es suficiente (primera regla de ARIA)
2. **MUST** mantener ARIA roles, states, properties actualizados dinamicamente
3. **MUST** testear ARIA con lectores de pantalla reales (NVDA, VoiceOver, JAWS)
4. **MUST NOT** cambiar roles ARIA despues del render inicial
5. **SHOULD** usar `aria-live="polite"` para actualizaciones de contenido dinamico

### 4.5 Forms

1. **MUST** asociar cada input con un `<label>` usando `for`/`id` o `aria-labelledby`
2. **MUST** agrupar inputs relacionados con `<fieldset>` y `<legend>`
3. **MUST** mostrar errores inline con `aria-describedby` y `aria-invalid`
4. **MUST** mantener mensajes de error claros y accionables
5. **SHOULD** proporcionar sugerencias de formato (placeholder no es suficiente)

### 4.6 Images & Media

1. **MUST** proporcionar `alt` descriptivo para imagenes informativas
2. **MUST** usar `alt=""` para imagenes decorativas
3. **MUST** proporcionar transcripciones para audio/video
4. **MUST** proporcionar subtitulos sincronizados para video
5. **SHOULD** evitar GIFs animados o videos autoplay con audio

### 4.7 Responsive & Zoom

1. **MUST** soportar zoom hasta 400% sin perdida de funcionalidad (WCAG 1.4.10)
2. **MUST** mantener layout funcional en viewports desde 320px
3. **MUST** usar unidades relativas (rem, em, %) en vez de px para texto y contenedores
4. **MUST NOT** requerir scroll horizontal a 1280px de viewport
5. **SHOULD** testear en dispositivos reales (mobile, tablet, desktop)

---

## 5. HERRAMIENTAS DE VERIFICACION

### 5.1 Automated Testing

| Herramienta | Uso | Frecuencia |
|-------------|-----|------------|
| axe-core | Analisis automatizado de reglas WCAG | Cada PR |
| Lighthouse AI | Auditoria de accesibilidad + sugerencias | Cada PR |
| Pa11y | CI pipeline de accesibilidad | Cada commit |
| HTML Validator (Nu) | Validacion de HTML semantico | Cada PR |

### 5.2 Manual Testing

| Tecnica | Frecuencia | Herramienta |
|---------|------------|-------------|
| Keyboard only | Cada PR | Navegador nativo |
| Screen reader | Pre-release | NVDA / VoiceOver / JAWS |
| Zoom 400% | Pre-release | Navegador nativo |
| High Contrast | Pre-release | Windows High Contrast |
| Color blindness | Pre-release | Simuladores (Chrome DevTools) |

### 5.3 CI Integration

```yaml
- name: Accessibility audit
  run: |
    npx axe --exit --show-errors
  continue-on-error: false
```

---

## 6. COMPLIANCE CHECKPOINTS

TODO implementacion DEBE verificar:

1. [ ] Toda imagen tiene `alt` o `role="presentation"`
2. [ ] Todos los formularios tienen `<label>` asociado
3. [ ] Contraste de color >= 4.5:1 (normal) / 3:1 (large)
4. [ ] Navegacion completa por teclado funciona
5. [ ] Focus visible en todos los elementos interactivos
6. [ ] ARIA usado correctamente (no duplicar semantica nativa)
7. [ ] Zoom 400% no rompe layout
8. [ ] No hay trampas de foco (keyboard trap)
9. [ ] Skip link presente y funcional
10. [ ] Mensajes de error claros y accionables
11. [ ] Landmarks ARIA presentes y correctos
12. [ ] Jerarquia de headings correcta (h1 -> h2 -> h3, no saltos)

---

## 7. REFERENCIAS

| Resource | Path |
|----------|------|
| WCAG 2.2 Specification | w3.org/TR/WCAG22 |
| WCAG 2.3 Draft | w3.org/TR/WCAG23 |
| ARIA Authoring Practices | w3.org/WAI/ARIA/apg |
| axe-core Documentation | dequeuniversity.com/rules/axe |
| WebAIM Contrast Checker | webaim.org/resources/contrastchecker |
| Development Standards | `rules/DEVELOPMENT-STANDARDS.md` |
| Testing Standards | `rules/TESTING-STANDARDS.md` |
| Code Standards | `rules/NORMATIVAS-CODIGO.md` |

---

_Version: 1.0.0 — 2026-05-11 — Status: ACTIVE_
