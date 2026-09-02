# Plan Maestro: Unificación Total del Design System Gentle-Vanguard v3.0 "Premium Commercial"

> **Objetivo**: Unificar TODAS las apps bajo un **Design System v3.0 "Premium Commercial"** único, coherente, accesible (WCAG 2.2 AA), y de calidad enterprise. Academy como inspiración visual, elevado a nivel **comercial premium 10000%**.

---

## 🎯 Estado Actual (Fragmentación Crítica)

| App | Design System Actual | Problemas |
|---|---|---|
| **web-dashboard** | Styles propio (`src/styles/`) + gv-design-system.css (legacy v1) | Fragmentado, no usa DS v2 |
| **gv-analytics** | @gentle-vanguard/design-system/tokens.css (v2 alpha) + custom | v2 alpha, tokens divergentes |
| **content-cms** | gv-design-system.css (legacy v1) + styles.css propio | Legacy v1, no v2 |
| **academy-web** | Fork local v2 con colores custom (`--color-primary: #22d3ee`) | Fork divergente, no usa tokens.json SoT |
| **prompt-studio** | styles.css propio + gv-design-system.css (legacy) | Legacy v1 |
| **archify** | gv-design-system.css (legacy) + styles.css propio | Legacy v1 |
| **command-center** | Sirve gv-design-system.css (legacy) en ruta | Legacy v1, vanilla |
| **gv-design-system-catalog** | tokens.css (v2) + styles.css propio | Demo v2 alpha |

**Tokens divergentes detectados**:
- `--gv-primary`: `#00bfff` (legacy) vs `#a78bfa` (v2 purple) vs `#22d3ee` (academy cyan)
- `--gv-bg`: `#0d1117` (legacy) vs `#121212` (v2/academy)
- `--gv-gradient`: `135deg #a855f7→#00bfff` (legacy) vs `135deg #a78bfa→#22d3ee` (v2) vs custom academy
- `--gv-font-display`: Orbitron (legacy/v2) vs custom academy

---

## 🎯 Objetivo: Design System v3.0 "Premium Commercial"

### Principios de Diseño "Premium Commercial 10000%"

1. **Single Source of Truth**: `packages/gv-design-system/src/tokens/tokens.json` (ÚNICO SoT)
2. **Dark-First, Light-Ready**: Modo oscuro por defecto, light mode perfecto
3. **WCAG 2.2 AA**: Contraste, focus visible, motion reduction, semántica
4. **Anti-AI-Slop**: Sin bounce-easing, sin cream+terracotta, sin near-black+acid-green, tipografía editorial
5. **Micro-interacciones Premium**: Spring physics, stagger, hover lift, focus rings, loading states
6. **Motion Choreography**: Stagger, easing curves (cubic-bezier premium), reduced-motion respect
7. **Tipografía Editorial**: Orbitron (display) + Inter (body) + JetBrains Mono (mono) — clamp fluid
8. **Glassmorphism Premium**: Backdrop-filter, bordes sutiles, sombras en capas, depth tokens
8. **Brand Identity**: Purple (#a78bfa) + Cyan (#22d3ee) gradient como firma, #121212 bg profundo
9. **Component Library Premium**: 7+ componentes React + CSS vanilla (Button, Card, Input, Tag, Stack, Text, IconButton, Avatar, Badge, Tooltip, Modal, Tabs, Table, DataViz)
10. **Developer Experience**: TypeScript strict, Storybook, visual regression, a11y testing

### Paleta v3.0 "Premium Commercial" (Locked)

```json
{
  "color": {
    "brand": {
      "purple": "#a78bfa",
      "purpleDeep": "#7c3aed",
      "purpleSoft": "#c4b5fd",
      "cyan": "#22d3ee",
      "cyanDeep": "#06b6d4",
      "cyanSoft": "#67e8f9",
      "gradient": "linear-gradient(135deg, #a78bfa 0%, #22d3ee 100%)",
      "gradientSubtle": "linear-gradient(135deg, rgba(167,139,250,0.18), rgba(34,211,238,0.18))",
      "text": "linear-gradient(135deg, #a78bfa 0%, #22d3ee 100%)"
    },
    "surface": {
      "bg": "#121212",
      "bgDeep": "#0a0e17",
      "surface": "#1f2937",
      "surfaceRaised": "#273548",
      "surfaceOverlay": "rgba(31,41,55,0.6)"
    },
    "text": {
      "primary": "#e5e7eb",
      "muted": "#9ca3af",
      "inverse": "#0a0e17"
    },
    "feedback": {
      "success": "#4ade80",
      "warning": "#f4bb4f",
      "error": "#ee6d75",
      "info": "#22d3ee"
    },
    "border": {
      "default": "rgba(156,163,175,0.25)",
      "accent": "rgba(167,139,250,0.18)",
      "accentStrong": "rgba(34,211,238,0.5)"
    },
    "glow": {
      "purple": "rgba(168,85,247,0.16)",
      "cyan": "rgba(34,211,238,0.13)"
    },
    "gradient": {
      "primary": "linear-gradient(135deg, #a78bfa 0%, #22d3ee 100%)",
      "primarySubtle": "linear-gradient(135deg, rgba(167,139,250,0.18), rgba(34,211,238,0.18))",
      "text": "linear-gradient(135deg, #a78bfa 0%, #22d3ee 100%)"
    }
  },
  "surface": {
    "bg": "#121212",
    "bgDeep": "#0a0e17",
    "surface": "#1f2937",
    "surfaceRaised": "#273548",
    "surfaceOverlay": "rgba(31,41,55,0.6)"
  },
  "typography": {
    "fontFamily": {
      "display": "'Orbitron', 'Rajdhani', 'Share Tech Mono', monospace",
      "body": "'Inter', 'Segoe UI', system-ui, -apple-system, sans-serif",
      "mono": "'JetBrains Mono', 'Cascadia Code', Consolas, monospace"
    },
    "size": { "xs": "0.75rem", "sm": "0.8125rem", "base": "0.875rem", "md": "1rem", "lg": "1.125rem", "xl": "1.25rem", "2xl": "1.5rem", "3xl": "1.875rem", "4xl": "2.25rem", "5xl": "3rem" },
    "weight": { "regular": 400, "medium": 500, "semibold": 600, "bold": 700, "extrabold": 800, "black": 900 },
    "lineHeight": { "tight": 1.2, "snug": 1.35, "normal": 1.5, "relaxed": 1.65, "loose": 1.8 }
  },
  "spacing": { "0": "0", "1": "0.25rem", "2": "0.5rem", "3": "0.75rem", "4": "1rem", "5": "1.25rem", "6": "1.5rem", "8": "2rem", "10": "2.5rem", "12": "3rem", "16": "4rem" },
  "radius": { "none": "0", "sm": "0.25rem", "md": "0.375rem", "lg": "0.5rem", "xl": "0.75rem", "2xl": "1rem", "full": "9999px" },
  "shadow": {
    "xs": "0 1px 2px rgba(0,0,0,0.05)",
    "sm": "0 1px 3px rgba(0,0,0,0.1), 0 1px 2px rgba(0,0,0,0.06)",
    "md": "0 4px 6px rgba(0,0,0,0.1), 0 2px 4px rgba(0,0,0,0.06)",
    "lg": "0 10px 15px rgba(0,0,0,0.1), 0 4px 6px rgba(0,0,0,0.05)",
    "xl": "0 20px 25px rgba(0,0,0,0.15), 0 10px 10px rgba(0,0,0,0.04)",
    "2xl": "0 25px 50px rgba(0,0,0,0.25)",
    "glow": "0 0 30px rgba(168,85,247,0.35)",
    "glowCyan": "0 0 30px rgba(34,211,238,0.35)",
    "elev1": "0 1px 2px rgba(0,0,0,0.3), 0 1px 1px rgba(0,0,0,0.2)",
    "elev2": "0 4px 6px rgba(0,0,0,0.3), 0 2px 4px rgba(0,0,0,0.2)",
    "elev3": "0 10px 15px rgba(0,0,0,0.3), 0 4px 6px rgba(0,0,0,0.2)",
    "elev4": "0 20px 25px rgba(0,0,0,0.4), 0 10px 10px rgba(0,0,0,0.15)",
    "glowPurple": "0 0 30px rgba(168,85,247,0.35)",
    "glowCyan": "0 0 30px rgba(34,211,238,0.35)",
    "inner": "inset 0 2px 4px rgba(0,0,0,0.06)"
  },
  "transition": {
    "fast": "150ms cubic-bezier(0.4, 0, 0.2, 1)",
    "normal": "200ms cubic-bezier(0.4, 0, 0.2, 1)",
    "slow": "300ms cubic-bezier(0.4, 0, 0.2, 1)",
    "spring": "400ms cubic-bezier(0.34, 1.56, 0.64, 1)"
  },
  "breakpoints": { "sm": "640px", "md": "768px", "lg": "1024px", "xl": "1280px", "2xl": "1536px" },
  "zIndex": { "dropdown": 50, "sticky": 40, "modal": 60, "popover": 70, "tooltip": 80, "toast": 90 }
}
```

---

## 🚀 Fases de Ejecución

### FASE 1: Consolidar Design System v3.0 "Locked" (Día 1)
- [ ] **Lock tokens.json v3.0** en `packages/gv-design-system/src/tokens/tokens.json`
- [ ] Generar build artifacts: `tokens.css`, `tokens.ts`, `tailwind.config.ts`, `figma-tokens.json`
- [ ] Crear `packages/gv-design-system/src/index.ts` export barrel
- [ ] Publicar como `@gentle-vanguard/design-system@3.0.0` (workspace)
- [ ] Validar con `impeccable detect` → 0 issues

### FASE 2: Component Library Premium v3 (Día 2-3)
Crear en `packages/gv-design-system/src/components/`:
| Componente | Variantes | Estados | Premium Features |
|---|---|---|---|
| **Button** | primary, secondary, ghost, danger, success, outline | default, hover, focus, active, loading, disabled | spinner, ripple, spring press |
| **Card** | glass, solid, outline, elevated | default, hover, focus, interactive, selected | lift, glow, backdrop-filter |
| **Input** | text, email, password, search, textarea, select | default, focus, error, success, disabled, loading | icon left/right, clearable, password toggle |
| **Tag/Badge** | primary, secondary, success, warning, error, neutral | default, removable, clickable | sizes sm/md/lg, gradient primary |
| **Stack** (Row/Column) | gap tokens, align, justify, wrap | responsive gaps | gap tokens, responsive |
| **Text/Typography** | display-1/2, heading-1/2/3, body, body-sm, eyebrow, metric, code, gradient | gradient text, metric, code | clamp fluid, gradient text |
| **Button** | primary, secondary, ghost, danger, outline | loading, disabled, icon-left/right | spinner, icon position |
| **IconButton** | default, primary, ghost, danger | sizes sm/md/lg | aria-label required |
| **Avatar** | sizes sm/md/lg/xl, fallback initials, status ring | online/offline/busy | status ring, fallback gradient |
| **Tooltip** | positions, delay, arrow | animated | spring, portal |
| **Modal/Dialog** | sizes sm/md/lg/xl/full, backdrop, focus trap | animated | spring, focus trap, scroll lock |
| **Tabs** | default, underline, pills, card | animated indicator | spring indicator, keyboard nav |
| **Table** | sortable, selectable, pagination, sticky header | loading, empty, row click | virtualized, sticky cols |
| **DataViz** (Charts) | Line, Bar, Area, Donut, Sparkline | tooltip, legend, animation | spring, gradient fills |

**Entregables**:
- `packages/gv-design-system/src/components/` (React + CSS modules)
- `packages/gv-design-system/src/index.ts` (barrel export)
- `packages/gv-design-system/src/components.css` (CSS vanilla fallback)
- Storybook configurado
- Tests: a11y, visual regression, unit

### FASE 3: Migrar TODAS las Apps (Día 4-5)

| App | Estado Actual | Acción |
|---|---|---|
| **web-dashboard** | Fragmentado | Re-escribir UI con DS v3 components |
| **gv-analytics** | v2 alpha + custom | Migrar a DS v3 components |
| **content-cms** | Legacy v1 | Re-escribir con DS v3 |
| **academy-web** | Fork v2 custom | **REFERENCIA VISUAL** → Migrar a DS v3, elevar a premium |
| **prompt-studio** | Legacy v1 | Migrar a DS v3 |
| **archify** | Legacy v1 + custom | Ya migrado a DS v3 parcial → completar |
| **command-center** | Legacy v1 vanilla | Migrar a DS v3 (vanilla CSS) |
| **gv-design-system-catalog** | v2 alpha demo | **REEMPLAZAR** por Showcase Premium v3 |

### FASE 4: Academy Premium - La Referencia Visual (Día 5-6)

Transformar Academy en **la vitrina premium** del design system:
- Hero premium con gradient text animado
- Sidebar navigation premium con iconos, badges, progress
- Lesson cards premium con progress rings, hover lift
- Code blocks premium con copy button, line numbers, copy feedback
- Progress rings animados, streak badges, achievement system
- Dark/Light toggle premium con iconos animados
- Search command palette (⌘K) con fuzzy search
- Reading progress bar, TOC sticky, reading time

### FASE 5: Design System Showcase Premium (Día 6)

Reemplazar `gv-design-system-catalog` por **Showcase Premium v3**:
- Interactive playground con todos los componentes
- Token visualizer con copy-to-clipboard
- Theme builder (color picker, preview)
- Accessibility auditor integrado
- Code snippets copy-to-clipboard
- Figma export button
- Component playground con knobs

### FASE 6: Sincronización Total + Documentación (Día 7)

- [ ] Actualizar `assets/gv-design-system.css` → generated from v3 tokens
- [ ] Actualizar `packages/gv-design-system` → v3.0.0
- [ ] Sincronizar `assets/logo.svg` + `logo-gv.svg` en todas las apps
- [ ] Actualizar `command-center` para servir DS v3
- [ ] Documentation: `DESIGN.md`, `COMPONENTS.md`, `TOKENS.md`, `MIGRATION.md`
- [ ] Visual regression tests baseline
- [ ] Accessibility audit (axe-core)
- [ ] Performance audit (lighthouse)

---

## 📦 Entregables Finales

| Entregable | Ubicación |
|---|---|
| **Tokens v3 Locked** | `packages/gv-design-system/src/tokens/tokens.json` |
| **CSS Tokens** | `packages/gv-design-system/tokens.css` (generated) |
| **React Components** | `packages/gv-design-system/src/components/` |
| **CSS Vanilla** | `packages/gv-design-system/components.css` |
| **Tokens CSS** | `packages/gv-design-system/tokens.css` |
| **TypeScript Types** | `packages/gv-design-system/src/tokens/tokens.ts` |
| **Tailwind Config** | `packages/gv-design-system/tailwind.config.ts` |
| **Showcase Premium** | `apps/gv-design-system-showcase/` (reemplaza catalog) |
| **Academy Premium** | `apps/academy-web/` (migrated + premium) |
| **All Apps Migrated** | `apps/*/src/` using `@gentle-vanguard/design-system` |
| **Documentation** | `DESIGN.md`, `COMPONENTS.md`, `TOKENS.md`, `MIGRATION.md` |

---

## ✅ Criterios de Aceptación "10000%"

- [ ] **0 warnings** `impeccable detect` en todo el stack
- [ ] **WCAG 2.2 AA** passed (axe-core 0 violations)
- [ ] **Visual Regression** baseline established (playwright)
- [ ] **Lighthouse** Performance ≥95, Accessibility 100, Best Practices 100, SEO 100
- [ ] **Bundle size** DS v3 < 50kb gzipped (tree-shaken)
- [ ] **All 7 apps** using `@gentle-vanguard/design-system@3.0.0`
- [ ] **Academy Premium** = reference implementation
- [ ] **Showcase Premium** = interactive playground
- [ ] **Zero** legacy tokens in any app
- [ ] **Bundle analyzer** DS v3 < 50kb gzipped

---

## 🚀 Próximo Paso Inmediato

**EMPEZAR FASE 1 AHORA**: Lockear `tokens.json` v3.0 y generar build artifacts.