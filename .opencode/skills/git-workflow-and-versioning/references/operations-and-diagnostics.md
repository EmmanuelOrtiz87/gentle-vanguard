# Operations, Patterns & Diagnostics

## The Save Point Pattern

```
Agent starts work
    │
    ├── Makes a change
    │   ├── Test passes? → Commit → Continue
    │   └── Test fails? → Revert to last commit → Investigate
    │
    ├── Makes another change
    │   ├── Test passes? → Commit → Continue
    │   └── Test fails? → Revert to last commit → Investigate
    │
    └── Feature complete → All commits form a clean history
```

This pattern means you never lose more than one increment of work. If an agent goes off the rails,
`git reset --hard HEAD` takes you back to the last successful state.

## Change Summaries

After any modification, provide a structured summary. This makes review easier, documents scope
discipline, and surfaces unintended changes:

```
CHANGES MADE:
- src/routes/tasks.ts: Added validation middleware to POST endpoint
- src/lib/validation.ts: Added TaskCreateSchema using Zod

THINGS I DIDN'T TOUCH (intentionally):
- src/routes/auth.ts: Has similar validation gap but out of scope
- src/middleware/error.ts: Error format could be improved (separate task)

POTENTIAL CONCERNS:
- The Zod schema is strict — rejects extra fields. Confirm this is desired.
- Added zod as a dependency (72KB gzipped) — already in package.json
```

This pattern catches wrong assumptions early and gives reviewers a clear map of the change. The
"DIDN'T TOUCH" section is especially important — it shows you exercised scope discipline and didn't
go on an unsolicited renovation.

## Using Git for Debugging

```bash
# Find which commit introduced a bug
git bisect start
git bisect bad HEAD
git bisect good <known-good-commit>
# Git checkouts midpoints; run your test at each to narrow down

# View what changed recently
git log --oneline -20
git diff HEAD~5..HEAD -- src/

# Find who last changed a specific line
git blame src/services/task.ts

# Search commit messages for a keyword
git log --grep="validation" --oneline
```

## Common Rationalizations

| Rationalization                             | Reality                                                                                                                                 |
| ------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| "I'll commit when the feature is done"      | One giant commit is impossible to review, debug, or revert. Commit each slice.                                                          |
| "The message doesn't matter"                | Messages are documentation. Future you (and future agents) will need to understand what changed and why.                                |
| "I'll squash it all later"                  | Squashing destroys the development narrative. Prefer clean incremental commits from the start.                                          |
| "Branches add overhead"                     | Short-lived branches are free and prevent conflicting work from colliding. Long-lived branches are the problem — merge within 1-3 days. |
| "I'll split this change later"              | Large changes are harder to review, riskier to deploy, and harder to revert. Split before submitting, not after.                        |
| "I don't need a .gitignore"                 | Until `.env` with production secrets gets committed. Set it up immediately.                                                             |
| "It's just a small fix, bump the patch"     | Check what consumers can observe. A behavior change they relied on is a major, whatever the diff size.                                  |
| "The changelog is just the commit log"      | Commits are for you; the changelog is for consumers, curated by impact. Generating one from raw commits buries what matters.            |
| "We'll write the changelog at release time" | By then the impact is reconstructed from memory and half of it is missing. Write the entry with the change.                             |

## Red Flags

- Large uncommitted changes accumulating
- Commit messages like "fix", "update", "misc"
- Formatting changes mixed with behavior changes
- No `.gitignore` in the project
- Committing `node_modules/`, `.env`, or build artifacts
- Long-lived branches that diverge significantly from main
- Force-pushing to shared branches
- A breaking change shipped under a minor or patch version bump
- A release with no tag, or a version number hand-edited out of sync with the tag
- A user-facing release with no changelog entry, or a changelog that's just dumped commit messages

## Verification

For every commit:

- [ ] Commit does one logical thing
- [ ] Message explains the why, follows type conventions
- [ ] Tests pass before committing
- [ ] No secrets in the diff
- [ ] No formatting-only changes mixed with behavior changes
- [ ] `.gitignore` covers standard exclusions

For every release (anything with consumers):

- [ ] The version bump matches the change: breaking → major, additive → minor, fix → patch
- [ ] The release is tagged, and the version is derived from the tag, not hand-edited out of sync
- [ ] The changelog has a curated, human-readable entry grouped by impact for this version
