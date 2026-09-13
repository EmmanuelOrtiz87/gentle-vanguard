---
created: 2026-09-08 16:53:50
tags: [engram, decision]
engram_id: 3788
type: decision
---

# Identidad v2.0 formalizada como OFICIAL en todo el stack

**What**: Formalización de la identidad v2.0 APPLICATION FINAL como OFICIAL: propagación LIVE a ubicaciones oficiales, propagación a 7 apps (public + dist), regeneración de tokens desde config/brand.json, actualización de TOKENS-v2.json, renombrado Candidate → Official en el Design Hub (banner, asset generator, brand editor), ADR-0033 status accepted.
**Why**: El usuario validó la identidad v2.0 y ordenó "llevemos todo a todas las app, actualicemos documentacion, formalicemos lo oficial y productivo".
**Where**: assets/logo.svg + logo-icon.svg + logo-mono-*.svg (propagados), 7 apps (academy-web, archify, command-center, content-cms, gv-analytics, prompt-studio, web-dashboard), config/brand.json (v2.1.0), assets/tokens.json/css/scss (regenerados), docs/brand/TOKENS-v2.json (v2.1.0), docs/brand/BRAND-KIT.md (v2.0 = OFICIAL), docs/adr/ADR-0033 (accepted), apps/design-hub (banner OFICIAL + badges Official v2.0)
**Learned**:
- Paleta oficial v2.0: primary #06B6D4, accent #8B5CF6, background #0B1020, gradiente #6E4DEB→#7B63E8→#06B6D4
- Tagline oficial: "APRENDER · EXPERIMENTAR · CONSTRUIR · TRANSFORMAR"
- npm run gv:tokens regenera assets/tokens.{json,css,scss} desde config/brand.json
- validate.js pasa con 0 failures después de todos los cambios
- Verificado con Playwright: banner "✅ OFICIAL — GV New Identity v2.0" y 19 badges "Official v2.0" en Asset Generator

---
*Imported from Engram on 2026-09-08*
