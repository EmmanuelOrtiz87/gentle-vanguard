---
name: backlog-management-skill
description: >
  Backlog management patterns: JSON schema, triage automation, migration from markdown.
  Trigger: "backlog", "triage", "roadmap", "feature intake"
---

## Purpose
Standardize backlog intake, triage, and lifecycle management using structured JSON for automation readiness while maintaining human-readable markdown views.

## Directory Structure
```
docs/backlog/
 items.json              # Source of truth (structured data)
 README.md               # Human-readable view (generated or manual)
 archive/                # Completed/discarded items
```

## JSON Schema
```json
{
  "id": "BL-XXX",
  "title": "Short descriptive title",
  "type": "feature|tech-debt|optimization|docs",
  "priority": "high|medium|low",
  "status": "pending|triaged|scheduled|in-progress|done|discarded",
  "created_at": "YYYY-MM-DD",
  "owner": "AGENT-ROLE or User",
  "description": "Detailed context",
  "value_prop": "Why this matters",
  "defer_reason": "Why it wasn't done immediately",
  "trigger": "Condition to revisit",
  "linked_sessions": [],
  "linked_prs": []
}
```

## Triage Workflow
1. **Intake:** New items added to `items.json` with status `pending`.
2. **Analysis:** Agent reviews for duplicates, scope clarity, and priority alignment.
3. **Enrichment:** Add `estimated_effort` and `dependencies`.
4. **Scheduling:** Move to `scheduled` when assigned to a release/milestone.

## Automation Rules
- **Duplicate Detection:** Compare new items against existing `title` and `description` using fuzzy matching.
- **Stale Item Alert:** Flag items with `status: pending` for > 30 days.
- **Traceability:** Auto-link `linked_sessions` when commit messages reference `BL-XXX`.

## Migration from Markdown
1. Parse existing `FUTURE-FEATURES-BACKLOG.md` table rows.
2. Map columns to JSON schema fields.
3. Generate `items.json`.
4. Update `README.md` to point to new structure.
5. Deprecate old markdown file (move to archive).

