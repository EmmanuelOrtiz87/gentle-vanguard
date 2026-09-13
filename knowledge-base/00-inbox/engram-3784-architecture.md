---
created: 2026-09-08 15:06:57
tags: [engram, architecture]
engram_id: 3784
type: architecture
---

# Identidad v2.0 APPLICATION FINAL integrada al stack

**What**: Integración de la nueva identidad visual v2.0 (SVG Asset System v2.0 APPLICATION FINAL) en el stack: 19 SVGs con monograma GV centrado (canvas 1024×1024), favicon actualizado, 5 banners sociales reescritos, v3 Editor con path centrado, Asset Generator con canvas monograma GV.
**Why**: El usuario proporcionó un set mejorado de assets (centrado matemáticamente, corrige desequilibrio visual del anterior). Validó que los assets se ven bien y pidió aplicar la identidad a favicon y banners.
**Where**: assets/brand/gentle-vanguard/v2/ (22 archivos), apps/design-hub/public/assets/brand/gentle-vanguard/v2/, docs/brand/assets/banner-{og,github,linkedin,twitter,docs}.svg, docs/brand/assets/favicon.svg, apps/design-hub/src/v3-editor/editor.js, apps/design-hub/src/asset-generator/index.html, apps/design-hub/index.html + 3 subpáginas (referencias favicon), docs/adr/ADR-0033, docs/brand/BRAND-KIT.md, .design-hub/approved/manifest.json
**Learned**:
- La v2.0 APPLICATION FINAL reemplaza a la v3-candidate anterior como candidata vigente (histórico)
- Paleta: Midnight #0B1020, Electric Blue #1E40AF, Tech Cyan #06B6D4, Vanguard Violet #8B5CF6, Soft White #F8FAFC, Black #050A14
- Gradiente: #6E4DEB → #7B63E8 → #06B6D4 (135deg)
- Tipografía: Inter (primaria), Manrope (fallback), wordmark weight 800
- El favicon canónico (docs/brand/assets/favicon.svg) y las 4 referencias del Design Hub apuntan al nuevo favicon v2.0
- Los 5 banners sociales usan el monograma GV centrado con fondo Midnight
- El Asset Generator canvas dibuja el monograma GV v2.0 (verificado por muestreo de píxeles: #7457e9 violeta y #428bde cyan en la placa)
- Propagación dry-run lista: 7 assets mapeados a ubicaciones oficiales

---
*Imported from Engram on 2026-09-08*
