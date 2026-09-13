---
created: 2026-07-26 05:51:07
tags: [engram, architecture]
engram_id: 2010
type: architecture
---

# Design skills activation, SVG/Mermaid generators, build fixes

**What**: Activated 8 design skills, created SVG/Mermaid generators, fixed build pipeline PS1→TS references, created Copilot instructions
**Why**: Close gaps in design/documentation capabilities, fix broken references post-PS1-migration, extend professional tooling
**Where**:
- skills/: accessibility-design-skill, canvas-design-skill, canva-creator-skill, design-ui-designer, design-system-skill, design-ux-researcher, data-visualization-skill, presentaciones-visuales-skill (8 copied from public/skills/)
- src/cli/mermaid-renderer.ts — .mmd → SVG/PNG/HTML with watch, batch, themes
- src/cli/svg-generator.ts — logo + 5 banners from config/brand.json
- src/skills/skill-router.ts — +25 design/visual keywords
- .github/copilot-instructions.md — created (was referenced by 10+ files but missing)
- .github/workflows/reusable-release.yml — fixed PS1→TS reference
- build/Gentle-Vanguard.bat — fixed PS1→TS
- build/README.md — full rewrite (PS1→TS docs)
- .dockerignore — root level created
- releases/latest-version.json — v3.3.0→v3.3.3
- package.json — +5 scripts (gv:mermaid, gv:svg, gv:build, gv:build:quick)
**Commit**: 21521cdb on develop — "feat: design skills, SVG/Mermaid generators, copilot-instructions, build fixes, dockerignore"
**Learned**: SKILL_INDEX.md already listed design skills as "Imported" even before physical files existed. The real gap was in skill-router.ts (no design keywords). Nested directory issue in presentaciones-visuales-skill copy needed manual fix.

---
*Imported from Engram on 2026-09-06*
