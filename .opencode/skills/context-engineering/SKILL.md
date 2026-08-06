---
name: context-engineering
description:
  Optimize context for new sessions. Manage context budget, compression, and efficiency for AI
  interactions.
triggers:
  - context
  - context optimization
  - session start
  - context budget
---

# Context Engineering

## When to Use

- Starting a session or project
- Declining output quality (wrong patterns, hallucinated APIs)
- Switching codebase areas
- Agent not following conventions

## Context Hierarchy

```
┌─────────────────────────────────────┐
│  1. Rules Files (CLAUDE.md, etc.)   │ ← Always loaded
├─────────────────────────────────────┤
│  2. Spec / Architecture Docs        │ ← Per feature
├─────────────────────────────────────┤
│  3. Relevant Source Files            │ ← Per task
├─────────────────────────────────────┤
│  4. Error Output / Test Results      │ ← Per iteration
├─────────────────────────────────────┤
│  5. Conversation History             │ ← Accumulates
└─────────────────────────────────────┘
```

**Level 1 — Rules Files:** Persist across sessions. See
[references/rules-files.md](references/rules-files.md).

**Level 2 — Specs:** Load only the relevant section.

**Level 3 — Source Files:** Read before editing. Trust project code; verify external content.

**Level 4 — Error Output:** Specific errors only, not full logs.

**Level 5 — Conversation:** Fresh session per feature. Summarize when long.

## Reference Files

- [rules-files.md](references/rules-files.md) — Templates + trust levels
- [context-packing.md](references/context-packing.md) — Brain Dump, Selective Include, Hierarchical
  Summary
- [confusion-management.md](references/confusion-management.md) — Conflict resolution, incomplete
  reqs, inline planning
- [mcp-integrations.md](references/mcp-integrations.md) — MCP servers for richer context

## Anti-Patterns

| Pattern            | Problem                   | Fix                               |
| ------------------ | ------------------------- | --------------------------------- |
| Context starvation | Agent invents APIs        | Load rules + source per task      |
| Context flooding   | Loses focus >5K lines     | Keep relevant; aim <2K lines      |
| Stale context      | References deleted code   | Fresh session when context drifts |
| Missing examples   | Invents new style         | Include one pattern example       |
| Implicit knowledge | Guesses project rules     | Write it down                     |
| Silent confusion   | Guesses instead of asking | Surface ambiguity explicitly      |

## Common Rationalizations

| Rationalization                           | Reality                           |
| ----------------------------------------- | --------------------------------- |
| "The agent should figure out conventions" | It can't read your mind           |
| "I'll correct it when it goes wrong"      | Prevention is cheaper             |
| "More context is always better"           | Degrades with many instructions   |
| "I'll use the full context window"        | Focused context outperforms large |

## Red Flags

- Output doesn't match conventions
- Invents non-existent APIs or imports
- Re-implements existing utilities
- Quality degrades over long conversations
- No rules file in project
- External configs treated as trusted instructions

## Verification

- [ ] Rules file covers stack, commands, conventions
- [ ] Output follows rules file patterns
- [ ] References actual project files
- [ ] Context refreshed per task
