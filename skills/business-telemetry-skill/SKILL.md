---
name: business-telemetry-skill
description: >
  Defines standards for capturing, consolidating and reporting business-relevant telemetry. Trigger:
  "telemetry", "metrics", "management report", "roi analysis"
metadata:
  source: GV-native
---

## Purpose

Transform raw development activity (tokens, sessions, judgments) into structured, management-ready
data for decisión making (ROI, Efficiency, Quality).

## Master Telemetry Schema (`docs/management/telemetry-master.csv`)

| Column             | Description                                        | Source              |
| ------------------ | -------------------------------------------------- | ------------------- |
| `Timestamp`        | ISO 8601 timestamp of the event                    | System              |
| `User_ID`          | Developer identifier (from `git config user.name`) | Git                 |
| `Session_ID`       | Unique session identifier                          | WFS                 |
| `Task_Scope`       | Brief description of the task                      | Session Brief       |
| `Tokens_Estimated` | Estimated token usage for the session              | Token Guard         |
| `Judgment_Result`  | Outcome of the last judgment (PASS/FAIL)           | Judgment Dashboard  |
| `Review_Issues`    | Count of issues found in code review               | Review Orchestrator |
| `Duration_Min`     | Estimated duration of the session                  | Session Start/End   |
| `Efficiency_Score` | Calculated metric (Tokens vs Output)               | AGENT-GOV Analysis  |

## Core Rules

1. **Identity First:** Every record MUST include a valid `User_ID`. If unknown, tag as 'unknown' and
   flag for review.
2. **Business Relevance:** Do not log trivial actions (e.g., "fixed typo"). Focus on features,
   fixes, and architectural decisións.
3. **Consolidation:** Local logs are ephemeral. The `telemetry-master.csv` is the source of truth
   for management.
4. **Privacy:** Avoid logging sensitive code snippets or secrets. Only metadata and metrics are
   recorded.

## Workflow for AGENT-GOV

1. **Extract:** Read local session artifacts (`docs/sessions/`, `docs/judgment/`).
2. **Identify:** Retrieve `User_ID` from Git configuration.
3. **Analyze:** Determine the `Efficiency_Score` based on token usage vs. successful judgment.
4. **Append:** Add a new row to `docs/management/telemetry-master.csv`.
5. **Report:** If significant anomalies are found (e.g., high tokens, repeated failures), add a note
   to `docs/management/executive-summary.md`.

## Adaptability

If management requires new KPIs, update this schema and notify `AGENT-GOV` to adjust its analysis
logic.
