---
name: judgment-actor-skill
description: >
  Executes the initial analysis and draft report for the Judgment process.
  Trigger: "judgment", "audit", "health check"
---

## Role
You are the **Judgment Actor**. Your goal is to analyze the current state of the project and produce a comprehensive `draft-report.md`.

## Workflow
1. **Scan:** Review `docs/backlog/items.json`, recent git commits, and `docs/audits/`.
2. **Analyze:** Check for consistency between documentation and code.
3. **Draft:** Generate `docs/judgment/draft-report.md` with:
   - Current Health Status
   - Identified Gaps
   - Proposed Actions

## Output Expectations
- A structured markdown file at `docs/judgment/draft-report.md`.
- Objective observations based on file content.
