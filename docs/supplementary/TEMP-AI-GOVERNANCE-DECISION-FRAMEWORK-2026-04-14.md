# Temporary Governance and Decision Framework

Status: Temporary working document for analysis and future decisions
Date: 2026-04-14
Scope: workspace-foundation (without normalizing to bitbucket-dashboard)

## 1. Purpose

This document consolidates the current directives, rules, definitions, and operational criteria that influence AI-agent behavior in this workspace.

It answers:
1. What is done vs not done.
2. What must be consulted vs what can be automated.
3. What is accepted by default vs what requires double validation.
4. What can be omitted and why.
5. How automated decisions are made.
6. What should be improved in behavior, understanding, memory, and governance definitions.

## 2. Effective Governance Sources (Priority Order)

1. System and developer runtime instructions (highest runtime authority).
2. Workspace-level instructions:
   - .github/copilot-instructions.md
   - AGENTS.md (workspace root)
3. Repository governance and policy artifacts:
   - workspace-foundation/AGENTS.md
   - config/orchestrator.json
   - config/workspace.config.json
   - config/structure-policy.json
   - docs/guides/DEVELOPER-COMMUNICATION-POLICY.md
   - scripts/diagnostics/validate-script-governance.ps1
4. Operational scripts (actual behavior):
   - scripts/utilities/wf.ps1
   - scripts/utilities/ensure-tools-active.ps1
   - scripts/utilities/update-tools.ps1
   - scripts/validation/check-updates.ps1
   - scripts/validation/validate-workspace.ps1

## 3. Current Directives and Rules

### 3.1 Session and startup

1. Start session early before substantial work.
2. Session id pattern: session-YYYY-MM-DD-XX.
3. Project context defaults: project=workspace_local, directory=C:\Workspace_local.
4. Startup reliability criteria:
   - READY = pass
   - PARTIAL = actionable; resolve before deep work
5. Setup order when needed:
   - activate
   - validate
   - heavier actions later

### 3.2 Tooling behavior (homologated now)

Single source of truth for tools: config/workspace.config.json.

Unified behavior for all 5 tools (engram, gga, gentleman-skills, gentle-ai, opencode):
1. Check availability (command or path).
2. If AutoStart: verify prerequisites and attempt install.
3. Re-verify tool after install.
4. Warn clearly if manual action is needed.

### 3.3 Communication behavior

1. Workspace baseline says simple mode for minimum-token closure-first style.
2. Extended detail only with explicit trigger (example: DETALLE/EXTENDER).
3. Optional suggestions should be gated by developer authorization in local policy.
4. Critical risk warnings (security/data loss/regression) are mandatory even in minimal mode.

### 3.4 Structure and governance behavior

1. structureMode currently enforce-canonical.
2. Allowed script subfolders and root markdown constraints are enforced by policy and validators.
3. Deprecated path patterns are tracked and flagged by governance diagnostics.
4. Governance artifacts are required (orchestrator skill, script governance skill, session/task artifacts).

## 4. What Is Done vs Not Done

### 4.1 Done by default

1. Tool checks and optional auto-install flow through health/update scripts.
2. Workspace validation gates are available and currently passing.
3. Script governance and structure hygiene checks are available.
4. Optional MCP integrations are checked only if enabled.

### 4.2 Not done by default

1. Deep/full startup on every shell open (autostart is light by default).
2. Optional MCP service activation when disabled by config.
3. Heavy quality actions on every quick command unless explicitly requested.
4. Cross-repo normalization outside requested scope.

## 5. What Must Be Consulted vs What Can Be Automated

### 5.1 Must consult developer first

1. Any destructive action with potential data loss.
2. Relocation/removal of governance-required artifacts.
3. Policy-level behavior changes that alter team conventions.
4. Cross-repo homologation affecting repos outside requested scope.
5. Ambiguous requirements with architecture impact.

### 5.2 Can be automated safely

1. Running validations and health checks.
2. Non-destructive consistency fixes aligned with existing policy.
3. Tool install/update attempts using approved commands in workspace config.
4. Removal of proven orphan files with zero references and no governance dependency.

## 6. Accepted Defaults vs Double Validation Required

### 6.1 Accepted defaults

1. READY means acceptable baseline state.
2. Optional tools can be missing without hard fail unless strict mode is enabled.
3. MCP integrations remain disabled unless explicitly configured and env vars exist.
4. On-demand activation mode is the normal operating mode.

### 6.2 Double validation required

1. Security-sensitive changes.
2. Data deletion or irreversible migrations.
3. Publish/release flows with policy or branch gating impact.
4. Changes to install logic that can break environment bootstrap.
5. Governance-rule changes affecting validation outcomes.

## 7. Omission Rules (What to omit and why)

1. Omit optional suggestions unless authorized.
Reason: avoid scope creep and token noise.

2. Omit deep narratives in operational responses by default.
Reason: local communication policy favors concise closure-first output.

3. Omit heavy startup routines on every session.
Reason: startup config defaults to light mode for speed and low friction.

4. Omit optional integrations unless explicitly enabled.
Reason: principle of least surprise and lower setup complexity.

## 8. Automated Decision Logic (How the agent discerns)

Decision pipeline currently implied by policies and scripts:

1. Determine scope and constraints from request and active policies.
2. Classify action type:
   - informational
   - non-destructive automation
   - risky/destructive/policy-impacting
3. If risky or ambiguous: request developer confirmation.
4. If safe and within policy: execute automatically.
5. Validate result with appropriate gate (health/validation/tests as applicable).
6. Update affected docs/scripts when changes create reference drift.
7. Preserve memory of durable decision/bug/pattern for future sessions.

Practical discriminator set:
1. Risk level (security, data loss, regression).
2. Blast radius (single script vs policy-wide).
3. Reversibility (easy rollback vs irreversible).
4. Governance coupling (required artifact impact).
5. Scope compliance (inside requested repo and boundaries).

## 9. Is everything encapsulated in orchestrator skill + Engram?

Short answer: no.

Encapsulation is partial:
1. Orchestrator skill defines high-level workflow and coordination behavior.
2. Engram provides memory persistence and continuity.

But effective behavior also depends on:
1. Runtime instructions and workspace bootstrap rules.
2. Repository policies/configuration (orchestrator.json, structure-policy.json, workspace.config.json).
3. Validation and execution scripts (wf, ensure-tools-active, validate-script-governance, validate-workspace).
4. Documentation governance artifacts and required file inventory.

## 10. Artifacts influencing decisions

### 10.1 Policy and instruction artifacts

1. .github/copilot-instructions.md
2. AGENTS.md (workspace root)
3. workspace-foundation/AGENTS.md
4. docs/guides/DEVELOPER-COMMUNICATION-POLICY.md

### 10.2 Configuration artifacts

1. config/workspace.config.json
2. config/orchestrator.json
3. config/structure-policy.json
4. tools/session-autostart.config.json
5. config/context-efficiency.json

### 10.3 Operational enforcement artifacts

1. scripts/utilities/wf.ps1
2. scripts/utilities/ensure-tools-active.ps1
3. scripts/utilities/update-tools.ps1
4. scripts/validation/check-updates.ps1
5. scripts/validation/validate-workspace.ps1
6. scripts/diagnostics/validate-script-governance.ps1

### 10.4 Memory artifacts

1. Engram observations and session summaries.
2. Workspace/session memory notes.

## 11. Improvement Opportunities

### 11.1 Behavior and decision quality

1. Add explicit risk classification levels (low/medium/high/critical) as machine-readable policy.
2. Add mandatory confirmation prompts for high-risk categories (destructive, security, cross-repo).
3. Define an explicit decision matrix file consumed by wf and validators.

### 11.2 Understanding and consistency

1. Unify communication policy references (avoid mode drift between global and local expectations).
2. Add a single canonical glossary for terms: ready, partial, homologation, strict, advisory.
3. Add policy conflict resolution notes with concrete precedence examples.

### 11.3 Memory and learning

1. Define mandatory memory capture triggers after major actions:
   - architectural decisions
   - bug fixes
   - policy changes
2. Add periodic memory hygiene (dedupe, stale cleanup, wrong assumptions review).
3. Track "decision rationale" snapshots for reversible governance changes.

### 11.4 Training and governance maturity

1. Create a governance test suite (golden scenarios) that simulates requests and expected decisions.
2. Add CI checks for doc/code/policy reference drift.
3. Add a quarterly governance review checklist with acceptance criteria.

## 12. Suggested Next Iteration (Pragmatic)

1. Create config/decision-matrix.json with:
   - risk categories
   - consultation requirements
   - required validation gates per action type
2. Add scripts/diagnostics/validate-decision-matrix.ps1 to ensure matrix and docs remain synchronized.
3. Add docs/reference/AI-DECISION-GOVERNANCE.md as canonical non-temporary version.
4. Keep this file temporary until the team approves migration to canonical governance docs.

## 13. Coverage Mark (Implemented vs Partial)

Legend:
1. 100% = implemented, active, and validated in current workflow.
2. Partial = defined and mostly active, but not fully formalized as machine-enforced policy.
3. Pending = intentionally deferred.

### 13.1 Current coverage status

1. Tool lifecycle consistency for all 5 tools (check/install/re-check): 100%.
2. Validation gates for workspace and script governance: 100%.
3. Canonical structure enforcement and deprecated-reference checks: 100%.
4. Scope boundary discipline (no cross-repo normalization unless requested): 100% in current operating practice.
5. Consult-before-risk behavior (destructive, ambiguous, policy-impacting): Partial.
6. Double-validation criteria by explicit machine-readable matrix: Partial.
7. Unified communication-mode enforcement with conflict-proof precedence logic: Partial.
8. Decision matrix artifact plus validator in CI: Pending.

### 13.2 Interpretation

1. Operationally, the platform is active and functional for day-to-day use.
2. Remaining gaps are governance hardening gaps, not execution blockers.

## 14. Canonicalization Note for Future Releases

Decision note:
1. Keep this file as temporary analysis artifact for the current cycle.
2. Promote to canonical in a future release once the team approves the minimum governance baseline.

Minimum baseline before canonicalization:
1. Approved risk categories and consultation gates.
2. Approved double-validation requirements.
3. Agreed precedence rules when policies conflict.
4. Ownership assignment for maintenance.

Canonical target (future release):
1. docs/reference/AI-DECISION-GOVERNANCE.md
2. config/decision-matrix.json
3. scripts/diagnostics/validate-decision-matrix.ps1

## 15. Lessons Learned and Performance Trend

### 15.1 Lessons learned from project start to today

1. Config-driven tooling removes drift faster than script-by-script hardcoding.
2. Validation-only gates are not enough; cleanup and path hygiene must be continuously enforced.
3. Governance text must track executable behavior, or confidence degrades quickly.
4. Session memory and persistent observations reduce repeated mistakes and speed up closure.

### 15.2 Are we improving over time?

Evidence-based answer: yes.
1. Fewer inconsistencies after homogenizing tool behavior across scripts.
2. Faster issue detection through standardized validation gates.
3. Better predictability from explicit scope boundaries and structure policy.
4. Higher execution confidence due to repeated validate-and-fix loops.

### 15.3 Does feedback help improve?

Yes, if it is converted into artifacts.
1. Feedback that becomes config/policy/script checks is durable and reusable.
2. Feedback that remains only conversational tends to be lost.

## 16. Activation Model (Auto vs Manual)

1. Core behavior is auto-applicable when scripts run through the standard workflow.
2. Some controls are passive until triggered by command execution.
3. To force active verification, run workspace validation and governance checks explicitly.

Operational rule:
1. Automatic by convention in workflow.
2. Deterministic by command when explicit proof is required.

## 17. Portability and Knowledge Transfer

### 17.1 If repo is pushed or moved to another PC, does knowledge move too?

1. Repository-embedded knowledge moves with git (docs/config/scripts/policies).
2. External memory systems do not automatically move unless explicitly exported/synced.
3. Environment-local state (PATH, installed binaries, machine setup) must be re-established on the new machine.

### 17.2 How to share this effectively

1. Keep governance in versioned repo artifacts (docs + config + validators).
2. Add bootstrap and validation commands to onboarding guides.
3. Persist critical decisions in memory and also summarize them in repo artifacts.
4. Use release notes to announce governance changes and required actions.

---

## Annex A: Current criteria summary

1. Safety first: security/data-loss/regression warnings cannot be omitted.
2. Scope discipline: avoid cross-repo changes unless explicitly requested.
3. Canonical structure enforcement active.
4. Tooling must remain config-driven and consistent across scripts.
5. Validate after change; avoid silent drift between scripts and docs.
