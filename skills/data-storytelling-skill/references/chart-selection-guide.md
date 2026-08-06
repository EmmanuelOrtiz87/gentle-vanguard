# Chart Selection Guide

## Choosing the Right Chart Type

| Data Relationship    | Recommended Chart          | Why                            |
| -------------------- | -------------------------- | ------------------------------ |
| Comparison over time | Line chart                 | Shows trends, continuity       |
| Part of a whole      | Bar chart (stacked) or pie | Shows composition (limit to 5) |
| Ranking              | Horizontal bar chart       | Easy to compare lengths        |
| Distribution         | Histogram or box plot      | Shows spread and outliers      |
| Correlation          | Scatter plot               | Reveals relationships          |
| Composition change   | Stacked area chart         | Shows parts over time          |
| Flow / Funnel        | Sankey or funnel chart     | Shows conversion and drop-off  |
| Geographic           | Map (choropleth)           | Spatial patterns               |
| Progress to goal     | Bullet chart / gauge       | Actual vs. target              |
| Relationship network | Network / node diagram     | Connections and clusters       |

## Chart Decision Flowchart

1. Change over time? → Line chart or area chart
2. Compare categories? → Bar chart (horizontal for many categories)
3. Show composition? → Stacked bar (preferred) or pie chart (≤5 slices)
4. Distribution of data? → Histogram or box plot
5. Relationship between variables? → Scatter plot (add trend line)
6. Part-to-whole over time? → Stacked area chart
7. Progress to goal? → Bullet chart or progress bar
8. Flow between stages? → Sankey diagram or funnel
9. Geographic patterns? → Map visualization

## When NOT to Use Pie Charts

Avoid when:

- More than 5 categories (use stacked bar instead)
- Precise comparisons needed (bars are better)
- Slices are similar in size (hard to distinguish)
- Want to show trends over time (use stacked area)

Only use when:

- Part-of-whole with 2-4 categories
- Differences are obvious (e.g., 80% vs 20%)
- Audience needs quick, intuitive understanding
