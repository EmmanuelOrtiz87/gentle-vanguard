### Voice

- Professional but approachable
- Clear and concise
- Confident, not arrogant
- Helpful, not patronizing

### Tone by Context

| Situation      | Tone                           |
| -------------- | ------------------------------ |
| Error messages | Clear, solution-focused        |
| Success        | Celebratory but not excessive  |
| Onboarding     | Welcoming, guiding             |
| Technical docs | Precise, authoritative         |
| Marketing      | Enthusiastic, benefits-focused |

### Example Transformations

| Don't                             | Do                                            |
| --------------------------------- | --------------------------------------------- |
| "Your request has been processed" | "Done! Your request is complete"              |
| "An error occurred"               | "Something went wrong - here's how to fix it" |
| "You must upgrade"                | "Upgrade for pro features"                    |

````

---

## Brand Application Checklist

### Website

- [ ] Logo in header, linked to home
- [ ] Consistent navigation
- [ ] Brand colors in CTAs
- [ ] Typography hierarchy
- [ ] Footer with brand info

### Content

- [ ] Brand voice consistent
- [ ] No grammar/style violations
- [ ] Links use brand color
- [ ] Images follow brand style

### Email

- [ ] Logo in header
- [ ] Brand colors in buttons
- [ ] Consistent sender info
- [ ] Footer with unsubscribe

---

## Validation

### CSS Audit

```css
/* Check brand colors */
.brand-button {
  background: var(--color-primary);
}

/* Check font */
body {
  font-family: var(--font-body);
}
````

### Content Audit

```markdown
# Voice Check

- [ ] Conversational, not stiff
- [ ] First person where appropriate
- [ ] Active voice
- [ ] Short sentences
- [ ] No jargon
```

---

## Gentle-Vanguard Integration

```powershell
# Check brand consistency
.\gv.ps1 brand check

# Validate colors
.\gv.ps1 brand validate-colors

# Check copy voice
.\gv.ps1 brand check-voice
```

---

## Template

### brand.css

```css
:root {
  /* Brand Colors */
  --brand: #3b82f6;
  --brand-dark: #1d4ed8;
  --brand-light: #60a5fa;

  /* Brand Fonts */
  --font-brand: 'Inter', system-ui;

  /* Spacing */
  --space-xs: 0.25rem;
  --space-sm: 0.5rem;
  --space-md: 1rem;
  --space-lg: 2rem;
  --space-xl: 4rem;
}

/* Brand Button */
.btn-brand {
  background: var(--brand);
  color: white;
  padding: var(--space-sm) var(--space-md);
  border-radius: 0.5rem;
  font-family: var(--font-brand);
}
```

### brand-content.md

```markdown
# Brand Voice

Our voice is:

- Friendly but professional
- Direct and clear
- Confident but humble
- Helpful and supportive

# Tone Adjustments

- Support: Empathetic, solution-focused
- Marketing: Enthusiastic, benefit-driven
- Docs: Clear, authoritative
```
