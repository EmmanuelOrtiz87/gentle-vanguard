/**
 * Gentle-Vanguard Design System v2 — Tailwind v3 Bridge
 *
 * Returns a tailwind.config.js extension object that maps the gv-design-system
 * v2 tokens into Tailwind v3 colors/spacing/radius/etc.
 *
 * Usage in apps/web-dashboard/tailwind.config.js:
 *   import { gvDesignSystem } from '@gentle-vanguard/design-system/adapters/tailwind.v3';
 *   export default {
 *     ...gvDesignSystem,
 *     content: ['./src/**/*.{ts,tsx}'],
 *   };
 *
 * Or extend:
 *   import { gvColors, gvSpacing, gvRadius } from '@gentle-vanguard/design-system/adapters/tailwind.v3';
 *   export default {
 *     content: [...],
 *     theme: { extend: { colors: { ...gvColors, ... }, spacing: { ...gvSpacing, ... } } },
 *   };
 */

/** Tailwind v3 colors mapped from gv-design-system v2 tokens. */
export const gvColors = {
  'gv-purple': 'var(--gv-purple)',
  'gv-purple-deep': 'var(--gv-purple-deep)',
  'gv-purple-soft': 'var(--gv-purple-soft)',
  'gv-cyan': 'var(--gv-cyan)',
  'gv-cyan-deep': 'var(--gv-cyan-deep)',
  'gv-cyan-soft': 'var(--gv-cyan-soft)',
  'gv-bg': 'var(--gv-bg)',
  'gv-bg-deep': 'var(--gv-bg-deep)',
  'gv-surface': 'var(--gv-surface)',
  'gv-surface-raised': 'var(--gv-surface-raised)',
  'gv-surface-overlay': 'var(--gv-surface-overlay)',
  'gv-text': 'var(--gv-text)',
  'gv-muted': 'var(--gv-muted)',
  'gv-text-inverse': 'var(--gv-text-inverse)',
  'gv-amber': 'var(--gv-amber)',
  'gv-red': 'var(--gv-red)',
  'gv-green': 'var(--gv-green)',
  'gv-info': 'var(--gv-info)',
  'gv-border': 'var(--gv-border)',
  'gv-border-accent': 'var(--gv-border-accent)',
  'gv-border-accent-strong': 'var(--gv-border-accent-strong)',
  // Brand gradient helpers (for `bg-gv-gradient` etc.)
  'gv-gradient': 'linear-gradient(135deg, var(--gv-purple) 0%, var(--gv-cyan) 100%)',
  'gv-glow': 'var(--gv-elev-glow)',
};

/** Tailwind v3 spacing scale (4px base). */
export const gvSpacing = {
  'gv-1': 'var(--gv-space-1)',
  'gv-2': 'var(--gv-space-2)',
  'gv-3': 'var(--gv-space-3)',
  'gv-4': 'var(--gv-space-4)',
  'gv-5': 'var(--gv-space-5)',
  'gv-6': 'var(--gv-space-6)',
  'gv-8': 'var(--gv-space-8)',
  'gv-10': 'var(--gv-space-10)',
  'gv-12': 'var(--gv-space-12)',
  'gv-16': 'var(--gv-space-16)',
  'gv-20': 'var(--gv-space-20)',
  'gv-24': 'var(--gv-space-24)',
};

/** Tailwind v3 radius scale. */
export const gvRadius = {
  'gv-sm': 'var(--gv-radius-sm)',
  'gv-md': 'var(--gv-radius-md)',
  'gv-lg': 'var(--gv-radius-lg)',
  'gv-xl': 'var(--gv-radius-xl)',
  'gv-2xl': 'var(--gv-radius-2xl)',
  'gv-pill': 'var(--gv-radius-pill)',
};

/** Tailwind v3 elevation (shadows). */
export const gvShadow = {
  'gv-sm': 'var(--gv-elev-sm)',
  'gv-md': 'var(--gv-elev-md)',
  'gv-lg': 'var(--gv-elev-lg)',
  'gv-xl': 'var(--gv-elev-xl)',
  'gv-glow': 'var(--gv-elev-glow)',
};

/** Tailwind v3 font families. */
export const gvFontFamily = {
  'gv-display': ['var(--gv-font-display)'],
  'gv-body': ['var(--gv-font-body)'],
  'gv-mono': ['var(--gv-font-mono)'],
};

/** Drop-in extend config for tailwind.config.js theme.extend. */
export const gvDesignSystem = {
  theme: {
    extend: {
      colors: gvColors,
      spacing: gvSpacing,
      borderRadius: gvRadius,
      boxShadow: gvShadow,
      fontFamily: gvFontFamily,
      animation: {
        'gv-viewIn': 'gv-viewIn 0.28s ease-out forwards',
        'gv-fadeIn': 'gv-fadeIn 0.2s ease-out forwards',
        'gv-slideUp': 'gv-slideUp 0.28s cubic-bezier(0.4, 0, 0.2, 1) forwards',
        'gv-scaleIn': 'gv-scaleIn 0.15s ease-out forwards',
      },
      keyframes: {
        'gv-viewIn': {
          '0%': { opacity: '0', transform: 'translateY(8px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        'gv-fadeIn': {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        'gv-slideUp': {
          '0%': { opacity: '0', transform: 'translateY(16px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        'gv-scaleIn': {
          '0%': { opacity: '0', transform: 'scale(0.95)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
      },
    },
  },
};

export default gvDesignSystem;
