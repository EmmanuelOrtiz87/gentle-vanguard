# Advanced Features

## Agent Result Schema (FF-007)
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
Usage: `.\wf.ps1 agent DEV "implement feature" -AsJson`

## Skills Auto-Discovery (FF-008)
Auto-detect skills and generate mapping:
```powershell
.\wf.ps1 skills discover    # List all available skills
.\wf.ps1 skills map         # Show auto-generated agent mapping
.\wf.ps1 skills agents      # Show agent skill assignments
.\wf.ps1 skills validate    # Validate skill metadata
```
Scans `skills/` directory, extracts metadata from SKILL.md (name, description, triggers), generates keyword-based agent mapping, identifies unmapped skills.

## Parallel Agent Dispatch (FF-009)
Execute multiple agents in parallel with risk-based lane management:
```powershell
.\wf.ps1 dispatch "DEV,QA" "implement feature" -DryRun         # Preview
.\wf.ps1 dispatch "DEV,QA,BA" "plan sprint"                    # Parallel (default)
.\wf.ps1 dispatch "BA,DEV,QA" "new feature" -Mode adaptive     # Discovery first
.\wf.ps1 dispatch "BA,SAD,DEV" "requirements" -Mode sequential  # Sequential
```

### Execution Modes
| Mode | Behavior | Best For |
|------|----------|----------|
| `parallel` | Concurrent (max 3-4 by risk) | Independent tasks |
| `sequential` | One-by-one with dependencies | Dependent tasks |
| `adaptive` | Discovery agents first, then execution | New features |

### Risk-Based Parallelism
| Risk | Max Parallel | Use Case |
|------|-------------|----------|
| low | 4 | Documentation, testing |
| medium | 3 | Feature development |
| high | 2 | Production deployments |

## Event Bus System (FF-010)
Pub/sub event system for automation and hooks:
```powershell
.\wf.ps1 events list      # List available events
.\wf.ps1 events subscribe dispatch.started
.\wf.ps1 events emit agent.completed '{"agent":"DEV","status":"ready"}'
.\wf.ps1 events history   # View event history
```

### Standard Events
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

## Implementation Status
| Component | Status |
|-----------|--------|
| Agent Registry | ✅ Defined |
| Skill Mapping | ✅ Defined |
| Agent Scripts | ✅ Implemented |
| Agent Result Schema | ✅ Implemented (FF-007) |
| Skills Auto-Discovery | ✅ Implemented (FF-008) |
| Parallel Dispatch | ✅ Implemented (FF-009) |
| Event Bus System | ✅ Implemented (FF-010) |
| Orchestrator Update | ✅ Integrated |
| Documentation | ✅ Updated |
