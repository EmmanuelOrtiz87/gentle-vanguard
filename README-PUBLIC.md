<h1 align="center">Gentle-Vanguard</h1>

<p align="center">
  <strong>AI-powered development orchestrator · Distributed · Production ready</strong><br>
  <em>100% local · Persistent memory · No vendor lock-in</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-2.16.0-brightgreen?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/Status-Production%20Ready-success?style=flat-square" alt="Status">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License">
  <img src="https://img.shields.io/badge/Distribution-Encrypted-red?style=flat-square" alt="Distribution">
</p>

<p align="center">
  <a href="#installation">Installation</a>
  &nbsp;middot;&nbsp;
  <a href="#quick-start">Quick Start</a>
  &nbsp;middot;&nbsp;
  <a href="#documentation">Documentation</a>
  &nbsp;middot;&nbsp;
  <a href="#support">Support</a>
</p>

---

## What is Gentle-Vanguard?

Gentle-Vanguard is an **AI orchestrator** that turns your CLI or IDE into a disciplined engineering team. This is the **public distribution** of the framework — featuring encrypted core components, skill stubs, and bootstrap scripts for secure deployment.

### Key Capabilities

- **Routes work** through delegation rules: small changes stay inline, complex work goes to specialized subagents
- **Enforces SDD** (Spec-Driven Development): concepts before code, artifacts over chat context
- **Guards reviewer workload**: prevents oversized PRs with automated line-budget checks
- **Maintains a skill registry**: auto-scanned, always-current index of 130+ skills
- **Persists memory** across sessions via Engram
- **100% local execution**: no cloud dependencies, full privacy

---

## Installation

### Option 1: Installer (Recommended)

Download and run the latest `Gentle-Vanguard.exe` from [Releases](../../releases):

```powershell
.\Gentle-Vanguard.exe
```

The installer will:
1. Extract encrypted components to `%APPDATA%\Gentle-Vanguard\`
2. Register CLI commands (`gv`, `foundation`)
3. Initialize session management and Engram memory
4. Validate all dependencies

### Option 2: Manual Setup

```powershell
# Clone this repository
git clone https://github.com/EmmanuelOrtiz87/gentle-vanguard-public.git
cd gentle-vanguard-public

# Run bootstrap
.\scripts\gentle-vanguard\bootstrap.ps1

# Verify installation
gv verify
```

### Requirements

- **Windows 10+** or **Linux/macOS** with PowerShell 7+
- **.NET 6.0+** (for encrypted component decryption)
- **Git 2.30+**
- **Node.js 18+** (optional, for TypeScript projects)

---

## Quick Start

### 1. Initialize Session

```powershell
gv session-start
```

This activates:
- Session tracking and persistence
- Engram memory (local knowledge base)
- Skill registry (130+ available skills)
- Quality gates and audit hooks

### 2. Verify Installation

```powershell
gv verify
```

Expected output:
```
[✓] Configuration: 3/3
[✓] Skills: 130+ validated
[✓] Tests: 442 passing
[✓] Hooks: 2/2
[✓] Structure: 7/7
[✓] PRODUCTION READY
```

### 3. Run Your First Task

```powershell
# Example: Code review with delegation
gv code-review --file src/main.ts

# Example: SDD preflight (before new features)
gv sdd-preflight --interactive

# Example: Check review workload
gv review-workload-guard
```

---

## Architecture

### Work Routing

Gentle-Vanguard routes every request through the **smallest safe harness**:

```
Incoming Request
    ↓
[Size & Complexity Check]
    ├─→ Small, local, known → Inline Direct
    ├─→ Context-heavy, 4+ files → Scout Delegation
    ├─→ Multi-file change → Worker + Reviewer
    └─→ Ambiguous / architectural → SDD Lifecycle
```

### Delegation Rules

| Rule | Trigger | Action |
|------|---------|--------|
| **4-file rule** | Understanding needs 4+ files | Delegate to scout/context-builder |
| **Multi-file write** | Touching 2+ non-trivial files | One worker + fresh reviewer |
| **PR rule** | Before commit/push/PR | Fresh-context reviewer |
| **Incident rule** | Git/tooling accident | Fresh audit before recovery |
| **Long-session** | ~20 calls without delegation | Pause and delegate |

### Agent Ecosystem

| Agent | Role | Specialization |
|-------|------|-----------------|
| **Orchestrator** | Main router | Delegation & routing |
| **BA** | Requirements & analysis | Exploration & discovery |
| **SAD** | System design | Architecture & decisions |
| **DEV** | Code generation | Implementation |
| **QA** | Testing & validation | Quality assurance |
| **OPS** | Deployment & CI/CD | Infrastructure |
| **DOC** | Technical docs | Documentation |
| **GOV** | Compliance & audit | Governance |

---

## Documentation

### Getting Started

- **[INSTALLATION.md](INSTALLATION.md)** — Detailed setup instructions
- **[QUICK-START.md](docs/getting-started/QUICK-START.md)** — First 5 minutes
- **[FAQ.md](docs/getting-started/FAQ.md)** — Common questions

### Core Concepts

- **[SDD / OpenSpec](docs/reference/SDD-OVERVIEW.md)** — Spec-Driven Development workflow
- **[Delegation Rules](docs/reference/DELEGATION-RULES.md)** — When to delegate vs. work inline
- **[Skill Registry](docs/reference/SKILL-REGISTRY.md)** — Available skills and how to use them
- **[Architecture](docs/architecture/README.md)** — System design & decisions

### Advanced Topics

- **[Model Routing](docs/reference/MODEL-ROUTING.md)** — Per-agent model assignments
- **[Engram Memory](docs/reference/ENGRAM-MEMORY.md)** — Session persistence & learning
- **[Security & Encryption](docs/reference/SECURITY.md)** — Component protection
- **[Troubleshooting](docs/guides/TROUBLESHOOTING-RUNBOOK.md)** — Common issues & solutions

---

## Project Status

| Gate | Result |
|------|--------|
| Configuration | 3/3 ✓ |
| Skills | 130+ validated ✓ |
| Tests | 442 passing ✓ |
| Hooks | 2/2 ✓ |
| Structure | 7/7 ✓ |
| **Total** | **Production Ready** ✓ |

---

## Distribution Model

This repository contains:

✅ **Public & Safe**
- Bootstrap scripts (plain text, for onboarding)
- Skill stubs (SKILL.md definitions only)
- Documentation (guides, architecture, examples)
- Configuration examples (no secrets)
- Demos and tutorials
- Installer (.exe)

🔒 **Encrypted & Protected**
- Core orchestrator scripts (AES-256 encrypted)
- Agent implementations (encrypted)
- Configuration templates (encrypted)
- Skill implementations (encrypted)
- Session management (encrypted)

❌ **Not Included**
- Master encryption key (obtained separately)
- Internal audit logs
- Development tests
- Private documentation

### Getting the Master Key

To decrypt and run Gentle-Vanguard:

1. **Option A**: Clone the private repository (if you have access)
   ```powershell
   git clone https://github.com/EmmanuelOrtiz87/gentle-vanguard.git
   ```

2. **Option B**: Request access from the maintainer
   - Email: [contact info]
   - Include: use case, organization, timeline

3. **Option C**: Use the public installer
   - The installer includes all necessary keys for standard deployment
   - Run: `.\Gentle-Vanguard.exe`

---

## Development

### For Contributors

If you have access to the private repository:

```powershell
# Clone private repo
git clone https://github.com/EmmanuelOrtiz87/gentle-vanguard.git
cd gentle-vanguard

# Full development setup
.\scripts\utilities\session-autostart.cmd

# Run tests
Invoke-Pester tests/ -Output Detailed

# Quality gates
gv verify
```

### For Public Users

This repository is **read-only** for distribution. To contribute:

1. Fork the private repository (if you have access)
2. Create a feature branch
3. Submit a pull request
4. Changes will be homologated to the public repo after review

---

## Support

### Documentation

- 📖 [Full Documentation](docs/)
- 🚀 [Quick Start Guide](docs/getting-started/QUICK-START.md)
- ❓ [FAQ](docs/getting-started/FAQ.md)
- 🐛 [Troubleshooting](docs/guides/TROUBLESHOOTING-RUNBOOK.md)

### Community

- 💬 [Discussions](../../discussions)
- 🐛 [Issues](../../issues)
- 📧 Email: [contact info]

### Resources

- 📚 [Architecture Decisions](docs/architecture/decisions/)
- 🔧 [Configuration Guide](docs/reference/CONFIGURATION.md)
- 🎓 [Skill Development](docs/guides/SKILL-DEVELOPMENT.md)

---

## License

Gentle-Vanguard is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.

### Third-Party Components

- Encrypted components use **AES-256** (standard library)
- Installer built with **NSIS** (open source)
- CLI built with **.NET 6.0+** (open source)
- Skill framework compatible with **Claude, Cline, Windsurf**

---

## Roadmap

### v2.17.0 (Q3 2026)
- [ ] Multi-language skill support (Python, Go, Rust)
- [ ] Cloud-agnostic deployment templates
- [ ] Enhanced Engram memory with semantic search

### v2.18.0 (Q4 2026)
- [ ] Real-time collaboration features
- [ ] Advanced audit trails and compliance reporting
- [ ] Custom agent framework

### v3.0.0 (2027)
- [ ] Full open-source release (planned)
- [ ] Community skill marketplace
- [ ] Enterprise support tiers

---

<p align="center">
  <strong>Gentle-Vanguard v2.16.0</strong><br>
  <em>Local-First · Total Privacy · Production Ready</em><br><br>
  <a href="https://github.com/EmmanuelOrtiz87/gentle-vanguard-public">GitHub</a>
  &nbsp;·&nbsp;
  <a href="docs/">Documentation</a>
  &nbsp;·&nbsp;
  <a href="../../releases">Releases</a>
</p>