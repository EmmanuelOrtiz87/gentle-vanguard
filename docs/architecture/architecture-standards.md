# Architecture Standards

## Overview

Default decision shapes, common areas, and repository targets for architecture governance.

## Decision Shape

All architecture decisions follow this structure:

```markdown
## Context
[What is the situation? What problem are we solving?]

## Decision
[What did we decide? Be specific about the choice.]

## Rationale
[Why this option over alternatives? Tradeoffs considered.]

## Consequences
[What becomes easier? What becomes harder? Side effects?]

## Status
[Proposed | Accepted | Deprecated | Superseded]

## Follow-up
[Action items, tickets, or next steps]
```

## Common Decision Areas

| Area | Scope | Examples |
|------|-------|----------|
| **Project Structure** | Directory layout, naming conventions | Monorepo vs polyrepo, file naming patterns |
| **Technology Stack** | Language, framework, library choices | React vs Vue, PostgreSQL vs MySQL |
| **Architecture Pattern** | High-level design approach | Microservices, layered architecture, event-driven |
| **Integration** | How components communicate | REST APIs, GraphQL, message queues |
| **Persistence** | Data storage decisions | SQL vs NoSQL, ORM choices |
| **Security** | Auth, authorization, secrets | JWT vs sessions, OAuth providers |
| **Deployment** | How code reaches production | CI/CD pipelines, containerization |
| **Observability** | Monitoring, logging, tracing | Structured logging, metrics, distributed tracing |

## Repository Targets

Decisions are stored in:

1. **Local decisions**: `.decisions/` in the project root
   - Format: `DECISION-YYYYMMDD-XXX.md`
   - For project-specific decisions

2. **Foundation decisions**: `decisions/` in workspace-foundation
   - Format: `DECISION-YYYYMMDD-XXX.md`
   - For cross-project patterns and standards

3. **Engram memory**: For session-persistent decisions
   - Use `mem_save` with type `decision` or `architecture`
   - Survives across sessions and compactions

## Governance Rules

1. **Default to existing patterns** - Check SKILL_INDEX and existing code before introducing new patterns
2. **Document tradeoffs** - Every decision must list alternatives considered
3. **Review before implementation** - Major decisions should be reviewed (use judgment-day)
4. **Update SKILL_INDEX** - If a decision affects skill loading or triggers, update the index
5. **Cross-workspace sync** - Foundation decisions apply to all consumer repositories

## Quick Reference

```powershell
# List recent decisions
Get-ChildItem .decisions/ -Filter "DECISION-*.md" | Sort-Object Name -Descending | Select-Object -First 10

# Search decisions
Select-String -Path .decisions/*.md -Pattern "pattern" -Context 2,2

# Save decision to Engram
mem_save -title "Decision: chose X over Y" -type decision -content "**What**: ...**Why**: ...**Where**: ..."
```

## Navigation

- **Topology**: [layer-topology.md](layer-topology.md)
- **Workflows**: [role-workflows.md](role-workflows.md)
- **This file**: Architecture standards and decision templates
