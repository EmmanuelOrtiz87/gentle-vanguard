# Spec: {Feature Name}

**Status**: draft | reviewed | implementing | validated | done **Author**: {name} **Date**:
YYYY-MM-DD **Linked PR/Branch**: {link or N/A}

## Problem Statement

{1-3 sentences. Why this should exist.}

## Goals

1. {Goal 1}
2. {Goal 2}

## Non-Goals

1. {Explicitly out of scope item}

## Acceptance Criteria

```gherkin
Feature: {Feature Name}

  Scenario: {Happy path}
    Given {context}
    When {action}
    Then {expected outcome}

  Scenario: {Edge case}
    Given {context}
    When {action}
    Then {expected outcome}
```

## Technical Design

{Architecture, data model, API contract, and constraints.}

## Validation Plan

| Criteria | Test Type   | Status |
| -------- | ----------- | ------ |
| {AC 1}   | Unit        |        |
| {AC 2}   | Integration |        |
| {AC 3}   | E2E         |        |

## Traceability

| Spec Section | Implementation File/Area | Status |
| ------------ | ------------------------ | ------ |
| {Section}    | {path}                   |        |

## References

1. Related ADRs: {link}
2. Related tasks/issues: {link}
