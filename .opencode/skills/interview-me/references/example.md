# Example

A complete before-and-after showing the skill in action.

## Without `interview-me`

```
User:  build me a dashboard for our metrics
Agent: <starts proposing chart libraries and layouts>
```

The agent has assumed: who it's for, what metrics, what "for our team" means, what
success looks like. None of these are stated. Every assumption is a place the user can
later say "that's not what I meant."

## With `interview-me`

```
User: build me a dashboard for our metrics

Agent:
HYPOTHESIS: You want a way to answer "how are we doing?" in standup, and "dashboard"
            came to mind because that's the conventional answer.
CONFIDENCE: ~30% — missing: who it's for, what "metrics" are, and what success looks like

Q:     When you say "how are we doing?", who's asking — you alone, the engineering
       team in standup, or up the chain (e.g., your manager, an exec, a board)?
GUESS: engineering team in standup, because "we" usually scopes that way and standups
       are where this question gets asked. If it's for execs, metrics and framing
       change a lot.

User: It's actually for me. I keep losing track of which experiments are running and
      what their early signal looks like.

Agent:
Updated read: not a team dashboard at all. It's a personal experiment tracker.
Confidence: ~60% — still missing: what "early signal" means and what done looks like.

Q:     Is the gap that you don't know which experiments exist, or that you can't see
       their results in one place?
GUESS: the second one. You have a list of experiments somewhere, but their results
       live in five different tools, and reconciling them by hand is what you're
       tired of.

User: First one actually. I literally don't have a list. They're spread across
      different docs.

Agent: <continues>
```

Two questions in, the agent has discovered the actual ask isn't "a dashboard." It's
"a list." Different artifact, different scope, different work. The dashboard would
have been wrong.
