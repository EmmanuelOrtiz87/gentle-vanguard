---
name: brand-guide-skill
description: >
  Brand consistency: colors, typography, voice, tone, identity.
  Trigger: "brand", "brand guide", "brand identity", "branding", "voice", "tone",
  "visual identity", "logo usage", "brand colors"
license: Apache-2.0
metadata:
  author: gentleman-programming
  versión: "1.0"
allowed-tools: Read, Edit, Write, Glob, Grep, Bash, Task
---

# Brand Guide Skill

Maintain brand consistency across all touchpoints.

## When to Use

**USE this skill when:**
- Creating new pages/components
- Writing content
- Designing communications
- Establishing brand identity

**DON'T use when:**
- No brand guidelines exist (create first)
- Brand already consistent (not needed)

---

## Brand Elements

### 1. Color Palette

```css
:root {
  /* Primary - Brand Color */
  --brand-50: #eff6ff;
  --brand-100: #dbeafe;
  --brand-500: #3b82f6;
  --brand-600: #2563eb;
  --brand-700: #1d4ed8;
  --brand-900: #1e3a8a;
  
  /* Semantic */
  --color-primary: var(--brand-500);
  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-error: #ef4444;
  
  /* Neutrals */
  --gray-50: #f9fafb;
  --gray-900: #111827;
}
```

### 2. Typography

```css
:root {
  /* Display - Headlines */
  --font-display: 'Inter', system-ui, sans-serif;
  
  /* Body - Content */
  --font-body: 'Inter', system-ui, sans-serif;
  
  /* Mono - Code */
  --font-mono: 'Fira Code', monospace;
  
  /* Scale */
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem;
  --text-3xl: 1.875rem;
  --text-4xl: 2.25rem;
}
```

### 3. Logo Usage

```markdown
## Logo Guidelines

### Clear Space
- Maintain 2x letter height clear space around logo
- Never place logo on competing colors

### Minimum Size
- Print: 1 inch / 25mm
- Digital: 32px height

### Don'ts
- [NO] Stretch or distort
- [NO] Rotate
- [NO] Change colors
- [NO] Add effects
- [NO] Place on busy backgrounds
```

### 4. Voice & Tone

```markdown
## Voice Guidelines

### Voice
- Professional but approachable
- Clear and concise
- Confident, not arrogant
- Helpful, not patronizing

### Tone by Context
| Situation | Tone |
|-----------|------|
| Error messages | Clear, solution-focused |
| Success | Celebratory but not excessive |
| Onboarding | Welcoming, guiding |
| Technical docs | Precise, authoritative |
| Marketing | Enthusiastic, benefits-focused |

### Example Transformations
|  Don't |  Do |
|----------|-----|
| "Your request has been processed" | "Done! Your request is complete" |
| "An error occurred" | "Something went wrong - here's how to fix it" |
| "You must upgrade" | "Upgrade for pro features" |
```

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
```

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

## Foundation Integration

```powershell
# Check brand consistency
.\wf.ps1 brand check

# Validate colors
.\wf.ps1 brand validate-colors

# Check copy voice
.\wf.ps1 brand check-voice
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
