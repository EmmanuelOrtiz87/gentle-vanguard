# AGENTS.md - Project Coding Standards

This file defines the coding standards and rules that **GGA** (Gentleman Guardian Angel) will enforce on every commit.

Edit this file to customize the rules for your project. GGA will validate staged files against these rules before each commit.

## Project Overview

{{PROJECT_NAME}} - {{PROJECT_DESCRIPTION}}

## Technology Stack

{{TECHNOLOGY_STACK}}

## Coding Standards

### Code Style
- Follow language-specific best practices
- Use consistent naming conventions
- Keep functions small and focused
- Write self-documenting code

### Documentation
- Document all public APIs
- Add comments for complex logic
- Keep documentation up to date
- Use clear commit messages

### Testing
- Write tests for new features
- Maintain test coverage
- Mock external dependencies
- Test edge cases

### Security
- Never commit secrets or credentials
- Validate all user input
- Use parameterized queries
- Follow security best practices

## Review Checklist

Before committing, verify:

1. Code follows style guidelines
2. Tests are written and passing
3. Documentation is updated
4. No secrets in code
5. Commit message follows conventions

## File Patterns

### Include
Files matching these patterns will be reviewed:
```
*

```

### Exclude
Files matching these patterns will be skipped:
```
*.test.ts,*.spec.ts,*.test.tsx,*.spec.tsx,*.d.ts,*_test.py,*.pyc,__pycache__
```

## Custom Rules

{{CUSTOM_RULES}}
