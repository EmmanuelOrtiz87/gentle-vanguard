# Gentle-Vanguard

**AI-powered development orchestrator** — 18 specialized agents, 130+ on-demand skills, persistent memory, local-first architecture. Transform your IDE into a governed, multi-agent development team.

Born from the need to bring **structure, quality, and repeatability** to AI-assisted coding. Instead of prompting random models in isolated sessions, Gentle-Vanguard gives you a complete orchestration layer that routes tasks to specialized agents, enforces development standards, tracks every token, and persists learning across sessions.

![Version](https://img.shields.io/badge/Version-2.16.0-brightgreen?style=flat-square)
![Status](https://img.shields.io/badge/Status-Production%20Ready-success?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)
![PowerShell](https://img.shields.io/badge/PowerShell-7+-purple?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Win|Linux|macOS-lightgrey?style=flat-square)

---

## What It Solves

| Problem | How Gentle-Vanguard Solves It |
|---------|-------------------------------|
| AI gives inconsistent code quality | 7D validation gates (security, quality, architecture, testing, docs, API, gitflow) block bad code before commit |
| No memory between sessions | Persistent Engram memory — every decision, bug fix, and pattern is saved and retrievable across sessions |
| Random model selection wastes tokens | Cost-aware model router picks the cheapest capable provider, with 30K token/day budget guard |
| No governance in AI workflows | SDD enforcement (no spec, no code), judgment-day adversarial review, pre-commit hooks |
| Disconnected AI sessions | Session lifecycle tracking with context handoff between dispatches |
| No visibility into AI costs | Executive dashboard with token trends, per-agent costs, MTD/YTD spend, ROI analysis |

## Key Features

- **18 Specialized Agents** — BA (requirements), SAD (architecture), DEV (implementation), QA (testing), OPS (deployment), GOV (governance), DOC (documentation), PREMORTEM (risk analysis), MKT, SALES, FINANCE, HR, LEGAL, and more
- **130+ On-Demand Skills** — Angular, React, Next.js, Go, Django, Python, TypeScript, Docker, Kubernetes, Playwright, Security, API Design, and 120+ more — zero memory until triggered
- **Persistent Engram Memory** — Cross-session context, automatic learning capture, conflict detection and reconciliation
- **Cost-Aware Model Router** — 4 providers / 12 models with automatic cheapest-available routing and daily budget enforcement
- **Governance-First** — SDD lifecycle (spec → design → implement → verify), 7D validation hooks, judgment-day adversarial review, 15 CI/CD workflows
- **100% Local-First** — No required external services. All data stays on your machine. Optional cloud AI integration.
- **Cross-Platform** — Windows, macOS, Linux. PowerShell 7+ and Bash.
- **CLI** — `gv` command with 50+ subcommands: `dispatch`, `audit`, `review`, `judgment-day`, `dashboard`, `benchmark`, `health`, `update`

## Quick Install

### Option 1 — One-Click Installer (Windows)

[Download Gentle-Vanguard.exe](Gentle-Vanguard.exe) — NSIS installer, AES-256 encrypted, all-in-one.

```powershell
# Run as Administrator, then:
gv health
```

### Option 2 — Git Clone (All Platforms)

```powershell
git clone https://github.com/EmmanuelOrtiz87/gentle-vanguard-public.git
cd gentle-vanguard-public
pwsh -File scripts/gentle-vanguard/bootstrap.ps1
```

## Requirements

- Windows 10/11, macOS 13+, or Linux (Ubuntu 22.04+)
- PowerShell 7+
- Git 2.30+
- 4GB RAM minimum (8GB recommended)

## Documentation

- [Getting Started](docs/getting-started/)
- [Installation Guide](INSTALLATION.md)
- [Architecture Overview](docs/architecture/README.md)
- [Full Documentation Index](docs/)

## Security

Encrypted artifacts use AES-256. All secrets, API keys, and sensitive configs are encrypted at rest. See [SECURITY.md](SECURITY.md) for details.

## License

[MIT](LICENSE)
