# Avoiding Misleading Visuals

## Common Data Visualization Traps

| Trap                          | Why It's Misleading                      | How to Fix                              |
| ----------------------------- | ---------------------------------------- | --------------------------------------- |
| Truncated Y-Axis              | Exaggerates small differences            | Start axis at 0 (or clearly mark break) |
| 3D Charts                     | Distorts proportions, hard to read       | Use flat 2D charts                      |
| Cherry-picked timeframe       | Shows favorable data, hides full picture | Show full timeline                      |
| Dual axes manipulation        | Makes unrelated trends look correlated   | Use separate charts or clarify          |
| Pie chart with 10+ slices     | Tiny slices are unreadable               | Aggregate into "Other" or use bar chart |
| Area charts not starting at 0 | Exaggerates growth                       | Always start area charts at 0           |
| Color misuse                  | Red = bad, green = good (cultural bias)  | Use color consistently, add labels      |
| Inconsistent scales           | Makes comparison impossible              | Use same scale for related charts       |
| No baseline                   | Changes look bigger/smaller than reality | Always include a comparison baseline    |
| Selectively omitted data      | Hides context, skews perception          | Show all relevant data, mark outliers   |

## The Y-Axis Rule

Bar charts and area charts **MUST** start at zero. Line charts **CAN** have a non-zero baseline but
should indicate it.

✅ Bar chart starting at 0: `[||||||||||]` = 100% ❌ Bar chart starting at 80: `[|||]` = Looks like
15% but is actually 80%

Exception: Line charts for small fluctuations (e.g., stock prices) can zoom in — but clearly mark
the axis break or use a sparkline.
