#!/usr/bin/env node
/**
 * Token builder — validates src/tokens/tokens.json and regenerates ALL derived
 * formats from it (single command; closes the gap noted in
 * docs/design/03-migration-gv-analytics-v2.md):
 *
 *   src/tokens/tokens.css          CSS custom properties (--gv-* names frozen)
 *   src/tokens/tokens.ts           typed token object (index.ts + MCP server)
 *   dist/tokens.css                copy of src/tokens/tokens.css
 *   dist/components.css            tokens + component layer entry point
 *   dist/tokens.ts                 copy of src/tokens/tokens.ts
 *   dist/tailwind.config.ts        Tailwind v3 config (values from JSON)
 *   dist/figma-tokens.json         Figma Tokens import (values from JSON)
 *   dist/css-modules.d.ts          CSS var typings (names from generated CSS)
 *   dist/tokens.json               verbatim copy of the source JSON
 *
 * Values come from the JSON (v2 Premium canon: docs/brand/TOKENS-v2.json,
 * decision docs/brand/BRAND-DECISION-2026-09-01.md). Token NAMES (--gv-*) and
 * file structures are frozen; only values regenerate. Reserved top-level keys
 * ($schema, version, name, description, mode, meta) are metadata and are NEVER
 * emitted as CSS custom properties (fixes the old --gv-$schema bug).
 *
 * Usage:
 *   npx tsx packages/gv-design-system/src/cli/build-tokens.ts
 */
export {};
//# sourceMappingURL=build-tokens.d.ts.map