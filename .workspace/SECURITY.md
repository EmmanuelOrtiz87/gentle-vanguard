# SECURITY SYSTEM - Foundation

## Access Control Overview

```
                    ┌─────────────────────────────────────┐
                    │     RESTRICTED OPERATION           │
                    │  (skill-optimizer, orchestrator)   │
                    └──────────────┬────────────────────┘
                                   │
                    ┌──────────────▼──────────────────────┐
                    │  AUTHENTICATION REQUIRED           │
                    │  1. Check session (8hr cache)        │
                    │  2. If not → require credentials    │
                    └──────────────┬──────────────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                    │
    ┌──────────▼──────────┐  ┌──────▼──────┐  ┌────────▼────────┐
    │    API KEY          │  │ SECURITY   │  │    DENIED       │
    │    (preferred)      │  │ QUESTIONS  │  │    (wrong)      │
    └──────────┬─────────┘  └──────┬──────┘  └─────────────────┘
               │                   │
               │         ┌─────────▼─────────┐
               │         │ 3 correct →        │
               │         │ recover API key    │
               │         │ → authenticate     │
               │         └───────────────────┘
               │
       ┌───────▼────────┐
       │ AUTHENTICATED   │
       │ Session: 8hrs   │
       └─────────────────┘
```

## API Key

```
Key: fnd_local_2026_Emmanuel_

Location: .workspace/config/owner-auth.json (ENCRYPTED)
```

## Security Questions

| # | Question | Stored |
|---|----------|--------|
| Q1 | Nombre de tu primera mascota? | sha256:xxxxx |
| Q2 | Ciudad donde naciste? | sha256:xxxxx |
| Q3 | Nombre de tu mejor amigo de infancia? | sha256:xxxxx |

## How to Authenticate

### Option 1: API Key (Fast)
```powershell
.\scripts\utilities\auth-session.ps1 -ApiKey "fnd_local_2026_Emmanuel_"
# Result: Session authenticated for 8 hours
```

### Option 2: Security Questions (Recovery)
```powershell
.\scripts\utilities\auth-session.ps1 -UseSecurityQuestions
# Prompt for 3 answers
# If all correct → show API key option to authenticate
```

## What is Blocked

### For Developers (without authentication)

| Category | Blocked |
|----------|---------|
| Files | tools/skills/*, skills/*, AGENTS.md, .workspace/config/* |
| Commands | skill-optimizer, orchestrator, admin, config |
| Intents | "change orchestrator", "modify skill", "update architecture" |

### Error Messages

```powershell
# Attempting restricted operation without auth
> wf.ps1 skill-optimizer analyze

[ERROR] Esta operación requiere autenticación del owner
[INFO] Use: .\scripts\utilities\auth-session.ps1 -ApiKey <key>
   or: .\scripts\utilities\auth-session.ps1 -UseSecurityQuestions
```

```powershell
# Invalid API key
> .\scripts\utilities\auth-session.ps1 -ApiKey "wrong"

[X] API key inválida
[INFO] Usa --security-questions si la olvidaste
```

```powershell
# Wrong security answers
> .\scripts\utilities\auth-session.ps1 -UseSecurityQuestions

Q1: Nombre de tu primera mascota?
Answer: ****
[X] Incorrect

Q2: Ciudad donde naciste?
Answer: ****
[X] Incorrect

Q3: Nombre de tu mejor amigo de infancia?
Answer: ****
[X] Incorrect

[ERROR] Solo 0/3 respuestas correctas
⛔ ACCESS DENIED
No tienes permisos para realizar esta operación.
```

## Escalation Workflow

```
Developer wants to modify skill/orchestrator
         │
         ▼
NO DIRECT ACCESS (BLOCKED)
         │
         ▼
.Can submit escalation request
.\wf.ps1 skill-optimizer request improve --skill "xxx" --reason "..."
         │
         ▼
Goes to: .workspace/escalations/pending/
         │
         ▼
Owner reviews (authenticated)
         │
    ┌────┴────┐
    │         │
APPROVE  REJECT
    │         │
    ▼         ▼
IMPLEMENT  NOTIFY
```

## Session Duration

- Authentication valid for: **8 hours**
- Session file: `.workspace/config/session-auth.json`
- After 8 hours → re-authenticate required

## Security Principles

1. **Never expose API key in logs** - Use session-based auth
2. **Security questions are one-way hashed** - Cannot reverse engineer
3. **Block by default** - Developers can't modify without approval
4. **Escalation required** - All changes go through owner review
5. **Audit trail** - All requests logged in escalations/

---

Generated: 2026-04-25
Owner: Emmanuel (workspace_local)