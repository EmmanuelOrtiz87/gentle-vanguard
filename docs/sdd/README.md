# Spec-Driven Development (SDD)

This directory contains design documents and implementation specifications for Foundation
and its components.

## Purpose

Spec-Driven Development ensures that all features are designed, implemented, and validated according
to documented specifications. Each spec serves as both a blueprint for implementation and a contract
for validation.

## Directory Structure

```
sdd/
 foundation-sdd.md          # Main design document
 SPEC-TEMPLATE.md           # Template for new specs
 [feature]-[spec].md        # Individual feature specs
```

## Documentation Guidelines

1. **Use the SPEC-TEMPLATE.md** as the starting point for new specs
2. **Keep specs focused** - One spec per feature or major change
3. **Link to related artifacts** - PRs, issues, implementation files
4. **Maintain status** - Update spec status as work progresses
5. **Include validation criteria** - Clear acceptance criteria

## Spec Lifecycle

1. `draft` - Initial design and requirements
2. `reviewed` - Reviewed by team/stakeholders
3. `implementing` - Under active development
4. `validated` - Implementation validated against spec
5. `done` - Fully implemented and tested

## Governance

Follow the guidelines in `docs/reference/SDD-GOVERNANCE-POLICY.md` for spec creation, review, and
approval processes.

### SDD Exemption

In certain cases, a PR may be exempt from SDD requirements. To request an exemption, add these
lines to the PR body:

```
SDD-EXEMPT: true
SDD-EXEMPT-REASON: <brief justification, e.g., "documentation-only change" or "emergency hotfix">
```

Valid exemption reasons include:
- **Documentation-only changes**: No code or behavior changes
- **Emergency hotfixes**: Production issues requiring immediate fix (mini-spec still recommended)
- **Internal refactors**: No external behavior changes (still requires a brief spec)
- **Trivial changes**: One-line fixes, typo corrections, dependency updates

Exemptions are validated by `scripts/diagnostics/validate-sdd-governance.ps1` in CI.
The SDD gate (`scripts/hooks/check-sdd-gate.ps1`) enforces this on PRs to `main`/`develop`.

## Current Specs

Main specification:

- [foundation-sdd.md](foundation-sdd.md) - Core Foundation design

Template:

- [SPEC-TEMPLATE.md](SPEC-TEMPLATE.md) - Template for new specifications

## Related Documentation

- [SDD Governance Policy](../reference/SDD-GOVERNANCE-POLICY.md)
- [Development Workflow](../guides/DEVELOPMENT-WORKFLOW.md)
- [Session Guide](../guides/SESSION-GUIDE.md)
