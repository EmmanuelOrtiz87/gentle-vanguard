# Decision Gates — Context Engineering

## Context Usage Thresholds

| Context Used | Action | Token Cost |
|-------------|--------|------------|
| < 40% | Work normally | none |
| 40-60% | Consider `context-pack` for next session | ~1,200 tokens |
| > 60% (YELLOW) | Run `compact-start` before next message | ~1,600 tokens |
| > 80% (RED) | Must compact OR start new session with context pack | — |

## Activation Policy (compact-start)

| Condition | Action |
|-----------|--------|
| Context health RED (>60% used) | Run `compact-start` before next message |
| Starting new thread/session | Run `compact-start` OR check `.session/.compact-marker` |
| Health GREEN or YELLOW | Skip |
| `.compact-marker` <60 min old | Skip — already ran recently |

## Objective Rules

- MUST be ≤100 chars — one sentence, no filler
- MUST describe what to resume, not how
- ✅ `"fix ci noise in build pipeline"`
- ❌ `"we need to continue working on the issue with the CI pipeline where..."`

## Token Budget per Task

| Task | Base Tokens | Risk Multiplier |
|------|------------|-----------------|
| compact-start | 1,600 | medium (×1.0) |
| context-pack | 1,200 | medium (×1.0) |
| review | 3,200 | high (×1.25) |
| audit | 2,200 | medium (×1.0) |
| end-session | 1,800 | low (×0.8) |
| publish | 4,500 | high (×1.25) |

Daily budget: 120,000 tokens | Soft threshold: 70% | Hard threshold: 90%.
