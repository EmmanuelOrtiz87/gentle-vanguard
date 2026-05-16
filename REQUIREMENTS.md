# Requirements

Unified dependency manifest for Gentle-Vanguard. Consolidates data from 7 sources: `install-prerequisites.ps1`, `bootstrap.ps1`, `system-diagnostics.ps1`, `package.json`, `docs/getting-started/PREREQUISITES.md`, `docs/getting-started/README.md`, `auto-init-dev-environment.ps1`.

---

## Core Runtime

| Dependency | Min Version | Required | Auto-Install | Checked By |
|------------|-------------|----------|--------------|------------|
| Git | 2.30+ | **YES** | Manual | install-prerequisites.ps1, bootstrap.ps1, system-diagnostics.ps1, auto-init-dev-environment.ps1 |
| PowerShell 7+ | 7.0+ | **YES** | No | bootstrap-machine.ps1 (implicit), docs/getting-started/README.md |
| GitHub CLI (gh) | latest | Recommended | bootstrap.ps1 (winget/brew/apt) | bootstrap.ps1, auto-init-dev-environment.ps1 |

## Language Runtimes

| Dependency | Min Version | Required | Auto-Install | Checked By |
|------------|-------------|----------|--------------|------------|
| Node.js | 18+ | **YES** (PREREQUISITES.md, install-prerequisites.ps1), Optional (docs/getting-started/README.md, system-diagnostics.ps1) | Manual | install-prerequisites.ps1, system-diagnostics.ps1, auto-init-dev-environment.ps1 |
| npm | 9+ | **YES** (bundled with Node) | Bundled with Node | install-prerequisites.ps1, auto-init-dev-environment.ps1 |
| Go | 1.19+ | **YES** (bootstrap.ps1, system-diagnostics.ps1), Optional (install-prerequisites.ps1, README) | winget via install-prerequisites.ps1 | bootstrap.ps1, system-diagnostics.ps1, auto-init-dev-environment.ps1, install-prerequisites.ps1 |
| Python | 3.x | Optional | Manual (choco) | install-prerequisites.ps1 |
| pip | latest | Optional | Bundled with Python | install-prerequisites.ps1 |

## Tools

| Dependency | Min Version | Required | Auto-Install | Checked By |
|------------|-------------|----------|--------------|------------|
| lefthook | ^2.1.6 | Recommended | `npm install -g lefthook` (install-prerequisites.ps1) | install-prerequisites.ps1, package.json |
| prettier | ^3.0.0 | Recommended | `npm install -g prettier` (install-prerequisites.ps1) | install-prerequisites.ps1, package.json |
| commitlint | latest | Recommended | `npm install -g @commitlint/cli @commitlint/config-conventional` | install-prerequisites.ps1 |
| trufflehog | latest | Optional | Manual (choco install trufflehog) | install-prerequisites.ps1 |
| Engram CLI | latest | **YES** (bootstrap.ps1 exit 1) | `go install` via bootstrap.ps1 or install-engram.ps1 | bootstrap.ps1, system-diagnostics.ps1, install-prerequisites.ps1 |
| cairosvg | latest | Optional | `pip install cairosvg` | install-prerequisites.ps1 |
| OpenCode | latest | Optional | Manual (curl/website) | install-prerequisites.ps1 |
| safety | latest | Optional | `pip install safety` | PREREQUISITES.md |
| bandit | latest | Optional | `pip install bandit` | PREREQUISITES.md |

## Infrastructure

| Component | Required | Notes |
|-----------|----------|-------|
| Orchestrator config (`config/orchestrator.json`) | YES | system-diagnostics.ps1 checks existence |
| Skills directory | YES | system-diagnostics.ps1 checks existence |
| `.engram-data` directory | YES | Created on first use |
| Git hooks path (`scripts/git-hooks`) | YES | Set by bootstrap.ps1 |

## Auto-Install

### `install-prerequisites.ps1` can install automatically:
- lefthook (`npm install -g lefthook`)
- prettier (`npm install -g prettier`)
- commitlint (`npm install -g @commitlint/cli @commitlint/config-conventional`)
- Go (via `winget install GoLang.Go`)
- Engram (via `go install`, requires Go)

### `bootstrap.ps1` can install automatically:
- Engram (git clone + `go install ./cmd/engram`)
- GitHub CLI (winget/brew/apt depending on OS with user confirmation)

### `bootstrap-machine.ps1` can install automatically:
- Gentle-Vanguard directory structure and symlinks (NOT developers tools — it installs Gentle-Vanguard itself, not its prerequisites)

### Manual-only:
- Git (https://git-scm.com/)
- Node.js (https://nodejs.org/)
- PowerShell 7+ (https://github.com/PowerShell/PowerShell)
- trufflehog (`choco install trufflehog`)
- Python (`choco install python`)
- OpenCode (https://opencode.ai or curl script)
- safety (`pip install safety`)
- bandit (`pip install bandit`)

### Not auto-installed by any script:
- cairosvg — listed in install-prerequisites.ps1 but install block unreachable (only Required=$true items get installed)

## Verification

- `.\scripts\utilities\install-prerequisites.ps1 -CheckOnly` — checks all tools
- `.\scripts\diagnostics\system-diagnostics.ps1` — comprehensive health report (exit codes: 0=healthy, 1=degraded, 2=critical)
- `.\scripts\utilities\agent-verify.ps1` — agent self-verification
- `.\scripts\utilities\gv.ps1 verify` — workflow verification

---

## Inconsistencies Found

### 1. Go — Required vs Optional mismatch
| Source | Stance |
|--------|--------|
| `install-prerequisites.ps1` | `Required = $false` (optional) |
| `bootstrap.ps1` | **REQUIRED** — exit 1 if missing (unless Engram already installed) |
| `system-diagnostics.ps1` | **CRITICAL** — marked `-Critical`, FAIL causes exit 2 |
| `docs/getting-started/README.md` | Optional |

**Resolution needed**: Go should be **REQUIRED**. Three of four sources treat it as mandatory. Only install-prerequisites.ps1 marks it optional.

### 2. Node.js — Required vs Optional mismatch
| Source | Stance |
|--------|--------|
| `install-prerequisites.ps1` | `Required = $true` |
| `docs/getting-started/PREREQUISITES.md` | Required (top of table) |
| `system-diagnostics.ps1` | WARN only (optional for gentle-vanguard project type) |
| `docs/getting-started/README.md` | Optional |
| `bootstrap.ps1` | Not checked at all |

**Resolution needed**: Node.js is needed for npm tools (lefthook, prettier, commitlint). Likely **REQUIRED** but bootstrap.ps1 should verify it.

### 3. PowerShell 7+ — Required vs Optional mismatch
| Source | Stance |
|--------|--------|
| `install-prerequisites.ps1` | `Required = $false` |
| `docs/getting-started/README.md` | Required |

**Resolution needed**: PowerShell 7+ is **REQUIRED** — all scripts target `pwsh`. install-prerequisites.ps1 should mark it Required=$true.

### 4. Engram — Two different install methods
| Source | Method |
|--------|--------|
| `install-prerequisites.ps1` | `go install github.com/gentle-vanguard/engram/cmd/engram@latest` |
| `bootstrap.ps1` | `git clone https://github.com/gentle-vanguard/engram.git` + `go install ./cmd/engram` |

**Resolution needed**: Align on one method. bootstrap.ps1's approach (clone + local install) is more reliable for development.

### 5. npm — Required in install-prerequisites but never verified in bootstrap or diagnostics
npm is checked by install-prerequisites.ps1 and auto-init-dev-environment.ps1 but is entirely absent from bootstrap.ps1 and system-diagnostics.ps1.

### 6. GitHub CLI — Not in install-prerequisites or PREREQUISITES.md
Checked by bootstrap.ps1 and auto-init-dev-environment.ps1 but missing from the canonical prerequisites list.

### 7. Script location inconsistencies
| Script | Actual Location | Expected Location |
|--------|-----------------|-------------------|
| `install-engram.ps1` | `scripts/utilities/SKILLS-TOOLS/` | `scripts/utilities/` (referenced by system-diagnostics.ps1 as `scripts/utilities/install-engram.ps1`) |
| `auto-init-dev-environment.ps1` | `scripts/utilities/UTILITIES/` | `scripts/utilities/` (redundant nesting) |
| `gv.ps1` | 3 copies: `scripts/utilities/`, `scripts/utilities/WORKFLOW-ORCHESTRATION/`, `scripts/gentle-vanguard/` | Should consolidate |

### 8. Missing dependencies from PREREQUISITES.md not in install-prerequisites
`safety` and `bandit` (Python security tools) are listed in PREREQUISITES.md but absent from install-prerequisites.ps1.

### 9. cairosvg — Listed but never auto-installed
`cairosvg` is defined in install-prerequisites.ps1 with `Required = $false` and pip install command, but the install loop only processes `$missing` (Required=$true items), so cairosvg is never installed.

### 10. OpenCode — Listed in install-prerequisites but undocumented elsewhere
OpenCode is listed as an optional dependency in install-prerequisites.ps1 but doesn't appear in PREREQUISITES.md or any other documentation.

### 11. `bootstrap-machine.ps1` naming collision
`scripts/gentle-vanguard/bootstrap-machine.ps1` is a **global Gentle-Vanguard installer** (installs Gentle-Vanguard to `~/.gentle-vanguard/`), not a machine bootstrap for prerequisites. This is distinct from `scripts/gentle-vanguard/bootstrap.ps1` (workspace bootstrap) and `scripts/utilities/install-prerequisites.ps1` (tool installer). The name `bootstrap-machine.ps1` is misleading given docs/getting-started/README.md says "this will install required PowerShell modules, configure Git hooks, set up env vars, and validate prerequisites" — the actual script does none of those things (it installs Gentle-Vanguard itself to a user directory).

