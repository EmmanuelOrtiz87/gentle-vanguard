
- **Session close**: Run automatically during session closure (step between summary and end)
- **Manual trigger**: User can run `gv learning` to analyze current session anytime
- **Proposal executor**: Run `gv learning apply` to auto-execute pending proposals (scaffold skills, patch configs)
- **Auto mode**: `gv learning auto` runs analysis + auto-applies low-severity proposals in one step
- **PR mode**: `gv learning auto-pr` auto-applies + creates a git branch and commit with changes
- **Startup check**: At session start, check `.local/improvement-proposals/` for pending items

## Command Flow

```
session-learning-capture.ps1  →  usage-tracker.ps1  →  skill-nudge.ps1  →  skill-auto-patch.ps1  →  mem_save
```

## Output Files

| File                                              | Purpose                              |
| ------------------------------------------------- | ------------------------------------ |
| `.local/improvement-proposals/*.json`             | Structured improvement proposals     |
| `.local/improvement-proposals/learning-log.jsonl` | Append-only log of all learning runs |
| `.session/skill-usage/*.json`                     | Per-skill usage metrics              |
| `.session/skill-nudges/*.json`                    | Auto-generated nudge recommendations |