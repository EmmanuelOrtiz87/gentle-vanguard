---
created: 2026-09-08 13:12:17
tags: [engram, architecture]
engram_id: 3780
type: architecture
---

# BA exploration: Design Hub image upload + AI vision + versioning feature

**What**: BA exploration initiated for a major Design Hub feature: image upload, AI/vision analysis, proposal/versioning workflow, and automated promotion to official.

**Why**: The Design Hub currently has no file upload, image analysis, vision integration, structured version control, or proposal-to-official workflow. All brand decisions are ad-hoc (manual copy, markdown docs, validate.js checks).

**Where**: apps/design-hub/ (vanilla HTML/CSS/JS, zero deps, port 8095), assets/ (official SVGs), packages/gv-design-system/ (tokens, components, CLI), docs/brand/ (decision records, guidelines).

**Learned**:
- Current state is extremely well-structured: CRUD token editor with history, asset generator with canvas rendering, 4 official logos, v2/v3 candidates preserved for Labs.
- Propagation is entirely manual today (copy SVG to public/assets/, assets/, root assets/).
- Existing skills (image-to-code, brandkit, high-end-visual-design, impeccable) could provide AI/vision but require LLM with vision capability.
- local-first constraint means no cloud APIs — vision analysis must be either local model or manual.
- Token history in Token Editor already uses localStorage (proposed → approved → restored workflow) — pattern to extend.
- validate.js is the enforcement gate for official references (no stale logo refs, token CSS completeness).
- The stack already has a proposal → decision → official pattern (BRAND-DECISION-2026-09-01.md + labs experiments → public/assets/ official files).

---
*Imported from Engram on 2026-09-08*
