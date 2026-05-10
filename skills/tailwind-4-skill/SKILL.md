---
name: tailwind-4-skill
description: >
  Tailwind CSS 4 patterns: cn() utility, theme variables, no var() in className. Trigger:
  "Tailwind", "Tailwind CSS", "cn()", "className", "tailwind-4", "frontend", "UI", "interface".
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
  border: 1px solid #334155;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.3);
}

/* Subtle gradients */
.bg-gradient-subtle {
  background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
}
```

### 6. Focus States

```css
/* Accessibility */
button:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}
```

---

## Design Principles Summary

| Aspect     | Generic AI   | Production Grade   |
| ---------- | ------------ | ------------------ |
| Colors     | Default blue | Bold palette       |
| Spacing    | Tight        | Generous           |
| Typography | Default      | Weighted hierarchy |
| Animation  | None         | Intentional motion |
| Shadows    | Flat         | Layered depth      |
| Borders    | None         | Subtle separation  |

## Project Setup

```json
// package.json
{
  "scripts": {
    "dev": "vite"
  },
  "dependencies": {
    "tailwindcss": "^4.0.0",
    "@tailwindcss/vite": "^4.0.0"
  }
}
```

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [tailwindcss()],
});
```

```css
/* main.css */
@import 'tailwindcss';
```

## cn() Utility

Use `cn()` for conditional classes:

```typescript
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// Usage
<div className={cn(
  "base-class",
  isActive && "active-class",
  isDisabled && "opacity-50 cursor-not-allowed"
)} />
```

## Theme Variables

Tailwind 4 uses CSS variables:

```css
@theme {
  --color-primary: #3b82f6;
  --color-secondary: #64748b;

  --radius-lg: 0.5rem;
  --radius-md: 0.375rem;

  --font-sans: 'Inter', system-ui, sans-serif;
  --font-mono: 'Fira Code', monospace;
}
```

## Common Patterns

```tsx
// Button
<button className="
  px-4 py-2
  bg-blue-500 hover:bg-blue-600
  text-white
  rounded-lg
  transition-colors
  disabled:opacity-50 disabled:cursor-not-allowed
">
  Click me
</button>

// Card
<div className="
  bg-white dark:bg-gray-900
  rounded-xl
  border border-gray-200 dark:border-gray-800
  shadow-sm
  p-6
">
  {children}
</div>

// Input
<input
  className="
    w-full
    px-3 py-2
    border border-gray-300 dark:border-gray-700
    rounded-lg
    focus:outline-none focus:ring-2 focus:ring-blue-500
    placeholder:text-gray-400
  "
/>

// Grid
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  {items.map(item => <Card key={item.id} {...item} />)}
</div>
```

## Responsive Design

```tsx
<div className="
  /* Mobile first */
  grid-cols-1
  /* Tablet */
  md:grid-cols-2
  /* Desktop */
  lg:grid-cols-4
">
```

| Breakpoint | Prefix |
| ---------- | ------ |
| 640px      | sm:    |
| 768px      | md:    |
| 1024px     | lg:    |
| 1280px     | xl:    |
| 1536px     | 2xl:   |

## Dark Mode

```tsx
<div className="bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">Content</div>
```

```typescript
// Toggle dark mode
document.documentElement.classList.toggle('dark');
```

## Animations

```tsx
<div className="animate-spin">Loading...</div>
<div className="animate-pulse">Pulse</div>
<div className="animate-bounce">Bounce</div>
```

## Quick Reference

| Pattern     | Code                                |
| ----------- | ----------------------------------- |
| Conditional | `cn("base", condition && "active")` |
| Dark mode   | `dark:bg-gray-900`                  |
| Responsive  | `md:grid-cols-2`                    |
| Hover       | `hover:bg-blue-600`                 |
| Focus       | `focus:ring-2`                      |
| Group hover | `group-hover:opacity-100`           |
