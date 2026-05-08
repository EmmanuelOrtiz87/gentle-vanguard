# 🤖 Workspace Agent Bootstrap (Agnostic)#

<p align="center">
  <b>Defines agent-agnostic startup behavior for this workspace</b>
</p>

---

## 🚀 Startup Rule#

Before substantial work in a new conversation, run:

| Platform | Command |
|----------|----------|
| **🪟 Windows** | `scripts/utilities/session-autostart.cmd` |
| **🐧 Linux/macOS/WSL** | `bash ./scripts/utilities/session-autostart.sh` |

> **Default behavior** is controlled by `config/orchestrator.json`.

---

## 🧮 Session Tracking Rule#

When session tracking capability exists, initialize a session early using:

| Setting | Value |
|----------|--------|
| **project** | `workspace_local` |
| **directory** | `c:\Workspace_local` |
| **session id pattern** | `session-YYYY-MM-DD-XX` |

---

## 🛡️ Reliability Rule#

1. ✅ Treat `READY` as pass.
2. 🔍 Treat `PARTIAL` as actionable and resolve before deep implementation.
3. 🚀 Use `full` mode before release-critical work.

---

## 🗺️ Routing#

| Concept | Reference |
|----------|-----------|
| **Canonical trigger→skill mappings** | `config/auto-delegation.json#keywordMappings` |
| **Agent profiles** | `config/auto-delegation.json#agentProfiles` |
| **Pre-processing hook (mandatory)** | `scripts/utilities/pre-process-input.ps1` |
| **Parse output** | `TRIGGER_MATCH_FOUND` → load skill \| `PLAN_MODE_REQUIRED` → activate BA \| `NO_TRIGGER_MATCH` → continue |

---

## 🧠 Context Optimization#

| Technique | Description |
|------------|-------------|
| **Memory tiering** | Hot (active) → Warm (1 day, 90%) → Cold (7 days, 70%) |
| **Handoff compression** | `scripts/utilities/handoff-compress.ps1` (~30% size reduction) |
| **Pre-compact hook** | `scripts/utilities/pre-compact-hook.ps1 -ProjectName "workspace_local" -CompressionRatio 0.90` |

---

## 🏗️ Workspace-Specific Skills#

| Skill | Trigger | Path |
|-------|---------|------|
| **`workspace-automation`** | PowerShell scripts, scheduled tasks, automation | `skills/workspace-automation/SKILL.md` |
| **`session-lifecycle`** | Session start/end, hooks, session state | `skills/session-lifecycle/SKILL.md` |

---

## 🚀 Quick Commands#

```powershell
# Start session (Windows)
.\scripts\utilities\session-autostart.cmd

# Start session (Linux/macOS)
bash ./scripts/utilities/session-autostart.sh

# Check all 14 quality gates
wf verify

# Show stack version + skills count
wf version

# Begin tracked session
wf start-session

# Full QA gate before release
wf judgment-day

# Open HTML metrics dashboard
wf dashboard

# SLO benchmark of key commands
wf benchmark

# Detect drift between foundation and projects
wf sync-drift
```

---

## 📚 Related Documentation#

| Document | Purpose |
|-----------|---------|
| **[Session Guide](guides/SESSION-GUIDE.md)** | Daily workflow and commands |
| **[Architecture Overview](architecture/README.md)** | System design rationale |
| **[Auto-Delegation Config](../config/auto-delegation.json)** | Trigger mappings and agent profiles |
| **[Tool Activation](guides/TOOL-ACTIVATION.md)** | Auto-activation system |

---

<p align="center">
  <b>🤖 Ready to start a session?</b><br>
  <code>.\scripts\utilities\session-autostart.cmd</code>
</p>
