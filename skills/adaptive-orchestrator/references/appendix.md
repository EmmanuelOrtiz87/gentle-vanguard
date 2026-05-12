# Appendix: Additional Details

## Autonomous Flow Diagram

```
Session Event (Start/Close)
   │
   ├── 1. Auto Backup (restore if session-start, backup if session-close)
   ├── 2. Norm Enforcer (validate docs, create missing dirs)
   ├── 3. Norm Learner (query Engram, update norms)
   ├── 4. Doc-Drift Detector (compare code vs docs, auto-delegate)
   └── 5. Auto Testing (non-block: run tests, auto-repair, log for Judgment Day)
         │
    Session Ready / Closed
```

## Integration with Commit Hooks

| Stage         | System               | Blocking? | Purpose                              |
| ------------- | -------------------- | --------- | ------------------------------------ |
| Pre-commit    | Hooks check-\*.ps1   | YES       | Quick validation (security, quality) |
| Session close | 5 autonomous systems | NO        | Log for Judgment Day                 |
| Judgment Day  | Adversarial review   | YES       | Deep review before merge             |

## Security Architecture

- All Backups: AES-256 Encrypted
- Key: Derived from stack identity
- Storage: `.backups/` (local, in `.gitignore`)
- Doc-Drift: Metadata only (paths, timestamps, NO code/doc content)

## On-Demand Commands

| User Says              | Action                                         |
| ---------------------- | ---------------------------------------------- |
| "run autonomous stack" | Execute all 5 systems                          |
| "backup now"           | `auto-backup-orchestrator.ps1 -Action backup`  |
| "check drift"          | `auto-doc-drift-detector.ps1 -Trigger manual`  |
| "run tests autonomous" | `auto-testing-final.ps1 -Trigger manual`       |
| "restore from backup"  | `auto-backup-orchestrator.ps1 -Action restore` |

## Quick Test (Verify All Systems)

```powershell
cd .\foundation
.\scripts\adaptive\auto-backup-orchestrator.ps1 -Action check -VerboseOutput
.\scripts\adaptive\auto-norm-enforcer.ps1 -Trigger manual -AutoFix
.\scripts\adaptive\auto-norm-learner.ps1 -Trigger manual
.\scripts\adaptive\auto-doc-drift-detector.ps1 -Trigger manual
.\scripts\adaptive\auto-testing-final.ps1 -Trigger manual
```

## Status Notes

- **Session boundaries**: Full autonomy (start/close)
- **Commits**: Fast hooks (security, non-blocking for autonomy)
- **Judgment Day**: Run manually for deep review
- **Escalation**: Only if retries exhausted (3x) in auto-delegation
