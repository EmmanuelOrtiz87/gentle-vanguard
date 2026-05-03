---
version: "alpha"
name: "Gentleman Foundation"
description: "Design system for workspace-foundation: agnostic, minimal, ASCII-only documentation and tooling"
colors:
  primary: "#1A1C1E"
  secondary: "#4A5568"
  background: "#FFFFFF"
  surface: "#F7FAFC"
  text: "#1A202C"
  text-secondary: "#718096"
  border: "#E2E8F0"
  success: "#38A169"
  warning: "#D69E2E"
  error: "#E53E3E"
typography:
  mono:
    fontFamily: "Consolas, Monaco, 'Courier New', monospace"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: "1.5"
  body:
    fontFamily: "system-ui, -apple-system, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: "1.6"
  heading:
    fontFamily: "system-ui, -apple-system, sans-serif"
    fontSize: "24px"
    fontWeight: 600
    lineHeight: "1.3"
layout:
  spacing-xs: "4px"
  spacing-sm: "8px"
  spacing-md: "16px"
  spacing-lg: "24px"
  spacing-xl: "32px"
  max-width: "1200px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.background}"
    rounded: "4px"
    padding: "8px 16px"
    typography: "{typography.body}"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.primary}"
    rounded: "4px"
    padding: "8px 16px"
    border: "1px solid {colors.primary}"
  code-block:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text}"
    typography: "{typography.mono}"
    padding: "16px"
    rounded: "4px"
  table:
    border: "1px solid {colors.border}"
    textColor: "{colors.text}"
    typography: "{typography.body}"
  link:
    textColor: "{colors.primary}"
    textDecoration: "underline"
---

## 1. Overview

Gentleman Foundation uses a minimal, agnostic design system focused on readability and utility. The visual identity prioritizes:

- Monospace fonts for code and technical content
- System fonts for UI and documentation
- High contrast for accessibility (WCAG AA compliant)
- ASCII-only characters (no emojis) for maximum compatibility
- Minimal color palette to reduce cognitive load

## 2. Colors

| Token | Hex | Role |
|-------|-----|------|
| primary | #1A1C1E | Headings, primary actions, borders |
| secondary | #4A5568 | Secondary text, metadata |
| background | #FFFFFF | Page backgrounds |
| surface | #F7FAFC | Code blocks, cards, elevated surfaces |
| text | #1A202C | Body text |
| text-secondary | #718096 | Captions, hints |
| border | #E2E8F0 | Table borders, dividers |
| success | #38A169 | Success messages, positive indicators |
| warning | #D69E2E | Warning messages, cautions |
| error | #E53E3E | Error messages, destructive actions |

All color pairs meet WCAG AA contrast ratio (4.5:1 minimum).

## 3. Typography

Three typefaces serve different purposes:

**Mono**: Code blocks, terminal output, technical references. Uses Consolas/Monaco for consistent character width.

**Body**: Documentation prose, descriptions, instructions. Uses system-ui for native feel across platforms.

**Heading**: Section titles, document headers. Slightly larger, semi-bold weight for clear hierarchy.

## 4. Layout

Spacing follows a 4px base unit (4, 8, 16, 24, 32px). This creates consistent rhythm without complex calculations.

Max-width of 1200px prevents overly long line lengths on large screens. Content centers with auto margins.

## 5. Elevation & Depth

Foundation uses minimal elevation. Surfaces use background color with subtle borders. No shadows - keeps the ASCII-aesthetic consistent.

Code blocks use surface color (#F7FAFC) to create visual separation without depth effects.

## 6. Shapes

Border radius of 4px on all components. This creates a subtle rounded feel without being decorative.

Buttons, inputs, and containers all share this 4px radius for consistency.

## 7. Components

**Buttons**: Primary buttons use primary color background with white text. Secondary buttons are transparent with primary color border.

**Code blocks**: Surface background with monospace font. Padding of 16px creates comfortable reading space.

**Tables**: 1px borders with system body font. Alternating rows not needed - border provides sufficient separation.

**Links**: Primary color with underline. No hover effects - keeps behavior predictable.

## 8. Do's and Don'ts

**Do**:
- Use monospace for code, system font for prose
- Maintain WCAG AA contrast ratios
- Keep line lengths under 120 characters
- Use ASCII characters only (no emojis)
- Follow the 4px spacing scale

**Don't**:
- Use decorative fonts or emojis
- Create color pairs below 4.5:1 contrast
- Mix spacing units (stick to 4px base)
- Add shadows or gradients
- Use rounded corners greater than 4px
