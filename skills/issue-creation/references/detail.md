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
