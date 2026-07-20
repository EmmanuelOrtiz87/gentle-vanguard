---
name: five-whys-skill
description: >
  Imported from cc-thinking-skills. five whys, root cause, why analysis, cause analysis.
metadata:
  source: cc-thinking-skills
  original-name: thinking-five-whys-plus
---

# Five Whys Plus

## Overview

The Five Whys technique from Toyota Production System is powerful but often misapplied. This
enhanced version adds explicit guards against common failures: premature stopping, single-cause
bias, blame-oriented thinking, and confirmation bias. It transforms a simple technique into a
rigorous root cause methodology.

**Core Principle:** Keep asking "why" until you reach actionable root causes, but guard against the
technique's known failure modes.

## When to Use

- Incident post-mortems, Bug investigations, Process failures, Customer complaints, Recurring problems

## Standard Five Whys Failure Modes

| Failure Mode       | Description                     | Guard                              |
| ------------------ | ------------------------------- | ---------------------------------- |
| Premature stopping | Accepting first plausible cause | Minimum depth + actionability test |
| Single-cause bias  | Assuming one root cause         | Branch on "what else?"             |
| Blame orientation  | Stopping at human error         | "Why was error possible?"          |
| Confirmation bias  | Finding expected cause          | Devil's advocate review            |
| Circular reasoning | Why loops back on itself        | Detect and break cycles            |
| Speculation depth  | Going beyond evidence           | Evidence requirement               |

## Process Overview

1. **State the Problem Precisely** — Specific observable symptom with time, scope, impact
2. **Apply "Why" with Evidence** — Each answer requires supporting data
3. **Branch on "What Else?"** — Ruling out alternative causes
4. **Apply "Why Was This Possible?"** — Never stop at human error
5. **Check Stopping Criteria** — Actionable, Controllable, Fundamental, Evidenced, Not-blame
6. **Verify with Counter-Analysis** — Devil's advocate review

See `references/process-steps.md` for full step-by-step details with templates and examples.

## Key Questions

- "What evidence supports this answer?"
- "What else could explain this?"
- "Why was this mistake/error/failure possible?"
- "If we stop here, will the problem actually be prevented?"
- "Are we finding what we expected, or what the evidence shows?"
- "Would someone outside our team reach the same conclusion?"

## Ohno's Wisdom

Taiichi Ohno said: "By asking 'why' five times and answering each time, we can get to the real
cause of the problem."

The extension: Five is not magic. The real guidance is:
1. Keep asking until you reach something actionable
2. But don't speculate past your evidence
3. And never stop at human blame

## Additional Resources

- `references/process-steps.md` — Full step-by-step process with evidence requirements
- `references/template.md` — Enhanced analysis template with stopping criteria
- `references/example.md` — Production outage worked example
- `references/common-patterns.md` — Common failure patterns to catch
- `references/verification-checklist.md` — Verification checklist
