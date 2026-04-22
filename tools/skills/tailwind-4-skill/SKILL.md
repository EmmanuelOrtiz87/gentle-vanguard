---
name: tailwind-4-skill
description: >
  Tailwind CSS 4 patterns: cn() utility, theme variables, no var() in className.
  Trigger: "Tailwind", "Tailwind CSS", "cn()", "className", "tailwind-4".
---

## When to Use

- Styling with Tailwind CSS
- Component styling
- Responsive design
- Dark mode

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
@import "tailwindcss";
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
|------------|--------|
| 640px | sm: |
| 768px | md: |
| 1024px | lg: |
| 1280px | xl: |
| 1536px | 2xl: |

## Dark Mode

```tsx
<div className="bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
  Content
</div>
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

| Pattern | Code |
|---------|------|
| Conditional | `cn("base", condition && "active")` |
| Dark mode | `dark:bg-gray-900` |
| Responsive | `md:grid-cols-2` |
| Hover | `hover:bg-blue-600` |
| Focus | `focus:ring-2` |
| Group hover | `group-hover:opacity-100` |
