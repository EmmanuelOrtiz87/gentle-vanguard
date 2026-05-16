---
name: sdd-lifecycle
description: >
  Spec-Driven Development (SDD) complete lifecycle - all phases in one skill. Triggers: "sdd",
  "spec", "spec-driven", "write spec", "feature spec", 
  "sdd init", "sdd explore", "sdd propose", "sdd spec", "sdd design", "sdd tasks", "sdd apply", "sdd
  verify", "sdd archive"
---

# SDD Lifecycle Skill

Complete Spec-Driven Development workflow with all phases.

## Phases

```

                    SDD LIFECYCLE



    INIT    EXPLORE  PROPOSE   SPEC



         TASKS    DESIGN




                   APPLY




                  VERIFY




                  ARCHIVE



```

## Phase Details

### Phase 1: INIT

**Trigger:** `sdd init`, `initialize sdd`, `start sdd`

Detect project stack, conventions, bootstrap persistence:

```
1. Detect tech stack (package.json, go.mod, etc.)
2. Detect existing conventions
3. Bootstrap persistence backend (engram/openspec/hybrid)
4. Initialize SDD directory structure
```

### Phase 2: EXPLORE

**Trigger:** `sdd explore`, `explore feature`, `analyze requirements`

Explore and understand the problem space:

```
1. Understand user needs and context
2. Identify constraints and dependencies
3. Map existing system behavior
4. Document exploration findings
```

### Phase 3: PROPOSE

**Trigger:** `sdd propose`, `propose solution`, `create proposal`

Propose solution approaches:

```
1. Explore solution options
2. Evaluate tradeoffs
3. Select recommended approach
4. Document proposal with rationale
```

### Phase 4: SPEC

**Trigger:** `sdd spec`, `write spec`, `create specification`

Write formal specification:

```
1. Problem statement
2. Scope and non-goals
3. Functional requirements
4. Acceptance criteria
5. BDD scenarios (Given/When/Then)
```

### Phase 5: DESIGN

**Trigger:** `sdd design`, `design solution`, `architecture`

Design the implementation:

```
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
```

## Usage

```powershell
# Initialize SDD for a feature
foundation sdd init "user-authentication"

# Explore requirements
foundation sdd explore "user-authentication"

# Create specification
foundation sdd spec "user-authentication"

# Implement tasks
foundation sdd apply "user-authentication" --task "1.1"

# Verify implementation
foundation sdd verify "user-authentication"
```

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

| Phase   | Agent     | Skill                     |
| ------- | --------- | ------------------------- |
| init    | AGENT-BA  | Detect stack, conventions |
| explore | AGENT-BA  | bdd-scenarios             |
| propose | AGENT-SAD | architecture-governance   |
| spec    | AGENT-SAD | BDD scenarios             |
| design  | AGENT-SAD | api-design-skill          |
| apply   | AGENT-DEV | Framework skills          |
| verify  | AGENT-QA  | testing-skill             |
| archive | AGENT-DOC | documentation             |

## Enforcement

**Mandatory phases (ENFORCED by pre-process-input.ps1):**

- EXPLORE before SPEC — BA must explore requirements first
- SPEC before APPLY — no implementation without approved spec
- VERIFY before ARCHIVE — verification must pass before closing

**SDD FLOW RULE (ENFORCED by pre-process-input.ps1):**

When the system detects a feature/development request (keywords: implementar, crear, desarrollar, build, "nueva funcionalidad", etc.), the pre-process-input.ps1 hook automatically forces PLAN_MODE_REQUIRED → BA/sdd-explore. The agent MUST NOT skip to APPLY even if the trigger matched DEV-style keywords. See `rules/AI-NORMATIVES.md` for canonical definition.

**Flow enforcement:**

1. User request → pre-process-input.ps1 detects feature intent
2. → PLAN_MODE_REQUIRED → activate BA (sdd-explore)
3. BA completes EXPLORE → passes to SAD for SPEC+DESIGN
4. SAD completes → passes to DEV for TASKS+APPLY
5. DEV completes → passes to QA for VERIFY
6. QA passes → ARCHIVE

**If the agent receives TRIGGER_MATCH_FOUND with "implement"/"code"/"develop" and SKILL: sdd-lifecycle:**
→ DO NOT jump to APPLY phase
→ START from INIT or EXPLORE depending on context
→ Check if spec exists in docs/sdd/ before implementing

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
foundation sdd init <name>           # Initialize
foundation sdd explore <name>        # Explore
foundation sdd propose <name>        # Propose
foundation sdd spec <name>          # Write spec
foundation sdd design <name>         # Design
foundation sdd tasks <name>          # Create tasks
foundation sdd apply <name>          # Implement
foundation sdd verify <name>         # Verify
foundation sdd archive <name>         # Archive
foundation sdd status <name>         # Show progress
```
