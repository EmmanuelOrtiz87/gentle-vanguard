/**
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
      purple: "#a78bfa",
      purpleDeep: "#7c3aed",
      purpleSoft: "#c4b5fd",
      cyan: "#22d3ee",
      cyanDeep: "#0891b2",
      cyanSoft: "#67e8f9",
      gold: "#fbbf24",
    },
    surface: {
      bg: "#0f1115",
      bgDeep: "#090c11",
      elevated: "#151921",
      surface: "#1a1f2a",
      surfaceRaised: "#252b38",
      surfaceOverlay: "rgba(26, 31, 42, 0.72)",
      glass: "rgba(26, 31, 42, 0.72)",
      glassBorder: "rgba(167, 139, 250, 0.24)",
    },
    text: {
      primary: "#e8eef4",
      secondary: "#c4cdd8",
      muted: "#8b95a8",
      disabled: "#5a6370",
      inverse: "#090c11",
    },
    feedback: {
      amber: "#f4bb4f",
      red: "#ee6d75",
      green: "#4ade80",
      info: "#22d3ee",
    },
    border: {
      default: "rgba(139, 149, 168, 0.25)",
      accent: "rgba(167, 139, 250, 0.24)",
      accentStrong: "rgba(34, 211, 238, 0.5)",
    },
    glow: {
      purple: "rgba(167, 139, 250, 0.16)",
      cyan: "rgba(34, 211, 238, 0.13)",
    },
    gradient: {
      primary: "linear-gradient(135deg, #a78bfa 0%, color-mix(in srgb, #a78bfa 50%, #22d3ee) 50%, #22d3ee 100%)",
      primarySubtle: "linear-gradient(135deg, rgba(167,139,250,0.18), rgba(34,211,238,0.18))",
      text: "linear-gradient(135deg, #a78bfa 0%, color-mix(in srgb, #a78bfa 50%, #22d3ee) 50%, #22d3ee 100%)",
    },
  },
  typography: {
    fontFamily: {
      display: "'Space Grotesk', 'Orbitron', sans-serif",
      body: "'Inter', 'Inter Variable', system-ui, -apple-system, sans-serif",
      mono: "'JetBrains Mono NL', 'JetBrains Mono', 'Cascadia Code', Consolas, monospace",
      monoAccent: "'Space Mono', monospace",
    },
    weight: {
      regular: 400,
      medium: 500,
      semibold: 600,
      bold: 700,
      extrabold: 800,
      black: 900,
    },
    size: {
      xs: "0.75rem",
      sm: "0.8125rem",
      base: "0.875rem",
      md: "1rem",
      lg: "1.125rem",
      xl: "1.25rem",
      '2xl': "1.5rem",
      '3xl': "1.875rem",
      '4xl': "2.25rem",
      '5xl': "3rem",
    },
    lineHeight: {
      tight: 1.2,
      snug: 1.35,
      normal: 1.5,
      relaxed: 1.65,
      loose: 1.8,
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
    1: "0.25rem",
    2: "0.5rem",
    3: "0.75rem",
    4: "1rem",
    5: "1.25rem",
    6: "1.5rem",
    8: "2rem",
    10: "2.5rem",
    12: "3rem",
    16: "4rem",
    20: "5rem",
    24: "6rem",
  },
  radius: {
    none: "0",
    sm: "6px",
    md: "10px",
    lg: "14px",
    xl: "20px",
    '2xl': "28px",
    pill: "999px",
    full: "999px",
  },
  elevation: {
    0: 'none',
    sm: "0 1px 2px rgba(0, 0, 0, 0.4)",
    md: "0 4px 12px rgba(0, 0, 0, 0.5)",
    lg: "0 8px 24px rgba(0, 0, 0, 0.5)",
    xl: "0 20px 60px rgba(0, 0, 0, 0.6)",
    glow: "0 0 0 1px rgba(34, 211, 238, 0.15) inset, 0 8px 32px rgba(34, 211, 238, 0.35)",
  },
  motion: {
    duration: {
      instant: "100ms",
      fast: "180ms",
      base: "280ms",
      slow: "400ms",
      slower: '600ms',
      epic: "800ms",
    },
    easing: {
      linear: 'linear',
      easeIn: "cubic-bezier(0.4, 0, 1, 1)",
      easeOut: "cubic-bezier(0, 0, 0.2, 1)",
      easeInOut: "cubic-bezier(0.4, 0, 0.2, 1)",
      smooth: "cubic-bezier(0.16, 1, 0.3, 1)",
      outExpo: "cubic-bezier(0.19, 1, 0.22, 1)",
      // Note: bounce/elastic easing is BANNED. Do not add it back.
    },
  },
  breakpoint: {
    sm: "640px",
    md: "768px",
    lg: "1024px",
    xl: "1280px",
    '2xl': "1536px",
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
