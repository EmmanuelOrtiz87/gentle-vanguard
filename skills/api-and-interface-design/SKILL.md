---
name: api-and-interface-design
aliases: ["api-and-interface-design"]
description:
  Design stable APIs and module boundaries. Use for REST/GraphQL endpoints, component props, or
  public interface changes.
  
triggers:
  - api design
  - interface
  - endpoint
  - module boundary
  - public api
metadata:
  source: opencode-migrated
  migrated: true
  migratedAt: "2026-08-09T01:46:58.307Z"
  originalPath: C:\Workspace_local\gentle-vanguard\.opencode\skills\api-and-interface-design\SKILL.md
  version: "1.0.0"
---

# API and Interface Design

Design interfaces that are hard to misuse. Good interfaces make the right thing easy and the wrong
thing hard.

## When to Use

- Designing API endpoints
- Defining module boundaries or team contracts
- Creating component prop interfaces
- Changing existing public interfaces

## Core Principles (Summary)

| Principle                  | Guidance                                                   |
| -------------------------- | ---------------------------------------------------------- |
| **Contract First**         | Define the interface before implementing it                |
| **One-Version Rule**       | Extend rather than fork; avoid diamond dependencies        |
| **Prefer Addition**        | Add optional fields — never change or remove existing ones |
| **Hyrum's Law**            | Every observable behavior becomes a de facto contract      |
| **Validate at Boundaries** | Trust internal code; validate at system edges              |

→ Detail + code: `references/core-principles.md`

## Error Handling

Pick one error strategy and use it everywhere. Never mix patterns.

| Status | Meaning                                  |
| ------ | ---------------------------------------- |
| 400    | Client sent invalid data                 |
| 401    | Not authenticated                        |
| 403    | Authenticated but not authorized         |
| 404    | Resource not found                       |
| 409    | Conflict (duplicate, version mismatch)   |
| 422    | Validation failed (semantically invalid) |
| 500    | Server error (never expose internals)    |

→ Structured error body & validation code examples: `references/error-validation.md`

## REST API Patterns

| Method | Endpoint                  | Purpose                                      |
| ------ | ------------------------- | -------------------------------------------- |
| GET    | `/api/tasks`              | List (query params for filtering/pagination) |
| POST   | `/api/tasks`              | Create                                       |
| GET    | `/api/tasks/:id`          | Get single                                   |
| PATCH  | `/api/tasks/:id`          | Partial update                               |
| DELETE | `/api/tasks/:id`          | Delete (idempotent)                          |
| GET    | `/api/tasks/:id/comments` | List sub-resource                            |
| POST   | `/api/tasks/:id/comments` | Create sub-resource                          |

→ Pagination, filtering, PATCH patterns: `references/rest-api-patterns.md`

## TypeScript Interface Patterns

- **Discriminated unions** for state variants — type narrowing works out of the box
- **Input/Output separation** — inputs are partial; outputs include server-generated fields
- **Branded types** for IDs — prevents passing the wrong ID type

→ Examples: `references/typescript-interfaces.md`

## Common Pitfalls

| Rationalization                       | Reality                                             |
| ------------------------------------- | --------------------------------------------------- |
| "We'll document the API later"        | The types ARE the documentation                     |
| "We don't need pagination now"        | You will the moment someone has 100+ items          |
| "PATCH is complicated, let's use PUT" | PUT requires the full object every time             |
| "We'll version when we need to"       | Design for extension from day one                   |
| "Nobody uses undocumented behavior"   | Hyrum's Law: if observable, somebody depends on it  |
| "Internal APIs don't need contracts"  | Contracts prevent coupling and enable parallel work |

→ Full table, red flags, and verification checklist: `references/common-pitfalls.md`

## Red Flags

- Endpoints returning different shapes depending on conditions
- Inconsistent error formats across endpoints
- Validation scattered throughout internal code
- Breaking changes to existing fields
- List endpoints without pagination
- Verbs in REST URLs (`/api/createTask`)
- Third-party API responses used without validation

## Verification

→ Full checklist with 7 items: `references/common-pitfalls.md#verification-checklist`

## Reference Files

| File                                  | Covers                                                |
| ------------------------------------- | ----------------------------------------------------- |
| `references/core-principles.md`       | Hyrum's Law, One-Version Rule, Contract First, Naming |
| `references/error-validation.md`      | Error shape, status codes, validation boundaries      |
| `references/rest-api-patterns.md`     | Resource design, pagination, PATCH                    |
| `references/typescript-interfaces.md` | Discriminated unions, I/O separation, branded IDs     |
| `references/common-pitfalls.md`       | Rationalizations, red flags, checklist                |

## Examples

**Input:** a task matching `api-and-interface-design` triggers.
**Action:** apply the workflow described above.
**Expected result:** Design stable APIs and module boundaries.
