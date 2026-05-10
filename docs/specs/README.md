# 📂 Specs#

<p align="center">
  <b>Technical specifications and templates</b>
</p>

---

## 📋 Purpose#

Technical specifications for system components and interfaces.

| Goal              | Description                                        |
| ----------------- | -------------------------------------------------- |
| **🏗️ Design**     | System design rationale and architecture decisions |
| **📏 Scope**      | Clear boundaries and interfaces                    |
| **📊 Validation** | Acceptance criteria and test specifications        |
| **🔄 Continuity** | Reference implementations and examples             |

---

## 📂 Directory Structure#

```
specs/
├── 📄 README.md              # This file - specs hub
├── 📋 SPEC-TEMPLATE.md       # Template for new specs
└── 📊 [component]-spec.md    # Individual specifications
```

---

## 🚀 Quick Start#

### Create New Spec#

```powershell
# Use the template
cp SPEC-TEMPLATE.md <component>-spec.md
```

### Spec Components#

Each specification should include:

| Component                  | Description                        |
| -------------------------- | ---------------------------------- |
| **🎯 Overview**            | Purpose and scope of the component |
| **🏗️ Architecture**        | Design decisions and rationale     |
| **📏 Interfaces**          | APIs, contracts, and boundaries    |
| **📊 Acceptance Criteria** | Testable conditions for completion |
| **💻 Implementation**      | Reference code and examples        |
| **🔄 Status**              | Current state and next steps       |

---

## 📊 Available Specs#

| Spec                 | Description                     | Link                                 |
| -------------------- | ------------------------------- | ------------------------------------ |
| **📋 Spec Template** | Template for new specifications | [SPEC-TEMPLATE.md](SPEC-TEMPLATE.md) |

---

## 🔍 When to Create a Spec#

- ✅ For new system components or major features
- ✅ When defining APIs or interfaces
- ✅ Before starting implementation (SDD-first)
- ✅ For complex integrations requiring clear contracts

---

## 📚 Related Documentation#

| Document             | Purpose                                                  |
| -------------------- | -------------------------------------------------------- |
| **🏗️ Architecture**  | [../architecture/README.md](../architecture/README.md)   |
| **📋 SDD Lifecycle** | [../sdd/README.md](../sdd/README.md)                     |
| **📂 Supplementary** | [../supplementary/README.md](../supplementary/README.md) |
| **📖 Session Guide** | [../guides/SESSION-GUIDE.md](../guides/SESSION-GUIDE.md) |

---

## 🚀 Quick Commands Reference#

| Command                   | Description              | Output                                             |
| ------------------------- | ------------------------ | -------------------------------------------------- |
| `wf start-session <spec>` | Start session with spec  | `docs/sessions/YYYY-MM-DD-HHmmss-session-start.md` |
| `wf sdd-gate`             | Validate spec compliance | Console output                                     |
| `wf review`               | Full code review         | HTML report                                        |

---

<p align="center">
  <b>📂 Ready to create a specification?</b><br>
  <code>cp specs/SPEC-TEMPLATE.md specs/&lt;component&gt;-spec.md</code>
</p>
