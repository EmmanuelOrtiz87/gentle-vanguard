---
name: sia-skill
description: >
  Self-Improving Agent (SIA) loop. File-based workflow: META generates target, FEEDBACK reviews,
  orchestrator evaluates score and decides retry. Triggers: "self-improving", "auto-mejora",
  "sia loop", "meta-agent", "feedback agent", "self improvement", "improve yourself".
metadata:
  source: GV-native
  version: 1.0
---

# SIA Skill

Self-Improving Agent loop for iterative code generation with feedback.

## Architecture (file-based)

```
┌──────────────────────────────────────────────────┐
│               SIA Orchestrator (.ps1)             │
│                                                   │
│  init → write prompt-meta-N.md → [AGENT writes]   │
│  save-target → write prompt-feedback-N.md         │
│  save-review → parse score → retry or pass        │
│                                                   │
│  State: .sia/<session>/state.json                 │
│  Artifacts: target-N.ps1, review-N.md             │
└──────────────────────────────────────────────────┘
```

## Workflow (how to use)

Each SIA cycle requires agent interaction — the script manages state, the agent does the generation:

```
1. INIT:  sia-orchestrator.ps1 -Action init -TaskSpec "..." -SessionId "x"
          → creates .sia/x/ directory, writes spec.md

2. META:  sia-orchestrator.ps1 -Action meta -SessionId "x"
          → writes prompt-meta-1.md → status: pending-agent
          → AGENT reads prompt, generates target.ps1

3. SAVE:  sia-orchestrator.ps1 -Action save-target -SessionId "x" -TargetPath ./output.ps1
          → stores as target-1.ps1 → status: pending-feedback

4. FEED:  sia-orchestrator.ps1 -Action feedback -SessionId "x"
          → writes prompt-feedback-1.md → status: pending-agent
          → AGENT reads prompt, writes review-1.md

5. REVW:  sia-orchestrator.ps1 -Action save-review -SessionId "x" -ReviewPath ./review.md
          → parses Score: N from review → flags pass/retry

6. LOOP:  If score < threshold (80): go to step 2 (iteration N+1)
          If score ≥ threshold: done
```

## Scoring

| Criterion   | Weight | Checked by FEEDBACK agent |
|-------------|--------|---------------------------|
| Correctness | 30%    | Solves the problem, no bugs |
| Efficiency  | 20%    | Optimal approach, no unnecessary complexity |
| Style       | 15%    | GV conventions, idiomatic |
| Safety      | 20%    | No secrets, no side effects, input validation |
| Docs        | 15%    | Comments, clear interface |

Score ≥ 80 = pass. Max 5 iterations.

## Example

```powershell
# 1. Initialize
$sid = "my-task"
.\scripts\sia\sia-orchestrator.ps1 -Action init -TaskSpec "Write a PowerShell lister" -SessionId $sid

# 2. Generate META prompt → agent writes target.ps1
.\scripts\sia\sia-orchestrator.ps1 -Action meta -SessionId $sid
#   (read .sia/my-task/prompt-meta-1.md, generate code, save as .sia/my-task/target-1.ps1)

# 3. Save target
.\scripts\sia\sia-orchestrator.ps1 -Action save-target -SessionId $sid -TargetPath ".sia/my-task/target-1.ps1"

# 4. Generate FEEDBACK prompt → agent writes review
.\scripts\sia\sia-orchestrator.ps1 -Action feedback -SessionId $sid
#   (read .sia/my-task/prompt-feedback-1.md, write review as .sia/my-task/review-1.md)

# 5. Save review, check score
.\scripts\sia\sia-orchestrator.ps1 -Action save-review -SessionId $sid -ReviewPath ".sia/my-task/review-1.md"

# 6. Check status
.\scripts\sia\sia-orchestrator.ps1 -Action score -SessionId $sid -Json
```

## Files

| File | Purpose |
|------|---------|
| `scripts/sia/sia-orchestrator.ps1` | Workflow state machine (init/meta/feedback/save/score) |
| `config/agent-prompts/SIA-META.md` | Meta-agent prompt template |
| `config/agent-prompts/SIA-FEEDBACK.md` | Feedback-agent prompt template |
| `.sia/<session>/` | Per-session state: spec, prompts, targets, reviews |
| `docs/sia/BENCHMARK-TASKS.md` | 4 internal benchmark tasks |
| `docs/plans/FASE4-SIA-ADAPTATION.md` | Full adaptation plan |
