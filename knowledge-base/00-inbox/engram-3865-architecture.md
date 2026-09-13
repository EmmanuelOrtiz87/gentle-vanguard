---
created: 2026-09-10 20:47:43
tags: [engram, architecture]
engram_id: 3865
type: architecture
---

# Academy: SEO pack landing + deploy GitHub Pages

**What**: SEO pack completo para la landing pública + workflow de deploy a GitHub Pages. La landing ahora tiene Open Graph (og:title/description/image/locale), Twitter Card (summary_large_image), JSON-LD (EducationalOrganization), og-cover.svg 1200×630 con marca GV, sitemap.xml y robots.txt. El workflow deploy-landing.yml regenera la landing en CI y deploya a Pages.

**Why**: El usuario pidió preparar la landing para tráfico orgánico real. El SEO pack hace la landing indexable y compartible en redes; el workflow automatiza el deploy.

**Where**:
- `apps/academy-web/scripts/build-landing.mjs` — meta OG/Twitter/JSON-LD en el head + generación de og-cover.svg (1200×630), sitemap.xml y robots.txt al final. SITE_URL configurable con env ACADEMY_LANDING_URL (default: https://gentle-vanguard.github.io/academy-landing)
- `apps/academy-landing/covers/og-cover.svg` — imagen social con marca GV
- `apps/academy-landing/sitemap.xml` + `robots.txt` — indexación
- `.github/workflows/deploy-landing.yml` — NUEVO: deploy a GitHub Pages (regenera landing en CI con ACADEMY_LANDING_URL dinámico, copia a _site, deploy-pages). Trigger: push a main con cambios en landing/data/scripts, o manual

**Learned**: (1) El og:image es SVG — funciona self-hosted pero para producción en redes sociales conviene convertir a PNG (chrome --headless --screenshot). (2) El workflow regenera la landing en CI (no usa el HTML commiteado) — el catálogo siempre está fresco. (3) El SITE_URL se configura con env ACADEMY_LANDING_URL para que el sitemap apunte al dominio real. (4) Verificado: OG/Twitter/JSON-LD en el HTML, og-cover.svg 200, sitemap 200, robots 200. (5) El workflow requiere Settings → Pages → Source: GitHub Actions en el repo.

---
*Imported from Engram on 2026-09-12*
