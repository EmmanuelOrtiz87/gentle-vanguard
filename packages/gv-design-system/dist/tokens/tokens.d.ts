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
export declare const tokens: {
    readonly color: {
        readonly primary: {
            readonly purple: "#a78bfa";
            readonly purpleDeep: "#7c3aed";
            readonly purpleSoft: "#c4b5fd";
            readonly cyan: "#22d3ee";
            readonly cyanDeep: "#0891b2";
            readonly cyanSoft: "#67e8f9";
            readonly gold: "#fbbf24";
        };
        readonly surface: {
            readonly bg: "#0f1115";
            readonly bgDeep: "#090c11";
            readonly elevated: "#151921";
            readonly surface: "#1a1f2a";
            readonly surfaceRaised: "#252b38";
            readonly surfaceOverlay: "rgba(26, 31, 42, 0.72)";
            readonly glass: "rgba(26, 31, 42, 0.72)";
            readonly glassBorder: "rgba(167, 139, 250, 0.24)";
        };
        readonly text: {
            readonly primary: "#e8eef4";
            readonly secondary: "#c4cdd8";
            readonly muted: "#8b95a8";
            readonly disabled: "#5a6370";
            readonly inverse: "#090c11";
        };
        readonly feedback: {
            readonly amber: "#f4bb4f";
            readonly red: "#ee6d75";
            readonly green: "#4ade80";
            readonly info: "#22d3ee";
        };
        readonly border: {
            readonly default: "rgba(139, 149, 168, 0.25)";
            readonly accent: "rgba(167, 139, 250, 0.24)";
            readonly accentStrong: "rgba(34, 211, 238, 0.5)";
        };
        readonly glow: {
            readonly purple: "rgba(167, 139, 250, 0.16)";
            readonly cyan: "rgba(34, 211, 238, 0.13)";
        };
        readonly gradient: {
            readonly primary: "linear-gradient(135deg, #a78bfa 0%, color-mix(in srgb, #a78bfa 50%, #22d3ee) 50%, #22d3ee 100%)";
            readonly primarySubtle: "linear-gradient(135deg, rgba(167,139,250,0.18), rgba(34,211,238,0.18))";
            readonly text: "linear-gradient(135deg, #a78bfa 0%, color-mix(in srgb, #a78bfa 50%, #22d3ee) 50%, #22d3ee 100%)";
        };
    };
    readonly typography: {
        readonly fontFamily: {
            readonly display: "'Space Grotesk', 'Orbitron', sans-serif";
            readonly body: "'Inter', 'Inter Variable', system-ui, -apple-system, sans-serif";
            readonly mono: "'JetBrains Mono NL', 'JetBrains Mono', 'Cascadia Code', Consolas, monospace";
            readonly monoAccent: "'Space Mono', monospace";
        };
        readonly weight: {
            readonly regular: 400;
            readonly medium: 500;
            readonly semibold: 600;
            readonly bold: 700;
            readonly extrabold: 800;
            readonly black: 900;
        };
        readonly size: {
            readonly xs: "0.75rem";
            readonly sm: "0.8125rem";
            readonly base: "0.875rem";
            readonly md: "1rem";
            readonly lg: "1.125rem";
            readonly xl: "1.25rem";
            readonly '2xl': "1.5rem";
            readonly '3xl': "1.875rem";
            readonly '4xl': "2.25rem";
            readonly '5xl': "3rem";
        };
        readonly lineHeight: {
            readonly tight: 1.2;
            readonly snug: 1.35;
            readonly normal: 1.5;
            readonly relaxed: 1.65;
            readonly loose: 1.8;
        };
        readonly letterSpacing: {
            readonly tight: "-0.025em";
            readonly snug: "-0.01em";
            readonly normal: "0";
            readonly wide: "0.05em";
            readonly wider: "0.1em";
            readonly widest: "0.2em";
        };
    };
    readonly spacing: {
        readonly 0: "0";
        readonly 1: "0.25rem";
        readonly 2: "0.5rem";
        readonly 3: "0.75rem";
        readonly 4: "1rem";
        readonly 5: "1.25rem";
        readonly 6: "1.5rem";
        readonly 8: "2rem";
        readonly 10: "2.5rem";
        readonly 12: "3rem";
        readonly 16: "4rem";
        readonly 20: "5rem";
        readonly 24: "6rem";
    };
    readonly radius: {
        readonly none: "0";
        readonly sm: "6px";
        readonly md: "10px";
        readonly lg: "14px";
        readonly xl: "20px";
        readonly '2xl': "28px";
        readonly pill: "999px";
        readonly full: "999px";
    };
    readonly elevation: {
        readonly 0: "none";
        readonly sm: "0 1px 2px rgba(0, 0, 0, 0.4)";
        readonly md: "0 4px 12px rgba(0, 0, 0, 0.5)";
        readonly lg: "0 8px 24px rgba(0, 0, 0, 0.5)";
        readonly xl: "0 20px 60px rgba(0, 0, 0, 0.6)";
        readonly glow: "0 0 0 1px rgba(34, 211, 238, 0.15) inset, 0 8px 32px rgba(34, 211, 238, 0.35)";
    };
    readonly motion: {
        readonly duration: {
            readonly instant: "100ms";
            readonly fast: "180ms";
            readonly base: "280ms";
            readonly slow: "400ms";
            readonly slower: "600ms";
            readonly epic: "800ms";
        };
        readonly easing: {
            readonly linear: "linear";
            readonly easeIn: "cubic-bezier(0.4, 0, 1, 1)";
            readonly easeOut: "cubic-bezier(0, 0, 0.2, 1)";
            readonly easeInOut: "cubic-bezier(0.4, 0, 0.2, 1)";
            readonly smooth: "cubic-bezier(0.16, 1, 0.3, 1)";
            readonly outExpo: "cubic-bezier(0.19, 1, 0.22, 1)";
        };
    };
    readonly breakpoint: {
        readonly sm: "640px";
        readonly md: "768px";
        readonly lg: "1024px";
        readonly xl: "1280px";
        readonly '2xl': "1536px";
    };
    readonly zIndex: {
        readonly base: 0;
        readonly raised: 10;
        readonly sticky: 50;
        readonly overlay: 100;
        readonly modal: 200;
        readonly toast: 300;
        readonly max: 9999;
    };
    readonly iconography: {
        readonly size: {
            readonly xs: "12px";
            readonly sm: "16px";
            readonly md: "20px";
            readonly lg: "24px";
            readonly xl: "32px";
            readonly '2xl': "48px";
        };
    };
};
export type Tokens = typeof tokens;
export type ColorTokens = Tokens['color'];
export type TypographyTokens = Tokens['typography'];
export type SpacingTokens = Tokens['spacing'];
export type RadiusTokens = Tokens['radius'];
export type ElevationTokens = Tokens['elevation'];
export type MotionTokens = Tokens['motion'];
/** Brand asset waivers — patrones intencionales que el detector marca pero son firma de marca. */
export declare const BRAND_WAIVERS: {
    readonly 'gradient-text': {
        readonly reason: "Wordmark \"Vanguard\" usa gradiente de marca intencionalmente";
        readonly files: readonly ["assets/gv-design-system.css", "apps/academy-web/style.css", "apps/gv-analytics/src/styles.css"];
    };
    readonly 'side-tab': {
        readonly reason: "lesson-row + content cards usan border-left como signature de marca";
        readonly files: readonly ["apps/academy-web/style.css", "apps/gv-analytics/src/styles.css"];
    };
    readonly 'codex-grid-background': {
        readonly reason: "Atmosfera de fondo (grid + glow) es firma de marca GV";
        readonly files: readonly ["assets/gv-design-system.css", "apps/academy-web/style.css", "apps/gv-analytics/src/styles.css"];
    };
};
//# sourceMappingURL=tokens.d.ts.map