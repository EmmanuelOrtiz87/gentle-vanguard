---
name: memory-management-skill
description: >
  Knowledge work plugin from productivity department.
metadata:
  source: knowledge-work-plugins
  original-name: memory-management
  department: productivity
---

# Memory Management

Memory makes Claude your workplace collaborator — someone who speaks your internal language.

## The Goal

Transform shorthand into understanding:

```
User: "ask todd to do the PSR for oracle"
              ↓ Claude decodes
"Ask Todd Martinez (Finance lead) to prepare the Pipeline Status Report
 for the Oracle Systems deal ($2.3M, closing Q2)"
```

Without memory, that request is meaningless. With memory, Claude knows:

- **todd** → Todd Martinez, Finance lead, prefers Slack
- **PSR** → Pipeline Status Report (weekly sales doc)
- **oracle** → Oracle Systems deal, not the company

## Architecture

```
CLAUDE.md          ← Hot cache (~30 people, common terms)
memory/
  glossary.md      ← Full decoder ring (everything)
  people/          ← Complete profiles
  projects/        ← Project details
  context/         ← Company, teams, tools
```

**CLAUDE.md (Hot Cache):**

- Top ~30 people you interact with most
- ~30 most common acronyms/terms
- Active projects (5-15)
- Your preferences
- **Goal: Cover 90% of daily decoding needs**

**memory/glossary.md (Full Glossary):**

- Complete decoder ring — everyone, every term
- Searched when something isn't in CLAUDE.md
- Can grow indefinitely

**memory/people/, projects/, context/:**

- Rich detail when needed for execution
- Full profiles, history, context

## Lookup Flow

```
User: "ask todd about the PSR for phoenix"

1. Check CLAUDE.md (hot cache)
   → Todd? ✓ Todd Martinez, Finance
   → PSR? ✓ Pipeline Status Report
   → Phoenix? ✓ DB migration project

2. If not found → search memory/glossary.md
   → Full glossary has everyone/everything

3. If still not found → ask user
   → "What does X mean? I'll remember it."
```

## File Locations

- **Working memory:** `CLAUDE.md` in current working directory
- **Deep memory:** `memory/` subdirectory

## Working Memory Format (CLAUDE.md)

See [references/working-memory-format.md](references/working-memory-format.md) for the full
template.

## Deep Memory Format (memory/)

See [references/deep-memory-format.md](references/deep-memory-format.md) for glossary, people,
projects, and company context templates.

## Interaction Guide

See [references/interaction-guide.md](references/interaction-guide.md) for decoding, adding memory,
recalling, progressive disclosure, and bootstrapping.

## Conventions

- **Bold** terms in CLAUDE.md for scannability
- Keep CLAUDE.md under ~100 lines (the "hot 30" rule)
- Filenames: lowercase, hyphens (`todd-martinez.md`, `project-phoenix.md`)
- Always capture nicknames and alternate names
- Use glossary tables for easy lookup
- Promote frequently-used terms to CLAUDE.md; demote stale ones to memory/ only

## What Goes Where

| Type             | CLAUDE.md (Hot Cache)     | memory/ (Full Storage)           |
| ---------------- | ------------------------- | -------------------------------- |
| Person           | Top ~30 frequent contacts | glossary.md + people/{name}.md   |
| Acronym/term     | ~30 most common           | glossary.md (complete list)      |
| Project          | Active projects only      | glossary.md + projects/{name}.md |
| Nickname         | In Key People if top 30   | glossary.md (all nicknames)      |
| Company context  | Quick reference only      | context/company.md               |
| Preferences      | All preferences           | -                                |
| Historical/stale | ✗ Remove                  | ✓ Keep in memory/                |

## Promotion / Demotion

**Promote to CLAUDE.md when:**

- You use a term/person frequently
- It's part of active work

**Demote to memory/ only when:**

- Project completed
- Person no longer frequent contact
- Term rarely used
