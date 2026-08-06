---
name: memory-bootstrap
description:
  Full bootstrap workflow for first-run memory setup — interactive task decoding, comprehensive
  scan, and memory file creation.
---

# Memory Bootstrap

Called from [`SKILL.md`](../SKILL.md) step 5 when `CLAUDE.md` and `memory/` don't exist yet.

## 1. Interactive Task Decoding

The best source of workplace language is the user's actual task list. Real tasks = real shorthand.

**Ask the user:**

```
Where do you keep your todos or task list? This could be:
- A local file (e.g., TASKS.md, todo.txt)
- An app (e.g. Asana, Linear, Jira, Notion, Todoist)
- A notes file

I'll use your tasks to learn your workplace shorthand.
```

**Once you have access to the task list:**

For each task item, analyze it for potential shorthand:

- Names that might be nicknames
- Acronyms or abbreviations
- Project references or codenames
- Internal terms or jargon

**For each item, decode it interactively:**

```
Task: "Send PSR to Todd re: Phoenix blockers"

I see some terms I want to make sure I understand:

1. **PSR** - What does this stand for?
2. **Todd** - Who is Todd? (full name, role)
3. **Phoenix** - Is this a project codename? What's it about?
```

Continue through each task, asking only about terms you haven't already decoded.

## 2. Optional Comprehensive Scan

After task list decoding, offer:

```
Do you want me to do a comprehensive scan of your messages, emails, and documents?
This takes longer but builds much richer context about the people, projects, and terms in your work.

Or we can stick with what we have and add context later.
```

**If they choose comprehensive scan:**

Gather data from available MCP sources:

- **Chat:** Recent messages, channels, DMs
- **Email:** Sent messages, recipients
- **Documents:** Recent docs, collaborators
- **Calendar:** Meetings, attendees

Build a braindump of people, projects, and terms found. Present findings grouped by confidence:

- **Ready to add** (high confidence) — offer to add directly
- **Needs clarification** — ask the user
- **Low frequency / unclear** — note for later

## 3. Write Memory Files

From everything gathered, create:

### CLAUDE.md (working memory, ~50-80 lines)

```markdown
# Memory

## Me

[Name], [Role] on [Team].

## People

| Who            | Role                |
| -------------- | ------------------- |
| **[Nickname]** | [Full Name], [role] |

## Terms

| Term      | Meaning     |
| --------- | ----------- |
| [acronym] | [expansion] |

## Projects

| Name           | What          |
| -------------- | ------------- |
| **[Codename]** | [description] |

## Preferences

- [preferences discovered]
```

### memory/ directory

- `memory/glossary.md` — full decoder ring (acronyms, terms, nicknames, codenames)
- `memory/people/{name}.md` — individual profiles
- `memory/projects/{name}.md` — project details
- `memory/context/company.md` — teams, tools, processes

## Back to Main Workflow

After completing bootstrap, return to [SKILL.md](../SKILL.md) step 6 to report results.
