# Annotated Charts

## Five Essential Annotation Types

1. **Callout Box**: Text box + arrow on a specific point (key inflection points, record highs/lows)
2. **Trend Line**: Line showing overall direction (emphasize growth despite fluctuations)
3. **Threshold Line**: Horizontal/vertical line marking a target (progress toward goal)
4. **Data Label**: Direct label on the MOST important point only (not all points)
5. **Comparative Callout**: "vs. Industry Average" label (contextualize performance)

## Best Practices

**DO:**
- Annotate ONE key insight per chart
- Use arrows/lines to clearly connect annotation to data point
- Keep annotations short (8-12 words max)
- Use a contrasting color for the annotation
- Place annotations in empty space (not over data)

**DON'T:**
- Annotate every interesting point (overwhelming)
- Use annotations that explain what's already obvious
- Make annotations larger than the data itself
- Forget to include units or context

## Annotated Chart Example

```python
import matplotlib.pyplot as plt
import numpy as np

def annotated_revenue_chart():
    months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
    revenue = [200, 210, 205, 220, 260, 300, 320, 350, 380, 420, 460, 510]
    fig, ax = plt.subplots(figsize=(12, 6))
    ax.plot(months, revenue, color="#2B6CB0", linewidth=2.5, zorder=2)
    ax.fill_between(range(len(months)), revenue, alpha=0.1, color="#2B6CB0")

    # Product launch inflection
    ax.annotate("Mobile App\nLaunch", xy=(4, 260), xytext=(2, 350),
        fontsize=12, fontweight="bold", color="#E53E3E",
        arrowprops=dict(arrowstyle="->", color="#E53E3E", linewidth=2),
        bbox=dict(boxstyle="round,pad=0.3", facecolor="white", edgecolor="#E53E3E"))

    # Key result
    ax.annotate("Record: $510K\n↑ 155% YoY", xy=(11, 510), xytext=(9, 540),
        fontsize=12, fontweight="bold", color="#38A169",
        arrowprops=dict(arrowstyle="->", color="#38A169", linewidth=2),
        bbox=dict(boxstyle="round,pad=0.3", facecolor="white", edgecolor="#38A169"))

    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color("#CBD5E0")
    ax.spines["bottom"].set_color("#CBD5E0")
    ax.grid(True, alpha=0.3, axis="y")
    ax.tick_params(colors="#4A5568")
    ax.set_title("Monthly Revenue — $510K in Record December", fontsize=16, fontweight="bold", pad=20)
    ax.set_ylabel("Revenue ($K)", fontsize=12, color="#4A5568")
    return fig
```
