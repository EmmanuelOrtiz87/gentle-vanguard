---
name: ai-agent-design-skill
description: >
  Imported from mercury-agent-skills. Use when working with "agent design", "agent architecture",
  "tool use", "agent orchestration". Triggers: "agent design", "agent architecture", "tool use",
  "agent orchestration".
metadata:
  source: mercury-agent-skills
  original-name: ai-agent-design
---

# AI Agent Design

## Core Principles

1. **Agents Are Tools, Not Teammates** — Design agents as tools with clear boundaries
2. **Autonomy is a Spectrum** — More oversight for critical actions, more autonomy for routine
3. **Cache Everything, Guess Nothing** — Store every interaction explicitly
4. **Fail Predictably** — When uncertain ask, when stuck escalate, when broken stop
5. **Safety First, Speed Second** — Build guardrails before features

## Agent Maturity Model

| Level | Name | Tool Use | Memory | Autonomy |
|---|---|---|---|---|
| **L1** | Reactive | None | None | None |
| **L2** | Scripted | Basic calls | Session-only | Low |
| **L3** | Tool-Using | Multiple tools | Short-term | Medium |
| **L4** | Memory-Augmented | Complex tools | Long-term | High |
| **L5** | Autonomous Orchestrator | Tool composition | Semantic | Full |

**Progression**: L1→L2: conditional logic | L2→L3: tool schemas | L3→L4: persistent storage | L4→L5: planning + delegation

## Reference Files

Detailed content extracted to `references/`:

| File | Coverage |
|---|---|
| `TOOL-DEFINITION.md` | Tool schemas, best practices, categories, implementation |
| `MEMORY-SYSTEMS.md` | STM/LTM/episodic/semantic memory, retrieval strategies |
| `ORCHESTRATION.md` | Single/multi-agent, supervisor, routing patterns |
| `PLANNING.md` | ReAct, Plan-and-Execute, comparison |
| `ERROR-RECOVERY.md` | Failure modes, recovery, human-in-the-loop |
| `SAFETY.md` | Guardrails, input/output validation, action auth |
| `COMMON-MISTAKES.md` | 10 common mistakes with fixes |

## Quick Reference

| Component | Best Practice | Common Mistake |
|---|---|---|
| Tools | Detailed descriptions, validated params | Vague names, no error handling |
| Memory | Separate STM/LTM/episodic/semantic | One-size-fits-all storage |
| Orchestration | Start single, evolve to multi-agent | Over-engineering from day one |
| Planning | ReAct for exploration, P&E for stability | No planning at all |
| Safety | Input + output + action guardrails | Safety as an afterthought |
| Error Recovery | Retry + fallback + escalate | Assume success |
