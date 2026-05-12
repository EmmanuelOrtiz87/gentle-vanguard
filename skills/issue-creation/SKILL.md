---
name: issue-creation
description: >
  Issue creation workflow for Agent Teams Lite following the issue-first enforcement system.
  Trigger: When creating a GitHub issue, reporting a bug, or requesting a feature.
license: Apache-2.0
metadata:
  author: foundation
  versión: '1.0'
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

### Feature Request

Template: `.github/ISSUE_TEMPLATE/feature_request.yml` Auto-labels: `enhancement`,
`status:needs-review`

#### Required Fields

| Field                   | Description                                                             |
| ----------------------- | ----------------------------------------------------------------------- |
| **Pre-flight Checks**   | Checkboxes: no duplicate + understands approval workflow                |
| **Problem Description** | The pain point this feature solves                                      |
| **Proposed Solution**   | How it should work from the user's perspective                          |
| **Affected Area**       | Dropdown: Scripts, Skills, Examples, Documentation, CI/Workflows, Other |

#### Optional Fields

| Field                       | Description                     |
| --------------------------- | ------------------------------- |
| **Alternatives Considered** | Other approaches or workarounds |
| **Additional Context**      | Mockups, examples, references   |

#### Example Feature Request via CLI

```bash
gh issue create --template "feature_request.yml" \
  --title "feat(scripts): add Codex support to setup.sh" \
  --body "
### Pre-flight Checks
- [x] I have searched existing issues and this is not a duplicate
- [x] I understand this issue needs status:approved before a PR can be opened

### Problem Description
The setup script only configures Claude Code, Gemini CLI, and OpenCode. Codex users have to manually copy skills.

### Proposed Solution
Add a Codex option to setup.sh that links skills to the .codex/ directory.

Example:
\`\`\`bash
./scripts/setup.sh --agent codex
\`\`\`

### Affected Area
Scripts (setup, installation)

### Alternatives Considered
Manually symlinking, but that defeats the purpose of the setup script.
"
```

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
└── NO  → Is it a defect?
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

```bash
# Search existing issues before creating
gh issue list --search "keyword"
gh issue list --state open --search "your keywords"
gh issue list --state all --search "your keywords"

# Check issue status
gh issue view <number>

# Create bug report
gh issue create --template "bug_report.yml" --title "fix(scope): description"

# Create feature request
gh issue create --template "feature_request.yml" --title "feat(scope): description"

# Maintainer: approve an issue
gh issue edit <number> --add-label "status:approved"

# Maintainer: add priority
gh issue edit <number> --add-label "priority:high"
```
