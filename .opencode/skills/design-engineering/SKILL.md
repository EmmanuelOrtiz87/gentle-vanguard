---
name: design-engineering
description: Curated collection of design engineering skills for frontend development. Covers typography, color theory, motion design, interaction patterns, visual design, accessibility, and UI testing. Use when building professional frontend interfaces that need deep design knowledge.
triggers:
  - design engineering
  - typography
  - color theory
  - motion design
  - animation
  - interaction design
  - ui patterns
  - visual design
  - accessibility
  - color palette
  - font pairing
  - micro-interactions
  - animation timing
  - easing
  - motion principles
metadata:
  source: external-adopted
  upstream: ui-skills.com
  license: Various (curated)
  version: 1.0.0
  categories: 15+
  description: "Design engineering skills collection from ui-skills.com"
---

# Design Engineering Skills

> Comprehensive design engineering knowledge for building professional, enterprise-grade frontend interfaces.

## Categories

### 1. Typography (`skills/typography`)
- Font selection and pairing
- Type hierarchy and scale
- Reading optimization
- Web fonts performance
- Responsive typography

### 2. Color (`skills/color`)
- Color theory fundamentals
- Palette creation
- Accessible color combinations
- Dark mode design
- Brand color systems
- Color psychology

### 3. Motion (`skills/motion`)
- Animation principles
- Easing curves
- Transition timing
- Micro-interactions
- Page transitions
- Scroll-driven animations
- Physics-based motion

### 4. Interaction (`skills/interaction`)
- Click and tap behaviors
- Drag and drop patterns
- Form interactions
- Navigation patterns
- Modal and overlay behaviors
- Touch and gesture design

### 5. Visual (`skills/visual`)
- Layout systems
- Grid design
- Spacing and rhythm
- Visual hierarchy
- Iconography
- Photography and imagery
- Visual effects

### 6. Taste (`skills/taste`)
- Design quality judgment
- Avoiding AI slop
- Professional polish
- Brand consistency
- Design principles
- Aesthetic refinement

### 7. Accessibility (`skills/accessibility`)
- WCAG guidelines
- Screen reader support
- Keyboard navigation
- Focus management
- Color contrast
- ARIA patterns
- Inclusive design

### 8. Testing (`skills/testing`)
- Visual regression testing
- Component testing
- Cross-browser testing
- Accessibility testing
- Performance testing
- User flow testing

### 9. Frontend (`skills/frontend`)
- CSS architecture
- Component patterns
- Design system integration
- Responsive design
- Performance optimization
- Modern CSS features

### 10. Performance (`skills/performance`)
- Animation performance
- Rendering optimization
- Layout thrashing prevention
- GPU acceleration
- Lazy loading
- Code splitting

## Key Principles

### Typography Principles
- **Readability**: 16px minimum for body, 1.5 line-height
- **Hierarchy**: Clear size distinctions (4-5 steps)
- **Pairing**: One display font + one body font maximum
- **Metrics**: Consider x-height, cap height, measure

### Color Principles
- **Accessibility**: 4.5:1 contrast minimum for text
- **Meaning**: Colors carry semantic meaning
- **Balance**: 60-30-10 rule for distribution
- **Consistency**: Define semantic colors, not just palette

### Motion Principles
- **Purpose**: Every animation serves a function
- **Duration**: 150-300ms for micro, 300-500ms for major
- **Easing**: Use cubic-bezier for natural motion
- **Performance**: Transform and opacity only, avoid layout

### Interaction Principles
- **Feedback**: Every action needs visual feedback
- **Affordance**: Elements should show how to use them
- **Consistency**: Same actions same results across app
- **Recovery**: Easy to undo, clear error paths

## Design Systems Integration

When building with design systems:

1. **Use token values** from the design system
2. **Respect component APIs** and their variants
3. **Follow spacing and rhythm** of the system
4. **Apply brand colors** correctly
5. **Match typography scale** exactly

## Common Patterns

### Dark Mode
```css
/* Use semantic color tokens */
background: var(--color-canvas);
color: var(--color-ink);
border: var(--color-hairline);
```

### Responsive Typography
```css
/* Fluid typography */
font-size: clamp(1rem, 2vw + 0.5rem, 1.5rem);
```

### Performance Animation
```css
/* GPU-accelerated */
transform: translateX(0);
will-change: transform;
/* NOT: left, top, margin (layout thrashing) */
```

### Accessible Focus
```css
:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}
```

## Quality Checklist

Before shipping any UI:
- [ ] Typography hierarchy is clear
- [ ] Color contrast meets WCAG AA
- [ ] Focus states are visible
- [ ] Animations respect prefers-reduced-motion
- [ ] Touch targets are 44x44px minimum
- [ ] Loading states provide feedback
- [ ] Error states are clear and actionable
- [ ] Empty states are designed
- [ ] Loading is fast or shows skeleton

## Resources

- **Color**: Coolors.co, Adobe Color, CSS variables
- **Typography**: Google Fonts, Fontscale, Type Scale
- **Motion**: cubic-bezier.com, easings.net
- **Icons**: Heroicons, Lucide, Phosphor
- **Accessibility**: WebAIM, A11y Project

## Integration with Other Skills

This skill works alongside:
- **impeccable**: For design quality and anti-pattern detection
- **brand-design-systems**: For real brand references
- **modern-web-design**: For Gentle-Vanguard specific patterns
- **playwright-cli**: For visual testing and automation