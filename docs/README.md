# Gentle-Vanguard Documentation

This directory contains the permanent documentation for the Gentle-Vanguard stack. Keep it focused
on documents that explain how the stack works, how it is governed, how it is operated, and why
important decisions exist.

## Documentation Map

| Area                | Path                                          | Purpose                                                                                    |
| ------------------- | --------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Agent runtime       | [agents/](agents/)                            | Agent bootstrap, AI behavior rules, tool-specific local-first guidance, prompt behavior.   |
| Architecture        | [architecture/](architecture/)                | System architecture, topology, workflows, project structure, architecture diagrams.        |
| Decisions           | [adr/](adr/)                                  | Architecture decision records and durable technical decisions.                             |
| Dashboard           | [dashboard/](dashboard/)                      | Dashboard behavior, executive view, observability UI documentation.                        |
| Governance          | [governance/](governance/)                    | Normatives, policies, contribution rules, code review standards, compliance guidance.      |
| Getting started     | [getting-started/](getting-started/)          | Installation, prerequisites, developer setup, stack setup.                                 |
| Guides              | [guides/](guides/)                            | Operational and development guides that are still useful day to day.                       |
| Incidents           | [incidents/](incidents/)                      | Lessons learned and incident writeups worth preserving.                                    |
| Knowledge base      | [knowledge-base/](knowledge-base/)            | Knowledge-base architecture and usage documentation.                                       |
| Marketing and brand | [brand/](brand/) and [marketing/](marketing/) | Brand assets, launch copy, social material, external messaging.                            |
| Operations          | [operations/](operations/)                    | Runbooks, CI/CD docs, operating procedures, command references.                            |
| Presentations       | [presentations/](presentations/)              | Current presentation material. Older versions belong outside live docs.                    |
| Product             | [product/](product/)                          | Manifesto, requirements, design, roadmap, product-facing documentation.                    |
| Reference           | [reference/](reference/)                      | Stable technical references and implementation contracts.                                  |
| Releases            | [releases/](releases/)                        | Release-specific evidence, notes, final release documentation.                             |
| Research            | [research/](research/)                        | Curated research that supports stack decisions or capabilities.                            |
| SDD                 | [sdd/](sdd/)                                  | Spec-driven development documents and templates.                                           |
| Security            | [security/](security/)                        | Security policy, usage examples, hardening, dependency security support.                   |
| Status              | [status/](status/)                            | [Canonical current status](status/CANONICAL-STATUS.md) and intentionally retained reports. |
| Supplementary       | [supplementary/](supplementary/)              | Templates and supporting material that do not belong to a core area.                       |
| Tasks and backlog   | [tasks/](tasks/) and [backlog/](backlog/)     | Current task/backlog tracking. Completed plans should not live here.                       |
| Technical manual    | [technical/](technical/)                      | Multi-part technical manual and stack documentation.                                       |
| Use cases           | [use-cases/](use-cases/)                      | Representative examples and usage scenarios.                                               |

## Retention Rules

Keep documents in `docs/` when they are:

- Required to operate, govern, audit, extend, or troubleshoot the stack.
- Representative of current functionality, architecture, policy, behavior, or contracts.
- A formal decision record, normative, specification, runbook, test strategy, use case, or release
  record.
- A curated research artifact that directly informs the stack.

Do not keep documents in `docs/` when they are:

- Completed work plans, temporary implementation summaries, next-session notes, scratch reports, or
  one-off generated summaries.
- Raw research exports that are better stored under `research/`.
- Older presentations or duplicate bridge files that only point to a canonical document.
- Backups, generated outputs, logs, or transient test artifacts.

Historical material that may still be useful but is not live documentation belongs under
`.archive/`, with a clear reason for archival. Raw research outputs belong under the relevant
`research/` subdirectory.

## Recommendation

The current scope is good, but the stack should also keep explicit documentation for these
categories when they exist:

- Data lifecycle and retention: what gets stored, where, for how long, and how it is pruned.
- Recovery and rollback drills: not just rollback scripts, but verified recovery procedures.
- Ownership and review cadence: who reviews normatives, runbooks, architecture docs, and release
  docs.
- Deprecation policy: how a document moves from live docs to archive and when it is deleted.
- Plugin and connector contracts: expected configuration, security boundaries, lifecycle, and
  failure modes for each stack extension.
