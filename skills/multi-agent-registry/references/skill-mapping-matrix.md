# Skill Mapping Matrix

## Skill → Agent Grid

| Skill               | BA  | SAD | DEV | QA  | OPS | GOV | DOC |
| ------------------- | --- | --- | --- | --- | --- | --- | --- |
| bdd-scenarios       | X   |     |     |     |     |     |     |
| architecture        |     | X   |     |     |     |     |     |
| api-design          |     | X   |     |     |     |     |     |
| database-relational |     | X   |     |     |     |     |     |
| database-nosql      |     | X   |     |     |     |     |     |
| typescript          |     | X   | X   |     |     |     |     |
| angular-spa         |     |     | X   |     |     |     |     |
| react-19            |     |     | X   |     |     |     |     |
| nextjs-15           |     |     | X   |     |     |     |     |
| tailwind-4          |     |     | X   |     |     |     |     |
| zustand-5           |     |     | X   |     |     |     |     |
| zod-4               |     |     | X   |     |     |     |     |
| security            |     |     | X   |     |     | X   |     |
| testing-strategy    |     |     |     | X   |     |     |     |
| testing             |     |     |     | X   |     |     |     |
| playwright          |     |     |     | X   |     |     |     |
| pytest              |     |     |     | X   |     |     |     |
| docker-devops       |     |     |     |     | X   |     |     |
| kubernetes          |     |     |     |     | X   |     |     |
| terraform           |     |     |     |     | X   |     |     |
| git-workflow        |     |     |     |     | X   |     |     |
| observability       |     |     |     |     |     | X   |     |
| incident-response   |     |     |     |     |     | X   |     |
| code-review         |     |     |     |     |     | X   |     |
| documentation       |     |     |     |     |     |     | X   |
| sdd                 |     | X   |     |     |     |     | X   |
| github-pr           |     |     |     |     |     |     | X   |

## Agent ↔ Subagent Mapping

| Agent | Primary Subagent | Fallback  | Use Case                                   |
| ----- | ---------------- | --------- | ------------------------------------------ |
| BA    | `sdd-explore`    | `general` | Requirements analysis, feasibility studies |
| SAD   | `sdd-design`     | `general` | Architecture design, technical specs       |
| DEV   | `sdd-apply`      | `general` | Code implementation, bug fixes             |
| QA    | `sdd-verify`     | `general` | Testing, validation, judgment day          |
| OPS   | `general`        | `general` | DevOps tasks, infrastructure               |
| GOV   | `general`        | `general` | Governance, audits, reviews                |
| DOC   | `sdd-spec`       | `general` | Documentation, specifications              |

**Config file**: `config/subagent-mapping.json`

**Delegation template**:

```powershell
task --description 'Task description' --prompt 'Detailed prompt' --subagent_type <subagent>
```

## Token Efficiency Gains

| Pattern                            | Tokens/Session | Reduction |
| ---------------------------------- | -------------- | --------- |
| Monolithic (orchestrator does all) | ~50K           | baseline  |
| 3-agent specialization             | ~35K           | 30%       |
| 7-agent specialization             | ~20K           | 60%       |

- Orchestrator: slim context (~5K tokens)
- Each agent: loads only domain skills (~2-3K per agent)
