# 🚀 Getting Started

<p align="center">
  <b>Guides for new users and quick setup</b>
</p>

---

## 📚 Documents

| Document                                     | Description                                     |
| -------------------------------------------- | ----------------------------------------------- |
| **[PREREQUISITES.md](PREREQUISITES.md)**     | System requirements (git, PowerShell, AI agent) |
| **[DEVELOPER-SETUP.md](DEVELOPER-SETUP.md)** | Step-by-step developer setup                    |
| **[installation.md](installation.md)**       | Detailed installation guide                     |

---

## 🚀 Quick Start

| Step   | Action                                          | Command                                           |
| ------ | ----------------------------------------------- | ------------------------------------------------- |
| **1️⃣** | Check [PREREQUISITES.md](PREREQUISITES.md)      | Review system requirements                        |
| **2️⃣** | Follow [DEVELOPER-SETUP.md](DEVELOPER-SETUP.md) | Complete setup steps                              |
| **3️⃣** | Run bootstrap                                   | `.\scripts\gentle-vanguard\bootstrap-machine.ps1` |

> 💡 **TIP:** Start here for a smooth onboarding experience.

---

## 📋 Prerequisites

| Requirement                          | Version | Status      | Notes                                 |
| ------------------------------------ | ------- | ----------- | ------------------------------------- |
| **🪟 Windows 10/11 / Linux / macOS** | Any     | ✅ Required | Cross-platform support                |
| **⚡ PowerShell 7+**                 | 7.0+    | ✅ Required | `winget install Microsoft.PowerShell` |
| **🌿 Git**                           | 2.30+   | ✅ Required | Version control system                |
| **🟢 Node.js**                       | 18+     | ⚠️ Optional | For some tools                        |
| **🐹 Go**                            | 1.19+   | ⚠️ Optional | For compiled components               |

---

## 🛠️ Setup — 3 Steps

### Step 1: Clone the Repository

```powershell
git clone https://github.com/EmmanuelOrtiz87/gentle-vanguard.git
cd gentle-vanguard
```

### Step 2: Bootstrap Your Machine

```powershell
.\scripts\gentle-vanguard\bootstrap-machine.ps1
```

This will:

- ✅ Install required PowerShell modules
- ✅ Configure Git hooks (Lefthook + Trufflehog)
- ✅ Set up environment variables
- ✅ Validate all prerequisites

### Step 3: Start Working

```powershell
.\scripts\utilities\WORKFLOW-ORCHESTRATION\gv.ps1 start-session
```

---

## 📖 Daily Usage Commands

```powershell
gv verify  # Check all 14 quality gates
gv version # Show stack version + skills count
gv start-session   # Begin tracked session
gv judgment-day    # Full QA gate before release
gv dashboard       # Open HTML metrics dashboard
gv benchmark       # SLO benchmark of key commands
gv sync-drift      # Detect drift between gentle-vanguard and projects
```

---

## 🎯 Next Steps

1. **[Read the Architecture Overview](../architecture/README.md)** — Understand the 5-layer topology
2. **[Explore Available Skills](../reference/SKILL-ORGANIZATION.md)** — 127 specialized skills
3. **[Set Up Your First Project](../guides/GETTING-STARTED.md)** — Use scaffolding tools
4. **[Configure AI Agent](../guides/COMPATIBILITY-MATRIX.md)** — OpenCode, Claude, Cursor, etc.

---

<p align="center">
  <b>🚀 Ready to start?</b><br>
  <code>git clone https://github.com/EmmanuelOrtiz87/gentle-vanguard.git</code>
</p>
