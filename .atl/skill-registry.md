# Skill Registry (Auto-Resolved)

This file defines the enforceable skills and compact rules for the workspace-foundation project.

## Example Entry
- Skill: testing-strategy-skill
- Applies to: *.tests.ps1, *.test.go, *.spec.js, tests/
- Compact Rule: All code must have automated tests. Tests must run and pass in CI/CD before merge.

## Skills
- testing-strategy-skill: Automated testing and coverage enforcement
- foundation-audit-skill: Structure, docs, links, and duplicate validation
- judgment-day: Adversarial review protocol
- github-pr: Pull request quality and description enforcement
- go-testing: Go test patterns and coverage
- pytest: Python test patterns
- playwright: E2E testing patterns

## Usage
- Update this file when adding or removing skills.
- See docs/architecture/PROJECT-STRUCTURE.md for structure guidance.
