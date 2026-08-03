---
name: technical-writer
description: Create, edit and improve technical documentation. Use when writing docs, READMEs, API docs, ADRs, or any technical writing task. Covers Markdown, Confluence, Notion-compatible output.
triggers:
  - write documentation
  - documentation
  - README
  - API docs
  - technical writing
  - create docs
  - edit documentation
---

# Technical Writer Skill

## Overview

Create, improve, and maintain technical documentation.
Supports multiple output formats and documentation types.

## Document Types

| Type | Purpose | Location |
|------|---------|----------|
| README | Project overview | Repository root |
| API Docs | Interface documentation | docs/api/ |
| ADR | Architecture decisions | docs/adr/ |
| How-To | Step-by-step guides | docs/guides/ |
| Reference | Detailed reference | docs/reference/ |
| Changelog | Change history | CHANGELOG.md |
| Wiki | Knowledge base | wiki/ or Confluence |

## Workflow

```
Document needed
    │
    ├── Analyze purpose ──────────→ Determine type & audience
    │
    ├── Gather source material ─────→ Code, comments, specs
    │
    ├── Create structure ───────────→ Outline sections
    │
    ├── Draft content ──────────────→ Generate prose
    │
    ├── Review & refine ────────────→ Self-review checklist
    │
    └── Output ─────────────────────→ Markdown / Confluence / Notion
```

## Commands

### 1. Generate README
```bash
# Auto-generate from package.json + code structure
npx tsx src/technical-writer.ts readme --output README.md

# With custom sections
npx tsx src/technical-writer.ts readme --include api,examples,contributing
```

### 2. Generate API Documentation
```bash
# From TypeScript sources
npx tsx src/technical-writer.ts api --src src/ --output docs/api/

# From OpenAPI spec
npx tsx src/technical-writer.ts api --spec openapi.yaml --output docs/
```

### 3. Create ADR
```bash
# Generate ADR template
npx tsx src/technical-writer.ts adr --title "Use GraphQL over REST" --status proposed

# Output: docs/adr/0001-use-graphql-over-rest.md
```

### 4. Update Changelog
```bash
# From git commits since last tag
npx tsx src/technical-writer.ts changelog --since v1.2.0

# With custom format
npx tsx src/technical-writer.ts changelog --format conventional
```

### 5. Improve Existing Doc
```bash
# Analyze and suggest improvements
npx tsx src/technical-writer.ts improve README.md --focus clarity

# Auto-apply fixes
npx tsx src/technical-writer.ts improve README.md --apply
```

## Document Structure Templates

### README Template
```markdown
# Project Name

## Description
One-paragraph summary

## Features
- Feature 1
- Feature 2

## Installation
\`\`\`bash
npm install package
\`\`\`

## Usage
### Basic
\`\`\`javascript
import { something } from 'package';
\`\`\`

### Advanced
...

## API Reference
[Link to full docs]

## Contributing
[CONTRIBUTING.md]

## License
MIT
```

### ADR Template
```markdown
# [Number]. [Title]

## Status
- Proposed / Accepted / Deprecated

## Context
What is the issue that we're seeing?

## Decision
What is the change that we're proposing?

## Consequences
- Positive: ...
- Negative: ...
- Neutral: ...

## Alternatives Considered
- Alternative 1: Why rejected
- Alternative 2: Why rejected
```

## Quality Guidelines

### 1. Clarity
- One idea per sentence
- Active voice preferred
- Define acronyms on first use

### 2. Completeness
- All code examples runnable
- Prerequisites listed
- Error cases documented

### 3. Consistency
- Same terminology throughout
- Consistent formatting
- Standard markdown syntax

### 4. Findability
- Clear headings
- Table of contents for long docs
- Cross-references as links

## Output Formats

| Format | Command | Notes |
|--------|---------|-------|
| Markdown | Default | Full GFM support |
| Confluence | `--format confluence` | Storage format |
| Notion | `--format notion` | Blocks API compatible |
| PDF | `--format pdf` | Via pandoc |
| HTML | `--format html` | Self-contained |

## Integration Points

- **source-driven-development**: Synchronizes with source
- **documentation-and-adrs**: Cross-skill compatibility
- **spec-driven-development**: Transforms specs to docs
- **code-simplification**: Explains refactored code

## Examples

### Example 1: Document New Feature
```bash
# After implementing feature
npx tsx src/technical-writer.ts feature-doc --module auth

Output: docs/features/authentication.md
```

### Example 2: API Documentation from Tests
```bash
# Extract examples from test files
npx tsx src/technical-writer.ts api --from-tests "*.test.ts"

Creates: docs/api/endpoints.md with live examples
```

### Example 3: Troubleshooting Guide
```bash
# Generate from error logs
npx tsx src/technical-writer.ts troubleshooting --errors errors.log

Creates: docs/troubleshooting/common-issues.md
```

## Checklist

Before marking documentation complete:

- [ ] Title is descriptive
- [ ] Summary exists in first paragraph
- [ ] All code examples tested
- [ ] No broken links
- [ ] Appropriate for target audience
- [ ] Formatting consistent
- [ ] Reviewed for clarity
- [ ] Cross-references added

## See Also

- `documentation-and-adrs` - Similar skill, different approach
- `source-driven-development` - Verified documentation
- `spec-driven-development` - From spec to doc
