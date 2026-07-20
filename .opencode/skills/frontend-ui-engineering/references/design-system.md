# Design System Adherence

## Avoid the AI Aesthetic

AI-generated UI has recognizable patterns. Avoid all of them:

| AI Default                       | Why It Is a Problem                                                                           | Production Quality                                      |
| -------------------------------- | --------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| Purple/indigo everything         | Models default to visually "safe" palettes, making every app look identical                   | Use the project's actual color palette                  |
| Excessive gradients              | Gradients add visual noise and clash with most design systems                                 | Flat or subtle gradients matching the design system     |
| Rounded everything (rounded-2xl) | Maximum rounding signals "friendly" but ignores the hierarchy of corner radii in real designs | Consistent border-radius from the design system         |
| Generic hero sections            | Template-driven layout with no connection to the actual content or user need                  | Content-first layouts                                   |
| Lorem ipsum-style copy           | Placeholder text hides layout problems that real content reveals (length, wrapping, overflow) | Realistic placeholder content                           |
| Oversized padding everywhere     | Equal generous padding destroys visual hierarchy and wastes screen space                      | Consistent spacing scale                                |
| Stock card grids                 | Uniform grids are a layout shortcut that ignores information priority and scanning patterns   | Purpose-driven layouts                                  |
| Shadow-heavy design              | Layered shadows add depth that competes with content and slows rendering on low-end devices   | Subtle or no shadows unless the design system specifies |

## Spacing and Layout

Use a consistent spacing scale. Don't invent values:

```css
/* Use the scale: 0.25rem increments (or whatever the project uses) */
/* Good */
padding: 1rem; /* 16px */
/* Good */
gap: 0.75rem; /* 12px */
/* Bad */
padding: 13px; /* Not on any scale */
/* Bad */
margin-top: 2.3rem; /* Not on any scale */
```

## Typography

Respect the type hierarchy:

```
h1 → Page title (one per page)
h2 → Section title
h3 → Subsection title
body → Default text
small → Secondary/helper text
```

Don't skip heading levels. Don't use heading styles for non-heading content.

## Color

- Use semantic color tokens: `text-primary`, `bg-surface`, `border-default` — not raw hex values
- Ensure sufficient contrast (4.5:1 for normal text, 3:1 for large text)
- Don't rely solely on color to convey information (use icons, text, or patterns too)
