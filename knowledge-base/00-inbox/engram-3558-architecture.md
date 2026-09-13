---
created: 2026-09-01 00:18:54
tags: [engram, architecture]
engram_id: 3558
type: architecture
---

# oc-keyring v1.0.0 — multi-account rotation for OpenCode Zen & Go

## Problem

OpenCode Desktop stores credentials in %USERPROFILE%\.local\share\opencode\auth.json with ONE slot per provider ID. To add a 2nd account the user had to: deslog in opencode.io, login with other account, copy the API key, paste in Desktop. Slow, manual, error-prone.

## Solution

Declare N custom providers in ~/.config/opencode/opencode.json with unique IDs (opencode-zen-A, opencode-zen-B, opencode-go-A, opencode-go-B). OpenCode matches provider IDs between opencode.json (config) and uth.json (credentials) natively. Result: model picker shows 4 groups, switching = 1 click, no copy/paste, no restart.

## Components

- C:\Users\emman\bin\oc-keyring.ps1 — script: list/add/remove/switch/status/which/sync/open/backup/help
- C:\Users\emman\bin\oc-keyring.cmd — wrapper
- C:\Users\emman\bin\oc-keyring-validate.ps1 — end-to-end validator
- C:\Users\emman\.config\opencode\accounts.json — vault, source of truth
- C:\Users\emman\.config\opencode\opencode.json — 4 custom providers (zen-A, zen-B, go-A, go-B)
- C:\Users\emman\.local\share\opencode\auth.json — auto-generated from vault
- C:\Users\emman\.local\share\opencode\backups\<ts>\ — timestamped backups (14 created)

## Conventions

- A = primary account, B = secondary
- Provider ID: opencode-<product>-<letter>, e.g. opencode-zen-A
- Vault path: ccounts.<product>.<letter>

## 6 free models on Zen (verified opencode.ai/docs/zen/)

1. ig-pickle (default)
2. mimo-v2.5-free
3. ling-3.0-flash-fin-free
4.
emotron-3-ultra-free
5.
emotron-3.5-lightning-free
6. muse-spark-1.2-contributor-free — uses @ai-sdk/openai (override per model), all others use @ai-sdk/openai-compatible

## PowerShell 5.1 gotchas hit

- \6396 is read-only (use \)
- ?? null-coalescing is PS7+ only
- hashtable literal @{} iteration order is non-deterministic — use [ordered]@{}
- Read-Host fails in non-interactive mode — add -Force switch
- Get-Content default encoding is ANSI on Win PS 5.1 — pass -Encoding UTF8

## Test results (all green)

- JSON validity: 3/3
- Auth list: 6 custom + 2 legacy + 1 env = 9 credentials
- Custom models: 34 visible (22 Zen + 12 Go)
- API call real: opencode-zen-A/big-pickle responded 'oc-keyring works'
- Backups: 14 timestamped snapshots
- Legacy providers preserved (no breakage)

## Tech debt: 0

Nothing added to the gentle-vanguard repo. Lives entirely in user space. No new deps. No rebuild required. config/model-router.json untouched.

## Docs

- docs/operations/oc-keyring-guide.md — usage
- docs/operations/oc-keyring-architecture.md — design decisions, alternatives, risks
- docs/operations/oc-keyring-changelog.md — audit trail

---
*Imported from Engram on 2026-09-06*
