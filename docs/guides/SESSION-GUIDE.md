# Session Guide

## Quick Commands

| Command | Description |
|---------|-------------|
| `Continuar` | Resume work, check context |
| `Estado` | Show project status |
| `Guardar` | Commit & push changes |
| `Review` | Run code review |
| `PR` | Create pull request |
| `Health` | Check system health & activate tools |
| `Start Session` | Create session brief and optional task brief |

---

## Automatic Tool Activation

The Gentleman Foundation automatically ensures all development tools are active:

### Auto-Activation Triggers
- **Pre-commit**: Tools validated before each commit
- **Session start**: Session brief artifacts are generated
- **Manual**: Use `.\wf.ps1 health` anytime

### Tools Activated
- **Engram**: Memory system for context persistence
- **GGA**: Gentleman Guardian Angel (code review)
- **Gentle-AI**: AI CLI assistant
- **Orchestrator Skills**: Project coordination system

### Manual Activation
```powershell
# Check and activate all tools
.\wf.ps1 health

# Create the session brief for today
.\wf.ps1 start-session

# Create the session brief and the first task brief
.\wf.ps1 start-session api-hardening

# Force auto-start missing tools
.\wf.ps1 health -Force

# Auto-init environment (any directory)
.\scripts\utilities\auto-init-dev-environment.ps1
```

---

## Workflow

### 0. Workspace Hygiene

```
1. Remove temporary or backup files immediately.
2. Do not keep duplicate or stale folders or files.
3. Use symbols and formatting only in documentation, not in code/config.
4. Remove stale references to deleted files.
```

### 1. Session Start

```
1. Run the standard bootstrap:
   - .\wf.ps1 health
   - .\wf.ps1 start-session [task-name]

2. Orchestrator auto-detects:
   - Project type
   - Tech stack
   - Available skills
   - Git branch status

3. Memory check:
   - mem_context
   - Show recent work

4. Review generated artifacts:
   - docs/sessions/YYYY-MM-DD-HHmmss-session-start.md
   - docs/tasks/<task>.md

5. Present status:
   - Project name
   - Branch
   - Pending tasks
   - Next step
```

### 2. During Work

```
1. Execute with loaded skills
2. Update todo list
3. Verify each step
4. Run tests locally
```

### 3. Before Push/PR

```
1. Run: wf.ps1 review
2. Generate: Audit document
3. Check: Specification complete?
4. Optional closeout: wf.ps1 push (prints guided commit/push commands)
5. Ask: Create PR?
```

### 4. Code Review (7 Dimensions)

| Dimension | Severity | Auto |
|-----------|----------|------|
| Security | CRITICAL/HIGH | Yes |
| Quality | HIGH/MEDIUM | Yes |
| Architecture | MEDIUM | No |
| Testing | MEDIUM | No |
| Documentation | LOW | No |
| API Design | MEDIUM | No |
| Git Workflow | LOW | No |

### 5. Findings Decision

```
[X] CRITICAL -> Block immediately, fix now
[!]️ HIGH     -> Must fix before PR
[-] MEDIUM   -> Your choice
[*] LOW      -> Optional fixes
```

---

## Commands Reference

### Orchestrator Commands

```bash
Continuar     # Resume work
Estado        # Show status
Guardar       # Commit & push
Review        # Run code review
PR            # Create PR
```

### CLI Commands

```powershell
.\wf.ps1 start-session [task]  # Create session brief and optional task brief
.\wf.ps1 task-brief <task>     # Create or refresh a task brief
.\wf.ps1 review     # Code review
.\wf.ps1 audit      # Generate audit doc
.\wf.ps1 pr         # PR template
.\wf.ps1 status     # Show status
.\wf.ps1 push       # Prepare to push
.\wf.ps1 update-all # Alias for full update workflow
.\wf.ps1 homologate # Preview cleanup/homologation actions
.\wf.ps1 homologate apply # Apply cleanup/homologation actions
.\wf.ps1 health -StrictCleanup # Health + cleanup drift gate
```

### Git Commands

```bash
git status              # Check changes
git add .               # Stage changes
git commit -m "..."     # Commit
git push                # Push to remote
gh pr create            # Create PR
```

---

## Workflow Automation

### wf.ps1 Workflow

```powershell
# 1. Check status
.\wf.ps1 status

# 2. Run code review
.\wf.ps1 review

# 3. Generate audit
.\wf.ps1 audit

# 4. Create PR
.\wf.ps1 pr
```

### Pre-commit Hook

Automatically runs:
1. Project validation script (when hook is installed)
2. Cross-platform PowerShell execution fallback

### Pre-push Hook

Automatically runs:
1. Protected branch warning checks
2. Local test checks for Node/Go projects
3. Conventional commit warning (advisory)

Note: hook installation depends on local Git hook wiring. Canonical script paths are under `scripts/git-hooks/`.

---

## Best Practices

### Before Any Commit

- [ ] Tests pass
- [ ] No secrets
- [ ] Commit message follows convention
- [ ] Code follows project patterns
- [ ] Task brief is still aligned with the work actually done

### Before Any PR

- [ ] All tests pass
- [ ] Code review completed
- [ ] Audit document generated
- [ ] Specification validated
- [ ] Documentation updated

### Before Push

- [ ] Review findings resolved
- [ ] Audit document created
- [ ] Changes documented

---

## Questions to Ask

### During Session

```
¿Cumplimos con la especificación?
¿Hay algo que olvidamos?
¿Los cambios están listos?
¿El task brief sigue representando el alcance real?
```

### Before PR

```
¿Findings de code review?
  - CRITICAL/HIGH: Must fix
  - MEDIUM: Your choice
  - LOW: Optional

¿Creamos PR o trabajamos más?
```

---

## Resources

- [Orchestrator Skill](../skills/project-orchestrator-skill/SKILL.md)
- [Git Workflow Skill](../skills/git-workflow-skill/SKILL.md)
- [Code Review Skill](../skills/code-review-orchestrator-skill/SKILL.md)
- [AGENTS.md](../AGENTS.md)
