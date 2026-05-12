# 🤖 Workspace Agent Bootstrap (Agnostic)#

<p align="center">
  <b>Defines agent-agnostic startup behavior for this workspace | TOOL-AGNOSTIC</b>
</p>

---

## 🔧 Tool Detection Rule#

**BEFORE** any other action, detect which AI tool is running:

```powershell
pwsh -NoProfile -File scripts/utilities/detect-tool.ps1 -AsJson
```

The detection script checks (in order):
1. `$env:OPENCODE_SERVER_USERNAME` → opencode
2. `$env:CLAUDE_VSCODE_VERSION` → claude-code
3. `.clinerules` file → cline
4. `.cursorrules` file → cursor
5. `.windsurf/` directory → windsurf

Based on the detected tool, load the correct config from `config/orchestrator.json#toolProfiles`.

> **CRITICAL**: This file (`AGENTS.md`) is the canonical tool-agnostic entry point.  
> Do NOT rely on `CLAUDE.md`, `.clinerules`, or `.cursorrules` as primary bootstrap —  
> those are tool-specific and may be incomplete.

---

## 🚀 Startup Rule#

Before substantial work in a new conversation, execute ALL steps in order:

### Phase A — Init

0. **Run `pre-process-input.ps1`** BEFORE first response:
   ```powershell
   pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/pre-process-input.ps1 -UserInput "<first_message>" -WorkspaceRoot "."
   ```
   Parse output for routing (AI-NORMATIVES.md #1).

1. **Start session** (OS-dependent):

   | Platform               | Command                                         |
   | ---------------------- | ----------------------------------------------- |
   | **🪟 Windows**         | `scripts/utilities/session-autostart.cmd`       |
   | **🐧 Linux/macOS/WSL** | `bash ./scripts/utilities/session-autostart.sh` |

2. **Register session** with Engram: `engram_mem_session_start`
3. **Restore context**: `engram_mem_context`
4. **Check workspace**: `git status`
5. **Read bootstrap**: this file (`docs/AGENTS.md`)

### Phase B — Analysis (MOST OFTEN OMITTED)

6. **Read `scripts/.session/startup-summary.json`** — check `isPeakHour`, `sessionId`, `workspaceClean`
7. **Create task list**: `todowrite`
8. **Self-verify**: `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/agent-verify.ps1`
9. **Report to user** compact block (peak hour, session ID, workspace state)

> **Default behavior** is controlled by `config/orchestrator.json`.

---

## 🧮 Session Tracking Rule#

When session tracking capability exists, initialize a session early using:

| Setting                | Value                   |
| ---------------------- | ----------------------- |
| **project**            | `workspace_local`       |
| **directory**          | `c:\Workspace_local`    |
| **session id pattern** | `session-YYYY-MM-DD-XX` |

---

## 🛡️ Reliability Rule#

1. ✅ Treat `READY` as pass.
2. 🔍 Treat `PARTIAL` as actionable and resolve before deep implementation.
3. 🚀 Use `full` mode before release-critical work.

---

## 🗺️ Routing#

| Concept                              | Reference                                                                                                 |
| ------------------------------------ | --------------------------------------------------------------------------------------------------------- |
| **Canonical trigger→skill mappings** | `config/auto-delegation.json#keywordMappings`                                                             |
| **Agent profiles**                   | `config/auto-delegation.json#agentProfiles`                                                               |
| **Pre-processing hook (mandatory)**  | `scripts/utilities/pre-process-input.ps1`                                                                 |
| **Parse output**                     | `TRIGGER_MATCH_FOUND` → load skill \| `PLAN_MODE_REQUIRED` → activate BA \| `NO_TRIGGER_MATCH` → continue |

---

## 🧠 Context Optimization#

| Technique               | Description                                                                                    |
| ----------------------- | ---------------------------------------------------------------------------------------------- |
| **Memory tiering**      | Hot (active) → Warm (1 day, 90%) → Cold (7 days, 70%)                                          |
| **Handoff compression** | `scripts/utilities/handoff-compress.ps1` (~30% size reduction)                                 |
| **Pre-compact hook**    | `scripts/utilities/pre-compact-hook.ps1 -ProjectName "workspace_local" -CompressionRatio 0.90` |

---

## 📝 Response Compression#

All agents MUST follow `config/orchestrator.json#response_policy`:
- **Profile**: ultra — aggressive compression, abbreviations
- **Detail**: simple — no digressions, no preamble/postamble
- **Chat level**: chat-compact — max 4 lines of text before tool calls

Key rules:
1. NO preamble ("Let me...", "I'll...") — just do it
2. NO postamble — no summaries, no explanations of what was done
3. NO echoing user's question
4. NO progress commentary during multi-step tasks
5. Batch independent tool calls in parallel
6. Answer THEN act: 1-3 line answer, then tools

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

| Document                                                     | Purpose                             |
| ------------------------------------------------------------ | ----------------------------------- |
| **[Session Guide](guides/SESSION-GUIDE.md)**                 | Daily workflow and commands         |
| **[Architecture Overview](architecture/README.md)**          | System design rationale             |
| **[Auto-Delegation Config](../config/auto-delegation.json)** | Trigger mappings and agent profiles |
| **[Tool Activation](guides/TOOL-ACTIVATION.md)**             | Auto-activation system              |

---

<p align="center">
  <b>🤖 Ready to start a session?</b><br>
  <code>.\scripts\utilities\session-autostart.cmd</code>
</p>
