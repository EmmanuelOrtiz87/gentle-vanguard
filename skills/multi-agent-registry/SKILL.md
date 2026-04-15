---
name: multi-agent-registry
description: >
  Multi-agent specialization registry defining 7 specialized sub-agents.
  Trigger: When orchestrator needs to delegate tasks to specialized agents.
  Replaces monolithic orchestrator pattern with distributed specialist agents.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# MULTI-AGENT SPECIALIZATION REGISTRY

## ARCHITECTURE OVERVIEW

```
ORCHESTRATOR (context slim - only orchestrates)
│
├── AGENT-BA     → Business Analysis & Requirements
├── AGENT-SAD    → Solution Architecture & Design
├── AGENT-DEV    → Development & Implementation
├── AGENT-QA     → Quality Assurance & Testing
├── AGENT-OPS    → DevOps & Infrastructure
├── AGENT-GOV    → Governance & Observability
└── AGENT-DOC    → Documentation & Specifications
```

## DELEGATION MODEL

**Orchestrator responsibilities:**
- Task decomposition and routing
- Cross-agent coordination
- Final validation and handoff
- Session management and memory

**Agent responsibilities:**
- Domain-specific execution
- Skill application
- Focused output within scope

---

## AGENT-BA: Business Analyst

### ROLE
Analyzes requirements, creates BDD scenarios, defines acceptance criteria.

### SKILLS ASSIGNED
- bdd-scenarios-skill
- documentation-governance
- requirements patterns

### TRIGGERS
```
requirements, user story, BDD, Gherkin, acceptance criteria,
feature analysis,需求分析, especificación funcional
```

### DELIVERABLES
- BDD scenario files (`docs/specs/*.feature`)
- Acceptance criteria documents
- User story mappings
- Requirements traceability matrix

### COMMANDS
```powershell
# Activate BA agent
.\scripts\utilities\wf.ps1 agent BA "<task>"

# Generate BDD scenarios
.\scripts\utilities\wf.ps1 bdd "<feature-description>"
```

---

## AGENT-SAD: Solution Architect & Designer

### ROLE
Defines system architecture, creates SDD documents, makes technical decisions.

### SKILLS ASSIGNED
- architecture-governance
- api-design-skill
- database-relational-skill
- database-nosql-skill
- typescript-skill
- golang-api-skill

### TRIGGERS
```
architecture, design, SDD, system design, API design,
database schema, technical decision, arquitectura, diseño
```

### DELIVERABLES
- SDD documents (`docs/specs/SDD-*.md`)
- Architecture decision records (ADR)
- API contracts and schemas
- Database design documents

### COMMANDS
```powershell
# Activate SAD agent
.\scripts\utilities\wf.ps1 agent SAD "<task>"

# Generate SDD
.\scripts\utilities\wf.ps1 sdd "<feature-name>"
```

---

## AGENT-DEV: Senior Developer

### ROLE
Implements features, writes code, performs refactoring.

### SKILLS ASSIGNED
- angular-spa-skill
- react-19-skill
- nextjs-15-skill
- tailwind-4-skill
- zustand-5-skill
- zod-4-skill
- security-skill
- technical-debt-skill

### TRIGGERS
```
implement, code, develop, feature, refactor, fix bug,
frontend, backend, component, API endpoint
```

### DELIVERABLES
- Source code implementations
- Code refactoring
- Technical debt records
- Security hardening

### COMMANDS
```powershell
# Activate DEV agent
.\scripts\utilities\wf.ps1 agent DEV "<task>"

# Create component
.\scripts\utilities\wf.ps1 scaffold "<component-name>"
```

---

## AGENT-QA: Quality Assurance

### ROLE
Creates tests, validates functionality, ensures quality gates.
Owns Judgment Day: dual-review adversarial protocol for pre-merge validation.

### SKILLS ASSIGNED
- testing-strategy-skill
- testing-skill
- playwright-skill
- pytest-skill
- code-review-orchestrator-skill (judgment-day)

### TRIGGERS
```
test, testing, QA, validation, E2E, unit test,
integration test, playwright, pytest, calidad,
judgment day, juicio final, dia del juicio, revision de a pares,
dual review, adversarial review, corre juicio, ejecuta juicio,
activa juicio, realizar juicio, corre dual review,
corre adversarial, revision profunda pre-merge
```

### DELIVERABLES
- Test files and suites
- E2E test scenarios
- Test coverage reports
- Validation evidence
- Judgment Day verdict reports

### COMMANDS
```powershell
# Activate QA agent
.\scripts\utilities\wf.ps1 agent QA "<task>"

# Run tests
.\scripts\utilities\wf.ps1 test "<scope>"

# Judgment Day - dual review
.\scripts\utilities\wf.ps1 review --scope judgment-day
.\scripts\utilities\wf.ps1 review --scope judgment-day --target <path>
```

---

## AGENT-OPS: DevOps & Infrastructure

### ROLE
Manages deployment, CI/CD, infrastructure as code.

### SKILLS ASSIGNED
- docker-devops-skill
- kubernetes-deployment
- terraform-infrastructure
- git-workflow-skill
- release-management-skill

### TRIGGERS
```
deploy, CI/CD, Docker, Kubernetes, infrastructure,
Terraform, helm, release, ops, DevOps
```

### DELIVERABLES
- Docker configurations
- Kubernetes manifests
- CI/CD pipeline definitions
- Deployment runbooks

### COMMANDS
```powershell
# Activate OPS agent
.\scripts\utilities\wf.ps1 agent OPS "<task>"

# Deploy
.\scripts\utilities\wf.ps1 deploy "<environment>"
```

---

## AGENT-GOV: Governance & Observability

### ROLE
Ensures compliance, monitors metrics, handles incidents.

### SKILLS ASSIGNED
- observability-skill
- incident-response-plan
- security-skill
- code-review-orchestrator-skill

### TRIGGERS
```
governance, compliance, metrics, monitoring, observability,
incident, security audit, review, auditoría
```

### DELIVERABLES
- Audit reports
- Compliance documentation
- Incident runbooks
- Monitoring dashboards

### COMMANDS
```powershell
# Activate GOV agent
.\scripts\utilities\wf.ps1 agent GOV "<task>"

# Run audit
.\scripts\utilities\wf.ps1 audit
```

---

## AGENT-DOC: Documentation

### ROLE
Creates and maintains all project documentation.

### SKILLS ASSIGNED
- documentation-governance
- sdd-skill
- github-pr-skill

### TRIGGERS
```
documentation, docs, README, guide, runbook,
BDD specs, SDD specs, specification
```

### DELIVERABLES
- README files
- API documentation
- Runbooks and guides
- BDD/SDD specifications

### COMMANDS
```powershell
# Activate DOC agent
.\scripts\utilities\wf.ps1 agent DOC "<task>"

# Generate docs
.\scripts\utilities\wf.ps1 docs "<type>"
```

---

## SKILL MAPPING MATRIX

| Skill | BA | SAD | DEV | QA | OPS | GOV | DOC |
|-------|----|-----|-----|-----|-----|-----|-----|
| bdd-scenarios | ✓ |   |   |   |   |   |   |
| architecture |   | ✓ |   |   |   |   |   |
| api-design |   | ✓ |   |   |   |   |   |
| database-relational |   | ✓ |   |   |   |   |   |
| database-nosql |   | ✓ |   |   |   |   |   |
| typescript |   | ✓ | ✓ |   |   |   |   |
| angular-spa |   |   | ✓ |   |   |   |   |
| react-19 |   |   | ✓ |   |   |   |   |
| nextjs-15 |   |   | ✓ |   |   |   |   |
| tailwind-4 |   |   | ✓ |   |   |   |   |
| zustand-5 |   |   | ✓ |   |   |   |   |
| zod-4 |   |   | ✓ |   |   |   |   |
| security |   |   | ✓ |   |   | ✓ |   |
| testing-strategy |   |   |   | ✓ |   |   |   |
| testing |   |   |   | ✓ |   |   |   |
| playwright |   |   |   | ✓ |   |   |   |
| pytest |   |   |   | ✓ |   |   |   |
| docker-devops |   |   |   |   | ✓ |   |   |
| kubernetes |   |   |   |   | ✓ |   |   |
| terraform |   |   |   |   | ✓ |   |   |
| git-workflow |   |   |   |   | ✓ |   |   |
| observability |   |   |   |   |   | ✓ |   |
| incident-response |   |   |   |   |   | ✓ |   |
| code-review |   |   |   |   |   | ✓ |   |
| documentation |   |   |   |   |   |   | ✓ |
| sdd |   | ✓ |   |   |   |   | ✓ |
| github-pr |   |   |   |   |   |   | ✓ |

---

## DELEGATION FLOW

```
USER REQUEST
     │
     ▼
┌─────────────────────────┐
│     ORCHESTRATOR        │
│  (decompose & route)    │
└────────────┬────────────┘
             │
    ┌────────┼────────┐
    │        │        │
    ▼        ▼        ▼
  [BA]     [SAD]    [DEV]
    │        │        │
    └────────┼────────┘
             │
             ▼
    ┌────────────────┐
    │  CROSS-AGENT   │
    │  COORDINATION  │
    └───────┬────────┘
            │
    ┌───────┴───────┐
    │               │
    ▼               ▼
 [QA]            [OPS]
    │               │
    └───────┬───────┘
            │
            ▼
┌─────────────────────────┐
│  ORCHESTRATOR VALIDATE  │
│  (final check & handoff)│
└─────────────────────────┘
```

---

## TOKEN EFFICIENCY GAINS

| Pattern | Tokens/Session | Reduction |
|---------|----------------|----------|
| Monolithic (orchestrator does all) | ~50K | baseline |
| 3-agent specialization | ~35K | 30% |
| 7-agent specialization | ~20K | 60% |

**Key savings:**
- Orchestrator: slim context (~5K tokens)
- Each agent: loads only domain skills (~2-3K per agent)
- Parallel execution: compounds savings

---

## AGENT RESULT SCHEMA (FF-007)

Structured JSON output for agent results enabling merge/consolidation:

```json
{
  "lane_id": "agent-DEV-timestamp",
  "agent": "DEV",
  "role": "Developer - Implementation",
  "status": "success|failed|blocked|partial",
  "task": "implementation task description",
  "action": "run|plan|validate",
  "timestamp": "2026-04-15T...",
  "skills_loaded": ["angular-spa", "typescript"],
  "skills_missing": [],
  "deliverables_expected": ["source-code", "refactoring"],
  "files_touched": [],
  "findings": [],
  "validation_result": { "passed": true },
  "next_action": "merge-output",
  "token_estimate": 2400
}
```

**Usage:**
```powershell
.\wf.ps1 agent DEV "implement feature" -AsJson
```

---

## SKILLS AUTO-DISCOVERY (FF-008)

Auto-detect skills and generate mapping:

```powershell
.\wf.ps1 skills discover    # List all available skills
.\wf.ps1 skills map         # Show auto-generated agent mapping
.\wf.ps1 skills agents      # Show agent skill assignments
.\wf.ps1 skills validate    # Validate skill metadata
```

**Discovery Features:**
- Scans `skills/` directory automatically
- Extracts metadata from SKILL.md (name, description, triggers)
- Generates keyword-based agent mapping
- Identifies unmapped skills

---

## PARALLEL AGENT DISPATCH (FF-009)

Execute multiple agents in parallel with risk-based lane management:

```powershell
# Dry run - preview execution plan
.\wf.ps1 dispatch "DEV,QA" "implement feature" -DryRun

# Execute in parallel mode (default)
.\wf.ps1 dispatch "DEV,QA,BA" "plan sprint"

# Execute in adaptive mode (discovery first, then execution)
.\wf.ps1 dispatch "BA,DEV,QA" "new feature" -Mode adaptive

# Execute sequentially with dependencies
.\wf.ps1 dispatch "BA,SAD,DEV" "requirements" -Mode sequential
```

**Execution Modes:**
| Mode | Behavior | Best For |
|------|----------|----------|
| `parallel` | Concurrent execution (max 3-4 by risk) | Independent tasks |
| `sequential` | One-by-one with dependencies | Dependent tasks |
| `adaptive` | Discovery agents first, then execution | New features |

**Risk-Based Parallelism:**
| Risk | Max Parallel | Use Case |
|------|-------------|----------|
| low | 4 | Documentation, testing |
| medium | 3 | Feature development |
| high | 2 | Production deployments |

---

## EVENT BUS SYSTEM (FF-010)

Pub/sub event system for automation and hooks:

```powershell
# List available events
.\wf.ps1 events list

# Subscribe to event
.\wf.ps1 events subscribe dispatch.started

# Emit custom event
.\wf.ps1 events emit agent.completed '{"agent":"DEV","status":"ready"}'

# View event history
.\wf.ps1 events history
```

**Standard Events:**
| Event | Trigger |
|-------|---------|
| `dispatch.started` | Parallel dispatch begins |
| `dispatch.completed` | Parallel dispatch finishes |
| `agent.dispatched` | Single agent dispatched |
| `agent.completed` | Single agent completes |
| `session.started/ended` | Session lifecycle |
| `workflow.checkpoint` | Checkpoint created |
| `workflow.publish` | Publish/commit action |
| `validation.started/completed` | Validation lifecycle |

---

## IMPLEMENTATION STATUS

| Component | Status |
|-----------|--------|
| Agent Registry | ✓ Defined |
| Skill Mapping | ✓ Defined |
| Agent Scripts | ✓ Implemented |
| Agent Result Schema | ✓ Implemented (FF-007) |
| Skills Auto-Discovery | ✓ Implemented (FF-008) |
| Parallel Dispatch | ✓ Implemented (FF-009) |
| Event Bus System | ✓ Implemented (FF-010) |
| Orchestrator Update | ✓ Integrated |
| Documentation | ✓ Updated |

---

## REFERENCES

- Skill Index: [SKILL_INDEX.md](../SKILL_INDEX.md)
- Orchestrator: [project-orchestrator-skill](../project-orchestrator-skill/SKILL.md)
- Documentation: [documentation-governance](../documentation-governance/SKILL.md)
- Future Backlog: [FUTURE-FEATURES-BACKLOG.md](../../docs/reference/FUTURE-FEATURES-BACKLOG.md)
