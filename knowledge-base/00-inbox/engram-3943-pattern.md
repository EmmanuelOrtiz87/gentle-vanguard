---
created: 2026-09-15 23:51:24
tags: [engram, pattern]
engram_id: 3943
type: pattern
---

# shell:verify visual 10/10 + conformance 22 checks + CI dual-gate

**What**: Ronda de potenciación del stack: (1) conformance.ts extendido a 22 checks — 3 checks de identidad a nivel SOURCE (wordmark blanco, gradiente span, 13px), check gv-app-shell relajado (acepta <Shell> que lo renderiza internamente), academy-crm agregado a imports. 22/22 PASS. (2) CI job design-identity ahora ejecuta DUAL gate: validate:shell + conformance. (3) Herramienta nativa `npm run shell:verify` (src/design/shell-visual-verify.ts): verificación visual en vivo de las 10 apps homologadas con chromium headless (librería playwright directa) — full-contract (8 apps: topbar+wordmark blanco+gradiente+13px+icono) y keys-only (web-dashboard theme-only, gv-analytics). **10/10 PASS**. (4) Fix 13px en academy-web (academy-layout.css) y academy-landing (index.html inline) — tenían 13.3333px heredado.
**Why**: El usuario pidió potenciar el stack con verificación continua; el gate estático (conformance) garantiza la cadena src→snapshots→dist, y shell:verify agrega la capa EN VIVO (computed styles reales).
**Where**: packages/gv-design-system/src/cli/conformance.ts; .github/workflows/ci.yml (job design-identity, 2 steps); src/design/shell-visual-verify.ts; package.json (script shell:verify); apps/academy-web/academy-layout.css + apps/academy-landing/index.html (fix 13px, apps gitignoreadas salvo landing trackeada); docs/stack-manual-full.md.
**Learned**: (a) **playwright-cli `open` MATA el shell padre** (reproducible 2x, "Unknown: ChildProcess.kill") — para automatización Node usar la librería playwright directa (chromium headless), nunca el CLI open. (b) playwright@1.61.1 está en node_modules root — la librería es la vía nativa. (c) Probe structure-aware: icono de idioma puede ser SVG (content-cms/prompt-studio/command-center), no solo glifo 文A; langBtn = cualquier button dentro de .gv-lang-dropdown. (d) web-dashboard es theme-only (sin selector de idioma, usa gv-cc-theme via Tailwind) — contrato keys-only. (e) waitForSelector antes del probe: la hidratación React necesita espera activa (600ms fijo no basta en dashboard). Commit e06ba4d6, push develop OK.

---
*Imported from Engram on 2026-09-16*
