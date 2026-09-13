---
created: 2026-08-11 09:55:07
tags: [engram, decision]
engram_id: 2748
type: decision
---

# Análisis: Inconsistencias en heroes HTML - Correcciones pendientes

**What**: Análisis de inconsistencias en heroes de presentaciones HTML + intento de corrección
**Why**: Usuario reporta heroes inconsistentes entre páginas
**Where**: docs/presentations/*.html (20 páginas)
**Learned**:

## PROBLEMAS IDENTIFICADOS:

### 1. Sin `id="overview"` en hero (7 páginas):

- memory-knowledge.html
- dashboard.html
- health.html
- operations-cloud.html
- patterns-conventions.html
- quickstart.html

### 2. Sin CTAs (botones) en hero (13 páginas):

- memory-knowledge.html, security-governance.html, dashboard.html, patterns-conventions.html
- quickstart.html, contract-viewer.html, image-studio.html, marketing.html
- md-viewer.html, resources-index.html, social-post.html, video-studio.html

### 3. Sin stats (14 páginas secundarias):

- autonomy (tiene carrusel), dashboard, health, operations-cloud, patterns-conventions
- contract-viewer, image-studio, marketing, md-viewer, resources-index, social-post, video-studio

### 4. SIN HERO COMPLETO:

- product-doc-gentle.html

### ESTRUCTURA DE REFERENCIA (index.html - COMPLETA):

```html
<header class="hero" id="overview">
  <span class="hero-badge mb-3">✦ v4.0 — ...</span>
  <h1><span class="glow">...</span></h1>
  <p class="lead">...</p>
  <div class="stats">...</div>
  <div class="ctas">
    <a href="..." class="btn-gv">...</a>
    <a href="..." class="btn-gv-alt">...</a>
  </div>
</header>
```

## CORRECCIONES NECESARIAS:

Para cada página que falta `id="overview"`:

```html
<!-- ANTES -->
<header class="hero">

<!-- DESPUÉS -->
<header class="hero" id="overview">
```

## PROBLEMA TÉCNICO:

El sistema de archivos bloquea escritura en ciertos archivos (error UNKNOWN -4094).
Las correcciones deben hacerse manualmente o con editor de texto.

---
*Imported from Engram on 2026-09-06*
