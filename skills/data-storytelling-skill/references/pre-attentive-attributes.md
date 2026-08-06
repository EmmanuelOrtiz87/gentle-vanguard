# Pre-Attentive Attributes

Visual properties the brain processes in under 500ms — before conscious attention. Use them to
direct the audience's eye to the most important insight instantly.

| Attribute   | Best Used For                    | Example                                  |
| ----------- | -------------------------------- | ---------------------------------------- |
| Color (hue) | Highlighting a specific category | One bar in red, others in gray           |
| Intensity   | Showing magnitude or importance  | Darker shade = higher value              |
| Size        | Showing quantity or hierarchy    | Larger circle = more users               |
| Position    | Showing ranking or sequence      | Top of list = highest ranked             |
| Orientation | Showing difference or grouping   | Angled element vs. straight              |
| Shape       | Categorizing different types     | Circles for product, squares for service |
| Motion      | Showing change or urgency        | Animated growth (use sparingly)          |

## The Highlighting Technique

```python
import matplotlib.pyplot as plt
import numpy as np

def highlight_bar_chart(categories, values, highlight_index,
                         highlight_color="#E53E3E",
                         default_color="#CBD5E0"):
    colors = [highlight_color if i == highlight_index else default_color
              for i in range(len(categories))]
    fig, ax = plt.subplots(figsize=(10, 6))
    bars = ax.bar(categories, values, color=colors, width=0.6)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color("#E2E8F0")
    ax.spines["bottom"].set_color("#E2E8F0")
    ax.grid(False)
    for bar, value in zip(bars, values):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 1,
                f"{value}", ha="center", va="bottom",
                fontsize=12, fontweight="bold" if value == max(values) else "normal",
                color="#2D3748")
    ax.set_title("Revenue by Channel", fontsize=16, fontweight="bold", pad=20)
    return fig

# Example
categories = ["Direct", "Organic", "Paid Ads", "Social", "Referral"]
values = [45, 120, 85, 60, 40]
# chart = highlight_bar_chart(categories, values, highlight_index=1)
```
