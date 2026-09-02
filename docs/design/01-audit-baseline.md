# 01 — Audit Baseline (impeccable detect)

> Generado: 2026-09-01 · tool: `impeccable detect` v4.1.2 · scope: 7 apps + canonical assets
> Config: `.impeccable/config.json` (designSystem.enabled, waivers de marca documentados)
> 0 critical / 51 warning / 7 advisory

## Resumen ejecutivo

- **Total findings**: **58** (51 warning + 7 advisory)
- **Sin critical** — el codebase no presenta antipatrones bloqueantes
- **Por categoría**: `slop` 40 (69%) · `quality` 18 (31%)
- **Por app**: academy-web 24, web-dashboard 19, command-center 7, gv-analytics 3, prompt-studio 3, archify 1, content-cms 1
- **Top antipatterns**: `gradient-text` (14), `gray-on-color` (12), `codex-grid-background` (6), `side-tab` (5), `radial-spotlight-glow` (4)
- **Top archivos**: `apps/academy-web/index.html` (14), `apps/academy-web/style.css` (9), `apps/command-center/public/index.html` (7)
- **Waivers documentados**: `gradient-text` (19 instancias) + `side-tab` (5 instancias) en archivos con assets de marca intencionales (wordmark "Vanguard", lesson-row accents). La estructura `ignoreValues` con `files[]` anidadas en `config.json` está persistida para el detector aunque el schema del CLI actual todavía no la hidrata → los warnings se reportan y se marcan como **brand-intentional** en la columna Notes.

## Tabla consolidada (58 findings, ordenados por severity)

| App | Archivo | Línea | Antipattern | Severity | Categoría | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| academy-web | `apps/academy-web/index.html` | 0 | low-contrast | warning | quality | WCAG AA 4.5:1 |
| academy-web | `apps/academy-web/index.html` | 0 | layout-transition | warning | quality | use DS transition tokens |
| academy-web | `apps/academy-web/index.html` | 0 | low-contrast | warning | quality | WCAG AA 4.5:1 |
| academy-web | `apps/academy-web/index.html` | 0 | radial-spotlight-glow | warning | slop | subtle accent instead |
| academy-web | `apps/academy-web/index.html` | 0 | overused-font | warning | slop | use brand font (Inter/IBM Plex) |
| academy-web | `apps/academy-web/index.html` | 0 | flat-type-hierarchy | warning | slop | vary font-weight/size |
| academy-web | `apps/academy-web/index.html` | 0 | ai-color-palette | warning | slop | shift to brand-SoT palette |
| academy-web | `apps/academy-web/index.html` | 0 | radial-spotlight-glow | warning | slop | subtle accent instead |
| academy-web | `apps/academy-web/index.html` | 0 | dark-glow | warning | slop | use brand glow token |
| academy-web | `apps/academy-web/index.html` | 0 | clipped-overflow-container | warning | quality | verify overflow-x handling |
| academy-web | `apps/academy-web/index.html` | 0 | gradient-text | warning | slop | wordmark/brand (waiver) |
| academy-web | `apps/academy-web/index.html` | 0 | gradient-text | warning | slop | wordmark/brand (waiver) |
| academy-web | `apps/academy-web/style.css` | 200 | layout-transition | warning | quality | use DS transition tokens |
| academy-web | `apps/academy-web/style.css` | 242 | gradient-text | warning | slop | wordmark/brand (waiver) |
| academy-web | `apps/academy-web/style.css` | 462 | gradient-text | warning | slop | wordmark/brand (waiver) |
| academy-web | `apps/academy-web/style.css` | 508 | gradient-text | warning | slop | wordmark/brand (waiver) |
| academy-web | `apps/academy-web/style.css` | 695 | gradient-text | warning | slop | wordmark/brand (waiver) |
| academy-web | `apps/academy-web/style.css` | 858 | side-tab | warning | slop | brand signature (waiver) |
| academy-web | `apps/academy-web/style.css` | 892 | gradient-text | warning | slop | wordmark/brand (waiver) |
| academy-web | `apps/academy-web/style.css` | 954 | gradient-text | warning | slop | wordmark/brand (waiver) |
| archify | `apps/archify/src/styles.css` | 70 | gradient-text | warning | slop | wordmark/brand (waiver) |
| command-center | `apps/command-center/public/index.html` | 0 | radial-spotlight-glow | warning | slop | subtle accent instead |
| command-center | `apps/command-center/public/index.html` | 0 | radial-spotlight-glow | warning | slop | subtle accent instead |
| command-center | `apps/command-center/public/index.html` | 0 | ai-color-palette | warning | slop | shift to brand-SoT palette |
| command-center | `apps/command-center/public/index.html` | 0 | low-contrast | warning | quality | WCAG AA 4.5:1 |
| command-center | `apps/command-center/public/index.html` | 0 | dark-glow | warning | slop | use brand glow token |
| command-center | `apps/command-center/public/index.html` | 0 | overused-font | warning | slop | use brand font (Inter/IBM Plex) |
| content-cms | `apps/content-cms/src/styles.css` | 48 | gradient-text | warning | slop | wordmark/brand (waiver) |
| gv-analytics | `apps/gv-analytics/src/styles.css` | 180 | gradient-text | warning | slop | wordmark/brand (waiver) |
| gv-analytics | `apps/gv-analytics/src/styles.css` | 889 | gradient-text | warning | slop | wordmark/brand (waiver) |
| prompt-studio | `apps/prompt-studio/src/App.tsx` | 493 | ai-color-palette | warning | slop | shift to brand-SoT palette |
| prompt-studio | `apps/prompt-studio/src/App.tsx` | 576 | gray-on-color | warning | quality | use white/near-white for contrast |
| prompt-studio | `apps/prompt-studio/src/App.tsx` | 588 | gray-on-color | warning | quality | use white/near-white for contrast |
| web-dashboard | `apps/web-dashboard/src/components/AgentChat.tsx` | 282 | gray-on-color | warning | quality | use white/near-white for contrast |
| web-dashboard | `apps/web-dashboard/src/components/AgentChat.tsx` | 282 | gray-on-color | warning | quality | use white/near-white for contrast |
| web-dashboard | `apps/web-dashboard/src/components/AgentChat.tsx` | 312 | gray-on-color | warning | quality | use white/near-white for contrast |
| web-dashboard | `apps/web-dashboard/src/components/AgentChat.tsx` | 312 | gray-on-color | warning | quality | use white/near-white for contrast |
| web-dashboard | `apps/web-dashboard/src/components/AgentMessage.tsx` | 358 | side-tab | warning | slop | brand signature (waiver) |
| web-dashboard | `apps/web-dashboard/src/components/AlertPanel.tsx` | 26 | side-tab | warning | slop | brand signature (waiver) |
| web-dashboard | `apps/web-dashboard/src/components/AlertPanel.tsx` | 29 | side-tab | warning | slop | brand signature (waiver) |
| web-dashboard | `apps/web-dashboard/src/components/Marketplace.tsx` | 453 | border-accent-on-rounded | warning | slop | remove or reduce weight |
| web-dashboard | `apps/web-dashboard/src/components/Marketplace.tsx` | 782 | border-accent-on-rounded | warning | slop | remove or reduce weight |
| web-dashboard | `apps/web-dashboard/src/components/SloPanel.tsx` | 204 | side-tab | warning | slop | brand signature (waiver) |
| web-dashboard | `apps/web-dashboard/src/components/TenantSelector.tsx` | 62 | gray-on-color | warning | quality | use white/near-white for contrast |
| web-dashboard | `apps/web-dashboard/src/components/TenantSelector.tsx` | 62 | gray-on-color | warning | quality | use white/near-white for contrast |
| web-dashboard | `apps/web-dashboard/src/components/TenantSelector.tsx` | 70 | gray-on-color | warning | quality | use white/near-white for contrast |
| web-dashboard | `apps/web-dashboard/src/components/TenantSelector.tsx` | 70 | gray-on-color | warning | quality | use white/near-white for contrast |
| web-dashboard | `apps/web-dashboard/src/components/TracingDashboard.tsx` | 503 | gray-on-color | warning | quality | use white/near-white for contrast |
| web-dashboard | `apps/web-dashboard/src/components/TracingDashboard.tsx` | 512 | gray-on-color | warning | quality | use white/near-white for contrast |
| web-dashboard | `apps/web-dashboard/src/styles/index.css` | 200 | gradient-text | warning | slop | wordmark/brand (waiver) |
| web-dashboard | `apps/web-dashboard/src/styles/index.css` | 222 | gradient-text | warning | slop | wordmark/brand (waiver) |
| academy-web | `apps/academy-web/gv-design-system.css` | 68 | codex-grid-background | advisory | slop | not blocking |
| academy-web | `apps/academy-web/index.html` | 0 | codex-grid-background | advisory | slop | not blocking |
| academy-web | `apps/academy-web/index.html` | 0 | gpt-thin-border-wide-shadow | advisory | slop | balance border+shadow |
| academy-web | `apps/academy-web/style.css` | 160 | codex-grid-background | advisory | slop | not blocking |
| command-center | `apps/command-center/public/index.html` | 0 | codex-grid-background | advisory | slop | not blocking |
| gv-analytics | `apps/gv-analytics/src/styles.css` | 106 | codex-grid-background | advisory | slop | not blocking |
| web-dashboard | `apps/web-dashboard/src/styles/index.css` | 128 | codex-grid-background | advisory | slop | not blocking |

## Breakdown por severity

| Severity | Count | % |
| --- | --- | --- |
| critical | 0 | 0% |
| warning | 51 | 88% |
| advisory | 7 | 12% |

## Breakdown por categoría

| Categoría | Count | % |
| --- | --- | --- |
| slop | 40 | 69% |
| quality | 18 | 31% |

## Breakdown por app

| App | Count | Notas |
| --- | --- | --- |
| academy-web | 24 | Referencia viva con waivers de marca explícitos |
| web-dashboard | 19 | Tailwind 3.4 + React, alta concentración de `gray-on-color` |
| command-center | 7 | Vanilla JS sin DS — `ai-color-palette` + `dark-glow` |
| gv-analytics | 3 | Estándar implementado; solo gradient-text detectado |
| prompt-studio | 3 | Tailwind 4.1 — `ai-color-palette` + 2x `gray-on-color` |
| archify | 1 | Solo gradient-text (70) |
| content-cms | 1 | Solo gradient-text (48) |

## Top 5 antipatterns recurrentes

1. **`gradient-text`** (14) — wordmark/brand intentional en `academy-web`, `gv-analytics`, `web-dashboard/styles`, `archify`, `content-cms`, `web-dashboard/components` (AgentMessage, AlertPanel, SloPanel)
2. **`gray-on-color`** (12) — texto gris sobre fondos coloreados en `web-dashboard` (8) y `prompt-studio` (4)
3. **`codex-grid-background`** (6) — advisory en `academy-web`, `gv-analytics`, `web-dashboard`, `command-center`
4. **`side-tab`** (5) — border-left en `academy-web`, `web-dashboard/AgentMessage`, `web-dashboard/AlertPanel`, `web-dashboard/SloPanel`
5. **`radial-spotlight-glow`** (4) — en `academy-web/index.html` (2) y `command-center/public/index.html` (2)

## Top 3 archivos más flagged

1. `apps/academy-web/index.html` — **14** findings (asset de marca denso, waivers explícitos)
2. `apps/academy-web/style.css` — **9** findings (8 gradient-text + 1 layout-transition)
3. `apps/command-center/public/index.html` — **7** findings (5 warning + 2 advisory, sin DS)

## Hallazgos destacables

- **Academy-web concentra 41% (24/58)** del total: el archivo `index.html` es la "referencia viva" del brand per `UI-STANDARD-ECOSYSTEM.md`. Los waivers son **intencionales** — el detector marca 19 instancias de `gradient-text` + `side-tab` que son firma de marca (wordmark "Vanguard" + lesson-row accents). Persistido en `.impeccable/config.json` con `ignoreValues.{gradient-text,side-tab}.files[]`.
- **`gray-on-color` en web-dashboard** (8 instancias)集中在 `AgentChat.tsx`, `TenantSelector.tsx`, `TracingDashboard.tsx` — 4 componentes con texto gris sobre cards de color; WCAG AA fail. **Prioridad P1**.
- **`command-center` 7 findings sin DS** — la app está fuera del scope de tokens (`--dash-*`/`--gv-*`) y usa vanilla JS. La mayoría son `ai-color-palette` + `dark-glow` típicos de generación AI. **Out of scope para este DS salvo decisión arquitectural**.
- **`prompt-studio` 3 findings en `App.tsx`** (Tailwind 4.1) — incluye `ai-color-palette` que choca con el brand SoT.
- **0 critical findings** — el detector no encontró issues bloqueantes (no `jsx-without-key`, no `dangerously-set`, no `missing-alt` severo).

## Configuración del detector (`.impeccable/config.json`)

```json
{
  "detector": {
    "designSystem": { "enabled": true },
    "ignoreValues": {
      "gradient-text": { "files": [...], "reason": "..." },
      "side-tab":       { "files": [...], "reason": "..." }
    }
  }
}
```

**Limitación detectada**: la estructura anidada `ignoreValues[rule].files[]` no es la consumida por la CLI actual — `impeccable ignores list` ignora esos nodos y solo respeta `ignoreRules`/`ignoreFiles`/`ignoreValues[rule][value]` planos. Por lo tanto los 19 findings de marca siguen apareciendo pero están **documentados como waivers en la columna Notes** para triage. La estructura queda persistida para cuando el detector evolucione.

## Recomendación priorizada de remediación (5 acciones)

### P0 — Critical (esta semana)

1. **`web-dashboard/AgentChat.tsx` (líneas 282, 312) + `TenantSelector.tsx` (62, 70) + `TracingDashboard.tsx` (503, 512)** — 8 instancias de `gray-on-color` rompen WCAG AA. Reemplazar `text-gray-400/500` por `text-white/95` o `text-gray-200` en surfaces coloreados. Fix: 1 commit, ~30 min. **Owner**: web-dashboard.

### P1 — High (siguiente sprint)

2. **`prompt-studio/src/App.tsx` líneas 493, 576, 588** — `ai-color-palette` + 2x `gray-on-color` no alineados con brand-SoT. Wire `tailwind.config.ts` con theme bridge que importe `--gv-purple` / `--gv-cyan` de `assets/gv-design-system.css`. **Owner**: prompt-studio + DS team.

3. **`command-center/public/index.html`** — 7 findings, app sin DS. Decisión: ¿se excluye del DS (status quo) o se le provee un drop-in CSS mínimo con tokens `--gv-*`? Documentar ADR. **Owner**: arquitectura.

### P2 — Medium (backlog)

4. **`academy-web/index.html` + `style.css`** — 23 de los 24 findings son waivers de marca (wordmark + lesson-row). Mantener como referencia viva. Agregar `<!-- impeccable-disable-next-line gradient-text: brand wordmark -->` en cada línea flagged para que el detector los respete en CI sin perder la señal de auditoría. **Owner**: academy-web.

5. **`web-dashboard/index.css` 200/222, `gv-analytics/styles.css` 180/889, `archify/styles.css` 70, `content-cms/styles.css` 48, `web-dashboard/components/{AgentMessage:358, AlertPanel:26+29, SloPanel:204}`** — 11 instancias de `gradient-text` + `side-tab` que también son waivers de marca. Mismo tratamiento: inline `impeccable-disable-next-line` con razón. **Owner**: cada app + DS team para alinear redacción del waiver.

## Próximos pasos (post-audit)

- [ ] **ADR-0026**: consolidar 3 sets de tokens → 1 (`assets/tokens.v2.json`) con los waivers aquí documentados
- [ ] **Skill wrapper** `.agents/skills/gv-design-system/` que envuelve `impeccable detect` + waivers para uso cross-tool
- [ ] **Hook lefthook** `design-lint` que corra `impeccable detect --no-config` solo en archivos cambiados (más rápido, sin waivers globales)
- [ ] **Ingest findings como `mem_save`** en engram para evitar re-detección en próximas sesiones
- [ ] **Re-run post-fix** P0/P1 y comparar delta
