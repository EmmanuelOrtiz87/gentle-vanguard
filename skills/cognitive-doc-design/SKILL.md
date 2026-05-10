---
name: cognitive-doc-design
description: >
  Design documentation that reduces reader cognitive load through progressive disclosure, chunking,
  signposting, tables, checklists, and recognition over recall. Trigger: when writing guides,
  READMEs, RFCs, onboarding docs, architecture docs, or review-facing documentation.
license: Apache-2.0
metadata:
  author: workspace-foundation (adapted for Foundation)
  version: '1.0'
---

# Cognitive Doc Design (Foundation Adaptation)

## When to Use

Load this skill when creating or editing documentation that people/agents need to understand
quickly, retain, or use during review.

Use it especially for:

- PR descriptions and review notes
- Contributor or maintainer guides
- Architecture, workflow, or onboarding docs
- Any doc that currently feels long, dense, or hard to scan
- Foundation READMEs (main, AGENTS.md, docs/guides/)

## Critical Patterns

| Pattern                 | Rule                                                                                   |
| ----------------------- | -------------------------------------------------------------------------------------- |
| Lead with the answer    | Put the decision, action, or outcome first. Context comes after.                       |
| Progressive disclosure  | Start with the happy path, then add details, edge cases, and references.               |
| Chunking                | Group related information into small sections. Keep flat lists short.                  |
| Signposting             | Use headings, labels, callouts, and summaries so readers know where they are.          |
| Recognition over recall | Prefer tables, checklists, examples, and templates over prose that must be remembered. |
| Review empathy          | Design docs so reviewers can verify intent without reconstructing the whole story.     |

## Documentation Shape (Foundation Standard)

Use this structure for all Foundation docs (adapted from native-tools):

```markdown
# <Outcome-oriented title>

<One paragraph: what changed, who it helps, and why it matters.>

## Quick Path

1. <First action>
2. <Second action>
3. <Verification or expected result>

## Details

| Topic  | Decision              |
| ------ | --------------------- |
| <area> | <concise explanation> |

## Checklist

- [ ] <Reader can confirm this>
- [ ] <Reader can confirm that>

## Next Step

<Link or action that continues the workflow.>
```

## Adaptation for Foundation

### 1. Lead with Answer (Foundation Rule)

```markdown
## ✅ RESULT (put first)

- Fix: 5 broken links repaired
- Move: 27 scripts to scripts/utilties/
- Rename: LEARNED-NORMS.md → TECH-ADAPTIVE-001-learned-norms.md
```

### 2. Chunking (Foundation Rule)

- Max 200 lines per doc section
- Group by: Problem → Solution → Metric
- Use tables for structured data (not prose)

### 3. Signposting (Foundation Rule)

```markdown
## 🔍 Discovery (what we found)

## 🛠️ Fix Applied (what we did)

## 📊 Result (what changed)

## 🎯 Conclusion (what we learned)
```

### 4. Recognition over Recall (Foundation Rule)

```markdown
| Check      | Status   | Metric                  |
| ---------- | -------- | ----------------------- |
| Audit      | ✅ 100%  | 0 broken links          |
| Judgment   | ✅ PASS  | 2-5 min (micro-scoping) |
| Validation | ✅ 33/33 | 100% pass rate          |
```

### 5. Review Empathy (Foundation Rule)

- Reviewers should NOT need to reconstruct context
- Each section is self-contained
- Use checklists for acceptance criteria
- Link previous/next steps explicitly

## Commands (Foundation)

```bash
# Check markdown files changed in current branch
git diff --name-only -- '*.md'

# Inspect PR changed-line count for cognitive load
gh pr view <PR_NUMBER> --json additions,deletions,changedFiles

# Validate doc structure (Foundation audit)
.\skills\foundation-audit-skill\scripts\audit-sweep.ps1 -Scope standard
```

## Integration with Foundation

### AGENTS.md

- Apply cognitive-doc-design to session startup rules
- Lead with: "Session started ✅" not "How to start session"

### README.md (main)

- Lead with: "Foundation is a 100% autonomous stack ✅"
- Not: "This is a project that..." (burying the lead)

### PR Template

- Add "Quick Path" section (3 steps max)
- Add "Cognitive Load" table (changed lines / 400 budget)
- Add "Review Empathy" checklist

## Reference

- Foundation adaptation: 2026-05-02
- Applied to: NORMATIVAS-ORQUESTADOR.md, AGENTS.md, READMEs
