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
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const DS_ROOT = join(__dirname, '..', '..');
const TOKENS_JSON = join(DS_ROOT, 'src', 'tokens', 'tokens.json');
const SRC_CSS = join(DS_ROOT, 'src', 'tokens', 'tokens.css');
const SRC_TS = join(DS_ROOT, 'src', 'tokens', 'tokens.ts');
const SRC_SHELL = join(DS_ROOT, 'src', 'shell', 'shell.css');
const DIST = join(DS_ROOT, 'dist');
const RUNTIME_SHELL = join(DS_ROOT, '..', '..', 'assets', 'gv-shell.css');
const DESIGN_HUB_SHELL = join(DS_ROOT, '..', '..', 'apps', 'design-hub', 'public', 'gv-shell.css');
/** Top-level JSON keys that are package metadata, not tokens. */
const RESERVED_KEYS = new Set(['$schema', 'version', 'name', 'description', 'mode', 'meta']);
function isObj(v) {
    return typeof v === 'object' && v !== null && !Array.isArray(v);
}
/** Resolve a dotted path ('color.brand.purple') against the token tree. */
function getPath(root, path) {
    let cur = root;
    for (const seg of path.split('.')) {
        if (!isObj(cur))
            return undefined;
        cur = cur[seg];
    }
    return cur;
}
// ============================================================================
// CSS mapping (token names frozen — values resolved from tokens.json)
// ============================================================================
/** Static (non-JSON) scales kept for continuity; append-only, never renamed. */
const STATIC_SCALE = {
    zScale: { base: 0, raised: 10, sticky: 50, overlay: 100, modal: 200, toast: 300, max: 9999 },
    layout: { headerHeight: '62px', contentMaxWidth: '1180px' },
};
/** [css custom property, dotted path in tokens.json / STATIC_SCALE]. */
const CSS_VARS = [
    ['--gv-purple', 'color.brand.purple'],
    ['--gv-purple-deep', 'color.brand.purpleDeep'],
    ['--gv-purple-soft', 'color.brand.purpleSoft'],
    ['--gv-cyan', 'color.brand.cyan'],
    ['--gv-cyan-deep', 'color.brand.cyanDeep'],
    ['--gv-cyan-soft', 'color.brand.cyanSoft'],
    ['--gv-gold', 'color.brand.gold'],
    ['--gv-bg', 'color.surface.bg'],
    ['--gv-bg-elevated', 'color.surface.elevated'],
    ['--gv-bg-deep', 'color.surface.bgDeep'],
    ['--gv-surface', 'color.surface.surface'],
    ['--gv-surface-raised', 'color.surface.surfaceRaised'],
    ['--gv-surface-overlay', 'color.surface.surfaceOverlay'],
    ['--gv-glass', 'color.surface.glass'],
    ['--gv-glass-border', 'color.surface.glassBorder'],
    ['--gv-text', 'color.text.primary'],
    ['--gv-text-secondary', 'color.text.secondary'],
    ['--gv-muted', 'color.text.muted'],
    ['--gv-text-disabled', 'color.text.disabled'],
    ['--gv-text-inverse', 'color.text.inverse'],
    ['--gv-amber', 'color.feedback.warning'],
    ['--gv-red', 'color.feedback.error'],
    ['--gv-green', 'color.feedback.success'],
    ['--gv-info', 'color.feedback.info'],
    ['--gv-border', 'color.border.default'],
    ['--gv-border-accent', 'color.border.accent'],
    ['--gv-border-accent-strong', 'color.border.accentStrong'],
    ['--gv-glow-purple', 'color.glow.purple'],
    ['--gv-glow-cyan', 'color.glow.cyan'],
    ['--gv-gradient', 'color.brand.gradient'],
    ['--gv-gradient-subtle', 'color.brand.gradientSubtle'],
    ['--gv-gradient-text', 'color.brand.gradientText'],
    ['--gv-font-display', 'typography.fontFamily.display'],
    ['--gv-font-body', 'typography.fontFamily.body'],
    ['--gv-font-mono', 'typography.fontFamily.mono'],
    ['--gv-font-mono-accent', 'typography.fontFamily.monoAccent'],
    ['--gv-radius-sm', 'radius.sm'],
    ['--gv-radius-md', 'radius.md'],
    ['--gv-radius-lg', 'radius.lg'],
    ['--gv-radius-xl', 'radius.xl'],
    ['--gv-radius-2xl', 'radius.2xl'],
    ['--gv-radius-pill', 'radius.full'],
    ['--gv-elev-sm', 'shadow.sm'],
    ['--gv-elev-md', 'shadow.md'],
    ['--gv-elev-lg', 'shadow.lg'],
    ['--gv-elev-xl', 'shadow.xl'],
    ['--gv-elev-glow', 'shadow.glowCyan'],
    ['--gv-duration-instant', 'motion.durations.instant'],
    ['--gv-duration-fast', 'motion.durations.fast'],
    ['--gv-duration-base', 'motion.durations.normal'],
    ['--gv-duration-slow', 'motion.durations.slow'],
    ['--gv-duration-epic', 'motion.durations.epic'],
    ['--gv-ease-out', 'motion.easings.easeOut'],
    ['--gv-ease-in-out', 'motion.easings.easeInOut'],
    ['--gv-ease-smooth', 'motion.easings.smooth'],
    ['--gv-ease-out-expo', 'motion.easings.outExpo'],
    ['--gv-z-base', 'zScale.base'],
    ['--gv-z-raised', 'zScale.raised'],
    ['--gv-z-sticky', 'zScale.sticky'],
    ['--gv-z-overlay', 'zScale.overlay'],
    ['--gv-z-modal', 'zScale.modal'],
    ['--gv-z-toast', 'zScale.toast'],
    ['--gv-z-max', 'zScale.max'],
    ['--gv-header-height', 'layout.headerHeight'],
    ['--gv-content-max-width', 'layout.contentMaxWidth'],
];
function varLine(source, name, path) {
    const value = getPath(source, path);
    if (value === undefined)
        throw new Error(`Unresolved token path: ${path}`);
    return `  ${name}: ${String(value)};`;
}
function generateTokensCss(tokens) {
    const source = { ...tokens, ...STATIC_SCALE };
    const v = (name) => {
        const entry = CSS_VARS.find(([n]) => n === name);
        if (!entry)
            throw new Error(`Unknown css var: ${name}`);
        return varLine(source, entry[0], entry[1]);
    };
    const spacing = tokens.spacing;
    const spacingLines = Object.keys(spacing)
        .filter((k) => k !== '0')
        .map((k) => `  --gv-space-${k}: ${String(spacing[k])};`);
    const breakpoints = tokens.breakpoints;
    const bpLines = Object.keys(breakpoints).map((k) => `  --gv-breakpoint-${kebab(k)}: ${String(breakpoints[k])};`);
    const section = (title, lines) => [`  /* === ${title} === */`, ...lines].join('\n');
    const body = [
        section('PRIMARY', [
            v('--gv-purple'),
            v('--gv-purple-deep'),
            v('--gv-purple-soft'),
            v('--gv-cyan'),
            v('--gv-cyan-deep'),
            v('--gv-cyan-soft'),
            v('--gv-gold'),
        ]),
        section('SURFACE', [
            v('--gv-bg'),
            v('--gv-bg-elevated'),
            v('--gv-bg-deep'),
            v('--gv-surface'),
            v('--gv-surface-raised'),
            v('--gv-surface-overlay'),
            v('--gv-glass'),
            v('--gv-glass-border'),
        ]),
        section('TEXT', [
            v('--gv-text'),
            v('--gv-text-secondary'),
            v('--gv-muted'),
            v('--gv-text-disabled'),
            v('--gv-text-inverse'),
        ]),
        section('FEEDBACK', [v('--gv-amber'), v('--gv-red'), v('--gv-green'), v('--gv-info')]),
        section('BORDER', [v('--gv-border'), v('--gv-border-accent'), v('--gv-border-accent-strong')]),
        section('GLOW', [v('--gv-glow-purple'), v('--gv-glow-cyan')]),
        section('GRADIENT', [v('--gv-gradient'), v('--gv-gradient-subtle'), v('--gv-gradient-text')]),
        section('TYPOGRAPHY', [
            v('--gv-font-display'),
            v('--gv-font-body'),
            v('--gv-font-mono'),
            v('--gv-font-mono-accent'),
        ]),
        section('SPACING', spacingLines),
        section('RADIUS', [
            v('--gv-radius-sm'),
            v('--gv-radius-md'),
            v('--gv-radius-lg'),
            v('--gv-radius-xl'),
            v('--gv-radius-2xl'),
            v('--gv-radius-pill'),
        ]),
        section('ELEVATION', [
            v('--gv-elev-sm'),
            v('--gv-elev-md'),
            v('--gv-elev-lg'),
            v('--gv-elev-xl'),
            v('--gv-elev-glow'),
        ]),
        [
            '  /* === MOTION === */',
            v('--gv-duration-instant'),
            v('--gv-duration-fast'),
            v('--gv-duration-base'),
            v('--gv-duration-slow'),
            v('--gv-duration-epic'),
            v('--gv-ease-out'),
            v('--gv-ease-in-out'),
            v('--gv-ease-smooth'),
            v('--gv-ease-out-expo'),
            '  /* Note: bounce/elastic easing is BANNED (per impeccable + DESIGN.md §7.2). Never define it. */',
        ].join('\n'),
        section('BREAKPOINTS (used in @media)', bpLines),
        section('Z-INDEX', [
            v('--gv-z-base'),
            v('--gv-z-raised'),
            v('--gv-z-sticky'),
            v('--gv-z-overlay'),
            v('--gv-z-modal'),
            v('--gv-z-toast'),
            v('--gv-z-max'),
        ]),
        section('LAYOUT', [v('--gv-header-height'), v('--gv-content-max-width')]),
    ].join('\n\n');
    return `/*
 * Gentle-Vanguard Design System v${String(tokens.version)} — Tokens (CSS)
 * GENERATED from src/tokens/tokens.json by src/cli/build-tokens.ts — do not edit by hand.
 * Regenerate: npx tsx packages/gv-design-system/src/cli/build-tokens.ts
 *
 * v2 Premium canon (official since 2026-09-02):
 *   - Canon:    ${String(tokens.meta.canon)}
 *   - Decision: docs/brand/BRAND-DECISION-2026-09-01.md
 *
 * Consolidated from 4 divergent legacy sets (see ADR-0026):
 *   - assets/gv-design-system.css (legacy canonical)
 *   - docs/brand/BRAND-GUIDELINES.md + config/brand.json
 *   - docs/brand/UI-STANDARD-ECOSYSTEM.md v1.0.0
 *   - apps/gv-analytics/src/styles.css (custom)
 *
 * Source of truth: src/tokens/tokens.json
 */

:root {
  color-scheme: dark;

${body}
}

/* === LIGHT THEME OVERRIDES (preserved from v1, opt-in) === */
:root[data-theme='light'] {
  color-scheme: light;
  --gv-bg: #f5f7fb;
  --gv-bg-elevated: #e5e7eb;
  --gv-bg-deep: #e5e7eb;
  --gv-surface: #ffffff;
  --gv-surface-raised: #f9fafb;
  --gv-surface-overlay: rgba(255, 255, 255, 0.7);
  --gv-glass: rgba(255, 255, 255, 0.7);
  --gv-glass-border: rgba(15, 23, 42, 0.1);
  --gv-text: #0f172a;
  --gv-text-secondary: #334155;
  --gv-muted: #475569;
  --gv-text-disabled: #94a3b8;
  --gv-text-inverse: #ffffff;
  --gv-border: rgba(15, 23, 42, 0.1);
  --gv-border-accent: rgba(167, 139, 250, 0.25);
  --gv-elev-md: 0 4px 12px rgba(15, 23, 42, 0.08);
  --gv-elev-lg: 0 8px 24px rgba(15, 23, 42, 0.12);
  --gv-elev-xl: 0 20px 60px rgba(15, 23, 42, 0.18);
}

/* === REDUCED MOTION === */
@media (prefers-reduced-motion: reduce) {
  :root {
    --gv-duration-base: 0ms;
    --gv-duration-fast: 0ms;
    --gv-duration-slow: 0ms;
  }
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
`;
}
// ============================================================================
// TypeScript generation (structure frozen — values from JSON)
// ============================================================================
function q(v) {
    return JSON.stringify(String(v));
}
function generateTokensTs(tokens) {
    const g = (path) => {
        const v = getPath(tokens, path);
        if (v === undefined)
            throw new Error(`Unresolved token path: ${path}`);
        return String(v);
    };
    const s = (path) => q(g(path));
    const n = (path) => String(getPath(tokens, path));
    return `/**
 * Gentle-Vanguard Design System v2 — Tokens (TypeScript)
 * GENERATED from src/tokens/tokens.json by src/cli/build-tokens.ts — do not edit by hand.
 * Regenerate: npx tsx packages/gv-design-system/src/cli/build-tokens.ts
 *
 * v2 Premium canon (official since 2026-09-02):
 *   - Canon: docs/brand/TOKENS-v2.json · Decision: docs/brand/BRAND-DECISION-2026-09-01.md
 *
 * Provides typed access to design tokens for TS/React code.
 */

export const tokens = {
  color: {
    primary: {
      purple: ${s('color.brand.purple')},
      purpleDeep: ${s('color.brand.purpleDeep')},
      purpleSoft: ${s('color.brand.purpleSoft')},
      cyan: ${s('color.brand.cyan')},
      cyanDeep: ${s('color.brand.cyanDeep')},
      cyanSoft: ${s('color.brand.cyanSoft')},
      gold: ${s('color.brand.gold')},
    },
    surface: {
      bg: ${s('color.surface.bg')},
      bgDeep: ${s('color.surface.bgDeep')},
      elevated: ${s('color.surface.elevated')},
      surface: ${s('color.surface.surface')},
      surfaceRaised: ${s('color.surface.surfaceRaised')},
      surfaceOverlay: ${s('color.surface.surfaceOverlay')},
      glass: ${s('color.surface.glass')},
      glassBorder: ${s('color.surface.glassBorder')},
    },
    text: {
      primary: ${s('color.text.primary')},
      secondary: ${s('color.text.secondary')},
      muted: ${s('color.text.muted')},
      disabled: ${s('color.text.disabled')},
      inverse: ${s('color.text.inverse')},
    },
    feedback: {
      amber: ${s('color.feedback.warning')},
      red: ${s('color.feedback.error')},
      green: ${s('color.feedback.success')},
      info: ${s('color.feedback.info')},
    },
    border: {
      default: ${s('color.border.default')},
      accent: ${s('color.border.accent')},
      accentStrong: ${s('color.border.accentStrong')},
    },
    glow: {
      purple: ${s('color.glow.purple')},
      cyan: ${s('color.glow.cyan')},
    },
    gradient: {
      primary: ${s('color.gradient.primary')},
      primarySubtle: ${s('color.gradient.primarySubtle')},
      text: ${s('color.gradient.text')},
    },
  },
  typography: {
    fontFamily: {
      display: ${s('typography.fontFamily.display')},
      body: ${s('typography.fontFamily.body')},
      mono: ${s('typography.fontFamily.mono')},
      monoAccent: ${s('typography.fontFamily.monoAccent')},
    },
    weight: {
      regular: ${n('typography.weight.regular')},
      medium: ${n('typography.weight.medium')},
      semibold: ${n('typography.weight.semibold')},
      bold: ${n('typography.weight.bold')},
      extrabold: ${n('typography.weight.extrabold')},
      black: ${n('typography.weight.black')},
    },
    size: {
      xs: ${s('typography.size.xs')},
      sm: ${s('typography.size.sm')},
      base: ${s('typography.size.base')},
      md: ${s('typography.size.md')},
      lg: ${s('typography.size.lg')},
      xl: ${s('typography.size.xl')},
      '2xl': ${s('typography.size.2xl')},
      '3xl': ${s('typography.size.3xl')},
      '4xl': ${s('typography.size.4xl')},
      '5xl': ${s('typography.size.5xl')},
    },
    lineHeight: {
      tight: ${n('typography.lineHeight.tight')},
      snug: ${n('typography.lineHeight.snug')},
      normal: ${n('typography.lineHeight.normal')},
      relaxed: ${n('typography.lineHeight.relaxed')},
      loose: ${n('typography.lineHeight.loose')},
    },
    letterSpacing: {
      tight: '-0.025em',
      snug: '-0.01em',
      normal: '0',
      wide: '0.05em',
      wider: '0.1em',
      widest: '0.2em',
    },
  },
  spacing: {
    0: '0',
    1: ${s('spacing.1')},
    2: ${s('spacing.2')},
    3: ${s('spacing.3')},
    4: ${s('spacing.4')},
    5: ${s('spacing.5')},
    6: ${s('spacing.6')},
    8: ${s('spacing.8')},
    10: ${s('spacing.10')},
    12: ${s('spacing.12')},
    16: ${s('spacing.16')},
    20: ${s('spacing.20')},
    24: ${s('spacing.24')},
  },
  radius: {
    none: ${s('radius.none')},
    sm: ${s('radius.sm')},
    md: ${s('radius.md')},
    lg: ${s('radius.lg')},
    xl: ${s('radius.xl')},
    '2xl': ${s('radius.2xl')},
    pill: ${s('radius.full')},
    full: ${s('radius.full')},
  },
  elevation: {
    0: 'none',
    sm: ${s('shadow.sm')},
    md: ${s('shadow.md')},
    lg: ${s('shadow.lg')},
    xl: ${s('shadow.xl')},
    glow: ${s('shadow.glowCyan')},
  },
  motion: {
    duration: {
      instant: ${s('motion.durations.instant')},
      fast: ${s('motion.durations.fast')},
      base: ${s('motion.durations.normal')},
      slow: ${s('motion.durations.slow')},
      slower: '600ms',
      epic: ${s('motion.durations.epic')},
    },
    easing: {
      linear: 'linear',
      easeIn: ${s('motion.easings.easeIn')},
      easeOut: ${s('motion.easings.easeOut')},
      easeInOut: ${s('motion.easings.easeInOut')},
      smooth: ${s('motion.easings.smooth')},
      outExpo: ${s('motion.easings.outExpo')},
      // Note: bounce/elastic easing is BANNED. Do not add it back.
    },
  },
  breakpoint: {
    sm: ${s('breakpoints.sm')},
    md: ${s('breakpoints.md')},
    lg: ${s('breakpoints.lg')},
    xl: ${s('breakpoints.xl')},
    '2xl': ${s('breakpoints.2xl')},
  },
  zIndex: {
    base: 0,
    raised: 10,
    sticky: 50,
    overlay: 100,
    modal: 200,
    toast: 300,
    max: 9999,
  },
  iconography: {
    size: {
      xs: '12px',
      sm: '16px',
      md: '20px',
      lg: '24px',
      xl: '32px',
      '2xl': '48px',
    },
  },
} as const;

export type Tokens = typeof tokens;
export type ColorTokens = Tokens['color'];
export type TypographyTokens = Tokens['typography'];
export type SpacingTokens = Tokens['spacing'];
export type RadiusTokens = Tokens['radius'];
export type ElevationTokens = Tokens['elevation'];
export type MotionTokens = Tokens['motion'];

/** Brand asset waivers — patrones intencionales que el detector marca pero son firma de marca. */
export const BRAND_WAIVERS = {
  'gradient-text': {
    reason: 'Wordmark "Vanguard" usa gradiente de marca intencionalmente',
    files: [
      'assets/gv-design-system.css',
      'apps/academy-web/style.css',
      'apps/gv-analytics/src/styles.css',
    ],
  },
  'side-tab': {
    reason: 'lesson-row + content cards usan border-left como signature de marca',
    files: [
      'apps/academy-web/style.css',
      'apps/gv-analytics/src/styles.css',
    ],
  },
  'codex-grid-background': {
    reason: 'Atmosfera de fondo (grid + glow) es firma de marca GV',
    files: [
      'assets/gv-design-system.css',
      'apps/academy-web/style.css',
      'apps/gv-analytics/src/styles.css',
    ],
  },
} as const;
`;
}
// ============================================================================
// dist artifacts (tailwind / figma / css-modules / copies)
// ============================================================================
function kebab(s) {
    return s.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase();
}
function flatten(obj, prefix = '') {
    const out = {};
    for (const [k, v] of Object.entries(obj)) {
        if (RESERVED_KEYS.has(k))
            continue;
        const key = prefix ? `${prefix}-${kebab(k)}` : kebab(k);
        if (isObj(v))
            Object.assign(out, flatten(v, key));
        else
            out[key] = v;
    }
    return out;
}
function generateTailwindConfig(tokens) {
    const colors = {};
    for (const [k, v] of Object.entries(flatten(tokens.color))) {
        if (typeof v === 'string' && /^(#|rgb)/.test(v))
            colors[`gv-${k}`] = v;
    }
    const fontFamily = {};
    for (const [k, v] of Object.entries(tokens.typography.fontFamily)) {
        fontFamily[kebab(k)] = String(v)
            .split(',')
            .map((f) => f.trim().replace(/['"]/g, ''));
    }
    return `/** @type {import('tailwindcss').Config} */
/* GENERATED from src/tokens/tokens.json by src/cli/build-tokens.ts — do not edit by hand. */
module.exports = {
  darkMode: 'class',
  content: [
    '../../apps/**/*.{ts,tsx,js,jsx,html}',
    '../../packages/gv-design-system/src/**/*.{ts,tsx,js,jsx}',
  ],
  theme: {
    extend: {
      colors: ${JSON.stringify(colors, null, 2)},
      spacing: ${JSON.stringify(tokens.spacing, null, 2)},
      fontFamily: ${JSON.stringify(fontFamily, null, 2)},
      fontSize: ${JSON.stringify(tokens.typography.size, null, 2)},
      borderRadius: ${JSON.stringify(tokens.radius, null, 2)},
      boxShadow: ${JSON.stringify(tokens.shadow, null, 2)},
      transitionTimingFunction: ${JSON.stringify(tokens.motion.easings, null, 2)},
      screens: ${JSON.stringify(tokens.breakpoints, null, 2)},
      zIndex: ${JSON.stringify(tokens.zIndex, null, 2)},
    },
  },
  plugins: [],
}`;
}
function generateFigmaTokens(tokens) {
    const figma = {
        $schema: 'https://tokens.studio/schema.json',
        $version: '0.1.0',
        $metadata: {
            tokenSetOrder: [
                'color',
                'surface',
                'typography',
                'spacing',
                'radius',
                'shadow',
                'transition',
                'breakpoints',
                'zIndex',
            ],
            tokenSetVersion: tokens.version,
            canon: tokens.meta.canon,
        },
        global: {
            $type: 'color',
            $value: getPath(tokens, 'color.surface.bg'),
            $description: 'Global background color (v2 Premium)',
        },
    };
    for (const [group, values] of Object.entries(tokens.color)) {
        figma[group] = {};
        for (const [k, v] of Object.entries(values)) {
            figma[group][k] = {
                $type: 'color',
                $value: v,
                $description: `color.${group}.${k}`,
            };
        }
    }
    figma.surfaceSet = {};
    for (const [k, v] of Object.entries(tokens.surface)) {
        figma.surfaceSet[k] = { $type: 'color', $value: v, $description: `surface.${k}` };
    }
    figma.typography = {
        fontFamilies: Object.fromEntries(Object.entries(tokens.typography.fontFamily).map(([k, v]) => [
            k,
            {
                $type: 'fontFamilies',
                $value: String(v)
                    .split(',')
                    .map((f) => f.trim().replace(/['"]/g, '')),
            },
        ])),
        fontWeights: Object.fromEntries(Object.entries(tokens.typography.weight).map(([k, v]) => [
            k,
            { $type: 'fontWeight', $value: v },
        ])),
        fontSizes: Object.fromEntries(Object.entries(tokens.typography.size).map(([k, v]) => [
            k,
            { $type: 'fontSize', $value: v },
        ])),
        lineHeights: Object.fromEntries(Object.entries(tokens.typography.lineHeight).map(([k, v]) => [
            k,
            { $type: 'lineHeight', $value: v },
        ])),
    };
    figma.spacing = Object.fromEntries(Object.entries(tokens.spacing).map(([k, v]) => [k, { $type: 'spacing', $value: v }]));
    figma.borderRadius = Object.fromEntries(Object.entries(tokens.radius).map(([k, v]) => [
        k,
        { $type: 'borderRadius', $value: v },
    ]));
    figma.shadow = Object.fromEntries(Object.entries(tokens.shadow).map(([k, v]) => [k, { $type: 'boxShadow', $value: v }]));
    figma.breakpoints = Object.fromEntries(Object.entries(tokens.breakpoints).map(([k, v]) => [
        k,
        { $type: 'breakpoint', $value: v },
    ]));
    figma.zIndex = Object.fromEntries(Object.entries(tokens.zIndex).map(([k, v]) => [k, { $type: 'zIndex', $value: v }]));
    return JSON.stringify(figma, null, 2);
}
function generateCssModulesTypes(css) {
    const names = [...css.matchAll(/^(?:  )?(--gv-[a-z0-9-]+):/gm)].map((m) => m[1]);
    const uniq = [...new Set(names)];
    let dts = `// Auto-generated CSS Modules types from tokens.css — do not edit by hand.\n`;
    dts += `// Regenerate: npx tsx packages/gv-design-system/src/cli/build-tokens.ts\n\n`;
    for (const mod of ['*.module.css', '*.module.scss', '*.module.sass']) {
        dts += `declare module '${mod}' {\n  const classes: Record<string, string>;\n  export default classes;\n}\n\n`;
    }
    dts += `interface GVTokenMap {\n`;
    for (const nm of uniq)
        dts += `  '${nm}': string;\n`;
    dts += `}\n`;
    return dts;
}
// ============================================================================
// Validation + main
// ============================================================================
function validate(tokens) {
    const errors = [];
    const requiredKeys = [
        'color',
        'surface',
        'typography',
        'spacing',
        'radius',
        'shadow',
        'transition',
        'breakpoints',
        'zIndex',
        'motion',
        'meta',
    ];
    for (const k of requiredKeys) {
        if (!tokens[k])
            errors.push(`Missing required top-level key: ${k}`);
    }
    if (tokens.color) {
        for (const k of ['brand', 'surface', 'text', 'feedback', 'border', 'glow', 'gradient']) {
            if (!tokens.color[k])
                errors.push(`Missing color.${k}`);
        }
    }
    // Hex sanity: any string that starts with '#' must be a 6-digit hex.
    const hexPattern = /^#[0-9a-f]{6}$/i;
    (function checkHex(obj, path = '') {
        for (const [k, v] of Object.entries(obj)) {
            const fullPath = path ? `${path}.${k}` : k;
            if (typeof v === 'string' && v.startsWith('#') && !hexPattern.test(v)) {
                errors.push(`Invalid hex at ${fullPath}: ${v}`);
            }
            else if (isObj(v)) {
                checkHex(v, fullPath);
            }
        }
    })(tokens);
    if (tokens.version !== '2.0.0') {
        errors.push(`Expected version 2.0.0 (v2 Premium canon), got: ${String(tokens.version)}`);
    }
    const meta = tokens.meta;
    if (meta) {
        if (meta.version !== tokens.version) {
            errors.push(`meta.version (${String(meta.version)}) != version (${String(tokens.version)})`);
        }
        if (typeof meta.canon !== 'string' || !meta.canon) {
            errors.push('meta.canon must point to docs/brand/TOKENS-v2.json');
        }
    }
    // Every CSS/TS mapping must resolve.
    const source = { ...tokens, ...STATIC_SCALE };
    for (const [, path] of CSS_VARS) {
        if (getPath(source, path) === undefined) {
            errors.push(`CSS mapping cannot resolve: ${path}`);
        }
    }
    const tsPaths = [
        'color.brand.gold',
        'color.surface.elevated',
        'color.surface.glass',
        'color.surface.glassBorder',
        'color.text.secondary',
        'color.text.disabled',
        'typography.fontFamily.monoAccent',
        'motion.durations.epic',
        'motion.easings.smooth',
        'motion.easings.outExpo',
    ];
    for (const p of tsPaths) {
        if (getPath(tokens, p) === undefined)
            errors.push(`TS mapping cannot resolve: ${p}`);
    }
    return errors;
}
function main() {
    console.log('🔨 Gentle-Vanguard Design System — token builder');
    console.log(`   Source: ${TOKENS_JSON}`);
    console.log('');
    if (!existsSync(TOKENS_JSON)) {
        console.error(`❌ tokens.json not found: ${TOKENS_JSON}`);
        process.exit(1);
    }
    const raw = readFileSync(TOKENS_JSON, 'utf-8');
    const tokens = JSON.parse(raw);
    console.log(`📦 Version: ${String(tokens.version)} · Canon: ${String(tokens.meta.canon)}`);
    console.log(`📦 Mode: ${String(tokens.mode)}`);
    console.log(`🎨 Colors: ${Object.keys(tokens.color.brand ?? {}).length} brand, ` +
        `${Object.keys(tokens.color.feedback ?? {}).length} feedback`);
    console.log(`🔤 Typography: ${Object.keys(tokens.typography.fontFamily ?? {}).length} families, ` +
        `${Object.keys(tokens.typography.size ?? {}).length} sizes`);
    console.log('');
    const errors = validate(tokens);
    if (errors.length > 0) {
        console.error(`❌ ${errors.length} validation error(s):`);
        for (const e of errors)
            console.error(`   - ${e}`);
        process.exit(1);
    }
    console.log('✅ All token validations passed.');
    const css = generateTokensCss(tokens);
    const ts = generateTokensTs(tokens);
    writeFileSync(SRC_CSS, css);
    writeFileSync(SRC_TS, ts);
    console.log('✅ src/tokens/tokens.css regenerated');
    console.log('✅ src/tokens/tokens.ts regenerated');
    mkdirSync(DIST, { recursive: true });
    writeFileSync(join(DIST, 'tokens.css'), css);
    writeFileSync(join(DIST, 'components.css'), css);
    if (!existsSync(SRC_SHELL))
        throw new Error(`Shared shell not found: ${SRC_SHELL}`);
    const shell = readFileSync(SRC_SHELL, 'utf8');
    writeFileSync(join(DIST, 'shell.css'), shell);
    writeFileSync(RUNTIME_SHELL, shell);
    if (existsSync(dirname(DESIGN_HUB_SHELL)))
        writeFileSync(DESIGN_HUB_SHELL, shell);
    writeFileSync(join(DIST, 'tokens.ts'), ts);
    writeFileSync(join(DIST, 'tailwind.config.ts'), generateTailwindConfig(tokens));
    writeFileSync(join(DIST, 'figma-tokens.json'), generateFigmaTokens(tokens));
    writeFileSync(join(DIST, 'css-modules.d.ts'), generateCssModulesTypes(css));
    writeFileSync(join(DIST, 'tokens.json'), JSON.stringify(tokens, null, 2) + '\n');
    console.log('✅ dist/tokens.css, components.css, shell.css, tokens.ts regenerated');
    console.log(`✅ runtime shell snapshot: ${RUNTIME_SHELL}`);
    console.log(`✅ Design Hub shell snapshot: ${DESIGN_HUB_SHELL}`);
    console.log('✅ dist/tailwind.config.ts, figma-tokens.json, css-modules.d.ts, tokens.json regenerated');
    console.log('');
    console.log('ℹ️  Next: `impeccable detect src/tokens/` (anti-slop regression) and');
    console.log('    `tsc -p tsconfig.json` (typecheck consumers of tokens.ts).');
}
main();
//# sourceMappingURL=build-tokens.js.map