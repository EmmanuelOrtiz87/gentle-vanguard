# SDD Governance Policy

This document standardizes how Spec-Driven Development (SDD) is applied in this workspace.

## Purpose

1. Make SDD expectations explicit and auditable.
2. Normalize enforcement across orchestrator, contributors, and PR reviews.
3. Keep delivery speed while preserving quality gates.

## Ownership Model

1. Primary owner: project orchestrator.
2. Governance support: native review and compliance checks.
3. Implementation support: orchestrator-guided execution assistants.

## Policy Scope

This policy applies to repositories and modules using the Foundation orchestration model.

## Enforcement Criteria

Mandatory SDD:

1. Net-new feature behavior.
2. API contract changes.
3. Cross-module behavior changes.
4. Architectural behavior changes.

Conditional exception (mini-spec required):

1. Hotfixes and production incident remediations.
2. Time-sensitive operational fixes.
3. Internal refactors with no user-visible behavior change.

## Required Artifacts

For mandatory SDD work, all of the following are required before merge:

1. Spec file in `docs/sdd/`.
2. Acceptance criteria in testable format.
3. Validation evidence (tests/check output).
4. Final spec status as `validated` or `done`.

For exception paths, a mini-spec must exist before merge with:

1. Problem statement.
2. Scope and non-goals.
3. Acceptance criteria.
4. Validation evidence.

## Default Workflow

1. SPEC: create or update `docs/sdd/{feature}.md`.
2. REVIEW: verify goals, constraints, and non-goals.
3. IMPLEMENT: map implementation work to spec sections.
4. VALIDATE: run required checks and tests.
5. CLOSE: mark status and include references in PR.

## PR Gate Checklist

1. Spec path included in PR description.
2. Acceptance criteria status included.
3. Validation evidence included.
4. Exception rationale included if mini-spec path is used.

## Recommended Quality Baseline

1. No behavior implementation without criteria.
2. No merge when spec status is still `draft` for mandatory SDD scope.
3. No undocumented exceptions.

## References

1. `skills/project-orchestrator-skill/SKILL.md`
2. `skills/sdd-lifecycle/SKILL.md`
3. `docs/sdd/README.md`
