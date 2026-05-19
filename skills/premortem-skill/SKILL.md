---
name: premortem-skill
description: >
  Premortem analysis for plans, launches, products, hires, strategies, or decisions. Assumes the
  plan already failed 6 months later and works backward to expose blind spots. Based on Gary Klein's
  method (Harvard Business Review), endorsed by Daniel Kahneman. Trigger: "premortem esto",
  "premortem mi", "ejecuta un premortem", "que podria matar esto", "prueba de estres este plan",
  "que me estoy perdiendo aqui", "encuentra los puntos ciegos", "que podria salir mal", "me estoy
  perdiendo algo", "hazle agujeros a esto", "donde va a romperse esto", "abogado del diablo",
  "stress test this plan", "find the blind spots", "run a premortem", "what could kill this". NOT
  triggered by simple feedback requests, factual questions, or LLM Council requests. DO trigger when
  someone has a plan where the cost of being wrong is high.
---

# Premortem Skill

## Activation Contract

Execute when user triggers a premortem request. A premortem is the opposite of a postmortem: instead
of figuring out what went wrong after something fails, you imagine it already failed and work
backward to find every reason why — before starting.

## Core Method

From psychologist Gary Klein (HBR). Daniel Kahneman called it his most valuable decision-making
technique. Used by Google, Goldman Sachs, Procter & Gamble.

**Key insight**: When asked "what could go wrong?", people give cautious, vague answers. When you
say "this already failed, tell me why", the brain shifts to narrative mode and generates much more
specific, creative, and honest reasons.

## Hard Rules

1. MUST set the premortem frame explicitly before generating failure reasons
2. MUST gather sufficient context (What, For Whom, Success criteria) before executing
3. MUST launch ALL deep-dive sub-agents in parallel, not sequentially
4. MUST generate a visual HTML report + markdown transcript
5. MUST produce a concise 3-sentence chat summary at the end
6. MUST NOT soften findings — the goal is to tell the user what they don't want to hear

## When To Execute

**Good targets**: product launches, pricing changes, hires, strategic pivots, partnerships, any
commitment where the cost of being wrong is high.

**Bad targets**: vague ideas with no concrete plan yet, single-answer factual questions, creative
feedback on drafts, already-irreversible decisions.

## Execution Steps

### 1. Context Gathering (minimum viable)

Scan current conversation and workspace for existing context. Need three things:

- **What** — clear understanding of what is being premortemed
- **For Whom** — audience, stakeholders, who it affects
- **Success** — what winning looks like

If context is insufficient, ask ONE question at a time until threshold is met.

### 2. Set The Frame

"Han pasado 6 meses. [El plan] ha fallado. Esta muerto. Miramos hacia atras intentando entender que
salio mal."

This shifts from "evaluate this plan" (compliant mode) to "explain why this died" (honest failure
identification mode).

### 3. Raw Premortem — Generate Failure Reasons

Single comprehensive analysis. No preset categories, no lenses, no constraints. Pure Klein method.
Each reason must be:

- Specific to this plan (not generic advice)
- Grounded in real details the user provided
- A genuine threat (not a minor inconvenience)

### 4. Deep-Dive Sub-Agents (ALL IN PARALLEL)

Launch one sub-agent per failure reason, all in parallel. Each agent:

**Prompt template:** "You are a researcher in a premortem analysis. The frame: 6 months have passed,
this plan has failed. Your assigned failure reason: [specific reason]. Write the story of how it
actually unfolded. Include:

1. THE FAILURE STORY — 2-3 paragraph narrative with specific moments
2. THE HIDDEN ASSUMPTION — the one thing the user took for granted that enabled this failure
3. EARLY WARNING SIGNS — 1-2 concrete, observable signals to watch for"

Each agent keeps response under 300 words.

### 5. Synthesis

Produce structured report with:

1. **Most Likely Failure** — highest probability scenario
2. **Most Dangerous Failure** — highest damage scenario (even if less likely)
3. **The Hidden Assumption** — the most important unchallenged belief
4. **The Revised Plan** — concrete changes that would increase resilience
5. **The Pre-Launch Checklist** — 3-5 specific things to verify before executing

### 6. Generate Reports

Two files in workspace root:

- `premortem-report-{timestamp}.html` — visual report with dark theme, severity indicators
- `premortem-transcript-{timestamp}.md` — full transcript as reference

## Output Contract

- **Chat**: 3-sentence summary (most likely failure, hidden assumption, single most important
  revision)
- **HTML report**: Visual, scannable, dark-themed, with synthesis cards and failure detail cards
- **Transcript**: Complete record of all context, reasons, deep-dives, and synthesis

## References

- Gary Klein, "Performing a Project Premortem", Harvard Business Review, 2007
- Daniel Kahneman, "Thinking, Fast and Slow", 2011
- Wharton/Cornell research on "prospective hindsight"
- HTML templates in `references/premortem-templates/`
- Output directory: workspace root
