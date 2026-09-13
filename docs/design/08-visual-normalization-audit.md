# Visual normalization audit

Status: Wave 2 shell migration complete, conformance gate active, 2026-09-07

## Decision

All active Gentle-Vanguard applications will share one v2 Premium application shell. Product
surfaces may differ in information architecture and task-specific density, but brand identity, shell
geometry, tokens, typography, motion, states, controls, and assets are shared.

Canonical sources:

- `docs/brand/BRAND-KIT.md`
- `docs/brand/TOKENS-v2.json`
- `packages/gv-design-system/src/tokens/tokens.json`
- `packages/gv-design-system/DESIGN.md`
- `assets/logo.svg` and `assets/logo-icon.svg`

The legacy `assets/gv-design-system.css` remains a compatibility layer only. New work must not add
another app-local token set or another topbar implementation.

## Current divergence

| App            | Current shell                                 | Main drift                                                   | Migration target                            |
| -------------- | --------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------- |
| Design Hub     | Vanilla `gv-*` shell                          | Uses generated shared shell snapshot                         | Shared shell adapter applied                |
| Command Center | Vanilla `gv-*` shell embedded in `index.html` | Legacy inline aliases remain for app widgets                 | Shared shell endpoint applied               |
| GV Analytics   | React + CSS shell                             | Local content selectors remain                               | Shared shell primitives applied             |
| Content Studio | React + CSS shell                             | Local workspace layout remains                               | Shared shell plus CMS workspace applied     |
| Prompt Studio  | React + Tailwind shell                        | Utility-level content styling remains                        | Shared shell bridge applied                 |
| Archify        | React + `ar-*` workspace shell                | Domain controls remain app-specific                          | Shared topbar shell applied                 |
| Academy        | Static reference shell                        | Strongest current shell reference, but legacy file ownership | Extract stable shell into package           |
| Web Dashboard  | React + Tailwind + local v2 overrides         | Theme override and separate dashboard shell                  | Shared shell adapter; preserve data density |

## Shared contract

Every app shell must provide:

1. `gv-app-shell` root with v2 tokens loaded before app styles.
2. Fixed atmosphere layers: `gv-grid-bg`, `gv-glow-a`, and `gv-glow-b`.
3. Sticky `gv-topbar` with the same logo, wordmark, app label, navigation, status, locale, and theme
   controls.
4. Shared responsive breakpoints at 640px, 768px, 1024px, and 1280px.
5. Shared button, icon button, panel, tab, input, menu, badge, toast, empty, loading, and error
   states.
6. Shared motion tokens and `prefers-reduced-motion` behavior.
7. Shared footer and favicon/logo assets.
8. App-specific content only below the shell boundary.

## Migration sequence

### Wave 1: foundation

- Add a vanilla-compatible shell stylesheet and shell markup contract to
  `packages/gv-design-system`.
- Export the same token CSS for Vite, static HTML, and Tailwind consumers.
- Add a small shell adapter for vanilla apps so Command Center and Design Hub do not duplicate DOM
  construction rules. **Done:** generated `shell.css` plus Design Hub adapter and Command Center
  endpoint.
- Add an app-level visual conformance check for required tokens, assets, classes, and reduced motion
  rules. **In progress:** build and Impeccable gates are active; screenshot matrix remains.

### Wave 2: shell migration

- Migrate Design Hub and Command Center first because they define and expose the design system.
  **Done.**
- Migrate Archify and Prompt Studio next because their divergence is visually obvious and their app
  surfaces are bounded. **Done at shell level.**
- Migrate CMS and Analytics together, preserving their existing functional workflows. **Done at
  shell level; CMS tests pass.**
- Migrate Web Dashboard last, keeping its observability density and accessibility behavior while
  replacing only the brand shell and token bridge. **Done at shell level; build passes.**

### Wave 3: verification

- Build every Vite app.
- Run the static/vanilla smoke checks.
- Capture desktop and mobile screenshots for every shell.
- Verify keyboard focus, reduced motion, overflow, light/dark behavior, and logo loading.
- Run Impeccable detector on the changed UI targets and fix critical/warning findings.

Current verification: the design-system package builds completely (tokens, React components and
MCP); all five Vite apps build and typecheck; CMS has 51 passing tests; Archify has 19 passing tests
plus engine smoke; the shared shell detector reports zero findings; and the native conformance
command passes 18 checks:

```bash
npm run conformance --prefix packages/gv-design-system
```

## CMS phase after visual convergence

CMS should be treated as a product expansion, not mixed into the shell migration. Its current
functional core is local-first content drafting, versioning, import/export, assets, preview, and
Content OS. The next product review should map the missing workflows before implementation:

- content types and reusable schemas;
- rich editing and structured blocks;
- media library and asset metadata;
- workflow states, approvals, scheduling, and publishing targets;
- search, filters, bulk operations, and version comparison;
- templates, localization, SEO, and validation;
- connector boundaries and real integration states;
- audit trail, permissions, and recovery UX.

The CMS redesign must follow the normalized shell, then expand these workflows incrementally with
real local behavior and explicit empty/loading/error states.

### CMS phase 1: editorial metadata

Implemented 2026-09-07 without changing the storage schema version:

- `ContentType`: article, landing, or social.
- SEO metadata: title, description, and canonical URL.
- Backward-compatible defaults for existing v2 records.
- Validation limits and safe URL handling.
- Editor fields with character counters and persisted export/import support.
- 53 domain tests passing and CMS visual audit clean.

### CMS phase 2: bulk library operations

Implemented 2026-09-07:

- Select all visible records or individual records from the library.
- Publish or return selected content to draft in one operation.
- Delete selected records with explicit confirmation.
- Bulk status changes create immutable versions; deletions remain in the audit trail.
- 55 CMS tests passing, build/typecheck green, visual audit clean.

### CMS phase 4: editorial workflow

Implemented 2026-09-07:

- Added `review`, `scheduled`, and `archived` content states.
- Added guarded transitions so draft content cannot bypass review into publication.
- Added filters and bulk actions for every editorial state.
- Preserved backward compatibility for existing draft/published records and imports.
- 56 CMS tests passing, build/typecheck green, visual audit clean.

### CMS phase 3: discovery and version review

Implemented 2026-09-07:

- Search across title, slug, summary, tags, and content type.
- Version comparison panel showing selected snapshot versus current editor content.
- Restore remains explicit and creates a new immutable version.
- 55 CMS tests passing, build/typecheck green, visual audit clean.

### CMS phase 5: Creative Studio

Implemented 2026-09-07 as the first native multimedia foundation:

- New Creative Studio tab: prompt visual, title, aspect ratio, provider and generated preview.
- Local GV template provider works offline and persists an SVG asset in the media library.
- OpenAI-compatible image provider is available through `/api/creative/generate`; it accepts
  `CONTENT_IMAGE_BASE_URL` plus `CONTENT_IMAGE_API_KEY`, or the existing OpenAI-compatible
  credentials in Settings IA. Secrets are never returned by the API.
- Generated media records include dimensions, provider, model, alt text and source, so they can be
  attached to any Content OS variant through the existing media workflow.
- The current stack can therefore produce deterministic branded graphics, social copy, platform
  previews and local template video. Photorealistic people, image editing and provider-specific
  raster generation require a configured image API; no tool can guarantee virality.
- CMS tests: 58 passing; typecheck, production build and Impeccable visual audit pass.

### Shell/header and video follow-up

Implemented 2026-09-07:

- Canonical shell now enforces the same `gv-topbar-inner` and legacy `header-inner` geometry: 1180px
  content width, 62px minimum height, 32px logo, 17px wordmark, white `Gentle` and gradient
  `Vanguard`. Runtime and Design Hub snapshots were regenerated.
- Command Center and Academy overrides now follow the same wordmark color and topbar proportions.
- Content OS reports OpenCode rate limits as provider/quota errors with an actionable account/model
  message instead of a generic create failure.
- Video gallery now has multi-select and bulk delete. Local video builds support 15/30/60 seconds, a
  visible thumbnail, optional media-library poster, local TTS/SRT and BGM.
- Video remains a local template assembler; AI video generation is not claimed or hidden behind the
  control. A real AI video provider can be added later through a separate adapter.

### Provider Connection Hub

Implemented 2026-09-07:

- Shared provider inventory at `src/integrations/provider-hub.ts` with conservative states and no
  password, cookie or full-secret exposure.
- Content OS exposes `GET /api/providers` and renders connection cards in Settings IA.
- OpenCode is detected as a local CLI session and is documented as the active `oc-keyring` account;
  Gemini and OpenAI-compatible report local/env credential state; Claude, MiniMax, z.ai, Google
  OAuth and GitHub Copilot remain explicit adapter/OAuth follow-ups until their official scopes are
  wired.
- This establishes one contract for future provider adapters without treating a consumer login as an
  API credential.
