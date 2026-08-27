---
name: brand-guidelines-gv
description: Applies the Gentle-Vanguard official brand system (azure #00BFFF on dark #0D1117, purple accent #A855F7, semantic colors) to decks, docs and artifacts. Use when a deliverable needs to look GV-branded — 'hazlo GV', 'aplica la marca', brand consistency, visual identity post-processing.
metadata:
  source: external-adopted
  upstream: anthropics/skills (skills/brand-guidelines)
  license: Apache-2.0
---

# Gentle-Vanguard Brand Styling (GV-native reskin)

## Overview

Official GV brand system (source of truth: `assets/tokens.json` + GENTLE_VANGUARD_MASTER/13-brand-system).

**Keywords**: branding, corporate identity, visual identity, post-processing, styling, brand colors, typography, GV brand, Gentle-Vanguard, visual formatting

## Brand Guidelines

### Colors

**Main Colors:**

- Background: `#0D1117` - Deep dark canvas (GV base)
- Surface: `#1A2035` - Cards/panels over background
- Text Primary: `#FFFFFF` / Text Muted: `#6B7280`
- Border: `#1E3A5F` - Subtle structural lines

**Accent Colors:**

- Primary (Azure): `#00BFFF` - Brand main (light variant `#4DCFFF`, dark `#0055BB`)
- Accent (Purple): `#A855F7` - Highlights/CTA
- Accent Teal: `#06B6D4` - Secondary data accents
- Semantic: success `#22C55E`, warning `#F59E0B`, error `#EF4444`

### Typography

- **Headings**: Poppins (with Arial fallback)
- **Body Text**: Lora (with Georgia fallback)
- **Note**: Fonts should be pre-installed in your environment for best results

## Features

### Smart Font Application

- Applies geometric sans (Poppins or Montserrat) to headings (24pt and larger) — per 13-brand-system
- Applies Inter font to body text — per 13-brand-system (geometric sans family)
- Automatically falls back to Arial/Georgia if custom fonts unavailable
- Preserves readability across all systems

### Text Styling

- Headings (24pt+): Poppins font
- Body text: Lora font
- Smart color selection based on background
- Preserves text hierarchy and formatting

### Shape and Accent Colors

- Non-text shapes use accent colors
- Cycles through orange, blue, and green accents
- Maintains visual interest while staying on-brand

## Technical Details

### Font Management

- Uses system-installed Poppins and Lora fonts when available
- Provides automatic fallback to Arial (headings) and Georgia (body)
- No font installation required - works with existing system fonts
- For best results, pre-install Poppins and Lora fonts in your environment

### Color Application

- Uses RGB color values for precise brand matching
- Applied via python-pptx's RGBColor class
- Maintains color fidelity across different systems
