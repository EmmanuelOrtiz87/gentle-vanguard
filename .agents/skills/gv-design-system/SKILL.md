---
name: gv-design-system
description: Use when the user wants to build, redesign, or audit Gentle-Vanguard app UI, or when generating any UI surface that should follow the Gentle-Vanguard brand. Triggers on mentions of "GV", "Gentle-Vanguard", "design system", "tokens", "components", or any request to make a UI look "on brand" for the ecosystem. Loads the canonical DESIGN.md, tokens, and component library. Provides React/TS code with strict type safety, accessibility (WCAG 2.2), and anti-AI-slop principles baked in. Pairs with impeccable detect for post-generation audit.
version: 2.0.0-alpha.1
---

# Gentle-Vanguard Design System v2

Native design system for the Gentle-Vanguard ecosystem. Cross-tool compatible (opencode, codex, copilot, antigravity, etc) via vercel-labs/agent-skills install.

> **CANON DE MARCA (2026-09-01):** el diseño oficial es **v2 Premium** (bg `#0F1115`, purple
> `#a78bfa`, cyan `#22d3ee`, Space Grotesk display) con **logo v1 monogram** (gradiente v2).
> Fuentes canónicas: `docs/brand/BRAND-DECISION-2026-09-01.md` → `docs/brand/BRAND-KIT.md` →
> `docs/brand/TOKENS-v2.json`. Logo operativo: `assets/logo.svg` (+ mono/icon en `assets/`).
> Herramienta oficial: Design Hub (`apps/design-hub`, :8095). El paquete `packages/gv-design-system`
> es SOLO library de componentes React; su tema `#121212`/Orbitron está deprecado para marca.

## When to use this skill

- Building or refactoring ANY UI in `apps/*/` (gv-analytics, academy-web, content-cms, prompt-studio, archify, web-dashboard).
- Generating landing pages, dashboards, forms, settings panels, modals, tables, lists.
- Reviewing/auditing existing UI for brand compliance.
- Migrating from legacy tokens (`#00bfff`, `#a855f7`, `#0d1117`, alpha `#121212`) to v2 Premium (`#22d3ee`, `#a78bfa`, `#0f1115` — full set in `docs/brand/TOKENS-v2.json`).
- Producing designs that avoid AI slop (purple gradients on dark, cream/terracotta, decorative grids, bounce easing, em-dash overuse).

## Setup

1. Read `docs/brand/BRAND-KIT.md` first — it is the operational entry point for the official brand. For deep component reference: `packages/gv-design-system/DESIGN.md`.
2. If MCP `gv-design-system` is available, prefer it for component queries. For official tokens use `docs/brand/TOKENS-v2.json` (the package theme is historic for brand).
3. After generating or modifying UI, run `impeccable detect <path>` to catch anti-patterns.

## Core principles (apply unconditionally)

1. **The brief wins.** Honor pinned aesthetics, eras, materials, fonts, and palettes even when they conflict with anti-pattern warnings. Brand waivers are explicit in `.impeccable/config.json`.
2. **Operate mode is the default** for app surfaces. Persuade for landing pages. Read for docs.
3. **Use Text for ALL text** — type scale + color tokens are enforced via the `Text` component. Never hardcode `font-size`, `color`, or `font-family` in ad-hoc styles.
4. **Use Stack for ALL layout** — never raw CSS flex with hardcoded gaps. Use `<Stack direction="row" gap={4}>` etc.
5. **Use Button, Card, Input, Tag, IconButton** — never reimplement these.
6. **Dark mode is the default.** Light theme is opt-in via `data-theme="light"`. Web-dashboard has its own theme (excluded until migration).
7. **Accessibility (WCAG 2.2) is non-negotiable:** all interactive elements keyboard-reachable, focus ring (`outline: 3px solid var(--gv-cyan)`) on `:focus-visible`, `aria-label` on icon-only buttons, `aria-invalid` + `aria-describedby` on form errors, `prefers-reduced-motion` collapses all transitions.
8. **Anti-AI-slop:** never use bounce easing on buttons, never use cream + terracotta palette, never use pure black on pure white text, never use `>2` em-dashes per paragraph, never use generic "Seamless" or "AI-powered" copy.

## Token cheat sheet

| Token | Value | Use |
| --- | --- | --- |
| `--gv-purple` | `#a78bfa` | Accent (eyebrows, section titles) |
| `--gv-cyan` | `#22d3ee` | Data, links, focus rings |
| `--gv-bg` | `#121212` | App background |
| `--gv-bg-deep` | `#0a0e17` | Inputs, code |
| `--gv-surface` | `#1f2937` | Cards, panels |
| `--gv-surface-raised` | `#273548` | Menus, dropdowns |
| `--gv-text` | `#e5e7eb` | Primary text |
| `--gv-muted` | `#9ca3af` | Subtitle, metadata |
| `--gv-green` | `#4ade80` | Success |
| `--gv-amber` | `#f4bb4f` | Warning |
| `--gv-red` | `#ee6d75` | Error |
| `--gv-gradient` | `linear-gradient(135deg, #a78bfa 0%, #22d3ee 100%)` | Primary buttons, wordmark |

## Component quick reference

```tsx
import { Button, Card, Input, Stack, Text, Tag, IconButton } from '@gentle-vanguard/design-system/react';

// Primary action
<Button variant="primary" size="md" onClick={save}>Save</Button>

// Glass card (default brand)
<Card variant="glass" padding="md">Content</Card>

// Form input with validation
<Input label="Email" type="email" error={error} required />

// Stack layout
<Stack direction="row" gap={4} align="center" justify="between">
  <Logo />
  <Text variant="heading-1">Dashboard</Text>
  <Button>Action</Button>
</Stack>

// Typography
<Text variant="display-1">Splash title</Text>
<Text variant="heading-2">Section title</Text>
<Text variant="body">Body content</Text>
<Text variant="eyebrow" color="accent">EYEBROW LABEL</Text>
<Text variant="metric" color="gradient">99.9%</Text>
<Text variant="code">npm install gv-design-system</Text>

// Status
<Tag variant="success">Active</Tag>
<Tag variant="warning" icon={<Icon />}>Pending</Tag>

// Icon-only (always with aria-label)
<IconButton icon={<SearchIcon />} aria-label="Search" />
```

## Anti-patterns to AVOID (will be caught by `impeccable detect`)

| Anti-pattern | Severity | Alternative |
| --- | --- | --- |
| Bounce/elastic easing on buttons | critical | Use `--gv-ease-out` for entrance, `--gv-ease-in-out` for state changes |
| Cream background + terracotta accent | warning | Use `--gv-bg` (dark) + `--gv-purple`/`--gv-cyan` accents |
| Near-black + acid-green | warning | Use `--gv-bg` (dark) + `--gv-cyan` accent |
| Broadsheet hairlines | warning | Use radius scale (--gv-radius-*), not zero-radius hairlines |
| Decorative grid background (NOT in waiver) | advisory | Use product structure or plain surface (the brand grid is waived for app atmosphere) |
| `gradient-text` on body/headings (NOT wordmark) | warning | Use solid colors; wordmark "Vanguard" is the only exception |
| `side-tab-border` on cards (NOT brand) | warning | Use border-`--gv-border-accent` instead |
| Tiny body text (<14px) | warning | Use `--gv-size-base` (14px) or larger |
| Cramped padding (<8px around content) | warning | Use `--gv-space-4` (16px) or larger |
| Long line length (>80ch) | warning | Use Container `maxWidth="sm"` for reading text |
| Small touch target (<44x44 mobile) | warning | Use `IconButton size="lg"` or `Button size="lg"` on mobile |
| Em-dash overuse (>2 per paragraph) | advisory | Use commas, periods, or restructure sentences |

## When the user pins a non-GV aesthetic

Honor the brief. The detector warnings are advisory when the user explicitly pins a different direction. Add an `impeccable-disable` comment in the source file with the reason:

```css
/* impeccable-disable gradient-text: pinned by user brief, 2026-09-01 */
.brand-mark { background: var(--gv-gradient-text); background-clip: text; }
```

## MCP integration

If the runtime exposes `gv-design-system` MCP server, prefer it:

- `list_tokens({ category: "color" })` — get current tokens
- `get_component({ name: "Button" })` — get full props + source
- `audit_design({ target: "apps/gv-analytics/src/styles.css" })` — run impeccable on a path
- `sync_design({ app: "gv-analytics" })` — regenerate tokens in consuming apps
- `get_design_md()` — return the canonical DESIGN.md
- `list_brand_waivers()` — get the waiver list

## Migration from v1 (legacy)

If you encounter legacy tokens, migrate as follows:

| Legacy (v1) | v2 | Notes |
| --- | --- | --- |
| `--gv-primary: #00bfff` | `--gv-cyan: #22d3ee` | More vibrant, modern |
| `--gv-accent: #a855f7` | `--gv-purple: #a78bfa` | Lighter, less neon |
| `--gv-bg: #0d1117` | `--gv-bg: #121212` | Slightly lighter for contrast |
| `--gv-accent-teal: #06b6d4` | `--gv-cyan-deep: #06b6d4` | Same value, renamed |
| `--gv-font-display: Orbitron, ...` | `--gv-font-display: 'Orbitron', ...` | Now quoted as string |

Use `npx tsx packages/gv-design-system/src/cli/sync.ts --app <name>` to migrate an app.

## Verification

After any UI generation:

1. `impeccable detect <changed-path>` — must return 0 critical, 0 warning (with waivers), ≤3 advisory.
2. If MCP available, `audit_design({ target: <changed-path> })` — same expectation.
3. If visual regression baseline exists, `playwright-cli snapshot <url>` and diff against baseline.
4. Manual check: focus the first interactive element, Tab through, verify focus rings are visible (cyan, 3px).
5. Manual check: enable `prefers-reduced-motion: reduce` in dev tools, verify animations collapse.

## Reference

- `packages/gv-design-system/DESIGN.md` — canonical design language (READ THIS FIRST)
- `packages/gv-design-system/src/tokens/tokens.json` — source of truth (all token values)
- `packages/gv-design-system/src/tokens/tokens.css` — CSS custom properties (consumed at runtime)
- `packages/gv-design-system/src/tokens/tokens.ts` — TS types (consumed in code)
- `packages/gv-design-system/src/react/` — React components
- `packages/gv-design-system/src/mcp/server.ts` — MCP server source
- `docs/adr/ADR-0026-gv-design-system-v2.md` — decision rationale
- `docs/design/00-stack-inventory.md` — stack audit
- `.impeccable/config.json` — detector config + brand waivers
- `docs/brand/UI-STANDARD-ECOSYSTEM.md` — original v1.0.0 standard
