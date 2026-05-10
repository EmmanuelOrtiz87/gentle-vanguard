## Session State Machine

### States

1. **START**
   - Run `wf.ps1 ide-status`
   - Refresh session/task artifacts
   - Capture context in Engram

2. **EXECUTE**
   - Apply changes under relevant skills
   - Keep behavior deterministic and idempotent

3. **VALIDATE**
   - Run governance validator and targeted checks
   - Fix blocking failures before publication

4. **AUDIT**
   - Update session/task/audit evidence
   - Persist durable learnings to Engram

5. **PUBLISH**
   - Commit, push, create PR
   - Close only when docs, repo state, and memory state are aligned

6. **HANDOFF**
   - Run `wf.ps1 compact-start [goal]` before moving to a new chat thread
   - Continue in a fresh thread using only compact prompt + immediate request

### Session Activation Strategy

1. Detect IDE session first (`wf.ps1 ide-status`)
2. If known IDE session: continue with auto-init and health checks
3. If unknown/low confidence: explicitly suggest activation command
4. Never block work if auto-detection fails; degrade gracefully

Preferred command order:

1. `.\scripts\utilities\wf.ps1 ide-status`
2. `.\scripts\utilities\wf.ps1 health`
3. `.\scripts\utilities\wf.ps1 start-session [task]`

On-demand fallback:

1. `.\scripts\utilities\stack-on-demand.ps1 -Action activate`
2. `.\scripts\utilities\stack-on-demand.ps1 -Action validate`
3. `.\scripts\utilities\stack-on-demand.ps1 -Action deactivate` at closeout

### Stability Rules

- Automatic activation must be idempotent (safe to run multiple times)
- Avoid noisy or risky auto-installs in routine startup paths
- Print actionable recommendations when auto-start prerequisites are missing
- Keep hooks non-blocking unless security-critical conditions are detected

### Complete Workflow Diagram

```
SESSION WORKFLOW

1. SESSION START
   mem_context
   Detect project/stack
   Check git branch/status
   Load skills
   Present status

2. WORK
   Execute with loaded skills
   Update todos
   Verify each step

3. PRE-PUSH
   Generate AUDIT DOCUMENT
   Run code review (if PR)
   Handle findings

4. VALIDATE SPEC
   Check acceptance criteria

5. ASK USER
   Did we meet the specification?
   Were any findings identified?
   Fix them now or later?
   Create a PR?

6. END SESSION
   Commit changes
   Push (if confirmed)
   mem_save summary
   Present completion summary
```
