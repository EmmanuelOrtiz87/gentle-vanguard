# CI/CD Operations

## Overview

This document describes the CI/CD configuration for **foundation**, optimized for GitHub
Free plan (2000 min/month on private repos).

**Context**: Self-hosted runners are NOT available for private repositories on GitHub Free plan
(only available for public repos or Team/Enterprise plans).

## Branch Strategy

| Branch    | CI Runs                 | Purpose                  |
| --------- | ----------------------- | ------------------------ |
| `main`    | All workflows           | Stable branch, protected |
| `develop` | Security workflows only | Integration branch       |

## GitHub Actions Workflows

### Workflows Running on Every `main` Push

| Workflow                | Runner         | Est. Time | Criticality                       |
| ----------------------- | -------------- | --------- | --------------------------------- |
| Workflow Lint           | ubuntu-latest  | ~1 min    | Low (already runs in pre-commit)  |
| Format Check            | ubuntu-latest  | ~1 min    | Low (already runs in pre-commit)  |
| Test Suite              | windows-latest | ~4 min    | Medium (runs locally in pre-push) |
| PSScriptAnalyzer        | windows-latest | ~3 min    | Low (runs locally in pre-commit)  |
| Foundation Quality Gate | windows-latest | ~3 min    | Medium                            |
| Autonomous Validation   | windows-latest | ~15 min   | Low (weekly schedule)             |
| Script Governance       | windows-latest | ~3 min    | Medium                            |
| Sync Public             | windows-latest | ~2 min    | High                              |

### Workflows Running on Both `main` and `develop` (Security Critical)

| Workflow                     | Runner        | Est. Time        | Why Both                                         |
| ---------------------------- | ------------- | ---------------- | ------------------------------------------------ |
| Security Scan (consolidated) | ubuntu-latest | ~30 min (4 jobs) | Vulnerability detection, must catch before merge |
| Gitleaks Secret Scan         | ubuntu-latest | ~3 min           | Leaked credentials, must catch before merge      |

### Other Workflows (Not Push-Triggered)

| Workflow                  | Trigger                               | Est. Time |
| ------------------------- | ------------------------------------- | --------- |
| Pull Request Labeler      | `pull_request_target`                 | ~30s      |
| Dashboard Auto Refresh    | Schedule + manual + limited path push | ~3 min    |
| Monthly Management Report | Schedule + manual                     | ~5 min    |
| Release                   | Tag push (`v*.*.*`)                   | ~2 min    |
| SDD Gate                  | PR to main                            | ~1 min    |

## Pre-Push Hooks (Local)

Run locally on every `git push`. Catch issues before GHA minutes are consumed:

| Hook                  | Est. Time | Purpose                      |
| --------------------- | --------- | ---------------------------- |
| Orchestrator Auto-Fix | ~6s       | Self-heals config drift      |
| Test Suite (28 tests) | ~73s      | Runs all Pester tests        |
| Audit Check (quick)   | ~1s       | Foundation consistency sweep |

**Removed from pre-push** (runs in GHA instead):

- `trufflehog-full` — handled by Gitleaks in GHA (gitleaks.yml + security-scan.yml)

**Total pre-push time**: ~80s

## GitHub Free Plan Budget

- **Limit**: 2000 min/month
- **Estimated consumption**: ~50 min per `main` push (all workflows), ~35 min per `develop` push
  (security only)
- **Capacity**: ~40 full pushes/month or ~57 develop pushes/month (combined)
- **Strategy**: Heavy hooks locally prevent broken pushes → fewer GHA runs wasted

## Local Machine Setup (foundation)

- **OS**: Windows (PowerShell 7)
- **Tools**: `node`, `npm`, `trufflehog`, `gitleaks`, `lefthook`
- **Lefthook hooks installed**: `npx lefthook install`
- **Key files**:
  - `.lefthook.yml` — hook configuration
  - `scripts/run-tests-simple.ps1` — test runner
  - `skills/foundation-audit-skill/scripts/audit-sweep.ps1` — audit

## How to Operate from Another Machine

1. Clone both branches: `main` and `develop`
2. Install dependencies: `npm ci`
3. Install hooks: `npx lefthook install`
4. Run pre-push hooks before pushing: the hooks will validate everything locally
5. Push to `main` to trigger all GHA workflows
6. Push to `develop` to trigger only security scans

## Troubleshooting

- **GHA quota exhausted (2000 min/month)**: Wait for reset (1st of month) or reduce pushes to `main`
- **Pre-push hooks fail**: Run `npx lefthook run pre-push` to debug
- **Audit failures**: Run audit sweep directly:
  `.\skills\foundation-audit-skill\scripts\audit-sweep.ps1 -Scope full`
