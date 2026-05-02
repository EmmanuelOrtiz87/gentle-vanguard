# Workspace Agent Bootstrap (Agnostic)

> 💡 **Purpose:** Defines agent-agnostic startup behavior for this workspace.

## 🚀 Startup Rule

Before substantial work in a new conversation, run:

1. `tools/session-autostart.cmd` on Windows, or
2. `bash ./tools/session-autostart.sh` on Linux/macOS/WSL.

Default behavior is controlled by `tools/session-autostart.config.json`.

## 📅 Session Tracking Rule

When session tracking capability exists, initialize a session early using:

| Parameter | Value |
|-----------|--------|
| **Project** | `workspace_local` |
| **Directory** | `c:\Workspace_local` |
| **Session ID** | `session-YYYY-MM-DD-XX` |

## ✅ Reliability Rule

| Rule | Action |
|------|--------|
| **READY** | Treat as pass |
| **PARTIAL** | Actionable - resolve before deep implementation |
| **Full Mode** | Use before release-critical work |

## 📊 Context Optimization (Token Efficiency)

### Memory Tiering

| Tier | Description | Retention |
|------|-------------|-----------|
| **Hot** | Active session, no compression | 100% |
| **Warm** | Recent (1 day) | 90% |
| **Cold** | Archive (7 days) | 70% |

### 🔄 Handoff Compression Mode

For agent-to-agent transfers, use `tools/handoff-compress.ps1`:

- **Preserves:** decisions, results, FIXMEs, status flags
- **Truncates:** verbose outputs, repeated patterns
- **Output:** state-only handoff (~30% size reduction)

### ⚙️ Pre-Compact Hook

Before context compaction (every ~25k tokens), run:

```powershell
.\tools\pre-compact-hook.ps1 -ProjectName "workspace_local" -CompressionRatio 0.90
```

Preserves anchored content (FIXME, TODO, BUG, DECISION, RESULT).

### 🤖 Adaptive Skill Loading

Skills auto-load based on project context:

| Signal | Skill |
|--------|-------|
| 🅰 Angular component | `angular-core`, `angular-spa` |
| ⚛ React TSX | `react-19` |
| 🐹 Go files | `golang-api` |
| 🐳 Docker files | `docker-devops` |
| 📜 PowerShell scripts | `workspace-automation` |
| 📅 Session management | `session-lifecycle` |

See: `rules/adaptive/` for dynamic rule configuration.

---

## 📋 Documentation Governance Policy

### Mandatory Rules for Markdown Files

| Rule | Description |
|------|-------------|
| **🇪 Spanish Accents** | Always use proper accents (automatización, configuración, revisión, activación) |
| **🔧 Code Blocks** | MUST specify language (```powershell, ```bash, ```json) |
| **📄 UTF-8 Encoding** | All markdown files must be UTF-8 (without BOM) |
| **📏 Blank Lines** | Use blank lines before/after headers and code blocks |
| **📝 Scannable Content** | Convert dense text to bullet points |
| **🎨 Emojis** | Use for visual scanning (🚀, ⚙️, 🤖, 💡, 🚨, ✅) |
| **📊 Tables** | Use for structured data |
| **📢 Visual Callouts** | Use blockquotes (> 💡 **TIP:**) |
| **✍ Friendly Writing** | Short paragraphs, bullet points, bold text |

### ✅ Pre-Commit Validation

Before committing markdown changes, verify:

- [ ] All Spanish words have proper accents
- [ ] All code blocks have language specified
- [ ] No broken links (run `wf.ps1 audit`)
- [ ] UTF-8 encoding
- [ ] Proper spacing around headers and code blocks

### 🚨 Anti-Ambiguity Rule (CRITICAL)

When editing markdown files:

- **Prefer `write` over `edit`** for large changes (avoids "multiple matches" errors)
- **Use `replaceAll: true`** only when you want to change ALL instances
- **Read entire file first**, then write corrected content

> 💡 **Reference:** `skills/documentation-governance/SKILL.md` and `references/TOKEN-CONTEXT-STANDARDS.md`

---

## 🛠️ Workspace-Specific Skills

### 🤖 Automation Skills

| Skill | Trigger | Path |
|-------|---------|------|
| `workspace-automation` | PowerShell scripts, scheduled tasks, automation | [↗](skills/workspace-automation/SKILL.md) |
| `session-lifecycle` | Session start/end, hooks, state tracking | [↗](skills/session-lifecycle/SKILL.md) |
| `documentation-governance` | Documentation, markdown, README files | [↗](skills/documentation-governance/SKILL.md) |

**📖 Usage:** These skills are automatically loaded when working with workspace automation. Load manually with:

```powershell
Read skills/workspace-automation/SKILL.md  # Before creating automation scripts
Read skills/session-lifecycle/SKILL.md    # Before modifying session management
Read skills/documentation-governance/SKILL.md  # Before updating documentation
```
