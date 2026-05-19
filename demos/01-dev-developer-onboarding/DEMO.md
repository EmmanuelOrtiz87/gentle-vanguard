# Demo 01 — Developer Onboarding (v2.14.0)

**Audience:** Development Team  
**Duration:** ~10 min  
**Stack version:** v2.14.0+

---

## Goal

Show how a developer starts with the stack in a clean and repeatable way — from tool detection to
first feature request.

---

## Scope

1. Environment activation and AI tool detection
2. Session autostart and health verification
3. Token budget awareness and response profile
4. First project context setup with SDD flow

---

## Components Demonstrated

1. `detect-tool.ps1` — identifies which AI tool (opencode, claude-code, etc.) is in use
2. `session-autostart.cmd` — one-command session bootstrap
3. `gv.ps1` — primary workflow dispatcher
4. `pre-process-input.ps1` — input routing and delegation
5. SDD lifecycle (BA → EXPLORE → DEV)

---

## Run Steps

### Step 1 — Detect the AI tool (always first)

```powershell
$detected = pwsh -NoProfile -File scripts/utilities/detect-tool.ps1 -AsJson | ConvertFrom-Json
$detected.name
# Expected output: "opencode" (or "claude-code", "cline", "cursor", etc.)
$detected.os.platform
# Expected: "windows" (or "linux", "macos")
$detected.instructions.sessionAutostart
# Path to the correct autostart script for this platform
```

**Why:** Every AI tool has different capabilities (skill tool, mem tools, file access). Detection
ensures correct routing, compression, and security profiles. OS detection prevents wasted tokens
from wrong-platform commands.

### Step 2 — Activate the stack

```powershell
# Activate the orchestrator and all subsystems
./scripts/utilities/stack-on-demand.ps1 -Action activate
# Expected: All services report ACTIVE status

# Verify health with a single command
./scripts/utilities/gv.ps1 health
# Expected: "OK" with component status summary
```

### Step 3 — Start a session with autostart

```powershell
# Full session bootstrap (notifications, security, engram, token guard)
./scripts/utilities/session-autostart.cmd
# Expected:
# [SESSION] Starting session-YYYY-MM-DD-XX
# [ENGRAM] Context restored — X previous observations loaded
# [TOKEN-GUARD] Budget: YY.K/day remaining
# [STATUS] Session active
```

Session autostart activates:

- Notifications subsystem
- Security context
- Engram memory bridge
- Token budget guard
- Karpathy conversation enforcer

### Step 4 — Check workspace and token status

```powershell
# Verify git workspace is clean
git status
# Expected: "nothing to commit, working tree clean" or list of modified files

# Check token budget awareness
./scripts/utilities/gv.ps1 status
# Expected: shows session ID, active profile, token usage, budget remaining

# View current response profile
./scripts/utilities/gv.ps1 response-mode
# Shows: current detail level, chat mode, token allocation
```

**Token Budget Awareness:** The stack enforces daily token caps. The profile determines response
detail. If you need more verbose output for complex tasks, use `gv response-mode set lleno` —
otherwise the compact default keeps costs predictable.

### Step 5 — Route a first feature request (SDD flow)

```powershell
# Simulate a feature request through pre-processing
$input = "Implement a user authentication module"
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/pre-process-input.ps1 `
  -UserInput $input -WorkspaceRoot "."
# Expected output includes:
# TRIGGER_MATCH_FOUND: true
# SKILL: sdd-lifecycle
# AGENT: BA (Business Analyst)
# ACTION: PLAN_MODE_REQUIRED — activate BA first

# The BA agent will now execute the EXPLORE phase before any DEV work begins
# This is enforced by the pre-routing hook — no implementation without analysis
```

**SDD Flow for New Features:**

1. Pre-processor detects `sdd-lifecycle` trigger
2. System routes to BA agent (not DEV)
3. BA completes EXPLORE phase: requirements, scope, constraints
4. Handoff to SAD for design
5. Only then does DEV begin implementation
6. The SDD gate blocks any commit without a validated spec

---

## Expected Outcome

1. AI tool is correctly identified and platform-aware routing is active
2. Session is running with full context restored from Engram
3. Token budget is visible and understood
4. Developer sees the SDD-mandated flow: BA first, code second
5. Pre-process routing correctly identifies the need for analysis before coding
