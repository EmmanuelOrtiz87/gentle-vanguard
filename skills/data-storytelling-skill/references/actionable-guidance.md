# Actionable Guidance

## The Three-Act Data Story

**ACT 1: Context**

- What's the situation?
- What are we measuring and why?
- What's the time frame?

**ACT 2: The Insight**

- What changed? (The "aha" moment)
- Why did it change? (Cause explanation)
- How significant is it? (Magnitude)

**ACT 3: Implication**

- What should we do about it?
- What happens if we don't act?
- What's the expected outcome?

## The Data-Narrative Template

```python
data_story = {
    "headline": "Revenue Grew 40% After Mobile Launch",
    "context": {
        "before": "Revenue was flat at $2M/month for 6 months",
        "catalyst": "Mobile app launched in March 2024",
        "after": "Revenue accelerated to $2.8M/month by June"
    },
    "evidence": {
        "primary_chart": "Line chart showing revenue trajectory",
        "supporting_data": "Mobile now accounts for 35% of all orders",
        "statistical_significance": "p < 0.01, R² = 0.89"
    },
    "implication": {
        "action": "Double down on mobile features and marketing",
        "projection": "Projecting $4M/month by Q4 at current growth",
        "risk": "Competitors also investing in mobile"
    }
}

def format_data_slide(story_dict):
    slide = f"""
    # {story_dict['headline']}
    **Context**: {story_dict['context']['before']}
    → {story_dict['context']['catalyst']}
    → {story_dict['context']['after']}
    [CHART: {story_dict['evidence']['primary_chart']}]
    **Key Insight**: {story_dict['evidence']['supporting_data']}
    **Action**: {story_dict['implication']['action']}
    """
    return slide
```
