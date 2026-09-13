---
created: 2026-09-09 01:38:02
tags: [engram, decision]
engram_id: 3796
type: decision
---

# Footer homologado + wordmark blanco + favicon: estándar de identidad en 8 apps

**What**: Homologación completa de identidad visual en el stack (2026-09-08): (1) Estándar de footer `.gv-footer-brand` — markup `<span class="gv-footer-brand">Gentle<span>Vanguard</span></span> · <tagline> — vX.Y.Z · 2026`, Gentle blanco (--gv-text) + Vanguard gradiente v2; aplicado en web-dashboard, gv-analytics y archify (footers NUEVOS, no existían), prompt-studio, content-cms, academy-web, design-hub, command-center. (2) Fix wordmark command-center: legacy v1 congelado tiene `.gv-brand span { color: var(--gv-primary) }` (0,1,1) que pintaba "Gentle" cyan; fix con `.gv-brand .gv-wordmark` (0,2,0). (3) Favicon: command-center server.ts no servía /favicon.svg (404 en tab) — ruta agregada. (4) Design Hub: Labs ahora tab permanente en nav + card en Overview; hero compactado (clamp 24-32px, padding 28px); página Proposals didáctica con workflow de 5 pasos.
**Why**: Usuario reportó: command-center sin "Gentle" blanco ni favicon en tab; footers no homologados; Labs solo accesible desde footer; Proposals sin explicación de propósito; hero gigante.
**Where**: apps/command-center/server.ts + public/index.html; apps/design-hub/src/scripts/shell.js + index.html + styles/main.css + src/proposals/{index.html,proposals.css} + styles/proposals.css; apps/{web-dashboard,gv-analytics,archify,prompt-studio,content-cms}/src/App.tsx + styles.css; apps/academy-web/academy-style-v2.css; rules/NORMATIVA-DESIGN-SYSTEM.md (decisiones 6-8 nuevas).
**Learned**: --gv-text-brand=#a78bfa es PÚRPURA (no usar para brand blanco; el canónico es --gv-text #e8eef4). El v1 congelado inyecta reglas de alta especificidad — apps que lo cargan necesitan overrides (0,2,0). Servers con readFileSync por request sirven HTML/CSS actualizado sin restart, pero cambios en server.ts SÍ requieren restart (watchdog revive el daemon con código nuevo). Verificación headless: este modelo no lee imágenes — usar checks programáticos HTTP (regex sobre contenido servido) en lugar de screenshots.

---
*Imported from Engram on 2026-09-09*
