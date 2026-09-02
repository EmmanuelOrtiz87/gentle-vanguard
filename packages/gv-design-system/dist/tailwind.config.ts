/** @type {import('tailwindcss').Config} */
/* GENERATED from src/tokens/tokens.json by src/cli/build-tokens.ts — do not edit by hand. */
module.exports = {
  darkMode: 'class',
  content: [
    '../../apps/**/*.{ts,tsx,js,jsx,html}',
    '../../packages/gv-design-system/src/**/*.{ts,tsx,js,jsx}',
  ],
  theme: {
    extend: {
      colors: {
  "gv-brand-purple": "#a78bfa",
  "gv-brand-purple-deep": "#7c3aed",
  "gv-brand-purple-soft": "#c4b5fd",
  "gv-brand-cyan": "#22d3ee",
  "gv-brand-cyan-deep": "#0891b2",
  "gv-brand-cyan-soft": "#67e8f9",
  "gv-brand-gold": "#fbbf24",
  "gv-surface-bg": "#0f1115",
  "gv-surface-bg-deep": "#090c11",
  "gv-surface-elevated": "#151921",
  "gv-surface-surface": "#1a1f2a",
  "gv-surface-surface-raised": "#252b38",
  "gv-surface-surface-overlay": "rgba(26, 31, 42, 0.72)",
  "gv-surface-glass": "rgba(26, 31, 42, 0.72)",
  "gv-surface-glass-border": "rgba(167, 139, 250, 0.24)",
  "gv-text-primary": "#e8eef4",
  "gv-text-secondary": "#c4cdd8",
  "gv-text-muted": "#8b95a8",
  "gv-text-disabled": "#5a6370",
  "gv-text-inverse": "#090c11",
  "gv-feedback-success": "#4ade80",
  "gv-feedback-warning": "#f4bb4f",
  "gv-feedback-error": "#ee6d75",
  "gv-feedback-info": "#22d3ee",
  "gv-border-default": "rgba(139, 149, 168, 0.25)",
  "gv-border-accent": "rgba(167, 139, 250, 0.24)",
  "gv-border-accent-strong": "rgba(34, 211, 238, 0.5)",
  "gv-glow-purple": "rgba(167, 139, 250, 0.16)",
  "gv-glow-cyan": "rgba(34, 211, 238, 0.13)"
},
      spacing: {
  "0": "0",
  "1": "0.25rem",
  "2": "0.5rem",
  "3": "0.75rem",
  "4": "1rem",
  "5": "1.25rem",
  "6": "1.5rem",
  "8": "2rem",
  "10": "2.5rem",
  "12": "3rem",
  "16": "4rem",
  "20": "5rem",
  "24": "6rem"
},
      fontFamily: {
  "display": [
    "Space Grotesk",
    "Orbitron",
    "sans-serif"
  ],
  "body": [
    "Inter",
    "Inter Variable",
    "system-ui",
    "-apple-system",
    "sans-serif"
  ],
  "mono": [
    "JetBrains Mono NL",
    "JetBrains Mono",
    "Cascadia Code",
    "Consolas",
    "monospace"
  ],
  "mono-accent": [
    "Space Mono",
    "monospace"
  ]
},
      fontSize: {
  "xs": "0.75rem",
  "sm": "0.8125rem",
  "base": "0.875rem",
  "md": "1rem",
  "lg": "1.125rem",
  "xl": "1.25rem",
  "2xl": "1.5rem",
  "3xl": "1.875rem",
  "4xl": "2.25rem",
  "5xl": "3rem"
},
      borderRadius: {
  "none": "0",
  "sm": "6px",
  "md": "10px",
  "lg": "14px",
  "xl": "20px",
  "2xl": "28px",
  "full": "999px"
},
      boxShadow: {
  "xs": "0 1px 2px rgba(0, 0, 0, 0.35)",
  "sm": "0 1px 2px rgba(0, 0, 0, 0.4)",
  "md": "0 4px 12px rgba(0, 0, 0, 0.5)",
  "lg": "0 8px 24px rgba(0, 0, 0, 0.5)",
  "xl": "0 20px 60px rgba(0, 0, 0, 0.6)",
  "2xl": "0 25px 60px rgba(0, 0, 0, 0.65)",
  "glow": "0 0 0 1px rgba(167, 139, 250, 0.2) inset, 0 8px 32px rgba(167, 139, 250, 0.25)",
  "glowCyan": "0 0 0 1px rgba(34, 211, 238, 0.15) inset, 0 8px 32px rgba(34, 211, 238, 0.35)",
  "elev1": "0 1px 2px rgba(0, 0, 0, 0.4)",
  "elev2": "0 4px 12px rgba(0, 0, 0, 0.5)",
  "elev3": "0 8px 24px rgba(0, 0, 0, 0.5)",
  "elev4": "0 20px 60px rgba(0, 0, 0, 0.6)",
  "glowPurple": "0 0 0 1px rgba(167, 139, 250, 0.2) inset, 0 8px 32px rgba(167, 139, 250, 0.25)",
  "inner": "inset 0 2px 4px rgba(0, 0, 0, 0.25)"
},
      transitionTimingFunction: {
  "linear": "linear",
  "easeIn": "cubic-bezier(0.4, 0, 1, 1)",
  "easeOut": "cubic-bezier(0, 0, 0.2, 1)",
  "easeInOut": "cubic-bezier(0.4, 0, 0.2, 1)",
  "smooth": "cubic-bezier(0.16, 1, 0.3, 1)",
  "outExpo": "cubic-bezier(0.19, 1, 0.22, 1)",
  "spring": "cubic-bezier(0.19, 1, 0.22, 1)",
  "springFast": "cubic-bezier(0.19, 1, 0.22, 1)",
  "springGentle": "cubic-bezier(0.16, 1, 0.3, 1)"
},
      screens: {
  "sm": "640px",
  "md": "768px",
  "lg": "1024px",
  "xl": "1280px",
  "2xl": "1536px"
},
      zIndex: {
  "dropdown": 50,
  "sticky": 40,
  "modal": 60,
  "popover": 70,
  "tooltip": 80,
  "toast": 90
},
    },
  },
  plugins: [],
}