# Demo Suite — Gentleman Foundation v2.14.0

Audience-oriented demos. Each includes run steps, expected output, and talking points. Use
`demos/shared/task-tracker/` as the sample project for live demos.

---

## Demo Index

| #   | Directory                              | Audience        | Focus                                       | Duration |
| --- | -------------------------------------- | --------------- | ------------------------------------------- | -------- |
| 01  | `01-dev-developer-onboarding/`         | Dev Team        | First session setup, hooks, CLI basics      | 10 min   |
| 02  | `02-dev-orchestrator-and-ai-cycle/`    | Dev Team        | Agent routing, dispatch, skill loading      | 15 min   |
| 03  | `03-dev-engram-memory-and-continuity/` | Dev Team        | Engram persistent memory, context handoff   | 10 min   |
| 04  | `04-dev-quality-gate-review-audit/`    | Dev / Tech Lead | PSScriptAnalyzer CI, SDD gate, Judgment Day | 15 min   |
| 05  | `05-dev-documentation-and-closure/`    | Dev / DOC       | Session closure, audit artifacts, docs      | 10 min   |
| 06  | `06-exec-executive-overview/`          | Executives      | Business impact, dashboard, KPIs            | 20 min   |
| 07  | `07-mixed-cookbook-real-request/`      | Mixed           | End-to-end real-world feature request       | 25 min   |
| 08  | `08-dev-enterprise-hardening-v265/`    | Dev / DevOps    | Enterprise hardening, SLOs, releases   | 20 min   |

---

## Quick Audience Guide

**For a Developer onboarding:**

```
01 → 02 → 03 → 04
```

**For an Executive or Management meeting:**

```
06 (standalone, 20 min, visual-first)
```

**For a Tech Lead / DevOps review:**

```
04 → 08
```

**For a full mixed walkthrough:**

```
01 → 02 → 04 → 06 → 07
```

**For "what's new in v2.14.0":**

```
08 (all new features in one place)
```

---

## Coverage Matrix (v2.14.0)

| Capability                    | Demos      |
| ----------------------------- | ---------- |
| Agent orchestration + routing | 02, 07     |
| Engram persistent memory      | 03, 05, 06 |
| SDD enforcement gate          | 04, 08     |
| PSScriptAnalyzer CI           | 04, 08     |
| WF Benchmark (SLOs)           | 08         |
| Sync Drift detection          | 08         |
| Quality gates (7D)            | 04, 07     |
| HTML Dashboard + metrics      | 06         |
| Executive business value      | 06         |
| Automated releases            | 08         |
| Normativas vivas              | 08         |
| Judgment Day review           | 04, 07     |
| Session lifecycle             | 01, 05     |
