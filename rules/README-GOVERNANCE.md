# README Governance Policy

<p align="center">
  <b>Protected Document — Changes Require Explicit Approval</b><br>
  <em>See modification protocol below before editing any README</em>
</p>

---

## Purpose

This document establishes a **governance policy** for all README files in the Gentle-Vanguard project. Its goal is to prevent the degradation of README quality that occurs when changes are made without review, resulting in loss of essential content, inconsistent data, or structural simplification.

**Problem this solves**: In previous iterations, READMEs were reduced from ~200 lines of comprehensive documentation to ~35 lines, losing Mermaid diagrams, architecture descriptions, delegation rules, model routing, and development guides. This policy ensures that cannot happen again.

---

## Scope

This policy applies to:

| File | Repository | Type |
|------|-----------|------|
| `README.md` | `gentle-vanguard` (private) | **Protected** |
| `README.md` | `gentle-vanguard-public` (public) | **Protected** |
| `docs/README.md` | `gentle-vanguard` (private) | **Advisory** |

---

## Mandatory Sections

### Private README (`gentle-vanguard/README.md`)

The following sections are **mandatory** and must not be removed, renamed, or substantially reduced:

| # | Section | Minimum Content | Rationale |
|---|---------|-----------------|-----------|
| 1 | **Header** | Title, subtitle with stats (agents, skills, tool-compatible), badges (version, status, license, PowerShell, agents, skills, workflows), navigation links | First impression — must show project scale at a glance |
| 2 | **What is Gentle-Vanguard?** | 6-bullet summary + Mermaid flowchart (request → orchestrator → delegation → SDD → skills → memory) | Core value proposition — cannot be reduced to a tagline |
| 3 | **Architecture** | Work Routing Ladder (Mermaid), Delegation Rules table (5 rules), Model Routing per Agent (Mermaid), 5-Layer Architecture table | Technical depth — this is the developer-facing repo |
| 4 | **Agent Ecosystem** | Full table: Agent, Role, Model Profile, Delegates to | 16 agents with their routing — essential for understanding delegation |
| 5 | **Key Capabilities** | SDD/OpenSpec (with Mermaid), SDD Preflight table, Review Workload Guard, Skill Registry, Chain-Delivery Skills, Cross-Tool Compatibility | Each capability is a differentiator — removing any loses value |
| 6 | **Quick Start** | Clone + session start + verify + SDD preflight + review guard | Developer onboarding — must be actionable |
| 7 | **Development** | Table with all dev commands (tests, quality gates, security audit, skill registry, build) | Developer reference — must be complete |
| 8 | **CI/CD Pipeline** | Full table: 16+ workflows with purpose and trigger | Shows project maturity and governance |
| 9 | **Project Status** | Gate results table (Configuration, Skills, Tests, Hooks, Structure) | Trust signal — must be present and current |
| 10 | **Key Documentation** | Links table: AGENTS.md, Architecture, Delegation Rules, Model Routing, SDD Config, Skill Registry, Build Pipeline, Contributing, Changelog | Navigation — must link to all major docs |

### Public README (`gentle-vanguard-public/README.md`)

| # | Section | Minimum Content | Rationale |
|---|---------|-----------------|-----------|
| 1 | **Header** | Title, subtitle with stats, badges (version, status, license, PowerShell, platform, agents, skills, workflows) | Public-facing first impression |
| 2 | **What It Solves** | Problem/Solution table (6+ rows) | Value proposition for non-technical audience |
| 3 | **Architecture** | Mermaid flowchart + 5-Layer Architecture table | Technical credibility |
| 4 | **Agent Ecosystem** | Full table: Agent, Role, Model Profile | Shows depth of orchestration |
| 5 | **Key Features** | 8+ bullet points with specific numbers | Differentiators with evidence |
| 6 | **Skill Catalog** | Category table with counts and key skills | Shows breadth of capabilities |
| 7 | **Quick Install** | Windows one-click + Git clone instructions | Must be actionable for new users |
| 8 | **Requirements** | Table with version, required/optional, notes | Prerequisites for installation |
| 9 | **CI/CD Pipeline** | Full table: 16+ workflows | Shows project maturity |
| 10 | **Defensive Patterns** | 6+ bullet points | Security and quality assurance |
| 11 | **Documentation** | Links table | Navigation to deeper docs |
| 12 | **Security** | AES-256 reference + SECURITY.md link | Trust signal |
| 13 | **License** | MIT link | Legal compliance |

---

## Prohibited Actions

The following actions are **prohibited** without explicit approval (see Modification Protocol):

1. **Removing mandatory sections** — Any section listed above cannot be removed
2. **Reducing section content** — Replacing a detailed section with a brief summary or link-only section
3. **Changing stats without verification** — Agent count, skill count, workflow count, etc. must match actual project data
4. **Removing Mermaid diagrams** — Architecture and routing diagrams are mandatory visual elements
5. **Consolidating sections** — Merging two mandatory sections into one loses information density
6. **Replacing tables with prose** — Tables provide scannable structure; prose does not
7. **Changing the version badge** without updating CHANGELOG.md first
8. **Removing badges** from the header section

---

## Modification Protocol

### Who Can Modify

| Role | Permission |
|------|-----------|
| **Project Owner** | Full edit access |
| **DOC Agent** | Can propose changes via PR — cannot directly commit |
| **Other Agents** | Cannot modify README files at all |

### Approval Process

1. **Propose**: Create a branch with the proposed changes
2. **Validate**: Run `scripts/utilities/validate-readme.ps1` — must pass all checks
3. **Review**: Project Owner reviews the diff
4. **Approve**: Project Owner approves and merges
5. **Sync**: If private README changed, sync to public repo via `sync-public.yml`

### Emergency Override

If a README contains **factually incorrect data** (wrong version, wrong count, broken links), any agent may fix that specific data point without full review, provided:
- Only the incorrect data point is changed
- No sections are removed or restructured
- The change is documented in the commit message with `[README-FIX]` prefix
- `validate-readme.ps1` is run afterward

---

## Baseline Versions

These are the approved baselines. Any structural change must reference the baseline version and justify the deviation.

| File | Baseline Version | Baseline Date | SHA |
|------|-----------------|---------------|-----|
| `gentle-vanguard/README.md` | v2.18.0-governed | 2026-05-18 | *(set on first commit)* |
| `gentle-vanguard-public/README.md` | v2.18.0-governed | 2026-05-18 | *(set on first commit)* |

### How to Update Baseline

After a reviewed and approved change to a README:

1. Update the SHA in this table to match the new commit
2. Update the Baseline Date
3. Commit this governance file together with the README change

---

## Validation

Run the validation script before any README change:

```powershell
.\scripts\utilities\validate-readme.ps1
```

This script checks:
- All mandatory sections are present
- No section has been reduced below minimum content threshold
- Stats (agents, skills, workflows) match actual project data
- Mermaid diagrams are present and syntactically valid
- Badges are present and version matches CHANGELOG.md
- No broken internal links

### Pre-Commit Hook

A pre-commit hook automatically runs `validate-readme.ps1` when README.md files are staged. If validation fails, the commit is blocked.

See `hooks/validate-readme-hook.ps1` for the hook implementation.

---

## Enforcement

| Mechanism | Description |
|-----------|-------------|
| **Pre-commit hook** | Blocks commits that fail README validation |
| **CI/CD gate** | `gentle-vanguard-quality-gate.yml` includes README structure check |
| **This document** | `rules/README-GOVERNANCE.md` is the authoritative policy |
| **Baseline tracking** | SHA-based baseline prevents silent degradation |
| **Manual review** | Project Owner must approve structural changes |

---

## Changelog

| Date | Change | Approved By |
|------|--------|-------------|
| 2026-05-18 | Initial governance policy created | Project Owner |