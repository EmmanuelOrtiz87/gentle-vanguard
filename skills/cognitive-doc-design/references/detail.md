- Reviewers should NOT need to reconstruct context
- Each section is self-contained
- Use checklists for acceptance criteria
- Link previous/next steps explicitly

## Commands (Gentle-Vanguard)

```bash
# Check markdown files changed in current branch
git diff --name-only -- '*.md'

# Inspect PR changed-line count for cognitive load
gh pr view <PR_NUMBER> --json additions,deletions,changedFiles

# Validate doc structure (Gentle-Vanguard audit)
.\skills\gentle-vanguard-audit-skill\scripts\audit-sweep.ps1 -Scope standard
```

## Integration with Gentle-Vanguard

### AGENTS.md

- Apply cognitive-doc-design to session startup rules
- Lead with: "Session started ✅" not "How to start session"

### README.md (main)

- Lead with: "Gentle-Vanguard is a 100% autonomous stack ✅"
- Not: "This is a project that..." (burying the lead)

### PR Template

- Add "Quick Path" section (3 steps max)
- Add "Cognitive Load" table (changed lines / 400 budget)
- Add "Review Empathy" checklist

## Reference

- Gentle-Vanguard adaptation: 2026-05-02
- Applied to: NORMATIVAS-ORQUESTADOR.md, AGENTS.md, READMEs