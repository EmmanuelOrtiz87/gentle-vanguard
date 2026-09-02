---
name: brand-design-systems
description: Reference library of 74 real brand design systems (Nike, Tesla, SpaceX, Linear, Apple, Figma, etc.) with complete color palettes, typography scales, spacing, and design tokens. Use when you need authentic professional brand references for enterprise designs, need to match a specific brand aesthetic, or want to understand how top companies approach design systems.
triggers:
  - brand design
  - brand system
  - design tokens
  - color palette
  - typography scale
  - enterprise design
  - professional design
  - brand reference
  - linear style
  - apple design
  - nike design
  - figma style
  - tesla design
  - spacex aesthetic
metadata:
  source: external-adopted
  upstream: VoltAgent/awesome-design-md
  license: MIT
  version: 1.0.0
  brands_count: 74
  description: "Collection of 74 real brand design systems for AI coding agents"
---

# Brand Design Systems Reference Library

> 74 authentic brand design systems from the world's best companies. Drop one into your project as a reference for professional, enterprise-grade design.

## Overview

This skill provides access to 74 real-world design systems from top companies including:
- **Tech/Productivity**: Linear, Figma, Notion, Raycast, Cursor, Claude, OpenCode
- **Automotive**: Tesla, BMW, Ferrari, Lamborghini, Bugatti, Renault
- **Fashion/Sports**: Nike, Apple
- **Finance**: Revolut, Coinbase, Binance, Kraken, Mastercard
- **Social/Content**: Pinterest, Meta, Nintendo, PlayStation
- **Developer Tools**: HashiCorp, MongoDB, NVIDIA, Mistral, Ollama, Replicate
- **And 50+ more...**

## How to Use

### 1. Browse Available Brands

List all available brand design systems:
```
Brand directory: .opencode/skills/brand-design-systems/brands/
```

### 2. Reference a Brand for Design

When designing for a specific aesthetic, reference the brand's DESIGN.md:

**Example - Linear-style dark interface:**
```bash
# Reference Linear's tokens for a dark productivity app
# Use: colors.canvas = "#010102", accent = "#5e6ad2", typography from Linear Display
```

**Example - Apple-inspired minimal interface:**
```bash
# Reference Apple's design language
# Focus on: subtle gradients, SF Pro typography, frosted glass, generous whitespace
```

### 3. Extract Specific Tokens

Each brand's DESIGN.md contains:
- **colors**: Primary, surface, ink, semantic colors
- **typography**: Display, headline, body, caption scales
- **spacing**: Token-based spacing system
- **effects**: Shadows, borders, radius values

## Featured Brands by Category

### Dark/Minimal (Enterprise SaaS)
| Brand | Aesthetic |
|-------|-----------|
| Linear | Near-black (#010102) with lavender accent |
| Claude | Dark with warm undertones |
| Cursor | Dark IDE aesthetic |
| Notion | Clean white/light gray |
| Figma | White with purple accents |

### Premium/Luxury
| Brand | Aesthetic |
|-------|-----------|
| Ferrari | Racing red, performance-focused |
| Lamborghini | Bold geometric, aggressive |
| Bugatti | Ultra-luxury, heritage |
| BMW M | Performance motorsport |

### Tech/Developer
| Brand | Aesthetic |
|-------|-----------|
| HashiCorp | Infrastructure tooling |
| MongoDB | Green/leaf-inspired |
| NVIDIA | GPU-deep learning |
| Ollama | Local AI aesthetic |

### Finance/Crypto
| Brand | Aesthetic |
|-------|-----------|
| Revolut | Modern fintech dark |
| Coinbase | Trustworthy blue |
| Binance | Professional trading |
| Kraken | Bold crypto brand |

## Quick Reference - Top 10 Most Popular

1. **linear.app** - Dark productivity, lavender accent, craft-focused
2. **figma** - Creative tool, purple brand, collaborative
3. **notion** - Clean, modular, document-first
4. **raycast** - Spotlight-style, developer-focused
5. **cursor** - AI-first IDE, dark theme
6. **claude** - Thoughtful AI, warm dark
7. **revolut** - Fintech dark mode, premium feel
8. **apple** - Human interface guidelines, minimal
9. **nike** - Athletic, bold, motion-driven
10. **tesla** - Automotive minimal, futuristic

## Design Token Structure

Each brand follows a consistent structure:

```yaml
colors:
  primary: "#hex"
  on-primary: "#hex"
  canvas: "#hex"         # Background
  surface-1: "#hex"      # Cards/panels
  ink: "#hex"            # Primary text
  ink-muted: "#hex"      # Secondary text

typography:
  display-xl: { fontSize, fontWeight, lineHeight, letterSpacing }
  headline: { ... }
  body: { ... }
  caption: { ... }

spacing:
  # Token-based spacing system (often 4px/8px base)

effects:
  # Shadows, borders, radius values
```

## Integration Tips

- **For dark enterprise apps**: Use Linear, Claude, or Revolut as reference
- **For consumer apps**: Use Nike, Apple, or Figma for inspiration
- **For developer tools**: Use HashiCorp, Raycast, or Cursor patterns
- **For fintech**: Use Revolut or Coinbase color systems
- **For automotive luxury**: Reference Ferrari, Lamborghini, or BMW M

## Adding More Brands

To add more brands:
1. Find a company's design system or analyze their UI
2. Create a folder in `brands/<brand-name>/`
3. Add `DESIGN.md` with color, typography, and token definitions
4. Follow the existing format from other brands

## License

This collection is compiled from publicly available design system analyses.
Individual brand designs are property of their respective owners.