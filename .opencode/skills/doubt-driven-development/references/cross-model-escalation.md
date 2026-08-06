# Cross-Model Escalation

A single-model reviewer shares blind spots with the original author — a colder,
different-architecture model catches them. Doubt-driven is already opt-in for non-trivial decisions,
so within that scope offering cross-model is part of the skill's value, not optional friction.

**Interactive sessions: always offer. Never silently skip.**

## Step 1: Ask the user

After the single-model review in Step 3, but before RECONCILE, pause and ask:

> _"Single-model review complete. Want a cross-model second opinion? Options: Gemini CLI, Codex CLI,
> manual external review (you paste it elsewhere), or skip."_

This question is mandatory in every interactive doubt cycle — even on artifacts that feel
low-stakes. The user — not the agent — decides whether the cost is worth it. The agent's job is to
surface the choice.

## Step 2: If the user picks a CLI — verify, then invoke

1. Check the tool is in PATH (`which gemini`, `which codex`).
2. Test it works (`gemini --version` or equivalent) before passing the full prompt — a stale or
   broken binary may pass `which` but fail on real input.
3. Confirm the exact invocation with the user, including required flags, auth, and env vars (e.g.,
   API keys). Implementations vary; never assume.
4. Pass ARTIFACT + CONTRACT + the adversarial prompt **only**. No session context, no CLAIM.
5. Mind shell escaping. If the artifact contains quotes, `$(...)`, or backticks, prefer stdin
   (`echo … | gemini`) or a heredoc over inline `-p "…"`. When in doubt, ask the user to confirm the
   invocation before running it.
6. Take the output into Step 4 (RECONCILE).

**Never interpolate the artifact into a shell-quoted argument.** Code, markdown, and review prompts
routinely contain backticks, `$(...)`, and quote characters that will either truncate the prompt or
execute embedded shell. Write the full prompt to a file and pipe it through stdin.

### Example invocations (verify flags against your installed tool — syntax differs across implementations and versions)

```bash
# Write the adversarial prompt + ARTIFACT + CONTRACT to a temp file first.
# Then pipe via stdin so shell metacharacters in the artifact stay inert.

# Codex (read-only sandbox keeps the CLI from writing to your workspace):
codex exec --sandbox read-only -C <repo-path> - < /tmp/doubt-prompt.md

# Gemini ('--approval-mode plan' is read-only; '-p ""' triggers non-interactive
# mode and the prompt is read from stdin):
gemini --approval-mode plan -p "" < /tmp/doubt-prompt.md
```

A read-only sandbox is the load-bearing detail: a doubt artifact may itself contain instructions
(intentional or accidental prompt injection) that the cross-model CLI would otherwise execute
against your workspace.

## Step 3: If the CLI is unavailable or fails

Surface the failure explicitly. Offer: run it manually, try a different tool, or skip. Do not
silently fall back to single-model — the user should know cross-model didn't happen.

## Step 4: If the user skips

Acknowledge the skip in the output (_"Proceeding with single-model findings only"_) and continue to
RECONCILE. Skipping is fine; silent skipping is not.

## Non-interactive contexts

In CI, `/loop`, autonomous-loop, or scheduled runs:

- Cross-model is **skipped**, and the skip must be **announced** in the output: _"Cross-model
  skipped: non-interactive context."_
- **Never invoke an external CLI without explicit user authorization** — this is a load-bearing
  safety property.

Cross-model adds cost, latency, and tool fragility. The agent surfaces the choice every cycle; the
user decides whether this artifact warrants it.
