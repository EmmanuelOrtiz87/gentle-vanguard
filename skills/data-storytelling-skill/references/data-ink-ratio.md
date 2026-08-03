# Data-Ink Ratio

Data-Ink = pixels used to display data
Non-Data-Ink = decorative elements, gridlines, borders, backgrounds

Data-Ink Ratio = Data-Ink / Total Ink

Goal: Maximize the data-ink ratio (remove non-data ink without losing context)

## Poor vs Good

❌ **POOR** (Low data-ink ratio):
- 3D bar chart with shadows and gradients
- Background color with gradient
- Thick gridlines every interval
- Heavy borders around everything
- Decorative clip art, drop shadows
- Excessive axis labels

✅ **GOOD** (High data-ink ratio):
- Flat, 2D design, minimal/no background fill
- Thin, light gridlines (or none), no chart borders
- Data points stand out with color
- Labels only where necessary
- Clean typography

## Applying Data-Ink Principle

```python
import matplotlib.pyplot as plt
import numpy as np

months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
revenue = [120, 145, 160, 185, 210, 245]

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

# BAD: Low data-ink ratio
ax1.bar(months, revenue, color="skyblue", edgecolor="black", linewidth=1.5)
ax1.set_title("Bad: Low Data-Ink Ratio", fontsize=16, fontweight="bold")
ax1.set_facecolor("#f0f0f0")
ax1.grid(True, axis="y", alpha=0.8, linewidth=1.5)
ax1.spines["top"].set_visible(True)
ax1.spines["right"].set_visible(True)
ax1.spines["left"].set_linewidth(2)
ax1.spines["bottom"].set_linewidth(2)

# GOOD: High data-ink ratio
ax2.bar(months, revenue, color="#2B6CB0", width=0.6)
ax2.set_title("Good: High Data-Ink Ratio", fontsize=16, fontweight="bold")
ax2.set_facecolor("white")
ax2.grid(False)
ax2.spines["top"].set_visible(False)
ax2.spines["right"].set_visible(False)
ax2.spines["left"].set_color("#CBD5E0")
ax2.spines["bottom"].set_color("#CBD5E0")
ax2.tick_params(colors="#4A5568")

plt.tight_layout()
```
