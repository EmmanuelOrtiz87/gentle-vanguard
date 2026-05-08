# 🤝 Contributing to Workspace Foundation#

<p align="center">
  <b>Thank you for your interest in contributing!</b>
</p>

---

## 📏 Code of Conduct#

By participating, you agree to maintain a **respectful and inclusive environment** for everyone.

---

## 🚀 How to Contribute#

### 1️⃣ Fork and Clone#

```bash
# Fork the repository on GitHub

# Clone your fork
git clone https://github.com/YOUR_USERNAME/workspace-foundation.git
cd workspace-foundation

# Add upstream remote
git remote add upstream https://github.com/EmmanuelOrtiz87/workspace-foundation.git
```

### 2️⃣ Create a Branch#

```bash
# Sync with upstream
git fetch upstream
git checkout main
git pull upstream main

# Create your branch
git checkout -b feat/your-feature-name
# Or: git checkout -b fix/issue-number
```

### 3️⃣ Development#

```bash
# Install dependencies
./scripts/project/init-workspace.ps1

# Validate your changes
./scripts/foundation/wf.ps1 validate

# Check workflow health
./scripts/utilities/wf.ps1 health
```

### 4️⃣ Make Changes#

#### Commit Messages#

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation changes
- style: Code style/formatting
- refactor: Code refactoring
- test: Adding or updating tests
- chore: Maintenance tasks
```

#### Documentation Standards#

All official documentation MUST follow **Section 7: Default Documentation Behavior** in:
- [Documentation Standards](https://github.com/EmmanuelOrtiz87/workspace-foundation/blob/main/.claude/skills/documentation-governance/references/documentation-standards.md)

**Requirements:**
- ✅ Use shields.io badges (version, status, license, runtime)
- ✅ Use strategic emojis in headers, list items, callouts
- ✅ Use tables for structured data with emojis
- ✅ Use blockquote callouts: 🚨 WARNING, 💡 TIP, ✅ SUCCESS, ℹ️ INFO
- ✅ Use ASCII art boxes for architecture diagrams
- ✅ Use horizontal rules (`---`) between major sections
- ✅ Write in friendly, conversational tone with Spanish accents
- ✅ Include 3-step wizards with emojis for complex processes

### 5️⃣ Test Your Changes#

```bash
# Run unit tests
./scripts/run-tests-simple.ps1

# Run integration tests
./tests/integration/auto-delegation-router.integration.tests.ps1

# Full validation
./scripts/utilities/agent-verify.ps1 -Domain all
```

### 6️⃣ Submit PR#

```bash
# Push to your fork
git push origin feat/your-feature-name

# Create Pull Request on GitHub
# - Use conventional commit title
# - Reference any related issues
# - Include screenshots/demos if UI changes
# - Ensure CI checks pass
```

---

## 📋 Development Setup#

### Prerequisites#

| Requirement | Version | Status |
|------------|---------|--------|
| **🪟 Windows 10/11 / Linux / macOS** | Any | ✅ Required |
| **⚡ PowerShell 7+** | 7.0+ | ✅ Required (`winget install Microsoft.PowerShell`) |
| **🌿 Git** | 2.30+ | ✅ Required |
| **🟢 Node.js** | 18+ | ⚠️ Optional |
| **🐹 Go** | 1.19+ | ⚠️ Optional |

### Quick Start#

```powershell
# Bootstrap your machine
./scripts/foundation/bootstrap-machine.ps1

# Start working
./scripts/utilities/WORKFLOW-ORCHESTRATION/wf.ps1 start-session
```

---

## 🏗️ Documentation Guidelines#

### For New Documentation#

1. ✅ Follow **Section 7: Default Documentation Behavior**
2. ✅ Use the [Documentation Standards](https://github.com/EmmanuelOrtiz87/workspace-foundation/blob/main/.claude/skills/documentation-governance/references/documentation-standards.md)
3. ✅ Update relevant README files
4. ✅ Link from related sections
5. ✅ Keep files under 2000 lines

### For Code Changes#

1. ✅ Follow [POWERSHELL-STANDARDS.md](rules/POWERSHELL-STANDARDS.md)
2. ✅ Add/update tests for new functionality
3. ✅ Update documentation if behavior changes
4. ✅ Run `wf validate` before committing
5. ✅ Ensure all CI checks pass

---

## 🚧 Testing#

### Test Structure#

| Type | Location | Count |
|------|----------|-------|
| **Unit Tests** | `tests/unit/` | 20 tests |
| **Integration Tests** | `tests/integration/` | 10 tests |
| **Total** | | **30 tests — 100% PASS** |

### Running Tests#

```bash
# All tests
./scripts/run-tests-simple.ps1

# Specific test file
./tests/unit/config-validaton.tests.ps1

# With timing
Measure-Command { ./scripts/run-tests-simple.ps1 }
```

---

## 📚 Related Documentation#

| Document | Purpose |
|-----------|---------|
| **[Session Guide](docs/guides/SESSION-GUIDE.md)** | Daily workflow and commands |
| **[Architecture Overview](docs/architecture/README.md)** | System design rationale |
| **[Documentation Standards](https://github.com/EmmanuelOrtiz87/workspace-foundation/blob/main/.claude/skills/documentation-governance/references/documentation-standards.md)** | How to write docs |
| **[PowerShell Standards](rules/POWERSHELL-STANDARDS.md)** | PS1 coding standards |
| **[CI Hardening Standards](rules/CI-HARDENING-STANDARDS.md)** | Workflow requirements |

---

## 🚨 Critical Rules#

> **🚨 WARNING:** Hooks run automatically before every commit.

| Mechanism | Description | Status |
|-----------|-------------|--------|
| **Automated Hooks** | pre-commit, pre-push, 7D validation | ✅ Active |
| **Adversarial Review** | Judgment day protocol | ✅ Active |
| **Testing & Coverage** | `testing-strategy-skill` integration | ✅ Active |
| **SDD Enforcement** | Specification and criteria validation | ✅ Mandatory |

---

## 🎯 Project Goals#

- ✅ **125+ Skills**: Specialized AI agent skills for common development tasks
- ✅ **Local-First**: All processing happens locally, no external dependencies
- ✅ **Zero Token Overhead**: Audit and validation with zero AI token usage
- ✅ **Enterprise Security**: Lefthook + Trufflehog integration
- ✅ **Plugin Architecture**: Extensible system for custom workflows

---

<p align="center">
  <b>🤝 Ready to contribute?</b><br>
  <code>git clone https://github.com/EmmanuelOrtiz87/workspace-foundation.git</code>
</p>
