# Demo 07 - Mixed Cookbook Real Request

Audience: Executive Council + Small Developer Team

## Summary

This is a single end-to-end simulation that starts from a realistic business request and finishes with implementation, review, audit, and session closure.

## Simulated Request Narrative

A team lead requests:

1. Build a tiny local CLI to track operational tasks for a daily standup.
2. Keep it simple for demo usage only.
3. Show how the stack reduces context/token waste while preserving quality.
4. Produce traceable outputs for review and audit.

## Functional Goal

Implement a simple project in `demos/shared/task-tracker/` with commands:

1. Add task.
2. List tasks.
3. Complete task.
4. Show summary stats.

## Reset Demo to Clean State

**If the demo was interrupted or needs a complete reset:**

```powershell
./scripts/utilities/wf.ps1 reset-demo
```

Or directly:

```powershell
./demos/07-mixed-cookbook-real-request/reset-demo.ps1
```

This will:
-  Terminate any active sessions
-  Clean all task-tracker data (tasks.json)
-  Remove session/context artifacts
-  Re-run preflight to restore clean state
-  Verify all tools are ready

Then you can run the demo again without failures or warnings.

## Start Here

**FIRST: Run the preflight setup script (required on fresh machines):**

```powershell
./demos/07-mixed-cookbook-real-request/preflight.ps1
```

This script will:
- Verify Go and Git are installed.
- Activate the orchestrator if needed.
- Verify task-tracker can run.
- Clean previous demo data if present.

After preflight, proceed with the recipe steps:

1. Open terminal at repository root.
2. Confirm stack status: `./scripts/utilities/wf.ps1 status`
3. Start session with a meaningful task name.
4. If you plan to show Step 4 (Engram segment) live, the preflight already verified availability. No additional setup needed.

```powershell
./scripts/utilities/wf.ps1 status
./scripts/utilities/wf.ps1 orchestrator-status
./scripts/utilities/wf.ps1 start-session "demo task tracker request"
```

## Recipe (Step by Step)

### Step 1 - Orchestrator and Communication Mode

Objective:

1. Show orchestrator status and auto communication preset behavior.

Commands:

```powershell
./scripts/utilities/orchestrator-next-steps.ps1
./scripts/utilities/wf.ps1 response-mode
./scripts/utilities/wf.ps1 response-mode list
```

Expected outcome:

1. Team sees recommended communication mode for this task.
2. Session operates with bounded detail and token-aware output.

### Step 2 - Context and Token Reduction

Objective:

1. Generate compact context before implementation.

Commands:

```powershell
./scripts/utilities/wf.ps1 context-pack "Implement demo task-tracker CLI with add/list/done/stats"
./scripts/utilities/wf.ps1 compact-start "task-tracker implementation"
./scripts/utilities/response-mode-efficiency-matrix.ps1
```

Expected outcome:

1. Compact continuation prompt is generated.
2. Team sees matrix-based estimate of token savings by communication mode.

### Step 3 - AI-Assisted Implementation Loop

Objective:

1. Implement and iterate quickly in `demos/shared/task-tracker/`.

Commands:

```powershell
cd demos/shared/task-tracker
go run . add --title "prepare standup notes"
go run . list
go run . done --id 1
go run . stats
cd ../../..
```

Expected outcome:

1. Feature works end-to-end with minimal local dependencies.
2. AI usage remains bounded by context + response mode controls.

### Step 4 - Engram Continuity

Objective:

1. Show persistent memory workflow.
2. Confirm first-use setup is non-blocking on a fresh machine.

Commands:

```powershell
./scripts/utilities/run-engram.ps1 --help
./scripts/utilities/wf.ps1 compact-start "handoff after task-tracker demo"
```

Expected outcome:

1. Team observes Engram as a lifecycle tool, not a blocker.
2. Continuity strategy between sessions is demonstrated.
3. Less re-briefing overhead in follow-up work.
4. Preflight ensures the environment is ready end-to-end.

### Step 5 - Code Review and Audit

Objective:

1. Produce quality and governance evidence.

Commands:

```powershell
./scripts/utilities/generate-session-review.ps1
./scripts/utilities/generate-session-audit.ps1
./scripts/utilities/generate-audit-report.ps1 -Period weekly
```

Expected outcome:

1. Review and audit artifacts are generated.
2. Executive audience sees traceability and governance posture.

### Step 6 - Session Closure

Objective:

1. Close the cycle with standard closure artifacts.

Commands:

```powershell
./scripts/utilities/wf.ps1 end-session demo-task-tracker
./scripts/utilities/day-end-closure.ps1 -Force
```

Expected outcome:

1. Closure artifacts are generated.
2. Team can continue next day with preserved context and clear status.

## Executive Talking Points (5 Minutes)

1. Request to delivery with one consistent workflow.
2. Measurable token/context reduction controls.
3. Standardized review + audit evidence.
4. Lower rework through session continuity and orchestrator guidance.

## Developer Talking Points (10 Minutes)

1. Commands are deterministic and repeatable.
2. Context-pack and response-mode prevent prompt sprawl.
3. Presets and recommendations reduce decision fatigue.
4. Review/audit/closure are built-in, not ad-hoc.

## Validation Checklist

1. `wf status` and `orchestrator-status` run clean.
2. Task-tracker commands execute without errors.
3. At least one context pack is generated.
4. At least one audit/review artifact is generated.
5. Session closure runs and writes closure report.

## Notes

1. This cookbook intentionally prioritizes operational simplicity over product complexity.
2. Use this as the default showcase for mixed audience sessions.
3. If a shorter demo is needed, execute Step 1, Step 2, Step 5, and Executive Talking Points.
4. Step 4 is optional for environments where Engram should not be demonstrated live; the rest of the demo remains fully runnable.
