---
name: workflow-orchestrator
description:
  "Trigger: 'workflow', 'flujo de trabajo', multi-step automation, scheduled tasks, error recovery.
  Advanced workflow automation with DAG-based graphs, intelligent scheduling, dependency management,
  error handling, and real-time monitoring."
metadata:
  source: GV-native
---

# Workflow Orchestrator Skill

## Activation Contract

Load when user mentions "workflow"/"flujo de trabajo", needs to automate complex multi-step
processes, workflow complexity exceeds 5 dependent tasks, autonomous execution needed, or error
recovery required.

## Hard Rules

- Tasks MUST execute in dependency order (DAG topological sort)
- NEVER execute a task whose dependencies have not completed
- Circular dependencies are forbidden — detect and reject
- Every workflow MUST have state tracking and error recovery strategy

## Decision Gates

| Recovery Strategy | Behavior                                  |
| ----------------- | ----------------------------------------- |
| Retry             | Retry up to 3 times with 5s delay         |
| Skip              | Log warning, continue to next task        |
| Rollback          | Execute rollback actions in reverse order |
| Alert             | Notify without stopping                   |

| Schedule Strategy | Behavior                                     |
| ----------------- | -------------------------------------------- |
| OptimalTime       | Based on system load                         |
| ASAP              | Execute immediately when resources available |
| Scheduled         | Use predefined schedule time                 |

## Execution Steps

1. Define workflow as DAG with Name, Tasks, Dependencies
2. Detect and reject circular dependencies
3. Resolve execution order via topological sort (level-order)
4. For each ready task: execute action, track state, handle errors per strategy
5. Pass data between tasks (output → input for dependents)
6. Collect metrics: duration, success rate, anomalies

## Output Contract

- State tracking per task: Name, Status, StartTime, EndTime, Result
- Workflow metrics: TotalDuration, SuccessRate, anomalies
- On failure: rollback state with rolled-back task list

## References

- Full code, examples, tables: [references/code.md](references/code.md)
