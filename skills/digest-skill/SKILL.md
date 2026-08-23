---
name: digest-skill
description: >
  Knowledge work plugin from enterprise-search department.
metadata:
  source: knowledge-work-plugins
  original-name: digest
  department: enterprise-search
---

# Digest Command

> If you see unfamiliar placeholders or need to check which tools are connected, see
> [CONNECTORS.md](../../CONNECTORS.md).

Scan recent activity across all connected sources and generate a structured digest highlighting what
matters.

## Instructions

### 1. Parse Flags

Determine the time window from the user's input:

- `--daily` — Last 24 hours (default if no flag specified)
- `--weekly` — Last 7 days

The user may also specify a custom range:

- `--since yesterday`
- `--since Monday`
- `--since 2025-01-20`

### 2. Check Available Sources

Identify which MCP sources are connected (same approach as the search command):

- **~~chat** — channels, DMs, mentions
- **~~email** — inbox, sent, threads
- **~~cloud storage** — recently modified docs shared with user
- **~~project tracker** — tasks assigned, completed, commented on
- **~~CRM** — opportunity updates, account activity
- **~~knowledge base** — recently updated wiki pages

If no sources are connected, guide the user:

```
To generate a digest, you'll need at least one source connected.
Check your MCP settings to add ~~chat, ~~email, ~~cloud storage, or other tools.
```

### 3. Gather Activity from Each Source

See [references/activity-gathering.md](references/activity-gathering.md) for per-source MCP calls.

### 4. Identify Key Items

From all gathered activity, extract and categorize into action items, decisions, mentions, and
updates. See [references/key-items.md](references/key-items.md) for the full categorization.

### 5. Group by Topic

Organize the digest by topic, project, or theme rather than by source. Merge related activity across
sources:

```
## Project Aurora
- ~~chat: Design review thread concluded — team chose Option B (#design, Tuesday)
- ~~email: Sarah sent updated spec incorporating feedback (Wednesday)
- ~~cloud storage: "Aurora API Spec v3" updated by Sarah (Wednesday)
- ~~project tracker: 3 tasks moved to In Progress, 2 completed

## Budget Planning
- ~~email: Finance team requesting Q2 projections by Friday
- ~~chat: Todd shared template in #finance (Monday)
- ~~cloud storage: "Q2 Budget Template" shared with you (Monday)
```

### 6. Format the Digest

See [references/output-format.md](references/output-format.md) for the full output template and
summary stats.

### 7. Handle Unavailable Sources

If any source fails or is unreachable:

```
Note: Could not reach [source name] for this digest.
The following sources were included: [list of successful sources].
```

Do not let one failed source prevent the digest from being generated. Produce the best digest
possible from available sources.

### 8. Summary Stats

End with a quick summary:

```
---
[X] action items · [Y] decisions · [Z] mentions · [W] doc updates
Across [N] sources · Covering [time range]
```

## Notes

- Default to `--daily` if no flag is specified
- Group by topic/project, not by source — users care about what happened, not where it happened
- Action items should always be listed first — they are the most actionable part of a digest
- Deduplicate cross-source activity (same decision in ~~chat and email = one entry)
- For weekly digests, prioritize significance over completeness — highlight what matters, skip noise
- If the user has a memory system (CLAUDE.md), use it to decode people names and project references
- Include enough context in each item that the user can decide whether to dig deeper without
  clicking through

## Examples

Concrete usage drawn from this skill's own documentation:

```
To generate a digest, you'll need at least one source connected.
Check your MCP settings to add ~~chat, ~~email, ~~cloud storage, or other tools.
```
