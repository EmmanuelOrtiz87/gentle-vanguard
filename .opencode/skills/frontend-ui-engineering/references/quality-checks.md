# Quality Checks

## Common Rationalizations

| Rationalization                                | Reality                                                                                      |
| ---------------------------------------------- | -------------------------------------------------------------------------------------------- |
| "Accessibility is a nice-to-have"              | It's a legal requirement in many jurisdictions and an engineering quality standard.          |
| "We'll make it responsive later"               | Retrofitting responsive design is 3x harder than building it from the start.                 |
| "The design isn't final, so I'll skip styling" | Use the design system defaults. Unstyled UI creates a broken first impression for reviewers. |
| "This is just a prototype"                     | Prototypes become production code. Build the foundation right.                               |
| "The AI aesthetic is fine for now"             | It signals low quality. Use the project's actual design system from the start.               |

## Red Flags

- Components with more than 200 lines (split them)
- Inline styles or arbitrary pixel values
- Missing error states, loading states, or empty states
- No keyboard navigation testing
- Color as the sole indicator of state (red/green without text or icons)
- Generic "AI look" (purple gradients, oversized cards, stock layouts)

## Verification Checklist

After building UI:

- [ ] Component renders without console errors
- [ ] All interactive elements are keyboard accessible (Tab through the page)
- [ ] Screen reader can convey the page's content and structure
- [ ] Responsive: works at 320px, 768px, 1024px, 1440px
- [ ] Loading, error, and empty states all handled
- [ ] Follows the project's design system (spacing, colors, typography)
- [ ] No accessibility warnings in dev tools or axe-core
