# `@gentle-vanguard/design-system` v2

> Native design system for the Gentle-Vanguard ecosystem. Tokens, React components, MCP server, audit CLI.

**Status**: `2.0.0` — **v2 Premium, Official since 2026-09-02 (BRAND-DECISION-2026-09-01)**. Canon: `docs/brand/TOKENS-v2.json` (bg `#0f1115`, purple `#a78bfa`, cyan `#22d3ee`, Space Grotesk display).

**Official logo**: `assets/logo.svg` (repo root — GV monogram v1 with v2 gradient). Apps copy it from there; never inline duplicate SVGs.

**Source of truth**: `DESIGN.md` (canonical design language reference, follows Google DESIGN.md spec per [getdesign.md](https://getdesign.md))

---

## What is this?

This is the consolidation of **4 divergent legacy design systems** in the Gentle-Vanguard monorepo (see [ADR-0026](docs/adr/ADR-0026-gv-design-system-v2.md)):

1. `assets/gv-design-system.css` (legacy canonical, Orbitron display, cyan `#00bfff`)
2. `docs/brand/BRAND-GUIDELINES.md` + `config/brand.json` (brand book, same values as #1)
3. `docs/brand/UI-STANDARD-ECOSYSTEM.md` v1.0.0 (Aug 2026, vibrant cyan `#22d3ee` + purple `#a78bfa`)
4. `apps/gv-analytics/src/styles.css` (custom divergence)

v2 takes the **vibrant palette from v1.0.0 + analytics** (most recent, most aligned with brand vision) and consolidates everything into a single npm-package-style monorepo package with:

- **Tokens** in 4 formats: JSON (source), CSS, TypeScript, SCSS-ready.
- **7 React components** with strict TypeScript, WCAG 2.2 accessibility, and anti-AI-slop defaults.
- **MCP server** (stdio) for cross-agent consumption (opencode, codex, copilot, antigravity, etc).
- **Audit CLI** that wraps `impeccable detect` with brand-aware waivers.
- **Sync CLI** that regenerates tokens in consuming apps.

---

## Install

This package lives in the monorepo's `packages/` directory. To consume from an app:

```bash
# From app's root
pnpm link ../../packages/gv-design-system
```

Then in your app:

```tsx
import { tokens } from '@gentle-vanguard/design-system';
import { Button, Card, Input, Stack, Text, Tag, IconButton } from '@gentle-vanguard/design-system/react';
import '@gentle-vanguard/design-system/tokens.css';
```

---

## Usage

### Tokens

```tsx
import { tokens } from '@gentle-vanguard/design-system';

// Direct access
const primaryPurple = tokens.color.primary.purple; // '#a78bfa'
const bodyFont = tokens.typography.fontFamily.body;
const cardPadding = tokens.spacing[4]; // '16px'
```

### Components

```tsx
import { Button, Card, Input, Stack, Text, Tag, IconButton } from '@gentle-vanguard/design-system/react';
import { Search, X } from 'lucide-react';

function MyDashboard() {
  return (
    <Card variant="glass" padding="lg">
      <Stack direction="column" gap={6}>
        <Stack direction="row" gap={4} align="center" justify="between">
          <Text variant="heading-1">Dashboard</Text>
          <Tag variant="success">Online</Tag>
        </Stack>
        <Input
          label="Search"
          iconLeft={<Search size={16} />}
          placeholder="Search items..."
        />
        <Stack direction="row" gap={3}>
          <Button variant="primary" onClick={save}>Save</Button>
          <Button variant="secondary" onClick={cancel}>Cancel</Button>
          <IconButton icon={<X />} aria-label="Close" />
        </Stack>
      </Stack>
    </Card>
  );
}
```

### CSS-only (no React)

If you can't or don't want to use the React components, import the CSS tokens:

```css
@import '@gentle-vanguard/design-system/tokens.css';

.my-component {
  background: var(--gv-surface);
  color: var(--gv-text);
  border: 1px solid var(--gv-border-accent);
  border-radius: var(--gv-radius-lg);
  padding: var(--gv-space-5);
  font-family: var(--gv-font-body);
  transition: all var(--gv-duration-fast) var(--gv-ease-out);
}
```

---

## MCP Server

The package ships a [Model Context Protocol](https://modelcontextprotocol.io/) server that exposes the design system to any MCP-compatible client.

### Register in `config/mcp-registry.json`:

```json
{
  "name": "gv-design-system",
  "type": "user",
  "transport": "stdio",
  "command": "npx tsx packages/gv-design-system/src/mcp/server.ts",
  "description": "Gentle-Vanguard design system v2: tokens, components, audit"
}
```

### Tools exposed:

- `list_tokens({ category, theme })` — query design tokens
- `get_component({ name, variant? })` — get component props + source
- `audit_design({ target, json?, scope? })` — run `impeccable detect` on a path/URL
- `sync_design({ app?, dryRun? })` — regenerate tokens in consuming apps
- `get_design_md()` — return the canonical DESIGN.md
- `list_brand_waivers()` — get the list of brand asset waivers

### Try it:

```bash
# Direct invocation
npx tsx packages/gv-design-system/src/mcp/server.ts

# Or via the package
cd packages/gv-design-system && npm run mcp:start
```

---

## CLIs

### Audit

```bash
# Audit a path
npx tsx src/cli/audit.ts apps/gv-analytics/src/styles.css

# Audit with JSON output (for CI)
npx tsx src/cli/audit.ts apps/gv-analytics/src --json

# Audit specific scope
npx tsx src/cli/audit.ts apps/gv-analytics/src --scope type
```

### Sync

```bash
# Sync tokens to all consuming apps
npx tsx src/cli/sync.ts

# Sync to one app
npx tsx src/cli/sync.ts --app gv-analytics

# Dry run (show what would change)
npx tsx src/cli/sync.ts --dry-run
```

### Build tokens (validate)

```bash
# Validates that tokens.json matches tokens.css and tokens.ts
npm run build:tokens
```

---

## Anti-patterns explicitly banned

This package's `impeccable detect` config (`.impeccable/config.json` at repo root) explicitly waives patterns that are brand signatures (wordmark gradient, atmospheric grid, lesson-row border) and bans:

- Bounce/elastic easing on buttons (critical)
- Cream + terracotta palette (warning)
- Near-black + acid-green palette (warning)
- Broadsheet hairlines (warning)
- `gradient-text` on body/headings (warning, wordmark is waived)
- `side-tab-border` on generic cards (warning, lesson-row is waived)
- Tiny body text (<14px) (warning)
- Cramped padding (<8px around content) (warning)
- Long line length (>80ch) (warning)
- Small touch target (<44x44 mobile) (warning)
- Em-dash overuse (>2 per paragraph) (advisory)
- Pure black text on pure white background (warning)

See `DESIGN.md §13` for the full table.

---

## File structure

```
packages/gv-design-system/
├── package.json
├── tsconfig.json
├── tsconfig.mcp.json
├── DESIGN.md                       ← canonical reference (read first)
├── README.md                       ← this file
├── .impeccable/                    ← per-package detector config (future)
├── src/
│   ├── index.ts                    ← public API entry
│   ├── tokens/
│   │   ├── tokens.json             ← source of truth
│   │   ├── tokens.css              ← CSS custom properties
│   │   ├── tokens.ts               ← TypeScript types + constants
│   │   └── build-tokens.ts         ← validation CLI
│   ├── react/
│   │   ├── index.ts
│   │   ├── Button.tsx + .css
│   │   ├── Card.tsx + .css
│   │   ├── Input.tsx + .css
│   │   ├── Stack.tsx + .css
│   │   ├── Text.tsx + .css
│   │   ├── Tag.tsx + .css
│   │   └── IconButton.tsx + .css
│   ├── mcp/
│   │   ├── server.ts               ← MCP server (stdio)
│   │   └── index.ts
│   └── cli/
│       ├── audit.ts                ← audit CLI
│       ├── sync.ts                 ← sync CLI
│       └── build-tokens.ts         ← token validation CLI
└── dist/                           ← build output (gitignored)
```

---

## Migration from v1 (legacy `assets/gv-design-system.css`)

No breaking change for apps already consuming `--gv-*` tokens. The token names are preserved. Values changed:

| Legacy (v1) | v2 |
| --- | --- |
| `--gv-primary: #00bfff` | `--gv-cyan: #22d3ee` |
| `--gv-accent: #a855f7` | `--gv-purple: #a78bfa` |
| `--gv-bg: #0d1117` | `--gv-bg: #121212` |
| `--gv-font-display: Orbitron, ...` (no quotes) | `--gv-font-display: 'Orbitron', ...` (quoted) |

Apps that need to migrate: `apps/gv-analytics/src/styles.css` (the most divergent). Use `npx tsx src/cli/sync.ts --app gv-analytics` to apply.

For now, both v1 and v2 can coexist (`assets/gv-design-system.css` and `assets/gv-design-system.v2.css`). v1 will be deprecated in v2.1.

---

## Related

- [`DESIGN.md`](./DESIGN.md) — canonical design language
- [`docs/adr/ADR-0026-gv-design-system-v2.md`](../../docs/adr/ADR-0026-gv-design-system-v2.md) — decision rationale
- [`docs/brand/UI-STANDARD-ECOSYSTEM.md`](../../docs/brand/UI-STANDARD-ECOSYSTEM.md) — original v1.0.0 standard
- [impeccable](https://github.com/pbakaus/impeccable) — design linter
- [taste-skill](https://github.com/Leonxlnx/taste-skill) — anti-AI-slop principles
- [frontend-design (anthropics)](https://github.com/anthropics/skills) — opinionated design direction
- [getdesign.md](https://getdesign.md/) — DESIGN.md spec

---

*Built with care for the Gentle-Vanguard ecosystem. v2.0.0-alpha.1.*
