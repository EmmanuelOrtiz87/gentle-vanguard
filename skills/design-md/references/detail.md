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

## Integration with Gentle-Vanguard

This skill integrates with:

- **gentle-vanguard-audit-skill**: Validates DESIGN.md as part of project audits
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
6. **ASCII-only**: No emojis in DESIGN.md (Gentle-Vanguard rule)
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
