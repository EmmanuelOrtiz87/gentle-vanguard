---
name: write-spec-skill
description: >
  Knowledge work plugin from product-management department.
metadata:
  source: knowledge-work-plugins
  original-name: write-spec
  department: product-management
---

# Write Spec

Write a feature specification or product requirements document (PRD).

## Usage

```
/write-spec $ARGUMENTS
```

## Workflow

### 1. Understand the Feature

Ask the user what they want to spec: a feature name, problem statement, user request, or vague idea.

### 2. Gather Context

Ask the user (conversationally, not all at once):

- **User problem**: What problem does this solve? Who experiences it?
- **Target users**: Which user segment(s) does this serve?
- **Success metrics**: How will we know this worked?
- **Constraints**: Technical constraints, timeline, regulatory requirements, dependencies
- **Prior art**: Has this been attempted before? Are there existing solutions?

### 3. Pull Context from Connected Tools

If **~~project tracker** is connected: search for related tickets, epics, or features.
If **~~knowledge base** is connected: search for related research or prior specs.
If **~~design** is connected: pull related mockups or design explorations.

If not connected, work entirely from what the user provides.

### 4. Generate the PRD

Produce a structured PRD with these sections (see reference files for details):

- **Problem Statement**: The user problem, who is affected, and impact (2-3 sentences)
- **Goals**: 3-5 specific, measurable outcomes
- **Non-Goals**: 3-5 things explicitly out of scope
- **User Stories**: Standard format, grouped by persona
- **Requirements**: Categorized as P0, P1, P2 with acceptance criteria
- **Success Metrics**: Leading and lagging indicators with specific targets
- **Open Questions**: Unresolved questions tagged with who needs to answer
- **Timeline Considerations**: Hard deadlines, dependencies, and phasing

### 5. Review and Iterate

After generating the PRD: ask the user if any sections need adjustment, offer to expand, or offer to create follow-up artifacts.

## Reference Files

Detailed guidance for each section:

- [PRD Structure](references/prd-structure.md) — full breakdown of each PRD section
- [Writing Guides](references/writing-guides.md) — user stories, MoSCoW categorization, acceptance criteria
- [Metrics & Scope](references/metrics-and-scope.md) — leading/lagging indicators, scope management
- [Output Format & Tips](references/output-format.md) — markdown format, best practices
