# Git Normatives

**Version:** 1.0.0 **Last updated:** 2026-05-23

---

### 1. Branching Strategy

#### 1.1 Branch Types

**main**: Production-ready code

- Protected branch
- Requires PR review
- Requires CI/CD passing
- Tagged with versions

**develop**: Integration branch

- Base for feature branches
- Requires PR review
- Requires CI/CD passing
- Pre-release testing

**feature/**: Feature development

- Naming: `feature/ISSUE-123-description`
- Created from: `develop`
- Merged to: `develop`
- Deleted after merge

**bugfix/**: Bug fixes

- Naming: `bugfix/ISSUE-456-description`
- Created from: `develop`
- Merged to: `develop`
- Deleted after merge

**hotfix/**: Production hotfixes

- Naming: `hotfix/ISSUE-789-description`
- Created from: `main`
- Merged to: `main` and `develop`
- Deleted after merge

### 2. Commit Message Format

#### 2.1 Commit Message Structure

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### 2.2 Commit Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation
- **style**: Code style
- **refactor**: Code refactoring
- **perf**: Performance improvement
- **test**: Test addition/modification
- **chore**: Build/tooling changes

#### 2.3 Commit Message Rules

- Subject: 50 characters max
- Use imperative mood
- Don't capitalize subject
- No period at end
- Body: Explain what and why
- Reference issues: `Fixes #123`

### 3. Pull Request Procedures

#### 3.1 PR Requirements

- [ ] Branch naming follows convention
- [ ] Commits follow message format
- [ ] Tests passing
- [ ] Code coverage maintained
- [ ] Documentation updated
- [ ] No conflicts
- [ ] Descriptive PR title
- [ ] PR description explains changes

#### 3.2 PR Review Process

1. Author creates PR
2. Automated checks run
3. Reviewers assigned
4. Code review performed
5. Changes requested/approved
6. Author addresses feedback
7. PR approved
8. PR merged
9. Branch deleted

### 4. Code Review Requirements

#### 4.1 Review Criteria

- Code quality
- Test coverage
- Documentation
- Security
- Performance
- Architecture compliance

#### 4.2 Review Standards

- At least 2 approvals required
- No self-approval
- Comments must be constructive
- Discussions resolved before merge
- Approval expires after changes

### 5. Release Procedures

#### 5.1 Release Process

1. Create release branch
2. Update version numbers
3. Update changelog
4. Create release notes
5. Tag release
6. Deploy to production
7. Announce release

#### 5.2 Version Format

- Semantic versioning: `MAJOR.MINOR.PATCH`
- Pre-release: `1.0.0-alpha.1`
- Build metadata: `1.0.0+build.123`

---

_Version: 1.0.0 — 2026-05-23 — Status: ACTIVE_
