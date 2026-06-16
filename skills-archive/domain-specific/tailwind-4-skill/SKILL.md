---
name: tailwind-4-skill
description: >
  Tailwind CSS 4 patterns: cn() utility, theme variables, no var() in className. Trigger:
  "Tailwind", "Tailwind CSS", "cn()", "className", "tailwind-4", "frontend", "UI", "interface".
metadata:
  source: GV-native
---

## When to Use

- Styling with Tailwind CSS
- Component styling
- Responsive design
- Dark mode
- Building production-grade UI interfaces

## Anti-AI-Slop Design Guidelines

**CRITICAL**: Avoid generic AI aesthetics. Apply these principles:

### 1. Bold Color Choices

```css
/* Instead of default blue */
--color-primary: #8b5cf6; /* Violet instead of blue */
--color-accent: #f43f5e; /* Rose for highlights */
--color-success: #10b981; /* Emerald */

/* Dark theme */
--bg-dark: #09090b;
--surface: #18181b;
```

### 2. Typography Excellence

```css
/* System fonts for performance */
--font-display: 'Inter', system-ui, sans-serif;

/* Use weight for hierarchy */
font-weight: 700; /* Bold headers */
font-weight: 400; /* Body */
letter-spacing: -0.025em; /* Display text */
```

### 3. Motion & Animation

```css
/* Page load stagger */
.hero * {
  animation: fadeUp 0.6s ease-out forwards;
  opacity: 0;
}
.hero *:nth-child(1) {
  animation-delay: 0ms;
}
.hero *:nth-child(2) {
  animation-delay: 100ms;
}
.hero *:nth-child(3) {
  animation-delay: 200ms;
}

@keyframes fadeUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Micro-interactions */
button:active {
  transform: scale(0.98);
}
.card:hover {
  transform: translateY(-2px);
}
```

### 4. Spacing & Layout

```css
/* Generous spacing */
.hero {
  padding: 6rem 2rem;
}
.card {
  padding: 1.5rem;
  gap: 1rem;
}

/* Grid layouts */
.grid-cols-auto {
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
}
```

### 5. Visual Depth

```css
/* Layer depth */
.card {
  background: #1e293b;

---

> **Referencia detallada**: [
eferences/detail.md](references/detail.md)
```
