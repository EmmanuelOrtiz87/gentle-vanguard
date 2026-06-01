---
name: adaptive-orchestrator
description:
  'Trigger: enforce norms, learn norms, validate documentation placement, check adaptive rules, run
  norm enforcer, update learned norms. Autonomous norm enforcement and learning system with 5
  self-healing layers.'
metadata:
  source: GV-native
---

# Adaptive Orchestrator

## Activation Contract

Load on session start/close or when user triggers: "run autonomous stack", "backup now", "check
drift", "run tests autonomous", "restore from backup". Auto-triggers from session lifecycle events.

## Hard Rules

- MUST execute all systems via `scripts/adaptive/*.ps1` scripts
- MUST NOT block commits (non-blocking at session boundaries)
- MUST use AES-256 encryption for backups (key derived from stack identity)
- MUST only log metadata (paths, timestamps) for doc-drift — NO code/doc content
- MUST retry max 3x before escalation to human

## Decision Gates

| Event               | System Run           | Action                                 |
| ------------------- | -------------------- | -------------------------------------- |
| Session start       | Backup Orchestrator  | Restore if needed                      |
| Session start       | Norm Enforcer        | Validate docs, create dirs             |
| Session start/close | Norm Learner         | Query Engram, promote norms            |
| Session close       | Doc-Drift Detector   | Compare timestamps, delegate           |
| Session start/close | Testing Orchestrator | Detect project, run tests, auto-repair |
| Manual trigger      | All 5 systems        | Full autonomous stack                  |

## Execution Steps

1. **Backup Orchestrator**: `auto-backup-orchestrator.ps1 -Action restore` (start) or
   `-Action backup` (close)
2. **Norm Enforcer**: `auto-norm-enforcer.ps1 -Trigger <event> -AutoFix` — creates missing dirs,
   applies standards
3. **Norm Learner**: `auto-norm-learner.ps1 -Trigger <event>` — extracts patterns from Engram,
   promotes to `rules/custom/`
4. **Doc-Drift Detector**: `auto-doc-drift-detector.ps1 -Trigger <event>` — compares code vs doc
   timestamps, auto-delegates fixes
5. **Testing Orchestrator**: `auto-testing-final.ps1 -Trigger <event>` — detects project type
   (Node/Go/Python), runs tests, auto-repairs

## Output Contract

Return session state (Ready / Closed). Log results for Judgment Day review. Store encrypted backup
to `.backups/`. Report any escalation cases (3 retries exhausted).

## References

- All scripts: `scripts/adaptive/`
- On-demand commands, diagrams, test scripts, status notes: `references/appendix.md`
