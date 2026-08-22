# Design System Patterns

Premium UI design system patterns: typography, color theory, component design and
accessibility. Complemented by the native tooling in `src/design/design-tokens.ts` and
`src/design/design-system-cli.ts`.

## Design Tokens

Design tokens are the atomic values of a design system. Use them everywhere —
never hardcode raw values.

```css
/* Bad — magic values scattered through components */
.button { background: #6366f1; padding: 13px; border-radius: 9px; }

/* Good — semantic tokens */
.button {
  background: var(--color-primary-600);
  padding: var(--space-3);
  border-radius: var(--radius-md);
}
```

### Token layers

1. **Primitive tokens** — raw values: color steps, px sizes, rem values
2. **Semantic tokens** — purpose-bound aliases: `--color-primary`, `--text-body`,
   `--space-md`
3. **Component tokens** — scoped to a component: `--button-bg`, `--button-hover`

Semantic tokens make a theme changeable without touching components.

## Typography

### Modular scale

Sizes derive from a base size × a musical ratio. Pick one ratio and use it
consistently across the UI:

| Ratio            | Value | Character                |
| ---------------- | ----- | ------------------------ |
| Minor second     | 1.067 | Subtle, dense UIs        |
| Major second     | 1.125 | Compact dashboards       |
| Minor third      | 1.2   | Common default           |
| Major third      | 1.25  | Balanced, friendly       |
| Perfect fourth   | 1.333 | Airy, editorial          |
| Augmented fourth | 1.414 | Dramatic, marketing      |
| Perfect fifth    | 1.5   | Extreme hierarchy        |
| Golden ratio     | 1.618 | Expressive, poster-like  |

Generate a scale with:

```bash
npm run design:scale -- --base 16 --ratio 1.25 --levels 12
```

### Type hierarchy rules

- One `h1` per page — the page title
- `h2` sections, `h3` subsections; don't skip levels
- Body text ≥ 16px; never below 14px for reading content
- Line-height: 1.5 for body, 1.1–1.3 for headings
- Max line length 45–75 characters (about 60–75ch for desktop)
- Uppercase + letter-spacing only for micro-labels (caption/overline), never body

### Font pairing

- **Display** font: geometric/serif, for headings only (2–3 sizes max)
- **Body** font: highly legible sans, for all prose and UI chrome
- **Mono** font: code, numbers, timestamps, data tables

Keep to two families in a product UI (display + body); mono is a utility.

## Color Theory

### The color wheel (basics)

- **Primary** — the brand color, used sparingly for emphasis and key actions
- **Secondary** — a supporting hue, complements primary (analogous or complementary)
- **Accent** — a high-energy pop for highlights, badges, focus states
- **Neutral** — grays/graystone for text, borders, surfaces (the real workhorse)

### Hue relationships

| Relationship     | Angle   | Effect                                    |
| ---------------- | ------- | ----------------------------------------- |
| Complementary    | 180°    | High contrast, energetic — use sparingly  |
| Analogous        | 30°     | Harmonious, calm                          |
| Triadic          | 120°    | Balanced color pops                       |
| Split-complement | 150°    | Contrast with less tension                |
| Monochromatic    | same    | Sophisticated, safe                       |

### Color scales

Never use one shade of a hue. Every hue needs a **scale** (11 steps, 50–950):

- `50–200` — backgrounds, surfaces, subtle fills
- `300–500` — borders, secondary fills, mid-tones
- `600–800` — primary actions, interactive text
- `900–950` — high-contrast text on light backgrounds

Generate a scale:

```bash
npm run design:generate -- --primary "#6366f1" --neutral slate
```

### Semantic colors

- **success** (green) — confirmations, positive feedback
- **warning** (amber) — caution, pending, degraded
- **error** (red) — destructive actions, failures
- **info** (blue) — neutral announcements

Always pair semantic color with an icon or label — never color alone.

### 60-30-10 rule

60% neutral (backgrounds/surfaces), 30% secondary (supporting elements),
10% primary/accent (calls-to-action, highlights).

## Spacing

Use a 4px/8px base grid. Never invent intermediate values:

```
0, 0.5(2), 1(4), 1.5(6), 2(8), 2.5(10), 3(12), 3.5(14), 4(16), 5(20),
6(24), 8(32), 10(40), 12(48), 14(56), 16(64)   →   rem = px / 16
```

- Buttons/inputs: height multiples of 8px (32/40/48)
- Card padding: 16–24px; section gaps: 24–48px
- In-component gaps align with the scale; cross-component rhythm stays consistent

## Border Radius

Corner radius communicates surface character:

- `sm` (4px) — dense controls, inputs, table cells
- `md` (6px) — buttons, small cards
- `lg` (8px) — cards, modals, dropdowns
- `xl` (12px) — large surfaces, dialogs
- `full` (9999px) — pills, avatars, icon buttons

Limit to 3 radii per product. Don't round everything to max.

## Elevation / Shadows

Shadows encode layering. Keep them subtle:

- `xs`/`sm` — hover states, sticky headers
- `md` — default cards, dropdowns
- `lg` — modals, popovers, floating actions
- `xl`/`2xl` — full-screen overlays, drawers

Prefer borders + subtle backgrounds over heavy shadows for surfaces.

## Component Patterns

### Buttons

- One primary action per view; secondary + ghost for the rest
- Height ≥ 40px (touch target ≥ 44px on mobile)
- Clear hover/active/focus-visible/disabled states
- Loading and disabled states must be distinguishable from each other

### Forms

- Labels always visible; placeholder is not a label
- Error message tied to the input (`aria-describedby`), not just a red border
- Validation on blur, submit on enter; inline inline help stays quiet until needed

### Cards & surfaces

- Consistent padding from the spacing scale
- Header + body + optional footer structure
- Elevation communicates interaction: flat → hover lift → selected

### Navigation

- Current state must be evident beyond color (underline/icon + color)
- Mobile nav collapses with hamburger; keep ≥ 44px targets
- Breadcrumbs for deep hierarchies

## Accessibility (WCAG 2.1 AA minimum)

| Requirement        | Threshold     | Notes                                   |
| ------------------ | ------------- | --------------------------------------- |
| Text contrast      | 4.5:1         | Normal text (18px / 14px bold and under)|
| Large text contrast| 3:1           | ≥ 18pt / 14pt bold                      |
| UI component contrast | 3:1       | Inputs, icons, focus indicators         |
| Non-text contrast  | 3:1           | Borders of inputs, focus rings          |

Check any pairing with:

```bash
npm run design:check -- --fg "#FFFFFF" --bg "#0F172A"
# or scan a component file
npm run design:check -- ./components/Button.tsx
```

### Color accessibility rules

- Never rely on color alone for meaning (WCAG 1.4.1)
- Focus indicators must have 3:1 contrast against adjacent colors
- White-on-primary often fails AA — verify every primary step before using it
  for text

### Tips

- Test grayscale first: if the design loses meaning, add icons/text
- Use `accessibleTextOn()` to pick automatic white/black text per background
- Keep interactive color pairs (button text on button bg) ≥ 4.5:1
