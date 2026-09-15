---
created: 2026-09-12 22:51:43
tags: [engram, pattern]
engram_id: 3891
type: pattern
---

# Script social-unfollow para X y TikTok

**What**: Script de unfollow masivo humanizado para X (Twitter) y TikTok usando Playwright con perfil persistente. Creado en `scripts/social-unfollow/unfollow.ts` + README.md.

**Why**: El usuario pidió automatizar "dejar de seguir a todos" en X y TikTok. Se eligió Playwright (no API) porque TikTok no tiene API de unfollow y la API de X requiere tier de pago.

**Where**: scripts/social-unfollow/unfollow.ts, scripts/social-unfollow/README.md, .runtime/social-unfollow/ (config.json, profiles/, state.json — auto-generados)

**Learned**: 
- X: selectores `[data-testid="UserCell"]` + botón "Following" + confirm `[data-testid="confirmationSheetConfirm"]`
- TikTok: `[data-e2e="user-follow-item"]` + `[data-e2e="user-unfollow"]` + confirm `[data-e2e="unfollow-modal-confirm"]`
- Selectores configurables en config.json con fallback (ambas plataformas cambian el DOM seguido)
- Comportamiento anti-detección: retrasos aleatorios 4-15s, pausas largas cada 12-15, límite diario 75, dry-run por defecto, `--run` para ejecutar
- Login manual en primer arranque con perfil persistente (chromium.launchPersistentContext)
- Typecheck pasa con tsc strict; chromium de Playwright ya instalado en el sistema

---
*Imported from Engram on 2026-09-14*
