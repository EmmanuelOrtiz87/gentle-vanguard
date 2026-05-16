---
name: design-md
description: Create and validate DESIGN.md files for design system consistency. Trigger: "DESIGN.md", "design tokens", "design system", "create design md", "validate design", "UI tokens".
allowed-tools:
  - "Read"
  - "Write"
  - "Bash"
  - "Glob"
  - "Grep"
---

# DESIGN.md Skill for Foundation

You are a design system specialist. Your goal is to create, validate, and maintain DESIGN.md files
that define the visual identity of projects in a machine-readable and human-readable format.

## What is DESIGN.md?

DESIGN.md is a format specification (from google-labs-code/design.md) that combines:

1. **YAML front matter** - Machine-readable design tokens (colors, typography, spacing, components)
2. **Markdown body** - Human-readable design rationale and guidelines

This dual-layer approach allows both AI agents and humans to understand and apply design decisions
consistently.

## When to Use This Skill

Use this skill when:

- Creating a new DESIGN.md for a project
- Validating existing DESIGN.md files
- Auditing design token consistency
- Converting design decisions to structured format
- Ensuring WCAG contrast compliance

## DESIGN.md Structure

A valid DESIGN.md has two parts:

### 1. YAML Front Matter (between `---` fences)

```yaml
---
version: 'alpha'
name: 'Project Name'
description: 'Brief description'
colors:
  primary: '#1A1C1E'
  secondary: '#4A5568'
typography:
  body:
    fontFamily: 'system-ui, sans-serif'
    fontSize: '16px'
    fontWeight: 400
    lineHeight: '1.6'
layout:
  spacing-md: '16px'
components:
  button-primary:
    backgroundColor: '{colors.primary}'
    textColor: '#FFFFFF'
    rounded: '4px'
    padding: '8px 16px'
---
```

### 2. Markdown Body (sections with `##` headings)

Sections must appear in this order (can be omitted):

1. Overview (or Brand & Style)
2. Colors
3. Typography
4. Layout (or Layout & Spacing)
5. Elevation & Depth (or Elevation)
6. Shapes
7. Components
8. Do's and Don'ts

## Validation Rules

When validating a DESIGN.md, check for:

| Rule               | Severity | Check                                                              |
| ------------------ | -------- | ------------------------------------------------------------------ |
| broken-ref         | error    | Token references like `{colors.primary}` resolve to defined tokens |
| missing-primary    | warning  | Colors defined but no `primary` token exists                       |
| contrast-ratio     | warning  | Component backgroundColor/textColor pairs meet WCAG AA (4.5:1)     |
| orphaned-tokens    | warning  | Color tokens defined but never referenced by components            |
| missing-typography | warning  | Colors defined but no typography tokens                            |
| section-order      | warning  | Sections appear in canonical order                                 |
| token-summary      | info     | Summary of token counts per section                                |

## Foundation Design Principles

When creating DESIGN.md for Foundation projects, follow these principles:

- **Agnostic**: ASCII-only, no emojis, no decorative elements
- **Minimal**: Limited color palette (max 10 colors), simple typography
- **Accessible**: All color pairs must meet WCAG AA (4.5:1 contrast)
- **Machine-readable**: Valid YAML, proper token references
- **Human-readable**: Clear prose explaining design decisions

## Commands (Conceptual)

While the `@google/design.md` CLI provides these commands, this skill implements them conceptually:

### Validate (lint)

Check DESIGN.md for structural correctness and design token validity.

### Diff

Compare two DESIGN.md files and report token-level changes.

### Export

Convert DESIGN.md tokens to other formats (Tailwind config, CSS custom properties, DTCG).

### Spec

Output the DESIGN.md format specification for reference.

## Usage Instructions

### Creating a New DESIGN.md

1. Analyze the project's visual identity:
   - Colors used in UI
   - Typography choices
   - Spacing patterns
   - Component styles

2. Define design tokens in YAML front matter:
   - Start with colors (primary, secondary, background, text)
   - Add typography (body, heading, mono)
   - Define layout spacing
   - Specify component tokens

3. Write markdown body sections:
   - Explain the design rationale
   - Describe how tokens should be applied
   - Document do's and don'ts

4. Validate the file:
   - Check YAML syntax
   - Verify token references resolve
   - Test contrast ratios
   - Ensure section order

### Validating an Existing DESIGN.md

1. Read the DESIGN.md file
2. Parse YAML front matter
3. Check all token references (`{path.to.token}`) resolve
4. Verify WCAG contrast for component color pairs
5. Ensure sections follow canonical order
6. Report findings with severity levels

## Integration with Foundation

This skill integrates with:

- **foundation-audit-skill**: Validates DESIGN.md as part of project audits
- **cognitive-doc-design**: DESIGN.md follows cognitive-doc-design principles (lead with answer,
  chunked info, tables)
- **AGENTS.md**: DESIGN.md path documented for session tracking

## Example: Minimal DESIGN.md

```markdown
---
version: 'alpha'
name: 'Minimal Project'
colors:
  primary: '#000000'
  background: '#FFFFFF'
  text: '#333333'
typography:
  body:
    fontFamily: 'sans-serif'
    fontSize: '16px'
    fontWeight: 400
    lineHeight: '1.5'
---

## Overview

Minimal design system with high contrast and system fonts.

## Colors

| Token      | Hex     | Role              |
| ---------- | ------- | ----------------- |
| primary    | #000000 | Headings, buttons |
| background | #FFFFFF | Page background   |
| text       | #333333 | Body text         |

## Typography

Body text uses system sans-serif at 16px.

## Components

**Buttons**: Black background, white text, 4px border radius.
```

## Best Practices

1. **Lead with tokens**: YAML front matter defines exact values
2. **Explain rationale**: Markdown body tells why, not just what
3. **Use tables**: Color palettes and typography rules in table format
4. **Check contrast**: Always verify WCAG compliance
5. **Keep it minimal**: Don't over-engineer the design system
6. **ASCII-only**: No emojis in DESIGN.md (Foundation rule)
7. **Token references**: Use `{colors.primary}` not hardcoded values in components

## Output Format

When validating or creating DESIGN.md, output:

```
DESIGN.md Validation Report
============================
File: path/to/DESIGN.md

Errors:
- broken-ref: Token {colors.missing} not found (line 12)

Warnings:
- missing-primary: No primary color defined
- contrast-ratio: button-text has 3.5:1 contrast (needs 4.5:1)

Info:
- token-summary: 5 colors, 2 typography, 3 components defined

Status: INVALID (1 error, 2 warnings)
```

## Notes

- DESIGN.md format is at version "alpha" - expect changes
- Token references use curly braces: `{path.to.token}`
- Component variants (hover, active) are separate entries
- Colors must be hex codes in sRGB space (#RRGGBB)
- Dimensions use px, em, or rem units
