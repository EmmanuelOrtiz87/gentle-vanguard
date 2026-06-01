---
name: web-performance-optimization
description: >
  Optimize web application performance using code splitting, lazy loading, caching, compression, and
  monitoring. Use when improving Core Web Vitals and user experience.
metadata:
  source: GV-native
---

# Web Performance Optimization

## Table of Contents

- [Overview](#overview)
- [When to Use](#when-to-use)
- [Quick Start](#quick-start)
- [Best Practices](#best-practices)

## Overview

Implement performance optimization strategies including lazy loading, code splitting, caching,
compression, and monitoring to improve Core Web Vitals and user experience.

## When to Use

- Slow page load times
- High Largest Contentful Paint (LCP)
- Large bundle sizes
- Frequent Cumulative Layout Shift (CLS)
- Mobile performance issues

## Quick Start

Minimal working example:

```typescript
// utils/lazyLoad.ts
import React from 'react';

export const lazyLoad = (importStatement: Promise<any>) => {
  return React.lazy(() =>
    importStatement.then(module => ({
      default: module.default
    }))
  );
};

// routes.tsx
import { lazyLoad } from './utils/lazyLoad';

export const routes = [
  {
    path: '/',
    component: () => import('./pages/Home'),
    lazy: lazyLoad(import('./pages/Home'))
  },
  {
    path: '/dashboard',
    lazy: lazyLoad(import('./pages/Dashboard'))
  },
  {
// ... (expand this skeleton directly in this skill when needed)
```

Replace this section with native examples and checklists directly in this skill when extending it.

## Best Practices

### DO

- Follow established patterns and conventions
- Write clean, maintainable code
- Add appropriate documentation
- Test thoroughly before deploying

### DON'T

- Skip testing or validation
- Ignore error handling
- Hard-code configuration values
