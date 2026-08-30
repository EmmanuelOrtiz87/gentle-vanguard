# Skill Upgrade Shortlist — Design · Docs · Marketing (2026-08-27)

> Research web verificada (stars/licencias via GitHub API, 2026-08-27) para potenciar las 3 áreas
> con demanda: diseño, documentación y marketing. Objetivo: adoptar lo mejor del ecosistema como
> skills nativas GV (formato SKILL.md portátil, sincronizables vía `zcode-sync`). Regla dura:
> presupuesto de metadata de ZCode — NO copiar colecciones enteras; seleccionar.

## Shortlist rankeado por impacto

| #   | Origen (licencia)                                                                                          | Qué aporta                                                                                                                                                                                                                                                                                                                    | Adopción GV                                                                                                                                            |
| --- | ---------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | **coreyhayers31/marketingskills** (45.8k★, MIT) — [repo](https://github.com/coreyhaines31/marketingskills) | ~50 skills de marketing real: `copywriting` (estructura hero, fórmulas CTA), `product-marketing` (positioning — fundación que leen las demás), `cro`, `marketing-plan`, `launch`, `emails`, `marketing-psychology` (Cialdini/Kahneman), `content-strategy`                                                                    | Cherry-pick 8-10 → familia `marketing/`; conservar el patrón de contexto compartido `.agents/product-marketing.md` como fuente única de positioning GV |
| 2   | **alchaincyf/huashu-design** (23.6k★, MIT) — [repo](https://github.com/alchaincyf/huashu-design)           | Diseño HTML-native de calidad real: Brand Asset Protocol (extracción de marca → `brand-spec.md`), bans anti-slop (gradientes púrpura, Inter como display), oklch, 60 estilos, 3 direcciones en paralelo, review 5-dimensiones con radar. **PPTX editable real** vía `html2pptx.js` (DOM computed styles → objetos PowerPoint) | Port completo del folder (requiere `references/`, `scripts/` — 99 recetas); sustituir Playwright por chrome-devtools MCP local                         |
| 3   | **anthropics/skills** (172k★, Apache-2.0) — `frontend-design` + `canvas-design` + `theme-factory`          | `frontend-design`: persona "design lead", loop plan→critique→build→critique, blacklist de 3 estéticas AI genéricas. `canvas-design`: posters "museum-grade, never AI-looking". `theme-factory`: 10 temas completos (hex+fonts) para decks/docs/landings                                                                       | Copia casi verbatim; mapear a brand tokens GV; theme-factory capa sobre plugins pptx/pdf existentes                                                    |
| 4   | **Leonxlnx/taste-skill** (81.3k★, MIT) — [repo](https://github.com/Leonxlnx/taste-skill)                   | "Anti-Slop Frontend Framework": 3 diales ajustables (DESIGN_VARIANCE, MOTION_INTENSITY, VISUAL_DENSITY), protocolo de auditoría UI, 3 direcciones estéticas                                                                                                                                                                   | Fusionar diales + auditoría en skill GV `ui-taste` que haga gate de todo output UI/deck                                                                |
| 5   | **anthropics/skills** — `doc-coauthoring`                                                                  | Workflow de escritura pro en 3 etapas: Context Gathering → Refinement & Structure (5-20 opciones por sección, curada con justificación) → **Reader Testing** (simulación de lector sin contexto)                                                                                                                              | Casi verbatim; el Reader-Testing mapea a subagentes GV (spawn de lector ingenuo — mejora, no rewrite)                                                  |
| 6   | **ConardLi/garden-skills** (11.1k★, MIT) — [repo](https://github.com/ConardLi/garden-skills)               | `beautiful-article`: notas/URLs/PDF → artículos pulidos, 11 perfiles editoriales anclados en historia del diseño (tufte, bayer, vignelli). `web-design-engineer`: 25 recetas de estilo ancladas a sistemas reales (Linear, Aesop, Stripe Press)                                                                               | Adoptar beautiful-article para deliverables/ADRs; robar las 25 recetas como reference de vocabulario de diseño                                         |
| 7   | **JimLiu/baoyu-design** (3.6k★, MIT) — [repo](https://github.com/JimLiu/baoyu-design)                      | Repack local del motor de claude.ai/design: `system-prompt.md` con metodología completa, export a HTML/PDF/PPTX editable (Playwright+PptxGenJS)/MP4/Figma                                                                                                                                                                     | Minar estándares de craft + pipeline de export; agregar tool-map GV junto a los de Cursor/Codex                                                        |
| 8   | **anthropics/skills** — `brand-guidelines`                                                                 | Re-styler post-proceso: aplica sistema de marca completo (contraste, fallbacks, accent cycling) a artefactos                                                                                                                                                                                                                  | Re-skin con design tokens GV → skill "haz este deck GV-branded" sobre los plugins existentes                                                           |

## Plan de adopción recomendado (por fases)

1. **Fase 1 (quick wins, ~0 reescritura)**: doc-coauthoring + frontend-design + theme-factory + 8
   skills de marketingskills → validar en un deliverable real.
2. **Fase 2 (calidad de export)**: port de huashu-design (html2pptx.js) → decks GV con PPTX editable
   de verdad.
3. **Fase 3 (gobernanza de gusto)**: ui-taste (diales + auditoría) como gate transversal +
   brand-guidelines GV-skinned.
4. Todo pasa por `zcode-sync --tools zcode,codex,minimax`; mantener el conteo de skills críticas ≤
   presupuesto.

## Notas

- `obra/superpowers` (278k★, MIT): NO aplica a estas áreas (es metodología dev) — solo sus
  meta-skills `writing-skills`/`brainstorming` valen.
- `borghei/Claude-Skills` tiene AIDA/PAS explícito pero SIN licencia estándar — evitar.
- anthropics docx/pdf/pptx/xlsx son "source-available" (ya consumidos via plugin oficial — sin
  cambio).
- Ninguna del shortlist está atada a Claude Code: todas folder-portables SKILL.md.
