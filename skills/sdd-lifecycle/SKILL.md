---
name: sdd-lifecycle
description: >
  Spec-Driven Development (SDD) complete lifecycle - all phases in one skill. Triggers: "sdd",
  "spec", "spec-driven", "write spec", "feature spec", 
  "sdd init", "sdd explore", "sdd research", "sdd propose", "sdd spec", "sdd design", "sdd tasks", "sdd apply", "sdd
  verify", "sdd archive"
metadata:
  source: GV-native
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

### Phase 2.5: RESEARCH (optional lane)

**Trigger:** `sdd research`, `research questions`, `external evidence`

External-evidence lane selectable right after EXPLORE. Requires an existing
case (`.sdd/<feature>/`) — fail-closed. Produces a versioned artifact
(`gentle-vanguard.sdd-research/v1`) recording questions, graded sources,
claim-to-source mapping and contradictions:

```
1. npm run sdd:research -- run -f <feature> -q "q1;q2" --deep   # deterministic base
2. Agent layer fills "Mapeo claim → fuente" + "Contradicciones" scaffolds
3. Low-confidence questions must be resolved before PROPOSE
4. Artifact: .sdd/<feature>/RESEARCH/{artifact.md, research.json}
```

PROPOSE automatically surfaces the research summary. Command: `/sdd-research`.

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

---

> **Referencia detallada**: [
eferences/detail.md](references/detail.md)
```

## Usage

Use **sdd-lifecycle** when a task matches its triggers (sdd-lifecycle).

Purpose: Spec-Driven Development (SDD) complete lifecycle - all phases in one skill.

## Examples

Concrete usage drawn from this skill's own documentation:

```

                    SDD LIFECYCLE



    INIT    EXPLORE  PROPOSE   SPEC



         TASKS    DESIGN




                   APPLY




                  VERIFY




                  ARCHIVE



```
