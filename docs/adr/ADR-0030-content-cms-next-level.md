# ADR-0030 — Content CMS next-level local-first (F1–F5 + F3-full)

Fecha: 2026-09-06 · Estado: aceptado · App: `apps/content-cms` v3.8.2+

## Status

Accepted — implementado (Content CMS v3.9.0, 2026-09-06).

## Context

> **Addendum v3.9.0 (2026-09-06)** — Auditoría full + pass de calidad al estándar del stack: (1) fix
> de i18n (contexto React `I18nProvider`, propagación real a todas las tabs + locale pt + panels
> des-hardcodeados); (2) tab **Publicar** con UI de conectores (assisted/api + token local
> redactado), payload copy-paste y publish_log; (3) export kit JSON por variante; (4) calendario con
> drag&drop de slots, alta manual por día, filtros, título del item en pills y marca de vencidos;
> (5) items con búsqueda/renombrar (`PATCH /api/items/:id`)/duplicar (`POST /api/items`); (6) medios
> con dropzone multi-upload + dimensiones + lightbox + búsqueda; (7) video con aspect/BGM selectors
> y `DELETE /api/video/:id`; (8) KPI strip vivo con vencidos; (9) toasts semánticos; (10) streaming
> de archivos (`createReadStream`) en vez de `readFileSync`; (11) hashtags reales derivados del
> brief. Calidad: typecheck + lint + 51 tests + build verdes, validación visual de 7 tabs en Chrome.

## Contexto

El CMS era Studio legacy (localStorage) + Content OS `:3787` con generator/template, 10 plataformas,
calendario y media. El usuario pidió llevarlo a otro nivel absorbiendo `MoneyPrinterTurbo`
(video-IA) y `social-media-skills` (17 skills), más Settings IA estilo Archify y Gemini estilo
Prompt-Studio, 100% local-first.

## Decision

1. **Settings IA unificado** (`server/settings.ts`, `.runtime/content-os/settings.json`): provider
   `template|stack(muse-spark)|gemini|openai`, secrets redactados, env > archivo > template,
   validación Gemini viva. UI tab Settings IA.
2. **Skills deterministas v1 + puente IA** (`server/skills.ts`, 8 skills): voice-builder,
   hook-generator x6, post-formatter PAS/AIDA/BAB/STAR/SLAY, content-matrix 32, reels-scripting,
   post-scorer 0-100, graphic-designer, youtube-thumbnail. `Mejorar con IA` vía `/api/generate` con
   provider Settings + gate humano.
3. **Video F3-full local** (`server/video-pipeline.ts`): guion plantilla 3 beats + TTS Windows SAPI
   (fallback silencio) + fondo Medios con zoompan o sólido `#0F1115` + subs quemados libass
   (fallback SRT) + BGM `-22dB` si existe `bgm/<nombre>.mp3`. Galería `GET /api/video` + descargas
   `GET /api/video/:id/file`. Verificado `ffprobe h264 1080x1920 + aac`.
4. **Conectores** (`server/connectors.ts`, 11 plataformas): `assisted` por defecto (gate humano,
   ADR-0021), `api` opt-in con token local.
5. **Scheduler** (`server/scheduler.ts`, `scheduler-cli.ts --once|--daemon`): publica `confirmed`
   vencidos → `published`, schtasks `GVContentOS-Scheduler` cada 5min, pidfile + log.
6. **UX honesta**: briefs requeridos, disclosures del motor real, overlays en previews oscuros,
   transiciones `gv-view-fade`, hover, foco visible, `prefers-reduced-motion`. Identidad v2 Premium
   intacta.

## Alternativas descartadas

- Video-IA cloud (Pexels/ElevenLabs/upload TikTok): requiere keys/red; queda como F-siguiente
  opt-in, no default.
- `drawtext` quemado en MP4: falla sin fuentes en Windows; se usa fondo + SRT/quemado libass.
- Subagentes `sdd-*` con `big-pickle/gpt-5.6-luna`: sin crédito; se alineó todo a
  `muse-spark-1.3-contributor-free` + fallbacks `explore/general`.

## Consecuencias

- Requiere `winget install Gyan.FFmpeg` + reinicio `:3787` para heredar PATH.
- `.runtime/content-os/` concentra settings, video, bgm, scheduler (local-first, sin cloud).
- Calidad: `typecheck` + `lint` + `51 tests` + `vite build` verdes; endpoints vivos verificados.
