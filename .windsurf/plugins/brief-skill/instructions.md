# brief-skill

> Gentle-Vanguard Skill

## Description

>

## Triggers

## Instructions

# /brief -- Legal Team Briefing

> If you see unfamiliar placeholders or need to check which tools are connected, see
> [CONNECTORS.md](../../CONNECTORS.md).

Generate contextual briefings for legal work. Supports three modes: daily brief, topic brief, and
incident brief.

**Important**: This command assists with legal workflows but does not provide legal advice.
Briefings should be reviewed by qualified legal professionals before being relied upon.

## Invocation

```
/brief daily              # Morning brief of legal-relevant items
/brief topic [query]      # Research brief on a specific legal question
/brief incident [topic]   # Rapid brief on a developing situation
```

If no mode is specified, ask the user which type of brief they need.

## Modes

### Daily Brief

Morning summary of what a legal team member needs to start their day. Scans email, calendar, chat,
CLM, and CRM for legal-relevant items. See [references/daily-brief.md](references/daily-brief.md)
for sources and output format.

### Topic Brief

Research a specific legal question across documents, email, chat, and CLM. Synthesizes findings into
a structured brief. See [references/topic-brief.md](references/topic-brief.md) for workflow and
output format.

### Incident Brief

Rapid brief for developing situations (data breaches, litigation threats, regulatory inquiries).
Scans all sources for relevant context. See
[references/incident-brief.md](references/incident-brief.md) for workflow and output format.

## General Notes

- If sources are unavailable, note the gaps prominently so the user knows what was not checked
- For daily briefs, learn the user's preferences over time (what they find useful, what they want
  filtered out)
- Briefs should be actionable: every item should have a clear next step or reason for inclusion
- Keep briefs concise. Link to source materials rather than reproducing them in full
