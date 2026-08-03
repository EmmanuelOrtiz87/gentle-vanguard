# Core Principles

## 1. Clarity Over Cleverness

A clear, direct prompt always outperforms a clever but ambiguous one. State exactly what you want,
in what format, and with what constraints. Ambiguity is the enemy of consistent output.

## 2. Context is Everything

Models have no inherent context beyond their training data. Every prompt must establish:

- **Who** the model should be (role)
- **What** the task is (instruction)
- **How** to respond (format, tone, length)
- **Why** the task matters (optional but helpful for complex tasks)

## 3. Iterate, Don't Expect Perfection First Time

The first prompt is rarely the best. Prompt engineering is an iterative discipline. Each refinement
teaches you something about how the model interprets your instructions.

## 4. Constrain to Liberate

Paradoxically, more constraints (format, length constraints, guardrails) lead to better outputs.
Open-ended prompts invite hallucination and inconsistency.

## 5. Test Systematically

Change one variable at a time. Track what works. Build a personal library of prompt patterns that
reliably produce good results.
