# Spec-Driven Development (SDD)

This directory contains design documents and implementation specifications for Workspace Foundation and its components.

## Purpose

Spec-Driven Development ensures that all features are designed, implemented, and validated according to documented specifications. Each spec serves as both a blueprint for implementation and a contract for validation.

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

Follow the guidelines in `docs/reference/SDD-GOVERNANCE-POLICY.md` for spec creation, review, and approval processes.

## Current Specs

Main specification:
- [foundation-sdd.md](foundation-sdd.md) - Core Workspace Foundation design

Template:
- [SPEC-TEMPLATE.md](../specs/SPEC-TEMPLATE.md) - Template for new specifications

## Related Documentation

- [SDD Governance Policy](../reference/SDD-GOVERNANCE-POLICY.md)
- [Development Workflow](../guides/DEVELOPMENT-WORKFLOW.md)
- [Session Guide](../guides/SESSION-GUIDE.md)