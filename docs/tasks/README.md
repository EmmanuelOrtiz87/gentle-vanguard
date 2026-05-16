# 📋 Task Briefs#

<p align="center">
  <b>Lightweight documentation for development tasks</b>
</p>

---

## 📋 Purpose#

Task briefs provide context, scope, and acceptance criteria for development work.

| Goal              | Description                                 |
| ----------------- | ------------------------------------------- |
| **🎯 Focus**      | Clear problem statement and desired outcome |
| **📏 Scope**      | What's in scope and out of scope            |
| **✅ Acceptance** | Conditions for completion                   |
| **⚠️ Risks**      | Known technical or workflow risks           |
| **🔄 Status**     | Current state and next steps                |

> 💡 **TIP:** Use task briefs for any significant work that spans multiple sessions.

---

## 📂 Directory Structure#

```
tasks/
├── 📄 README.md              # This file - task briefs hub
├── 📋 task-name.md          # Individual task briefs
├── 🔥 PENDING-TASKS.md      # Task backlog
└── 📑 TASK-BRIEF-TEMPLATE.md # Template for new task briefs
```

---

## 🚀 Quick Start#

### Create New Task Brief#

```powershell
# Use the template
cp ../supplementary/TASK-BRIEF.template.md task-name.md

# Or generate via workflow CLI
.\scripts\utilities\gv.ps1 task-brief <task-name>
```

### Task Brief Components#

Each task brief should include:

| Component                     | Description                                 |
| ----------------------------- | ------------------------------------------- |
| **🎯 Goal**                   | Clear problem statement and desired outcome |
| **📏 Scope**                  | What's in scope and out of scope            |
| **📂 Key Files**              | Primary files to work with                  |
| **✅ Acceptance Criteria**    | Conditions for completion                   |
| **⚠️ Risks**                  | Known technical or workflow risks           |
| **🔄 Status**                 | Current state and next steps                |
| **🔮 Future Release Backlog** | Items deferred to future releases           |

---

## 📊 Active Task Briefs#

### Active Development#

| Task                                | Description                  | Link                                                                                 |
| ----------------------------------- | ---------------------------- | ------------------------------------------------------------------------------------ |
| **🏗️ Session Governance** | Governance improvements      | [PENDING-TASKS.md](PENDING-TASKS.md)                   |
| **📊 Chat Baseline Architecture**   | Chat architecture validation | [chat-baseline-architecture-validation.md](chat-baseline-architecture-validation.md) |

### Templates#

| Template                   | Description                  | Link                                                                                           |
| -------------------------- | ---------------------------- | ---------------------------------------------------------------------------------------------- |
| **📑 Task Brief Template** | Template for new task briefs | [../supplementary/TASK-BRIEF.template.md](../supplementary/TASK-BRIEF.template.md)             |
| **📑 Prompt Playbook**     | Prompt engineering guide     | [../supplementary/templates/PROMPT-PLAYBOOK.md](../supplementary/templates/PROMPT-PLAYBOOK.md) |

---

## 🔍 When to Create a Task Brief#

- ✅ For any significant work that spans multiple sessions
- ✅ When tackling complex problems requiring detailed planning
- ✅ For tasks that others might need to understand or take over
- ✅ As part of the session workflow (`gv.ps1 start-session [task-name]`)

---

## 📚 Related Documentation#

| Document             | Purpose                                                  |
| -------------------- | -------------------------------------------------------- |
| **📖 Session Guide** | [../guides/SESSION-GUIDE.md](../guides/SESSION-GUIDE.md) |
| **🏗️ Architecture**  | [../architecture/README.md](../architecture/README.md)   |
| **📋 SDD Lifecycle** | [../sdd/README.md](../sdd/README.md)                     |
| **📂 Supplementary** | [../supplementary/README.md](../supplementary/README.md) |

---

## 🚀 Quick Commands Reference#

| Command                   | Description             | Output                                                |
| ------------------------- | ----------------------- | ----------------------------------------------------- |
| `gv task-brief <name>`    | Generate task brief     | `tasks/<name>.md`                                     |
| `gv start-session <task>` | Start session with task | `docs/sessions/YYYY-MM-DD-HHmmss-session-start.md`    |
| `gv end-session`          | End session             | `docs/sessions/YYYY-MM-DD-HHmmss-delivery-closure.md` |

---

<p align="center">
  <b>📋 Ready to create a task brief?</b><br>
  <code>.\scripts\utilities\gv.ps1 task-brief &lt;task-name&gt;</code>
</p>

