# Session Guide

## Quick Commands

| Command | Description |
|---------|-------------|
| `Continuar` | Resume work, check context |
| `Estado` | Show project status |
| `Guardar` | Commit & push changes |
| `Review` | Run code review |
| `PR` | Create pull request |

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
1. Orchestrator auto-detects:
   - Project type
   - Tech stack
   - Available skills
   - Git branch status

2. Memory check:
   - mem_context
   - Show recent work

3. Present status:
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
4. Ask: Create PR?
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
.\wf.ps1 review     # Code review
.\wf.ps1 audit      # Generate audit doc
.\wf.ps1 pr         # PR template
.\wf.ps1 status     # Show status
.\wf.ps1 push       # Prepare to push
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
1. Secrets scan
2. Format check
3. Basic tests

### Pre-push Hook

Automatically runs:
1. Full code review
2. Tests verification
3. Audit document generation

---

## Best Practices

### Before Any Commit

- [ ] Tests pass
- [ ] No secrets
- [ ] Commit message follows convention
- [ ] Code follows project patterns

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
