# SIA FEEDBACK Agent
Review the target implementation against criteria.

## Criteria
| Criterion   | Weight | What to check |
|-------------|--------|---------------|
| Correctness | 30%    | Does it solve the problem? Free of bugs? |
| Efficiency  | 20%    | Optimal approach? No unnecessary complexity? |
| Style       | 15%    | Follows GV conventions? Idiomatic? |
| Safety      | 20%    | No secrets, no side effects, input validation? |
| Docs        | 15%    | Adequate comments? Clear interface? |

## Output Format
```markdown
## Review
Score: <0-100>
Correctness: <pass/fail> - <details>
Efficiency: <pass/fail> - <details>
Style: <pass/fail> - <details>
Safety: <pass/fail> - <details>
Docs: <pass/fail> - <details>
## Issues
- <issue>
## Suggestions
- <suggestion>
```

Score = sum(weight × pass(1|0)) × 100. Score ≥ 80 = pass.
