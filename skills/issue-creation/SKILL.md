---
name: issue-creation
description: >
  Issue creation workflow for Agent Teams Lite following the issue-first enforcement system.
  Trigger: When creating a GitHub issue, reporting a bug, or requesting a feature.

triggers:
  - issue
  - bug report
  - feature request
  - create issue
license: Apache-2.0
metadata:
  author: gentle-vanguard
  version: '1.0'
  source: GV-native
---

## When to Use

Use this skill when:

- Creating a GitHub issue (bug report or feature request)
- Helping a contributor file an issue
- Triaging or approving issues as a maintainer

---

## Critical Rules

1. **Blank issues are disabled** MUST use a template (bug report or feature request)
2. **Every issue gets `status:needs-review` automatically** on creation
3. **A maintainer MUST add `status:approved`** before any PR can be opened
4. **Questions go to Discussions** of the project repository, not issues
5. **No Co-Authored-By trailers** — never add AI attribution to commits
6. **Pre-submission privacy review is MANDATORY** — before `gh issue create`, replace private
   project names, usernames, home paths, hostnames, secrets/credentials, and environment-specific
   identifiers with explicit placeholders (`<project-name>`, `<user>`, `<hostname>`, `<token>`).
   Keep reproduction structure with placeholders — never redact an example into nothingness. Do NOT
   redact intentionally public identifiers like `gentle-vanguard`, `engram`, `opencode`. A final
   body scan happens immediately before publish.

---

## Pre-submission Privacy Review

Every issue body is scanned immediately before `gh issue create`. The scan replaces — never deletes
— environment-specific data with explicit placeholders so the reproduction still teaches:

| Category                    | Replace with                        | Example (before → after)                                      |
| --------------------------- | ----------------------------------- | ------------------------------------------------------------- |
| Private project names       | `<project-name>`                    | `my-private-project-b` → `<project-name>`                     |
| Usernames                   | `<user>`                            | `C:\Users\my-real-username\go\bin` → `C:\Users\<user>\go\bin` |
| Hostnames                   | `<hostname>`                        | `devbox-macbook.local` → `<hostname>`                         |
| Home paths                  | `/home/<user>` or `C:\Users\<user>` | (covered above)                                               |
| API keys, tokens, passwords | `<token>` / `<password>`            | `ghp_abc123...` → `<token>`                                   |
| Internal ports / hostnames  | `<host>:<port>`                     | `10.0.0.42:5432` → `<host>:<port>`                            |

Intentionally public identifiers are NOT redacted: tool names (`gentle-vanguard`, `engram`,
`opencode`, `node`, `python`), package names, public documentation URLs, generic example domains
(`example.com`, `localhost`).

**Rule of thumb:** if the reader can run the reproduction step after you replace every identifier
with its placeholder, the sanitization is correct. If a step becomes impossible (because the
placeholder consumed a needed value), that step needs the value — and you should mark it
`<value-required>` and explain in the body what the user should fill in.

---

## Workflow

```
1. Search existing issues for duplicates
2. Choose the correct template (Bug Report or Feature Request)
3. Fill in ALL required fields
4. Check pre-flight checkboxes
5. Submit  issue gets status:needs-review automatically
6. Wait for maintainer to add status:approved
7. Only then open a PR linking this issue
```

---

## Issue Templates

### Bug Report

Template: `.github/ISSUE_TEMPLATE/bug_report.yml` Auto-labels: `bug`, `status:needs-review`

#### Required Fields

| Field                  | Description                                                                 |
| ---------------------- | --------------------------------------------------------------------------- |
| **Pre-flight Checks**  | Checkboxes: no duplicate + understands approval workflow                    |
| **Bug Description**    | Clear description of the bug                                                |
| **Steps to Reproduce** | Numbered steps to reproduce                                                 |
| **Expected Behavior**  | What should have happened                                                   |
| **Actual Behavior**    | What happened instead (include errors/logs)                                 |
| **Operating System**   | Dropdown: macOS, Linux variants, Windows, WSL                               |
| **Agent / Client**     | Dropdown: Claude Code, OpenCode, Gemini CLI, Cursor, Windsurf, Codex, Other |
| **Shell**              | Dropdown: bash, zsh, fish, Other                                            |

#### Affected Areas

`CLI (commands, flags)` · `Session Pipeline` · `Dashboard` · `Agent Detection` · `Model Router` ·
`System Detection` · `Database (Nexus)` · `Documentation` · `Other`

#### Optional Fields

| Field                  | Description                               |
| ---------------------- | ----------------------------------------- |
| **Relevant Logs**      | Log output (auto-formatted as code block) |
| **Additional Context** | Screenshots, workarounds, extra info      |

#### Example Bug Report via CLI

```bash
gh issue create --template "bug_report.yml" \
  --title "fix(scripts): setup.sh fails on zsh with glob error" \
  --body "
### Pre-flight Checks
- [x] I have searched existing issues and this is not a duplicate
- [x] I understand this issue needs status:approved before a PR can be opened

### Bug Description
Running setup.sh on zsh throws a glob error when no matching files exist.

### Steps to Reproduce
1. Clone the repo
2. Run \`./scripts/setup.sh\` in zsh
3. See error: \`zsh: no matches found: skills/*\`

### Expected Behavior
The script should handle missing glob matches gracefully.

### Actual Behavior
Script crashes with glob error.

### Operating System
macOS

### Agent / Client
Claude Code

### Shell
zsh

### Relevant Logs
\`\`\`
zsh: no matches found: skills/*
\`\`\`
"
```

---

## Feature Request

Template: `.github/ISSUE_TEMPLATE/feature_request.yml` Auto-labels: `enhancement`,
`status:needs-review`

### Required Fields

| Field                   | Description                                                       |
| ----------------------- | ----------------------------------------------------------------- |
| **Pre-flight Checklist**| Confirm no duplicate exists; confirm PR-approval understanding    |
| **Affected Area**       | Which area of the stack this feature affects                      |
| **Problem Statement**   | Describe the problem this feature solves                          |
| **Proposed Solution**   | Specific description — include example command/output if relevant |
| **Alternatives Considered** | (optional) Other approaches you thought about                 |
| **Additional Context**  | (optional) Screenshots, config files, etc.                        |

---

## Label System

### Status Labels (applied to Issues)

| Label                 | Description                                     | Who Applies              |
| --------------------- | ----------------------------------------------- | ------------------------ |
| `status:needs-review` | Newly opened, awaiting maintainer review        | **Auto** (template)      |
| `status:approved`     | Approved — work can begin                       | Maintainer only          |
| `status:in-progress`  | Being actively worked on                        | Contributor              |
| `status:blocked`      | Blocked by another issue or external dependency | Maintainer / Contributor |
| `status:wont-fix`     | Out of scope or won't be addressed              | Maintainer only          |

### Type Labels (applied to Issues and PRs)

| Label                  | Description                                      |
| ---------------------- | ------------------------------------------------ |
| `bug`                  | Defect report                                    |
| `enhancement`          | Feature or improvement request                   |
| `type:bug`             | Bug fix (used on PRs)                            |
| `type:feature`         | New feature (used on PRs)                        |
| `type:docs`            | Documentation only (used on PRs)                 |
| `type:refactor`        | Refactoring, no functional changes (used on PRs) |
| `type:chore`           | Build, CI, tooling (used on PRs)                 |
| `type:breaking-change` | Breaking change (used on PRs)                    |

### Priority Labels

| Label               | Description                               |
| ------------------- | ----------------------------------------- |
| `priority:critical` | Blocking issues, security vulnerabilities |
| `priority:high`     | Important, affects many users             |
| `priority:medium`   | Normal priority                           |
| `priority:low`      | Nice to have                              |

---

## Maintainer Approval Workflow

```
Issue submitted
      │
      ▼
status:needs-review  ← auto-applied by template
      │
      ▼
Maintainer reviews
      │
  ┌───┴────────────────┐
  │                    │
  ▼                    ▼
status:approved    Closed
(work can begin)   (invalid / duplicate / wont-fix)
      │
      ▼
Contributor comments "I'll work on this"
      │
      ▼
status:in-progress
      │
      ▼
PR opened with `Closes #<N>`
```

---

## Decision Tree

```
Do you have a question or idea to discuss?
├── YES → GitHub Discussions (NOT issues)
└── NO  → Is it a defect in the stack?
          ├── YES → Bug Report template
          └── NO  → Feature Request template
                    │
                    ▼
          Does a similar issue already exist?
          ├── YES → Comment on existing issue instead
          └── NO  → Submit new issue → wait for status:approved
```

---

## Commands

### Search for Existing Issues

```bash
# Search open issues
gh issue list --repo EmmanuelOrtiz87/gentle-vanguard --state open --search "your keywords"

# Search all issues including closed
gh issue list --repo EmmanuelOrtiz87/gentle-vanguard --state all --search "your keywords"
```

### Create a Bug Report

```bash
gh issue create \
  --repo EmmanuelOrtiz87/gentle-vanguard \
  --template bug_report.yml \
  --title "fix(<scope>): <short description>"
```

### Create a Feature Request

```bash
gh issue create \
  --repo EmmanuelOrtiz87/gentle-vanguard \
  --template feature_request.yml \
  --title "feat(<scope>): <short description>"
```

### Check Issue Status

```bash
gh issue view <number> --repo EmmanuelOrtiz87/gentle-vanguard
```

### Valid Scopes for Issue Titles

`cli`, `pipeline`, `dashboard`, `agent`, `model-router`, `db`, `docs`, `ci`, `security`

---

> **Referencia detallada**: [references/detail.md](references/detail.md)
