# Contributing to Workspace Foundation

Thank you for your interest in contributing!

## Code of Conduct

By participating, you agree to maintain a respectful and inclusive environment for everyone.

## How to Contribute

### 1. Fork and Clone

```bash
# Fork the repository on GitHub

# Clone your fork
git clone https://github.com/YOUR_USERNAME/workspace-foundation.git
cd workspace-foundation

# Add upstream remote
git remote add upstream https://github.com/Gentleman-Programming/workspace-foundation.git
```

### 2. Create a Branch

```bash
# Sync with upstream
git fetch upstream
git checkout main
git pull upstream main

# Create your branch
git checkout -b feat/your-feature-name
# Or: git checkout -b fix/issue-number
```

### 3. Development

```bash
# Install dependencies
./scripts/init-workspace.ps1

# Validate your changes
./scripts/wf.ps1 validate

# Run tests
./scripts/wf.ps1 test
```

### 4. Make Changes

#### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation
- style: Formatting
- refactor: Code refactoring
- test: Adding tests
- chore: Maintenance
- perf: Performance
- ci: CI/CD
- build: Build system
```

Examples:
```bash
git commit -m "feat(cli): add interactive project wizard"
git commit -m "fix(docker): resolve multi-stage build issue"
git commit -m "docs(readme): update installation guide"
```

#### Code Style

- Use 2 spaces for indentation
- Follow `.editorconfig` settings
- ESLint/Prettier formatting is enforced
- Write meaningful comments for complex logic

### 5. Test Your Changes

```bash
# Validate workspace
./scripts/wf.ps1 validate

# Test specific functionality
./scripts/wf.ps1 new --name test-project --kind service
```

### 6. Push and Create PR

```bash
# Push your branch
git push origin feat/your-feature-name

# Create PR on GitHub
```

## Pull Request Guidelines

### PR Description

Include in your PR:

- **Summary**: Brief description of changes
- **Type**: Bug fix / New feature / Breaking change / Documentation
- **Motivation**: Why this change is needed
- **Testing**: How you tested the changes
- **Related Issues**: Link to issues (e.g., Closes #123)

### PR Checklist

- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No `console.log` or debug code
- [ ] No secrets committed
- [ ] Commits follow conventional commits
- [ ] Tests added/updated (if applicable)
- [ ] Validation passes

## Project Structure

```
workspace-foundation/
├── .github/           # GitHub templates
├── config/            # Workspace configuration
├── docs/              # Documentation
├── scripts/           # Automation scripts
│   ├── wf.ps1        # Main CLI
│   ├── deploy.ps1    # Deployment script
│   └── migrate.ps1   # Database migrations
├── skills/            # Agent skills
│   ├── workspace-foundation/
│   ├── testing-skill/
│   ├── security-skill/
│   └── ...
├── templates/        # Project templates
│   ├── config/       # Configuration templates
│   ├── editor/       # Editor configs
│   ├── project-root/ # Base template
│   ├── project-types/# Type-specific templates
│   ├── testing/      # Test templates
│   └── api/          # API specs
└── tools/            # External tools
```

## Scripts

| Script | Purpose |
|--------|---------|
| `wf.ps1 init` | Initialize workspace |
| `wf.ps1 new` | Create new project |
| `wf.ps1 validate` | Validate workspace |
| `wf.ps1 deploy` | Deploy application |
| `wf.ps1 migrate` | Run migrations |

## Questions?

- Open an issue for bugs or feature requests
- Check existing issues before creating new ones
- Join discussions in PRs

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
