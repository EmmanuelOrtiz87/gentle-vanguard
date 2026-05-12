---
name: multi-agent-registry
description:
  'Trigger: delegate task, specialized agent, sub-agent routing, dispatch agent. Multi-agent
  specialization registry defining 7 specialized sub-agents (BA, SAD, DEV, QA, OPS, GOV, DOC) for
  distributed orchestration replacing monolithic orchestrator pattern.'
license: Apache-2.0
metadata:
  author: foundation
  versión: '1.0'
---

# Multi-Agent Specialization Registry

## Activation Contract

Load when orchestrator needs to delegate tasks to specialized agents. Replaces monolithic
orchestrator with distributed specialist agents. Covers business analysis, solution architecture,
development, QA, DevOps, governance, and documentation domains.

## Hard Rules

- MUST decompose tasks before routing — orchestrator does NOT execute domain work
- MUST NOT cross agent boundaries (each agent stays in its CAN/CANNOT scope per agent-definitions)
- MUST use Agent Result Schema (FF-007) for structured JSON output
- MUST escalate to orchestrator on out-of-scope requests
- MUST route via `config/subagent-mapping.json`

## Decision Gates

| Task Domain                          | Primary Agent | Subagent      |
| ------------------------------------ | ------------- | ------------- |
| Requirements, BDD, user stories      | BA            | `sdd-explore` |
| Architecture, API design, DB schema  | SAD           | `sdd-design`  |
| Implementation, code, refactor       | DEV           | `sdd-apply`   |
| Testing, validation, judgment day    | QA            | `sdd-verify`  |
| DevOps, CI/CD, infrastructure        | OPS           | `general`     |
| Governance, audits, security reviews | GOV           | `general`     |
| Documentation, specs, runbooks       | DOC           | `sdd-spec`    |

| Execution Mode | Behavior                               | Best For          |
| -------------- | -------------------------------------- | ----------------- |
| `parallel`     | Concurrent (max 3-4 by risk)           | Independent tasks |
| `sequential`   | One-by-one with dependencies           | Dependent tasks   |
| `adaptive`     | Discovery agents first, then execution | New features      |

## Execution Steps

1. **Receive** user request → orchestrator decomposes task
2. **Route** to appropriate agent(s) via `config/subagent-mapping.json` using the lane table above
3. **Execute** agents via `wf.ps1 dispatch "<agents>" "<task>" -Mode <mode>` or per-agent
   `wf.ps1 agent <CODE> "<task>"`
4. **Coordinate** cross-agent results (orchestrator)
5. **Validate** final output and handoff to user

## Output Contract

Structured JSON per Agent Result Schema (FF-007): `lane_id`, `agent`, `role`, `status`
(success/failed/blocked/partial), `task`, `action`, `timestamp`, `skills_loaded`, `files_touched`,
`findings`, `validation_result`, `next_action`, `token_estimate`.

## References

- Agent definitions (BA, SAD, DEV, QA, OPS, GOV, DOC): `references/agent-definitions.md`
- Skill mapping matrix + subagent mapping: `references/skill-mapping-matrix.md`
- Advanced features (schema, dispatch, event bus, discovery, status):
  `references/advanced-features.md`
- Mapping config: `config/subagent-mapping.json`
- Skill index: `../SKILL_INDEX.md`
- Orchestrator: `../project-orchestrator-skill/SKILL.md`
- Backlog: `../../docs/reference/FUTURE-FEATURES-BACKLOG.md`
