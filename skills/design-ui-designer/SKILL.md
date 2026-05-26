---
name: design-ui-designer
description: >
  UI Designer: visual design, component libraries, design systems, pixel-perfect interfaces.
  Trigger: "UI design", "component library", "design system", "pixel-perfect", "interface", "visual
  design".
---

## When to Use

- Creating visual designs and component libraries
- Building design systems for scalable development
- Implementing pixel-perfect designs with modern techniques
- Ensuring brand consistency across interfaces
- Creating responsive and accessible visual experiences

## 📋 Technical Deliverables

### Design System Structure

```
design-system/
  tokens/
    colors.json          # Design tokens for colors
    typography.json       # Font scales and weights
    spacing.json          # Spacing and layout tokens
  components/
    button.md            # Component specifications
    input.md
    modal.md
  patterns/
    forms.md             # Reusable patterns
    navigation.md
  brand/
    guidelines.md        # Brand application rules
    assets/              # Logos, icons, imagery
```

### Component Specification Example

```typescript
// Button Component Specification
interface ButtonSpec {
  variants: ['primary', 'secondary', 'ghost', 'danger'];
  sizes: ['sm', 'md', 'lg'];
  states: ['default', 'hover', 'active', 'disabled', 'loading'];
  icons: boolean; // Left/right icon support

  accessibility: {
    ariaLabel: string;
    keyboardNav: boolean;
    focusVisible: boolean;
  };

  responsive: {
    mobile: 'full-width | auto';
    desktop: 'auto | fixed';
  };
}
```

### Responsive Breakpoint System

```css
/* Mobile-first responsive system */
:root {
  /* Breakpoints */
  --bp-sm: 640px; /* Tablets */
  --bp-md: 768px; /* Small laptops */
  --bp-lg: 1024px; /* Desktops */
  --bp-xl: 1280px; /* Large screens */

  /* Container widths */
  --container-sm: 640px;
  --container-md: 768px;
  --container-lg: 1024px;
  --container-xl: 1280px;
}
```

## 🔄 Workflow Process

### Step 1: Design Discovery

- Analyze brand guidelines and existing design assets
- Research competitors and industry best practices
- Identify design patterns and component needs
- Create mood boards and style direction

### Step 2: Design System Creation

- Define design tokens (colors, typography, spacing)
- Build component library with variants and states
- Create pattern library for common interactions
- Document usage guidelines and do's/don'ts

### Step 3: Component Design

- Design components in Figma/Sketch with all states
- Create responsive variants for each breakpoint
- Ensure keyboard navigation and focus states
- Export assets in modern formats (SVG, WebP)

### Step 4: Handoff to Development

- Provide specs with measurements and spacing
- Include accessibility annotations (ARIA labels)

---

> **Referencia detallada**: [ eferences/detail.md](references/detail.md)
