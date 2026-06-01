1. Architecture decisións
2. API contracts
3. Data models
4. Sequence diagrams
5. Technical approach

```

### Phase 6: TASKS

**Trigger:** `sdd tasks`, `breakdown tasks`, `create tasks`

Break down into implementable tasks:

```

1. Create task list
2. Estimate effort
3. Prioritize tasks
4. Define dependencies

```

### Phase 7: APPLY

**Trigger:** `sdd apply`, `implement`, `write code`

Implement tasks following specs:

```

1. Read specs and design
2. Implement with TDD if applicable
3. Follow project conventions
4. Update task status

```

### Phase 8: VERIFY

**Trigger:** `sdd verify`, `validate`, `verify implementation`

Verify implementation against spec:

```

1. Run acceptance criteria tests
2. Review BDD scenario coverage
3. Validate functionality
4. Document verification results

```

### Phase 9: ARCHIVE

**Trigger:** `sdd archive`, `close sdd`, `finalize`

Archive completed SDD:

```

1. Verify all criteria met
2. Document lessons learned
3. Archive artifacts
4. Update Engram with learnings

````

## Usage

```powershell
# Initialize SDD for a feature
gentle-vanguard sdd init "user-authentication"

# Explore requirements
gentle-vanguard sdd explore "user-authentication"

# Create specification
gentle-vanguard sdd spec "user-authentication"

# Implement tasks
gentle-vanguard sdd apply "user-authentication" --task "1.1"

# Verify implementation
gentle-vanguard sdd verify "user-authentication"
````

## Files

```
docs/sdd/
 SDD-{name}/
     01-exploration.md
     02-proposal.md
     03-specification.md
     04-design.md
     05-tasks.md
     06-verification.md
```

## Integration

| Phase   | Agent     | Skill                     | Thinking Framework          |
| ------- | --------- | ------------------------- | --------------------------- |
| init    | AGENT-BA  | Detect stack, conventions | —                           |
| explore | AGENT-BA  | bdd-scenarios             | cynefin, socratic           |
| propose | AGENT-SAD | architecture-governance   | first-principles, systems-thinking |
| spec    | AGENT-SAD | BDD scenarios             | inversion                   |
| design  | AGENT-SAD | api-design-skill          | second-order, leverage-points, feedback-loops |
| tasks   | AGENT-DEV | task-breakdown            | fermi, writing-plans        |
| apply   | AGENT-DEV | Framework skills          | ooda-loop, systematic-debugging, executing-plans, subagent-driven-dev |
| verify  | AGENT-QA  | testing-skill             | red-team, five-whys, debiasing |
| archive | AGENT-DOC | documentation             | feedback-loops, bayesian    |

> **Full mapping**: See `config/sdd-framework-mapping.json` for triggers, ordering, and per-framework purpose.

## Enforcement

**Mandatory phases (ENFORCED by pre-process-input.ps1):**

- EXPLORE before SPEC — BA must explore requirements first
- SPEC before APPLY — no implementation without approved spec
- VERIFY before ARCHIVE — verification must pass before closing

**SDD FLOW RULE (ENFORCED by pre-process-input.ps1):**

When the system detects a feature/development request (keywords: implementar, crear, desarrollar,
build, "nueva funcionalidad", etc.), the pre-process-input.ps1 hook automatically forces
PLAN_MODE_REQUIRED → BA/sdd-explore. The agent MUST NOT skip to APPLY even if the trigger matched
DEV-style keywords. See `rules/AI-NORMATIVES.md` for canonical definition.

**Flow enforcement:**

1. User request → pre-process-input.ps1 detects feature intent
2. → PLAN_MODE_REQUIRED → activate BA (sdd-explore)
3. BA completes EXPLORE → passes to SAD for SPEC+DESIGN
4. SAD completes → passes to DEV for TASKS+APPLY
5. DEV completes → passes to QA for VERIFY
6. QA passes → ARCHIVE

**If the agent receives TRIGGER_MATCH_FOUND with "implement"/"code"/"develop" and SKILL:
sdd-lifecycle:** → DO NOT jump to APPLY phase → START from INIT or EXPLORE depending on context →
Check if spec exists in docs/sdd/ before implementing

**Optional (with justification):**

- Hotfixes: mini-spec only (1-page spec, no explore/propose)
- Internal refactors: skip explore/propose (must still have spec)
- Bug fixes: skip explore if the bug is clearly understood (still need spec)

## Migration

This skill consolidates the old phase-specific skills:

- `sdd-init` Phase 1
- `sdd-explore` Phase 2
- `sdd-propose` Phase 3
- `sdd-spec` Phase 4
- `sdd-design` Phase 5
- `sdd-tasks` Phase 6
- `sdd-apply` Phase 7
- `sdd-verify` Phase 8
- `sdd-archive` Phase 9
- `sdd-skill` This file (overview)

Old skills are deprecated but continue to work as aliases.

## Commands

```powershell
gentle-vanguard sdd init <name>           # Initialize
gentle-vanguard sdd explore <name>        # Explore
gentle-vanguard sdd propose <name>        # Propose
gentle-vanguard sdd spec <name>          # Write spec
gentle-vanguard sdd design <name>         # Design
gentle-vanguard sdd tasks <name>          # Create tasks
gentle-vanguard sdd apply <name>          # Implement
gentle-vanguard sdd verify <name>         # Verify
gentle-vanguard sdd archive <name>         # Archive
gentle-vanguard sdd status <name>         # Show progress
```
