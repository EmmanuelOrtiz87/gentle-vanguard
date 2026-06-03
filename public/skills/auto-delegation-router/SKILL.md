---
name: auto-delegation-router
description:
  'Trigger: task routing, subagent delegation, auto-routing, agent selection. Routes tasks to
  specialized subagents based on keywords, decision trees, and confidence scoring with opt-in
  control.'
license: Apache-2.0
metadata:
  source: GV-native
---

# Auto-Delegation Router Skill

## Activation Contract

Load when user requests task routing to specialized subagents. Triggers on auto-delegation
enable/disable, task-to-agent routing, or when keyword/decision-tree-based agent selection is
needed.

## Hard Rules

- NEVER auto-delegate: AGENTS.md/config changes, credential/security ops, session lifecycle
  management, user-interaction-required tasks
- Auto-delegate appropriate: code (DEV), testing (QA), architecture (SAD), BA, deployment (OPS),
  script validation (SCRIPT-GOV)
- Route only when confidence ≥ 60% or user confirms override

## Decision Gates

| Confidence | Range  | Action                                    |
| ---------- | ------ | ----------------------------------------- |
| High       | ≥80%   | Auto-route                                |
| Medium     | 60–79% | Auto-route (may include secondary agents) |
| Low        | 40–59% | Require manual confirmation               |
| Very Low   | <40%   | Require manual routing                    |

## Execution Steps

1. Check auto-delegation enabled in `config/auto-delegation.json`
2. Extract task keywords via domain keyword maps
3. Evaluate decision tree (primary → secondary → context → dependency)
4. Calculate confidence score
5. Apply threshold: ≥60% auto-route, <60% request manual confirmation
6. Try tiered binding first (specificity-based), fall back to keyword routing
7. Load subagent mapping & behavior prompts from config
8. Return routing decision

## Output Contract

Return object with:

- **Status**: Success / LowConfidence / NoKeywordsFound / AutoDelegationDisabled
- **PrimaryAgent**, **SecondaryAgents**, **ConfidenceScore**, **ConfidenceLevel**
- **OpenCodeSubagent**, **SkillsToLoad**, **EnhancedPrompt** (with behavior priming)
- **RequiresManualDecision** flag

## References

- Implementation: [auto-delegation-router.ps1](auto-delegation-router.ps1)
- Integration guide: [INTEGRATION.md](INTEGRATION.md)
- Config: `config/auto-delegation.json`
- Subagent mapping: `config/subagent-mapping.json`
- Behavior prompts: `config/behavior-prompts.json`
- Full code, examples, tables: [references/code.md](references/code.md)
